#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
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
// Re-points the GPU resource's backing pages to the physical pages
// underlying the user buffer buf.  No pixel data is copied.
// buf must be page-aligned and all GPU_FB_PAGES pages must be mapped
// with user permission.  Returns 0 on success, -1 on error.
uint64
sys_flip_display(void)
{
  uint64 buf;
  argaddr(0, &buf);

  struct proc *p = myproc();

  if (buf % PGSIZE != 0)
    return -1;

  // Walk the user page table to collect physical addresses for each page.
  uint64 phys_pages[GPU_FB_PAGES];
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    uint64 va = buf + (uint64)i * PGSIZE;
    // walkaddr verifies PTE_V | PTE_U; returns 0 if not mapped or no user perm
    uint64 pa = walkaddr(p->pagetable, va);
    if (pa == 0)
      return -1;
    phys_pages[i] = pa;
  }

  virtio_gpu_flip(phys_pages, GPU_FB_PAGES);
  return 0;
}

// sys_map_display: map the GPU's kernel framebuffer pages (fb[]) directly
// into the calling process's address space with PTE_U|PTE_R|PTE_W.
//
// Argument 0: desired virtual address (page-aligned), or 0 to let the
// kernel auto-select a free VA above p->sz.
// Returns the mapped VA on success, (uint64)-1 on failure.
uint64
sys_map_display(void)
{
  uint64 addr;
  argaddr(0, &addr);

  struct proc *p = myproc();

  if (addr == 0) {
    // Auto-select: first page-aligned VA above the current heap.
    addr = PGROUNDUP(p->sz);
  } else {
    if (addr % PGSIZE != 0)
      return -1;
  }

  // The entire region must fit below the trapframe.
  if (addr + (uint64)GPU_FB_PAGES * PGSIZE > TRAPFRAME)
    return -1;

  // Verify that no page in the region is already mapped.
  for (uint64 va = addr; va < addr + (uint64)GPU_FB_PAGES * PGSIZE; va += PGSIZE) {
    pte_t *pte = walk(p->pagetable, va, 0);
    if (pte && (*pte & PTE_V))
      return -1;
  }

  if (virtio_gpu_map_fb(p->pagetable, addr) != 0)
    return -1;

  p->fb_map_va = addr;
  return addr;
}
