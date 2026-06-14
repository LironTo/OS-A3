#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

// Functions exposed from virtio_gpu.c.
extern void **virtio_gpu_fb_pages(void);
extern void   virtio_gpu_flip(uint64 *phys_addrs, int n);
extern void   virtio_gpu_restore_fb(void);

// Per-process record of where the GPU framebuffer is mapped (map_display).
// Indexed by pid % NPROC; 0 means not mapped.
static uint64 fb_va_by_pid[NPROC];

// Per-process flag: 1 if the GPU is currently backed by this process's
// user pages (flip_display was called).  Indexed by pid % NPROC.
static int flip_done_by_pid[NPROC];

// Temporary physical-address buffer used by sys_flip_display.
// Declared static to avoid a ~2400-byte stack allocation.
static uint64 flip_phys_buf[GPU_FB_PAGES];

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);

  struct proc *p = myproc();
  int idx = p->pid % NPROC;

  // Unmap the GPU framebuffer before the page table is freed so that
  // freewalk() does not panic on dangling leaf PTEs.  do_free=0 because
  // the pages are kernel-owned (fb[] in virtio_gpu.c).
  if (fb_va_by_pid[idx] != 0) {
    uvmunmap(p->pagetable, fb_va_by_pid[idx], GPU_FB_PAGES, 0);
    fb_va_by_pid[idx] = 0;
  }

  // Restore GPU backing to kernel fb[] so the device does not keep reading
  // freed user pages after this process dies.
  if (flip_done_by_pid[idx]) {
    virtio_gpu_restore_fb();
    flip_done_by_pid[idx] = 0;
  }

  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// sys_flip_display: zero-copy page flip.
//
// Syscall argument 0: user virtual address of a page-aligned buffer
// that is exactly GPU_FB_PAGES (300) * PGSIZE bytes (i.e. 640x480x4 =
// 1,228,800 bytes).  The buffer must already be fully mapped in the
// calling process's address space.
uint64
sys_flip_display(void)
{
  uint64 buf;
  struct proc *p = myproc();

  argaddr(0, &buf);

  // Buffer must be page-aligned.
  if (buf % PGSIZE != 0)
    return -1;

  // Walk the page table page-by-page to collect physical addresses.
  // walkaddr() returns 0 for any page that is not present or not
  // accessible to user space (PTE_V and PTE_U must both be set).
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    uint64 pa = walkaddr(p->pagetable, buf + (uint64)i * PGSIZE);
    if (pa == 0)
      return -1;
    flip_phys_buf[i] = pa;
  }

  // Re-point the GPU device's backing list to the user's physical pages.
  virtio_gpu_flip(flip_phys_buf, GPU_FB_PAGES);
  flip_done_by_pid[p->pid % NPROC] = 1;
  return 0;
}

// sys_map_display: map the GPU's kernel framebuffer pages (fb[]) directly
// into the calling process's address space with PTE_U|PTE_R|PTE_W.
//
// Syscall argument 0: desired user virtual address (must be page-aligned).
//   Pass 0 to let the kernel auto-select the next available VA above p->sz.
//
// Returns the mapped virtual address on success, (uint64)-1 on failure.
uint64
sys_map_display(void)
{
  uint64 addr;
  struct proc *p = myproc();

  argaddr(0, &addr);

  // User-supplied address must be page-aligned.
  if (addr != 0 && addr % PGSIZE != 0)
    return -1;

  void **fb = virtio_gpu_fb_pages();
  uint64 fb_size = (uint64)GPU_FB_PAGES * PGSIZE;

  if (addr == 0) {
    // Auto-select: first page-aligned VA above the heap.
    addr = PGROUNDUP(p->sz);
  }

  // Verify [addr, addr+fb_size) does not overlap any existing mapping.
  for (uint64 va = addr; va < addr + fb_size; va += PGSIZE) {
    pte_t *pte = walk(p->pagetable, va, 0);
    if (pte && (*pte & PTE_V))
      return -1;
  }

  // Install one PTE per framebuffer page with user r/w permission.
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    if (mappages(p->pagetable, addr + (uint64)i * PGSIZE, PGSIZE,
                 (uint64)fb[i], PTE_U | PTE_R | PTE_W) != 0) {
      // Undo any partial mapping; do_free=0, kernel owns these pages.
      if (i > 0)
        uvmunmap(p->pagetable, addr, i, 0);
      return -1;
    }
  }

  // Record the mapping so sys_exit can remove it before freewalk runs.
  fb_va_by_pid[p->pid % NPROC] = addr;

  return addr;
}
