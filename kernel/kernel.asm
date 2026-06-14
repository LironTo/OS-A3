
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	21013103          	ld	sp,528(sp) # 80009210 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	21e70713          	addi	a4,a4,542 # 80009270 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d4c78793          	addi	a5,a5,-692 # 80005db0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd8f07>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	422080e7          	jalr	1058(ra) # 8000254e <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	22650513          	addi	a0,a0,550 # 800113b0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	21648493          	addi	s1,s1,534 # 800113b0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	2a690913          	addi	s2,s2,678 # 80011448 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	822080e7          	jalr	-2014(ra) # 800019e2 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1d0080e7          	jalr	464(ra) # 80002398 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f1a080e7          	jalr	-230(ra) # 800020f0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2e6080e7          	jalr	742(ra) # 800024f8 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	18a50513          	addi	a0,a0,394 # 800113b0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	17450513          	addi	a0,a0,372 # 800113b0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	1cf72b23          	sw	a5,470(a4) # 80011448 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	0e450513          	addi	a0,a0,228 # 800113b0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2b2080e7          	jalr	690(ra) # 800025a4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	0b650513          	addi	a0,a0,182 # 800113b0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	09270713          	addi	a4,a4,146 # 800113b0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	06878793          	addi	a5,a5,104 # 800113b0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	0d27a783          	lw	a5,210(a5) # 80011448 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	02670713          	addi	a4,a4,38 # 800113b0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	01648493          	addi	s1,s1,22 # 800113b0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	fda70713          	addi	a4,a4,-38 # 800113b0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	06f72223          	sw	a5,100(a4) # 80011450 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	f9e78793          	addi	a5,a5,-98 # 800113b0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	00c7ab23          	sw	a2,22(a5) # 8001144c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	00a50513          	addi	a0,a0,10 # 80011448 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d0e080e7          	jalr	-754(ra) # 80002154 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	f5050513          	addi	a0,a0,-176 # 800113b0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	2d078793          	addi	a5,a5,720 # 80021748 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	f207a323          	sw	zero,-218(a5) # 80011470 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b6c50513          	addi	a0,a0,-1172 # 800080d8 <digits+0x98>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	caf72923          	sw	a5,-846(a4) # 80009230 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	eb6dad83          	lw	s11,-330(s11) # 80011470 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	e6050513          	addi	a0,a0,-416 # 80011458 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00011517          	auipc	a0,0x11
    8000075a:	d0250513          	addi	a0,a0,-766 # 80011458 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00011497          	auipc	s1,0x11
    80000776:	ce648493          	addi	s1,s1,-794 # 80011458 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00011517          	auipc	a0,0x11
    800007d6:	ca650513          	addi	a0,a0,-858 # 80011478 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00009797          	auipc	a5,0x9
    80000802:	a327a783          	lw	a5,-1486(a5) # 80009230 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00009797          	auipc	a5,0x9
    8000083a:	a027b783          	ld	a5,-1534(a5) # 80009238 <uart_tx_r>
    8000083e:	00009717          	auipc	a4,0x9
    80000842:	a0273703          	ld	a4,-1534(a4) # 80009240 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00011a17          	auipc	s4,0x11
    80000864:	c18a0a13          	addi	s4,s4,-1000 # 80011478 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00009497          	auipc	s1,0x9
    8000086c:	9d048493          	addi	s1,s1,-1584 # 80009238 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00009997          	auipc	s3,0x9
    80000874:	9d098993          	addi	s3,s3,-1584 # 80009240 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	8c2080e7          	jalr	-1854(ra) # 80002154 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	baa50513          	addi	a0,a0,-1110 # 80011478 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	9527a783          	lw	a5,-1710(a5) # 80009230 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00009717          	auipc	a4,0x9
    800008ec:	95873703          	ld	a4,-1704(a4) # 80009240 <uart_tx_w>
    800008f0:	00009797          	auipc	a5,0x9
    800008f4:	9487b783          	ld	a5,-1720(a5) # 80009238 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00011997          	auipc	s3,0x11
    80000900:	b7c98993          	addi	s3,s3,-1156 # 80011478 <uart_tx_lock>
    80000904:	00009497          	auipc	s1,0x9
    80000908:	93448493          	addi	s1,s1,-1740 # 80009238 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00009917          	auipc	s2,0x9
    80000910:	93490913          	addi	s2,s2,-1740 # 80009240 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	7d4080e7          	jalr	2004(ra) # 800020f0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00011497          	auipc	s1,0x11
    80000936:	b4648493          	addi	s1,s1,-1210 # 80011478 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00009797          	auipc	a5,0x9
    8000094a:	8ee7bd23          	sd	a4,-1798(a5) # 80009240 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	abc48493          	addi	s1,s1,-1348 # 80011478 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00025797          	auipc	a5,0x25
    80000a02:	efa78793          	addi	a5,a5,-262 # 800258f8 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	a9290913          	addi	s2,s2,-1390 # 800114b0 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00011517          	auipc	a0,0x11
    80000abe:	9f650513          	addi	a0,a0,-1546 # 800114b0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00025517          	auipc	a0,0x25
    80000ad2:	e2a50513          	addi	a0,a0,-470 # 800258f8 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00011497          	auipc	s1,0x11
    80000af4:	9c048493          	addi	s1,s1,-1600 # 800114b0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00011517          	auipc	a0,0x11
    80000b0c:	9a850513          	addi	a0,a0,-1624 # 800114b0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00011517          	auipc	a0,0x11
    80000b38:	97c50513          	addi	a0,a0,-1668 # 800114b0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e56080e7          	jalr	-426(ra) # 800019c6 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e24080e7          	jalr	-476(ra) # 800019c6 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e18080e7          	jalr	-488(ra) # 800019c6 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	e00080e7          	jalr	-512(ra) # 800019c6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dc0080e7          	jalr	-576(ra) # 800019c6 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d94080e7          	jalr	-620(ra) # 800019c6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b36080e7          	jalr	-1226(ra) # 800019b6 <cpuid>
    userinit();      // first user process
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	3c070713          	addi	a4,a4,960 # 80009248 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b1a080e7          	jalr	-1254(ra) # 800019b6 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	22250513          	addi	a0,a0,546 # 800080c8 <digits+0x88>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0f8080e7          	jalr	248(ra) # 80000fae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	826080e7          	jalr	-2010(ra) # 800026e4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	f2a080e7          	jalr	-214(ra) # 80005df0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	070080e7          	jalr	112(ra) # 80001f3e <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1f250513          	addi	a0,a0,498 # 800080d8 <digits+0x98>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1d250513          	addi	a0,a0,466 # 800080d8 <digits+0x98>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	35c080e7          	jalr	860(ra) # 8000127a <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	088080e7          	jalr	136(ra) # 80000fae <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9d4080e7          	jalr	-1580(ra) # 80001902 <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	786080e7          	jalr	1926(ra) # 800026bc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7a6080e7          	jalr	1958(ra) # 800026e4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e94080e7          	jalr	-364(ra) # 80005dda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	ea2080e7          	jalr	-350(ra) # 80005df0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	048080e7          	jalr	72(ra) # 80002f9e <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	6ec080e7          	jalr	1772(ra) # 8000364a <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	68a080e7          	jalr	1674(ra) # 800045f0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	f8a080e7          	jalr	-118(ra) # 80005ef8 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	690080e7          	jalr	1680(ra) # 80006606 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d3c080e7          	jalr	-708(ra) # 80001cba <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	ade50513          	addi	a0,a0,-1314 # 80006a6c <display_daemon>
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	da6080e7          	jalr	-602(ra) # 80001d3c <kproc_create>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	2af72223          	sw	a5,676(a4) # 80009248 <started>
    80000fac:	b70d                	j	80000ece <main+0x56>

0000000080000fae <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e422                	sd	s0,8(sp)
    80000fb2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb8:	00008797          	auipc	a5,0x8
    80000fbc:	2987b783          	ld	a5,664(a5) # 80009250 <kernel_pagetable>
    80000fc0:	83b1                	srli	a5,a5,0xc
    80000fc2:	577d                	li	a4,-1
    80000fc4:	177e                	slli	a4,a4,0x3f
    80000fc6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fcc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fd0:	6422                	ld	s0,8(sp)
    80000fd2:	0141                	addi	sp,sp,16
    80000fd4:	8082                	ret

0000000080000fd6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd6:	7139                	addi	sp,sp,-64
    80000fd8:	fc06                	sd	ra,56(sp)
    80000fda:	f822                	sd	s0,48(sp)
    80000fdc:	f426                	sd	s1,40(sp)
    80000fde:	f04a                	sd	s2,32(sp)
    80000fe0:	ec4e                	sd	s3,24(sp)
    80000fe2:	e852                	sd	s4,16(sp)
    80000fe4:	e456                	sd	s5,8(sp)
    80000fe6:	e05a                	sd	s6,0(sp)
    80000fe8:	0080                	addi	s0,sp,64
    80000fea:	84aa                	mv	s1,a0
    80000fec:	89ae                	mv	s3,a1
    80000fee:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ff0:	57fd                	li	a5,-1
    80000ff2:	83e9                	srli	a5,a5,0x1a
    80000ff4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff8:	04b7f263          	bgeu	a5,a1,8000103c <walk+0x66>
    panic("walk");
    80000ffc:	00007517          	auipc	a0,0x7
    80001000:	0e450513          	addi	a0,a0,228 # 800080e0 <digits+0xa0>
    80001004:	fffff097          	auipc	ra,0xfffff
    80001008:	53a080e7          	jalr	1338(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000100c:	060a8663          	beqz	s5,80001078 <walk+0xa2>
    80001010:	00000097          	auipc	ra,0x0
    80001014:	ad6080e7          	jalr	-1322(ra) # 80000ae6 <kalloc>
    80001018:	84aa                	mv	s1,a0
    8000101a:	c529                	beqz	a0,80001064 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000101c:	6605                	lui	a2,0x1
    8000101e:	4581                	li	a1,0
    80001020:	00000097          	auipc	ra,0x0
    80001024:	cb2080e7          	jalr	-846(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001028:	00c4d793          	srli	a5,s1,0xc
    8000102c:	07aa                	slli	a5,a5,0xa
    8000102e:	0017e793          	ori	a5,a5,1
    80001032:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001036:	3a5d                	addiw	s4,s4,-9
    80001038:	036a0063          	beq	s4,s6,80001058 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000103c:	0149d933          	srl	s2,s3,s4
    80001040:	1ff97913          	andi	s2,s2,511
    80001044:	090e                	slli	s2,s2,0x3
    80001046:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001048:	00093483          	ld	s1,0(s2)
    8000104c:	0014f793          	andi	a5,s1,1
    80001050:	dfd5                	beqz	a5,8000100c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001052:	80a9                	srli	s1,s1,0xa
    80001054:	04b2                	slli	s1,s1,0xc
    80001056:	b7c5                	j	80001036 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001058:	00c9d513          	srli	a0,s3,0xc
    8000105c:	1ff57513          	andi	a0,a0,511
    80001060:	050e                	slli	a0,a0,0x3
    80001062:	9526                	add	a0,a0,s1
}
    80001064:	70e2                	ld	ra,56(sp)
    80001066:	7442                	ld	s0,48(sp)
    80001068:	74a2                	ld	s1,40(sp)
    8000106a:	7902                	ld	s2,32(sp)
    8000106c:	69e2                	ld	s3,24(sp)
    8000106e:	6a42                	ld	s4,16(sp)
    80001070:	6aa2                	ld	s5,8(sp)
    80001072:	6b02                	ld	s6,0(sp)
    80001074:	6121                	addi	sp,sp,64
    80001076:	8082                	ret
        return 0;
    80001078:	4501                	li	a0,0
    8000107a:	b7ed                	j	80001064 <walk+0x8e>

000000008000107c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000107c:	57fd                	li	a5,-1
    8000107e:	83e9                	srli	a5,a5,0x1a
    80001080:	00b7f463          	bgeu	a5,a1,80001088 <walkaddr+0xc>
    return 0;
    80001084:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001086:	8082                	ret
{
    80001088:	1141                	addi	sp,sp,-16
    8000108a:	e406                	sd	ra,8(sp)
    8000108c:	e022                	sd	s0,0(sp)
    8000108e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001090:	4601                	li	a2,0
    80001092:	00000097          	auipc	ra,0x0
    80001096:	f44080e7          	jalr	-188(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000109a:	c105                	beqz	a0,800010ba <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000109c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109e:	0117f693          	andi	a3,a5,17
    800010a2:	4745                	li	a4,17
    return 0;
    800010a4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a6:	00e68663          	beq	a3,a4,800010b2 <walkaddr+0x36>
}
    800010aa:	60a2                	ld	ra,8(sp)
    800010ac:	6402                	ld	s0,0(sp)
    800010ae:	0141                	addi	sp,sp,16
    800010b0:	8082                	ret
  pa = PTE2PA(*pte);
    800010b2:	00a7d513          	srli	a0,a5,0xa
    800010b6:	0532                	slli	a0,a0,0xc
  return pa;
    800010b8:	bfcd                	j	800010aa <walkaddr+0x2e>
    return 0;
    800010ba:	4501                	li	a0,0
    800010bc:	b7fd                	j	800010aa <walkaddr+0x2e>

00000000800010be <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010be:	715d                	addi	sp,sp,-80
    800010c0:	e486                	sd	ra,72(sp)
    800010c2:	e0a2                	sd	s0,64(sp)
    800010c4:	fc26                	sd	s1,56(sp)
    800010c6:	f84a                	sd	s2,48(sp)
    800010c8:	f44e                	sd	s3,40(sp)
    800010ca:	f052                	sd	s4,32(sp)
    800010cc:	ec56                	sd	s5,24(sp)
    800010ce:	e85a                	sd	s6,16(sp)
    800010d0:	e45e                	sd	s7,8(sp)
    800010d2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d4:	c639                	beqz	a2,80001122 <mappages+0x64>
    800010d6:	8aaa                	mv	s5,a0
    800010d8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010da:	77fd                	lui	a5,0xfffff
    800010dc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010e0:	15fd                	addi	a1,a1,-1
    800010e2:	00c589b3          	add	s3,a1,a2
    800010e6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ea:	8952                	mv	s2,s4
    800010ec:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010f0:	6b85                	lui	s7,0x1
    800010f2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f6:	4605                	li	a2,1
    800010f8:	85ca                	mv	a1,s2
    800010fa:	8556                	mv	a0,s5
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	eda080e7          	jalr	-294(ra) # 80000fd6 <walk>
    80001104:	cd1d                	beqz	a0,80001142 <mappages+0x84>
    if(*pte & PTE_V)
    80001106:	611c                	ld	a5,0(a0)
    80001108:	8b85                	andi	a5,a5,1
    8000110a:	e785                	bnez	a5,80001132 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000110c:	80b1                	srli	s1,s1,0xc
    8000110e:	04aa                	slli	s1,s1,0xa
    80001110:	0164e4b3          	or	s1,s1,s6
    80001114:	0014e493          	ori	s1,s1,1
    80001118:	e104                	sd	s1,0(a0)
    if(a == last)
    8000111a:	05390063          	beq	s2,s3,8000115a <mappages+0x9c>
    a += PGSIZE;
    8000111e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001120:	bfc9                	j	800010f2 <mappages+0x34>
    panic("mappages: size");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fc650513          	addi	a0,a0,-58 # 800080e8 <digits+0xa8>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001132:	00007517          	auipc	a0,0x7
    80001136:	fc650513          	addi	a0,a0,-58 # 800080f8 <digits+0xb8>
    8000113a:	fffff097          	auipc	ra,0xfffff
    8000113e:	404080e7          	jalr	1028(ra) # 8000053e <panic>
      return -1;
    80001142:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret
  return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7e5                	j	80001144 <mappages+0x86>

000000008000115e <kvmmap>:
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e406                	sd	ra,8(sp)
    80001162:	e022                	sd	s0,0(sp)
    80001164:	0800                	addi	s0,sp,16
    80001166:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001168:	86b2                	mv	a3,a2
    8000116a:	863e                	mv	a2,a5
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	f52080e7          	jalr	-174(ra) # 800010be <mappages>
    80001174:	e509                	bnez	a0,8000117e <kvmmap+0x20>
}
    80001176:	60a2                	ld	ra,8(sp)
    80001178:	6402                	ld	s0,0(sp)
    8000117a:	0141                	addi	sp,sp,16
    8000117c:	8082                	ret
    panic("kvmmap");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f8a50513          	addi	a0,a0,-118 # 80008108 <digits+0xc8>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3b8080e7          	jalr	952(ra) # 8000053e <panic>

000000008000118e <kvmmake>:
{
    8000118e:	1101                	addi	sp,sp,-32
    80001190:	ec06                	sd	ra,24(sp)
    80001192:	e822                	sd	s0,16(sp)
    80001194:	e426                	sd	s1,8(sp)
    80001196:	e04a                	sd	s2,0(sp)
    80001198:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	94c080e7          	jalr	-1716(ra) # 80000ae6 <kalloc>
    800011a2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a4:	6605                	lui	a2,0x1
    800011a6:	4581                	li	a1,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	b2a080e7          	jalr	-1238(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b0:	4719                	li	a4,6
    800011b2:	6685                	lui	a3,0x1
    800011b4:	10000637          	lui	a2,0x10000
    800011b8:	100005b7          	lui	a1,0x10000
    800011bc:	8526                	mv	a0,s1
    800011be:	00000097          	auipc	ra,0x0
    800011c2:	fa0080e7          	jalr	-96(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c6:	4719                	li	a4,6
    800011c8:	6685                	lui	a3,0x1
    800011ca:	10001637          	lui	a2,0x10001
    800011ce:	100015b7          	lui	a1,0x10001
    800011d2:	8526                	mv	a0,s1
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	f8a080e7          	jalr	-118(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, VIRTIO1, VIRTIO1, PGSIZE, PTE_R | PTE_W);
    800011dc:	4719                	li	a4,6
    800011de:	6685                	lui	a3,0x1
    800011e0:	10002637          	lui	a2,0x10002
    800011e4:	100025b7          	lui	a1,0x10002
    800011e8:	8526                	mv	a0,s1
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f74080e7          	jalr	-140(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011f2:	4719                	li	a4,6
    800011f4:	004006b7          	lui	a3,0x400
    800011f8:	0c000637          	lui	a2,0xc000
    800011fc:	0c0005b7          	lui	a1,0xc000
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f5c080e7          	jalr	-164(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000120a:	00007917          	auipc	s2,0x7
    8000120e:	df690913          	addi	s2,s2,-522 # 80008000 <etext>
    80001212:	4729                	li	a4,10
    80001214:	80007697          	auipc	a3,0x80007
    80001218:	dec68693          	addi	a3,a3,-532 # 8000 <_entry-0x7fff8000>
    8000121c:	4605                	li	a2,1
    8000121e:	067e                	slli	a2,a2,0x1f
    80001220:	85b2                	mv	a1,a2
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f3a080e7          	jalr	-198(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000122c:	4719                	li	a4,6
    8000122e:	46c5                	li	a3,17
    80001230:	06ee                	slli	a3,a3,0x1b
    80001232:	412686b3          	sub	a3,a3,s2
    80001236:	864a                	mv	a2,s2
    80001238:	85ca                	mv	a1,s2
    8000123a:	8526                	mv	a0,s1
    8000123c:	00000097          	auipc	ra,0x0
    80001240:	f22080e7          	jalr	-222(ra) # 8000115e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001244:	4729                	li	a4,10
    80001246:	6685                	lui	a3,0x1
    80001248:	00006617          	auipc	a2,0x6
    8000124c:	db860613          	addi	a2,a2,-584 # 80007000 <_trampoline>
    80001250:	040005b7          	lui	a1,0x4000
    80001254:	15fd                	addi	a1,a1,-1
    80001256:	05b2                	slli	a1,a1,0xc
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f04080e7          	jalr	-252(ra) # 8000115e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001262:	8526                	mv	a0,s1
    80001264:	00000097          	auipc	ra,0x0
    80001268:	608080e7          	jalr	1544(ra) # 8000186c <proc_mapstacks>
}
    8000126c:	8526                	mv	a0,s1
    8000126e:	60e2                	ld	ra,24(sp)
    80001270:	6442                	ld	s0,16(sp)
    80001272:	64a2                	ld	s1,8(sp)
    80001274:	6902                	ld	s2,0(sp)
    80001276:	6105                	addi	sp,sp,32
    80001278:	8082                	ret

000000008000127a <kvminit>:
{
    8000127a:	1141                	addi	sp,sp,-16
    8000127c:	e406                	sd	ra,8(sp)
    8000127e:	e022                	sd	s0,0(sp)
    80001280:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f0c080e7          	jalr	-244(ra) # 8000118e <kvmmake>
    8000128a:	00008797          	auipc	a5,0x8
    8000128e:	fca7b323          	sd	a0,-58(a5) # 80009250 <kernel_pagetable>
}
    80001292:	60a2                	ld	ra,8(sp)
    80001294:	6402                	ld	s0,0(sp)
    80001296:	0141                	addi	sp,sp,16
    80001298:	8082                	ret

000000008000129a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000129a:	715d                	addi	sp,sp,-80
    8000129c:	e486                	sd	ra,72(sp)
    8000129e:	e0a2                	sd	s0,64(sp)
    800012a0:	fc26                	sd	s1,56(sp)
    800012a2:	f84a                	sd	s2,48(sp)
    800012a4:	f44e                	sd	s3,40(sp)
    800012a6:	f052                	sd	s4,32(sp)
    800012a8:	ec56                	sd	s5,24(sp)
    800012aa:	e85a                	sd	s6,16(sp)
    800012ac:	e45e                	sd	s7,8(sp)
    800012ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012b0:	03459793          	slli	a5,a1,0x34
    800012b4:	e795                	bnez	a5,800012e0 <uvmunmap+0x46>
    800012b6:	8a2a                	mv	s4,a0
    800012b8:	892e                	mv	s2,a1
    800012ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012bc:	0632                	slli	a2,a2,0xc
    800012be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c4:	6b05                	lui	s6,0x1
    800012c6:	0735e263          	bltu	a1,s3,8000132a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ca:	60a6                	ld	ra,72(sp)
    800012cc:	6406                	ld	s0,64(sp)
    800012ce:	74e2                	ld	s1,56(sp)
    800012d0:	7942                	ld	s2,48(sp)
    800012d2:	79a2                	ld	s3,40(sp)
    800012d4:	7a02                	ld	s4,32(sp)
    800012d6:	6ae2                	ld	s5,24(sp)
    800012d8:	6b42                	ld	s6,16(sp)
    800012da:	6ba2                	ld	s7,8(sp)
    800012dc:	6161                	addi	sp,sp,80
    800012de:	8082                	ret
    panic("uvmunmap: not aligned");
    800012e0:	00007517          	auipc	a0,0x7
    800012e4:	e3050513          	addi	a0,a0,-464 # 80008110 <digits+0xd0>
    800012e8:	fffff097          	auipc	ra,0xfffff
    800012ec:	256080e7          	jalr	598(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012f0:	00007517          	auipc	a0,0x7
    800012f4:	e3850513          	addi	a0,a0,-456 # 80008128 <digits+0xe8>
    800012f8:	fffff097          	auipc	ra,0xfffff
    800012fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e3850513          	addi	a0,a0,-456 # 80008138 <digits+0xf8>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	236080e7          	jalr	566(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	e4050513          	addi	a0,a0,-448 # 80008150 <digits+0x110>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	226080e7          	jalr	550(ra) # 8000053e <panic>
    *pte = 0;
    80001320:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001324:	995a                	add	s2,s2,s6
    80001326:	fb3972e3          	bgeu	s2,s3,800012ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000132a:	4601                	li	a2,0
    8000132c:	85ca                	mv	a1,s2
    8000132e:	8552                	mv	a0,s4
    80001330:	00000097          	auipc	ra,0x0
    80001334:	ca6080e7          	jalr	-858(ra) # 80000fd6 <walk>
    80001338:	84aa                	mv	s1,a0
    8000133a:	d95d                	beqz	a0,800012f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000133c:	6108                	ld	a0,0(a0)
    8000133e:	00157793          	andi	a5,a0,1
    80001342:	dfdd                	beqz	a5,80001300 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001344:	3ff57793          	andi	a5,a0,1023
    80001348:	fd7784e3          	beq	a5,s7,80001310 <uvmunmap+0x76>
    if(do_free){
    8000134c:	fc0a8ae3          	beqz	s5,80001320 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001350:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001352:	0532                	slli	a0,a0,0xc
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	696080e7          	jalr	1686(ra) # 800009ea <kfree>
    8000135c:	b7d1                	j	80001320 <uvmunmap+0x86>

000000008000135e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000135e:	1101                	addi	sp,sp,-32
    80001360:	ec06                	sd	ra,24(sp)
    80001362:	e822                	sd	s0,16(sp)
    80001364:	e426                	sd	s1,8(sp)
    80001366:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	77e080e7          	jalr	1918(ra) # 80000ae6 <kalloc>
    80001370:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001372:	c519                	beqz	a0,80001380 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	95a080e7          	jalr	-1702(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001380:	8526                	mv	a0,s1
    80001382:	60e2                	ld	ra,24(sp)
    80001384:	6442                	ld	s0,16(sp)
    80001386:	64a2                	ld	s1,8(sp)
    80001388:	6105                	addi	sp,sp,32
    8000138a:	8082                	ret

000000008000138c <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000138c:	7179                	addi	sp,sp,-48
    8000138e:	f406                	sd	ra,40(sp)
    80001390:	f022                	sd	s0,32(sp)
    80001392:	ec26                	sd	s1,24(sp)
    80001394:	e84a                	sd	s2,16(sp)
    80001396:	e44e                	sd	s3,8(sp)
    80001398:	e052                	sd	s4,0(sp)
    8000139a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000139c:	6785                	lui	a5,0x1
    8000139e:	04f67863          	bgeu	a2,a5,800013ee <uvmfirst+0x62>
    800013a2:	8a2a                	mv	s4,a0
    800013a4:	89ae                	mv	s3,a1
    800013a6:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	73e080e7          	jalr	1854(ra) # 80000ae6 <kalloc>
    800013b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013b2:	6605                	lui	a2,0x1
    800013b4:	4581                	li	a1,0
    800013b6:	00000097          	auipc	ra,0x0
    800013ba:	91c080e7          	jalr	-1764(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013be:	4779                	li	a4,30
    800013c0:	86ca                	mv	a3,s2
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	cf6080e7          	jalr	-778(ra) # 800010be <mappages>
  memmove(mem, src, sz);
    800013d0:	8626                	mv	a2,s1
    800013d2:	85ce                	mv	a1,s3
    800013d4:	854a                	mv	a0,s2
    800013d6:	00000097          	auipc	ra,0x0
    800013da:	958080e7          	jalr	-1704(ra) # 80000d2e <memmove>
}
    800013de:	70a2                	ld	ra,40(sp)
    800013e0:	7402                	ld	s0,32(sp)
    800013e2:	64e2                	ld	s1,24(sp)
    800013e4:	6942                	ld	s2,16(sp)
    800013e6:	69a2                	ld	s3,8(sp)
    800013e8:	6a02                	ld	s4,0(sp)
    800013ea:	6145                	addi	sp,sp,48
    800013ec:	8082                	ret
    panic("uvmfirst: more than a page");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d7a50513          	addi	a0,a0,-646 # 80008168 <digits+0x128>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	148080e7          	jalr	328(ra) # 8000053e <panic>

00000000800013fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013fe:	1101                	addi	sp,sp,-32
    80001400:	ec06                	sd	ra,24(sp)
    80001402:	e822                	sd	s0,16(sp)
    80001404:	e426                	sd	s1,8(sp)
    80001406:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001408:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000140a:	00b67d63          	bgeu	a2,a1,80001424 <uvmdealloc+0x26>
    8000140e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001410:	6785                	lui	a5,0x1
    80001412:	17fd                	addi	a5,a5,-1
    80001414:	00f60733          	add	a4,a2,a5
    80001418:	767d                	lui	a2,0xfffff
    8000141a:	8f71                	and	a4,a4,a2
    8000141c:	97ae                	add	a5,a5,a1
    8000141e:	8ff1                	and	a5,a5,a2
    80001420:	00f76863          	bltu	a4,a5,80001430 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001424:	8526                	mv	a0,s1
    80001426:	60e2                	ld	ra,24(sp)
    80001428:	6442                	ld	s0,16(sp)
    8000142a:	64a2                	ld	s1,8(sp)
    8000142c:	6105                	addi	sp,sp,32
    8000142e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001430:	8f99                	sub	a5,a5,a4
    80001432:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001434:	4685                	li	a3,1
    80001436:	0007861b          	sext.w	a2,a5
    8000143a:	85ba                	mv	a1,a4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	e5e080e7          	jalr	-418(ra) # 8000129a <uvmunmap>
    80001444:	b7c5                	j	80001424 <uvmdealloc+0x26>

0000000080001446 <uvmalloc>:
  if(newsz < oldsz)
    80001446:	0ab66563          	bltu	a2,a1,800014f0 <uvmalloc+0xaa>
{
    8000144a:	7139                	addi	sp,sp,-64
    8000144c:	fc06                	sd	ra,56(sp)
    8000144e:	f822                	sd	s0,48(sp)
    80001450:	f426                	sd	s1,40(sp)
    80001452:	f04a                	sd	s2,32(sp)
    80001454:	ec4e                	sd	s3,24(sp)
    80001456:	e852                	sd	s4,16(sp)
    80001458:	e456                	sd	s5,8(sp)
    8000145a:	e05a                	sd	s6,0(sp)
    8000145c:	0080                	addi	s0,sp,64
    8000145e:	8aaa                	mv	s5,a0
    80001460:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001462:	6985                	lui	s3,0x1
    80001464:	19fd                	addi	s3,s3,-1
    80001466:	95ce                	add	a1,a1,s3
    80001468:	79fd                	lui	s3,0xfffff
    8000146a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	08c9f363          	bgeu	s3,a2,800014f4 <uvmalloc+0xae>
    80001472:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001474:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	66e080e7          	jalr	1646(ra) # 80000ae6 <kalloc>
    80001480:	84aa                	mv	s1,a0
    if(mem == 0){
    80001482:	c51d                	beqz	a0,800014b0 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001484:	6605                	lui	a2,0x1
    80001486:	4581                	li	a1,0
    80001488:	00000097          	auipc	ra,0x0
    8000148c:	84a080e7          	jalr	-1974(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001490:	875a                	mv	a4,s6
    80001492:	86a6                	mv	a3,s1
    80001494:	6605                	lui	a2,0x1
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	c24080e7          	jalr	-988(ra) # 800010be <mappages>
    800014a2:	e90d                	bnez	a0,800014d4 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a4:	6785                	lui	a5,0x1
    800014a6:	993e                	add	s2,s2,a5
    800014a8:	fd4968e3          	bltu	s2,s4,80001478 <uvmalloc+0x32>
  return newsz;
    800014ac:	8552                	mv	a0,s4
    800014ae:	a809                	j	800014c0 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014b0:	864e                	mv	a2,s3
    800014b2:	85ca                	mv	a1,s2
    800014b4:	8556                	mv	a0,s5
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	f48080e7          	jalr	-184(ra) # 800013fe <uvmdealloc>
      return 0;
    800014be:	4501                	li	a0,0
}
    800014c0:	70e2                	ld	ra,56(sp)
    800014c2:	7442                	ld	s0,48(sp)
    800014c4:	74a2                	ld	s1,40(sp)
    800014c6:	7902                	ld	s2,32(sp)
    800014c8:	69e2                	ld	s3,24(sp)
    800014ca:	6a42                	ld	s4,16(sp)
    800014cc:	6aa2                	ld	s5,8(sp)
    800014ce:	6b02                	ld	s6,0(sp)
    800014d0:	6121                	addi	sp,sp,64
    800014d2:	8082                	ret
      kfree(mem);
    800014d4:	8526                	mv	a0,s1
    800014d6:	fffff097          	auipc	ra,0xfffff
    800014da:	514080e7          	jalr	1300(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014de:	864e                	mv	a2,s3
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8556                	mv	a0,s5
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f1a080e7          	jalr	-230(ra) # 800013fe <uvmdealloc>
      return 0;
    800014ec:	4501                	li	a0,0
    800014ee:	bfc9                	j	800014c0 <uvmalloc+0x7a>
    return oldsz;
    800014f0:	852e                	mv	a0,a1
}
    800014f2:	8082                	ret
  return newsz;
    800014f4:	8532                	mv	a0,a2
    800014f6:	b7e9                	j	800014c0 <uvmalloc+0x7a>

00000000800014f8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014f8:	7179                	addi	sp,sp,-48
    800014fa:	f406                	sd	ra,40(sp)
    800014fc:	f022                	sd	s0,32(sp)
    800014fe:	ec26                	sd	s1,24(sp)
    80001500:	e84a                	sd	s2,16(sp)
    80001502:	e44e                	sd	s3,8(sp)
    80001504:	e052                	sd	s4,0(sp)
    80001506:	1800                	addi	s0,sp,48
    80001508:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000150a:	84aa                	mv	s1,a0
    8000150c:	6905                	lui	s2,0x1
    8000150e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001510:	4985                	li	s3,1
    80001512:	a821                	j	8000152a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001514:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001516:	0532                	slli	a0,a0,0xc
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	fe0080e7          	jalr	-32(ra) # 800014f8 <freewalk>
      pagetable[i] = 0;
    80001520:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001524:	04a1                	addi	s1,s1,8
    80001526:	03248163          	beq	s1,s2,80001548 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000152a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000152c:	00f57793          	andi	a5,a0,15
    80001530:	ff3782e3          	beq	a5,s3,80001514 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001534:	8905                	andi	a0,a0,1
    80001536:	d57d                	beqz	a0,80001524 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001538:	00007517          	auipc	a0,0x7
    8000153c:	c5050513          	addi	a0,a0,-944 # 80008188 <digits+0x148>
    80001540:	fffff097          	auipc	ra,0xfffff
    80001544:	ffe080e7          	jalr	-2(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001548:	8552                	mv	a0,s4
    8000154a:	fffff097          	auipc	ra,0xfffff
    8000154e:	4a0080e7          	jalr	1184(ra) # 800009ea <kfree>
}
    80001552:	70a2                	ld	ra,40(sp)
    80001554:	7402                	ld	s0,32(sp)
    80001556:	64e2                	ld	s1,24(sp)
    80001558:	6942                	ld	s2,16(sp)
    8000155a:	69a2                	ld	s3,8(sp)
    8000155c:	6a02                	ld	s4,0(sp)
    8000155e:	6145                	addi	sp,sp,48
    80001560:	8082                	ret

0000000080001562 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001562:	1101                	addi	sp,sp,-32
    80001564:	ec06                	sd	ra,24(sp)
    80001566:	e822                	sd	s0,16(sp)
    80001568:	e426                	sd	s1,8(sp)
    8000156a:	1000                	addi	s0,sp,32
    8000156c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000156e:	e999                	bnez	a1,80001584 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001570:	8526                	mv	a0,s1
    80001572:	00000097          	auipc	ra,0x0
    80001576:	f86080e7          	jalr	-122(ra) # 800014f8 <freewalk>
}
    8000157a:	60e2                	ld	ra,24(sp)
    8000157c:	6442                	ld	s0,16(sp)
    8000157e:	64a2                	ld	s1,8(sp)
    80001580:	6105                	addi	sp,sp,32
    80001582:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001584:	6605                	lui	a2,0x1
    80001586:	167d                	addi	a2,a2,-1
    80001588:	962e                	add	a2,a2,a1
    8000158a:	4685                	li	a3,1
    8000158c:	8231                	srli	a2,a2,0xc
    8000158e:	4581                	li	a1,0
    80001590:	00000097          	auipc	ra,0x0
    80001594:	d0a080e7          	jalr	-758(ra) # 8000129a <uvmunmap>
    80001598:	bfe1                	j	80001570 <uvmfree+0xe>

000000008000159a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000159a:	c679                	beqz	a2,80001668 <uvmcopy+0xce>
{
    8000159c:	715d                	addi	sp,sp,-80
    8000159e:	e486                	sd	ra,72(sp)
    800015a0:	e0a2                	sd	s0,64(sp)
    800015a2:	fc26                	sd	s1,56(sp)
    800015a4:	f84a                	sd	s2,48(sp)
    800015a6:	f44e                	sd	s3,40(sp)
    800015a8:	f052                	sd	s4,32(sp)
    800015aa:	ec56                	sd	s5,24(sp)
    800015ac:	e85a                	sd	s6,16(sp)
    800015ae:	e45e                	sd	s7,8(sp)
    800015b0:	0880                	addi	s0,sp,80
    800015b2:	8b2a                	mv	s6,a0
    800015b4:	8aae                	mv	s5,a1
    800015b6:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015b8:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ba:	4601                	li	a2,0
    800015bc:	85ce                	mv	a1,s3
    800015be:	855a                	mv	a0,s6
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	a16080e7          	jalr	-1514(ra) # 80000fd6 <walk>
    800015c8:	c531                	beqz	a0,80001614 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ca:	6118                	ld	a4,0(a0)
    800015cc:	00177793          	andi	a5,a4,1
    800015d0:	cbb1                	beqz	a5,80001624 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015d2:	00a75593          	srli	a1,a4,0xa
    800015d6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015da:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015de:	fffff097          	auipc	ra,0xfffff
    800015e2:	508080e7          	jalr	1288(ra) # 80000ae6 <kalloc>
    800015e6:	892a                	mv	s2,a0
    800015e8:	c939                	beqz	a0,8000163e <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ea:	6605                	lui	a2,0x1
    800015ec:	85de                	mv	a1,s7
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	740080e7          	jalr	1856(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015f6:	8726                	mv	a4,s1
    800015f8:	86ca                	mv	a3,s2
    800015fa:	6605                	lui	a2,0x1
    800015fc:	85ce                	mv	a1,s3
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	abe080e7          	jalr	-1346(ra) # 800010be <mappages>
    80001608:	e515                	bnez	a0,80001634 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000160a:	6785                	lui	a5,0x1
    8000160c:	99be                	add	s3,s3,a5
    8000160e:	fb49e6e3          	bltu	s3,s4,800015ba <uvmcopy+0x20>
    80001612:	a081                	j	80001652 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001614:	00007517          	auipc	a0,0x7
    80001618:	b8450513          	addi	a0,a0,-1148 # 80008198 <digits+0x158>
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001624:	00007517          	auipc	a0,0x7
    80001628:	b9450513          	addi	a0,a0,-1132 # 800081b8 <digits+0x178>
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>
      kfree(mem);
    80001634:	854a                	mv	a0,s2
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	3b4080e7          	jalr	948(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000163e:	4685                	li	a3,1
    80001640:	00c9d613          	srli	a2,s3,0xc
    80001644:	4581                	li	a1,0
    80001646:	8556                	mv	a0,s5
    80001648:	00000097          	auipc	ra,0x0
    8000164c:	c52080e7          	jalr	-942(ra) # 8000129a <uvmunmap>
  return -1;
    80001650:	557d                	li	a0,-1
}
    80001652:	60a6                	ld	ra,72(sp)
    80001654:	6406                	ld	s0,64(sp)
    80001656:	74e2                	ld	s1,56(sp)
    80001658:	7942                	ld	s2,48(sp)
    8000165a:	79a2                	ld	s3,40(sp)
    8000165c:	7a02                	ld	s4,32(sp)
    8000165e:	6ae2                	ld	s5,24(sp)
    80001660:	6b42                	ld	s6,16(sp)
    80001662:	6ba2                	ld	s7,8(sp)
    80001664:	6161                	addi	sp,sp,80
    80001666:	8082                	ret
  return 0;
    80001668:	4501                	li	a0,0
}
    8000166a:	8082                	ret

000000008000166c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000166c:	1141                	addi	sp,sp,-16
    8000166e:	e406                	sd	ra,8(sp)
    80001670:	e022                	sd	s0,0(sp)
    80001672:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001674:	4601                	li	a2,0
    80001676:	00000097          	auipc	ra,0x0
    8000167a:	960080e7          	jalr	-1696(ra) # 80000fd6 <walk>
  if(pte == 0)
    8000167e:	c901                	beqz	a0,8000168e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001680:	611c                	ld	a5,0(a0)
    80001682:	9bbd                	andi	a5,a5,-17
    80001684:	e11c                	sd	a5,0(a0)
}
    80001686:	60a2                	ld	ra,8(sp)
    80001688:	6402                	ld	s0,0(sp)
    8000168a:	0141                	addi	sp,sp,16
    8000168c:	8082                	ret
    panic("uvmclear");
    8000168e:	00007517          	auipc	a0,0x7
    80001692:	b4a50513          	addi	a0,a0,-1206 # 800081d8 <digits+0x198>
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	ea8080e7          	jalr	-344(ra) # 8000053e <panic>

000000008000169e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000169e:	c6bd                	beqz	a3,8000170c <copyout+0x6e>
{
    800016a0:	715d                	addi	sp,sp,-80
    800016a2:	e486                	sd	ra,72(sp)
    800016a4:	e0a2                	sd	s0,64(sp)
    800016a6:	fc26                	sd	s1,56(sp)
    800016a8:	f84a                	sd	s2,48(sp)
    800016aa:	f44e                	sd	s3,40(sp)
    800016ac:	f052                	sd	s4,32(sp)
    800016ae:	ec56                	sd	s5,24(sp)
    800016b0:	e85a                	sd	s6,16(sp)
    800016b2:	e45e                	sd	s7,8(sp)
    800016b4:	e062                	sd	s8,0(sp)
    800016b6:	0880                	addi	s0,sp,80
    800016b8:	8b2a                	mv	s6,a0
    800016ba:	8c2e                	mv	s8,a1
    800016bc:	8a32                	mv	s4,a2
    800016be:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016c0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016c2:	6a85                	lui	s5,0x1
    800016c4:	a015                	j	800016e8 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016c6:	9562                	add	a0,a0,s8
    800016c8:	0004861b          	sext.w	a2,s1
    800016cc:	85d2                	mv	a1,s4
    800016ce:	41250533          	sub	a0,a0,s2
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	65c080e7          	jalr	1628(ra) # 80000d2e <memmove>

    len -= n;
    800016da:	409989b3          	sub	s3,s3,s1
    src += n;
    800016de:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016e0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016e4:	02098263          	beqz	s3,80001708 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016e8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ec:	85ca                	mv	a1,s2
    800016ee:	855a                	mv	a0,s6
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	98c080e7          	jalr	-1652(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    800016f8:	cd01                	beqz	a0,80001710 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016fa:	418904b3          	sub	s1,s2,s8
    800016fe:	94d6                	add	s1,s1,s5
    if(n > len)
    80001700:	fc99f3e3          	bgeu	s3,s1,800016c6 <copyout+0x28>
    80001704:	84ce                	mv	s1,s3
    80001706:	b7c1                	j	800016c6 <copyout+0x28>
  }
  return 0;
    80001708:	4501                	li	a0,0
    8000170a:	a021                	j	80001712 <copyout+0x74>
    8000170c:	4501                	li	a0,0
}
    8000170e:	8082                	ret
      return -1;
    80001710:	557d                	li	a0,-1
}
    80001712:	60a6                	ld	ra,72(sp)
    80001714:	6406                	ld	s0,64(sp)
    80001716:	74e2                	ld	s1,56(sp)
    80001718:	7942                	ld	s2,48(sp)
    8000171a:	79a2                	ld	s3,40(sp)
    8000171c:	7a02                	ld	s4,32(sp)
    8000171e:	6ae2                	ld	s5,24(sp)
    80001720:	6b42                	ld	s6,16(sp)
    80001722:	6ba2                	ld	s7,8(sp)
    80001724:	6c02                	ld	s8,0(sp)
    80001726:	6161                	addi	sp,sp,80
    80001728:	8082                	ret

000000008000172a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172a:	caa5                	beqz	a3,8000179a <copyin+0x70>
{
    8000172c:	715d                	addi	sp,sp,-80
    8000172e:	e486                	sd	ra,72(sp)
    80001730:	e0a2                	sd	s0,64(sp)
    80001732:	fc26                	sd	s1,56(sp)
    80001734:	f84a                	sd	s2,48(sp)
    80001736:	f44e                	sd	s3,40(sp)
    80001738:	f052                	sd	s4,32(sp)
    8000173a:	ec56                	sd	s5,24(sp)
    8000173c:	e85a                	sd	s6,16(sp)
    8000173e:	e45e                	sd	s7,8(sp)
    80001740:	e062                	sd	s8,0(sp)
    80001742:	0880                	addi	s0,sp,80
    80001744:	8b2a                	mv	s6,a0
    80001746:	8a2e                	mv	s4,a1
    80001748:	8c32                	mv	s8,a2
    8000174a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000174c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000174e:	6a85                	lui	s5,0x1
    80001750:	a01d                	j	80001776 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001752:	018505b3          	add	a1,a0,s8
    80001756:	0004861b          	sext.w	a2,s1
    8000175a:	412585b3          	sub	a1,a1,s2
    8000175e:	8552                	mv	a0,s4
    80001760:	fffff097          	auipc	ra,0xfffff
    80001764:	5ce080e7          	jalr	1486(ra) # 80000d2e <memmove>

    len -= n;
    80001768:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000176c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000176e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001772:	02098263          	beqz	s3,80001796 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001776:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177a:	85ca                	mv	a1,s2
    8000177c:	855a                	mv	a0,s6
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	8fe080e7          	jalr	-1794(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001786:	cd01                	beqz	a0,8000179e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001788:	418904b3          	sub	s1,s2,s8
    8000178c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000178e:	fc99f2e3          	bgeu	s3,s1,80001752 <copyin+0x28>
    80001792:	84ce                	mv	s1,s3
    80001794:	bf7d                	j	80001752 <copyin+0x28>
  }
  return 0;
    80001796:	4501                	li	a0,0
    80001798:	a021                	j	800017a0 <copyin+0x76>
    8000179a:	4501                	li	a0,0
}
    8000179c:	8082                	ret
      return -1;
    8000179e:	557d                	li	a0,-1
}
    800017a0:	60a6                	ld	ra,72(sp)
    800017a2:	6406                	ld	s0,64(sp)
    800017a4:	74e2                	ld	s1,56(sp)
    800017a6:	7942                	ld	s2,48(sp)
    800017a8:	79a2                	ld	s3,40(sp)
    800017aa:	7a02                	ld	s4,32(sp)
    800017ac:	6ae2                	ld	s5,24(sp)
    800017ae:	6b42                	ld	s6,16(sp)
    800017b0:	6ba2                	ld	s7,8(sp)
    800017b2:	6c02                	ld	s8,0(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret

00000000800017b8 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017b8:	c6c5                	beqz	a3,80001860 <copyinstr+0xa8>
{
    800017ba:	715d                	addi	sp,sp,-80
    800017bc:	e486                	sd	ra,72(sp)
    800017be:	e0a2                	sd	s0,64(sp)
    800017c0:	fc26                	sd	s1,56(sp)
    800017c2:	f84a                	sd	s2,48(sp)
    800017c4:	f44e                	sd	s3,40(sp)
    800017c6:	f052                	sd	s4,32(sp)
    800017c8:	ec56                	sd	s5,24(sp)
    800017ca:	e85a                	sd	s6,16(sp)
    800017cc:	e45e                	sd	s7,8(sp)
    800017ce:	0880                	addi	s0,sp,80
    800017d0:	8a2a                	mv	s4,a0
    800017d2:	8b2e                	mv	s6,a1
    800017d4:	8bb2                	mv	s7,a2
    800017d6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017d8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017da:	6985                	lui	s3,0x1
    800017dc:	a035                	j	80001808 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017de:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017e2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017e4:	0017b793          	seqz	a5,a5
    800017e8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017ec:	60a6                	ld	ra,72(sp)
    800017ee:	6406                	ld	s0,64(sp)
    800017f0:	74e2                	ld	s1,56(sp)
    800017f2:	7942                	ld	s2,48(sp)
    800017f4:	79a2                	ld	s3,40(sp)
    800017f6:	7a02                	ld	s4,32(sp)
    800017f8:	6ae2                	ld	s5,24(sp)
    800017fa:	6b42                	ld	s6,16(sp)
    800017fc:	6ba2                	ld	s7,8(sp)
    800017fe:	6161                	addi	sp,sp,80
    80001800:	8082                	ret
    srcva = va0 + PGSIZE;
    80001802:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001806:	c8a9                	beqz	s1,80001858 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001808:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000180c:	85ca                	mv	a1,s2
    8000180e:	8552                	mv	a0,s4
    80001810:	00000097          	auipc	ra,0x0
    80001814:	86c080e7          	jalr	-1940(ra) # 8000107c <walkaddr>
    if(pa0 == 0)
    80001818:	c131                	beqz	a0,8000185c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000181a:	41790833          	sub	a6,s2,s7
    8000181e:	984e                	add	a6,a6,s3
    if(n > max)
    80001820:	0104f363          	bgeu	s1,a6,80001826 <copyinstr+0x6e>
    80001824:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001826:	955e                	add	a0,a0,s7
    80001828:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000182c:	fc080be3          	beqz	a6,80001802 <copyinstr+0x4a>
    80001830:	985a                	add	a6,a6,s6
    80001832:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001834:	41650633          	sub	a2,a0,s6
    80001838:	14fd                	addi	s1,s1,-1
    8000183a:	9b26                	add	s6,s6,s1
    8000183c:	00f60733          	add	a4,a2,a5
    80001840:	00074703          	lbu	a4,0(a4)
    80001844:	df49                	beqz	a4,800017de <copyinstr+0x26>
        *dst = *p;
    80001846:	00e78023          	sb	a4,0(a5)
      --max;
    8000184a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000184e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001850:	ff0796e3          	bne	a5,a6,8000183c <copyinstr+0x84>
      dst++;
    80001854:	8b42                	mv	s6,a6
    80001856:	b775                	j	80001802 <copyinstr+0x4a>
    80001858:	4781                	li	a5,0
    8000185a:	b769                	j	800017e4 <copyinstr+0x2c>
      return -1;
    8000185c:	557d                	li	a0,-1
    8000185e:	b779                	j	800017ec <copyinstr+0x34>
  int got_null = 0;
    80001860:	4781                	li	a5,0
  if(got_null){
    80001862:	0017b793          	seqz	a5,a5
    80001866:	40f00533          	neg	a0,a5
}
    8000186a:	8082                	ret

000000008000186c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000186c:	7139                	addi	sp,sp,-64
    8000186e:	fc06                	sd	ra,56(sp)
    80001870:	f822                	sd	s0,48(sp)
    80001872:	f426                	sd	s1,40(sp)
    80001874:	f04a                	sd	s2,32(sp)
    80001876:	ec4e                	sd	s3,24(sp)
    80001878:	e852                	sd	s4,16(sp)
    8000187a:	e456                	sd	s5,8(sp)
    8000187c:	e05a                	sd	s6,0(sp)
    8000187e:	0080                	addi	s0,sp,64
    80001880:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001882:	00010497          	auipc	s1,0x10
    80001886:	07e48493          	addi	s1,s1,126 # 80011900 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000188a:	8b26                	mv	s6,s1
    8000188c:	00006a97          	auipc	s5,0x6
    80001890:	774a8a93          	addi	s5,s5,1908 # 80008000 <etext>
    80001894:	04000937          	lui	s2,0x4000
    80001898:	197d                	addi	s2,s2,-1
    8000189a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000189c:	00016a17          	auipc	s4,0x16
    800018a0:	a64a0a13          	addi	s4,s4,-1436 # 80017300 <tickslock>
    char *pa = kalloc();
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	242080e7          	jalr	578(ra) # 80000ae6 <kalloc>
    800018ac:	862a                	mv	a2,a0
    if(pa == 0)
    800018ae:	c131                	beqz	a0,800018f2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b0:	416485b3          	sub	a1,s1,s6
    800018b4:	858d                	srai	a1,a1,0x3
    800018b6:	000ab783          	ld	a5,0(s5)
    800018ba:	02f585b3          	mul	a1,a1,a5
    800018be:	2585                	addiw	a1,a1,1
    800018c0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018c4:	4719                	li	a4,6
    800018c6:	6685                	lui	a3,0x1
    800018c8:	40b905b3          	sub	a1,s2,a1
    800018cc:	854e                	mv	a0,s3
    800018ce:	00000097          	auipc	ra,0x0
    800018d2:	890080e7          	jalr	-1904(ra) # 8000115e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d6:	16848493          	addi	s1,s1,360
    800018da:	fd4495e3          	bne	s1,s4,800018a4 <proc_mapstacks+0x38>
  }
}
    800018de:	70e2                	ld	ra,56(sp)
    800018e0:	7442                	ld	s0,48(sp)
    800018e2:	74a2                	ld	s1,40(sp)
    800018e4:	7902                	ld	s2,32(sp)
    800018e6:	69e2                	ld	s3,24(sp)
    800018e8:	6a42                	ld	s4,16(sp)
    800018ea:	6aa2                	ld	s5,8(sp)
    800018ec:	6b02                	ld	s6,0(sp)
    800018ee:	6121                	addi	sp,sp,64
    800018f0:	8082                	ret
      panic("kalloc");
    800018f2:	00007517          	auipc	a0,0x7
    800018f6:	8f650513          	addi	a0,a0,-1802 # 800081e8 <digits+0x1a8>
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>

0000000080001902 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001902:	7139                	addi	sp,sp,-64
    80001904:	fc06                	sd	ra,56(sp)
    80001906:	f822                	sd	s0,48(sp)
    80001908:	f426                	sd	s1,40(sp)
    8000190a:	f04a                	sd	s2,32(sp)
    8000190c:	ec4e                	sd	s3,24(sp)
    8000190e:	e852                	sd	s4,16(sp)
    80001910:	e456                	sd	s5,8(sp)
    80001912:	e05a                	sd	s6,0(sp)
    80001914:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001916:	00007597          	auipc	a1,0x7
    8000191a:	8da58593          	addi	a1,a1,-1830 # 800081f0 <digits+0x1b0>
    8000191e:	00010517          	auipc	a0,0x10
    80001922:	bb250513          	addi	a0,a0,-1102 # 800114d0 <pid_lock>
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	220080e7          	jalr	544(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000192e:	00007597          	auipc	a1,0x7
    80001932:	8ca58593          	addi	a1,a1,-1846 # 800081f8 <digits+0x1b8>
    80001936:	00010517          	auipc	a0,0x10
    8000193a:	bb250513          	addi	a0,a0,-1102 # 800114e8 <wait_lock>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001946:	00010497          	auipc	s1,0x10
    8000194a:	fba48493          	addi	s1,s1,-70 # 80011900 <proc>
      initlock(&p->lock, "proc");
    8000194e:	00007b17          	auipc	s6,0x7
    80001952:	8bab0b13          	addi	s6,s6,-1862 # 80008208 <digits+0x1c8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001956:	8aa6                	mv	s5,s1
    80001958:	00006a17          	auipc	s4,0x6
    8000195c:	6a8a0a13          	addi	s4,s4,1704 # 80008000 <etext>
    80001960:	04000937          	lui	s2,0x4000
    80001964:	197d                	addi	s2,s2,-1
    80001966:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	00016997          	auipc	s3,0x16
    8000196c:	99898993          	addi	s3,s3,-1640 # 80017300 <tickslock>
      initlock(&p->lock, "proc");
    80001970:	85da                	mv	a1,s6
    80001972:	8526                	mv	a0,s1
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1d2080e7          	jalr	466(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    8000197c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001980:	415487b3          	sub	a5,s1,s5
    80001984:	878d                	srai	a5,a5,0x3
    80001986:	000a3703          	ld	a4,0(s4)
    8000198a:	02e787b3          	mul	a5,a5,a4
    8000198e:	2785                	addiw	a5,a5,1
    80001990:	00d7979b          	slliw	a5,a5,0xd
    80001994:	40f907b3          	sub	a5,s2,a5
    80001998:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199a:	16848493          	addi	s1,s1,360
    8000199e:	fd3499e3          	bne	s1,s3,80001970 <procinit+0x6e>
  }
}
    800019a2:	70e2                	ld	ra,56(sp)
    800019a4:	7442                	ld	s0,48(sp)
    800019a6:	74a2                	ld	s1,40(sp)
    800019a8:	7902                	ld	s2,32(sp)
    800019aa:	69e2                	ld	s3,24(sp)
    800019ac:	6a42                	ld	s4,16(sp)
    800019ae:	6aa2                	ld	s5,8(sp)
    800019b0:	6b02                	ld	s6,0(sp)
    800019b2:	6121                	addi	sp,sp,64
    800019b4:	8082                	ret

00000000800019b6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e422                	sd	s0,8(sp)
    800019ba:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019bc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019be:	2501                	sext.w	a0,a0
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019c6:	1141                	addi	sp,sp,-16
    800019c8:	e422                	sd	s0,8(sp)
    800019ca:	0800                	addi	s0,sp,16
    800019cc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ce:	2781                	sext.w	a5,a5
    800019d0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019d2:	00010517          	auipc	a0,0x10
    800019d6:	b2e50513          	addi	a0,a0,-1234 # 80011500 <cpus>
    800019da:	953e                	add	a0,a0,a5
    800019dc:	6422                	ld	s0,8(sp)
    800019de:	0141                	addi	sp,sp,16
    800019e0:	8082                	ret

00000000800019e2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019e2:	1101                	addi	sp,sp,-32
    800019e4:	ec06                	sd	ra,24(sp)
    800019e6:	e822                	sd	s0,16(sp)
    800019e8:	e426                	sd	s1,8(sp)
    800019ea:	1000                	addi	s0,sp,32
  push_off();
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	19e080e7          	jalr	414(ra) # 80000b8a <push_off>
    800019f4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f6:	2781                	sext.w	a5,a5
    800019f8:	079e                	slli	a5,a5,0x7
    800019fa:	00010717          	auipc	a4,0x10
    800019fe:	ad670713          	addi	a4,a4,-1322 # 800114d0 <pid_lock>
    80001a02:	97ba                	add	a5,a5,a4
    80001a04:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	224080e7          	jalr	548(ra) # 80000c2a <pop_off>
  return p;
}
    80001a0e:	8526                	mv	a0,s1
    80001a10:	60e2                	ld	ra,24(sp)
    80001a12:	6442                	ld	s0,16(sp)
    80001a14:	64a2                	ld	s1,8(sp)
    80001a16:	6105                	addi	sp,sp,32
    80001a18:	8082                	ret

0000000080001a1a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a1a:	1141                	addi	sp,sp,-16
    80001a1c:	e406                	sd	ra,8(sp)
    80001a1e:	e022                	sd	s0,0(sp)
    80001a20:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a22:	00000097          	auipc	ra,0x0
    80001a26:	fc0080e7          	jalr	-64(ra) # 800019e2 <myproc>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	260080e7          	jalr	608(ra) # 80000c8a <release>

  if (first) {
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	78e7a783          	lw	a5,1934(a5) # 800091c0 <first.1>
    80001a3a:	eb89                	bnez	a5,80001a4c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a3c:	00001097          	auipc	ra,0x1
    80001a40:	cc0080e7          	jalr	-832(ra) # 800026fc <usertrapret>
}
    80001a44:	60a2                	ld	ra,8(sp)
    80001a46:	6402                	ld	s0,0(sp)
    80001a48:	0141                	addi	sp,sp,16
    80001a4a:	8082                	ret
    first = 0;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	7607aa23          	sw	zero,1908(a5) # 800091c0 <first.1>
    fsinit(ROOTDEV);
    80001a54:	4505                	li	a0,1
    80001a56:	00002097          	auipc	ra,0x2
    80001a5a:	b74080e7          	jalr	-1164(ra) # 800035ca <fsinit>
    80001a5e:	bff9                	j	80001a3c <forkret+0x22>

0000000080001a60 <allocpid>:
{
    80001a60:	1101                	addi	sp,sp,-32
    80001a62:	ec06                	sd	ra,24(sp)
    80001a64:	e822                	sd	s0,16(sp)
    80001a66:	e426                	sd	s1,8(sp)
    80001a68:	e04a                	sd	s2,0(sp)
    80001a6a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a6c:	00010917          	auipc	s2,0x10
    80001a70:	a6490913          	addi	s2,s2,-1436 # 800114d0 <pid_lock>
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	160080e7          	jalr	352(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a7e:	00007797          	auipc	a5,0x7
    80001a82:	74678793          	addi	a5,a5,1862 # 800091c4 <nextpid>
    80001a86:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a88:	0014871b          	addiw	a4,s1,1
    80001a8c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a8e:	854a                	mv	a0,s2
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	1fa080e7          	jalr	506(ra) # 80000c8a <release>
}
    80001a98:	8526                	mv	a0,s1
    80001a9a:	60e2                	ld	ra,24(sp)
    80001a9c:	6442                	ld	s0,16(sp)
    80001a9e:	64a2                	ld	s1,8(sp)
    80001aa0:	6902                	ld	s2,0(sp)
    80001aa2:	6105                	addi	sp,sp,32
    80001aa4:	8082                	ret

0000000080001aa6 <proc_pagetable>:
{
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	e04a                	sd	s2,0(sp)
    80001ab0:	1000                	addi	s0,sp,32
    80001ab2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	8aa080e7          	jalr	-1878(ra) # 8000135e <uvmcreate>
    80001abc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001abe:	c121                	beqz	a0,80001afe <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ac0:	4729                	li	a4,10
    80001ac2:	00005697          	auipc	a3,0x5
    80001ac6:	53e68693          	addi	a3,a3,1342 # 80007000 <_trampoline>
    80001aca:	6605                	lui	a2,0x1
    80001acc:	040005b7          	lui	a1,0x4000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b2                	slli	a1,a1,0xc
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	5ea080e7          	jalr	1514(ra) # 800010be <mappages>
    80001adc:	02054863          	bltz	a0,80001b0c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ae0:	4719                	li	a4,6
    80001ae2:	05893683          	ld	a3,88(s2)
    80001ae6:	6605                	lui	a2,0x1
    80001ae8:	020005b7          	lui	a1,0x2000
    80001aec:	15fd                	addi	a1,a1,-1
    80001aee:	05b6                	slli	a1,a1,0xd
    80001af0:	8526                	mv	a0,s1
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	5cc080e7          	jalr	1484(ra) # 800010be <mappages>
    80001afa:	02054163          	bltz	a0,80001b1c <proc_pagetable+0x76>
}
    80001afe:	8526                	mv	a0,s1
    80001b00:	60e2                	ld	ra,24(sp)
    80001b02:	6442                	ld	s0,16(sp)
    80001b04:	64a2                	ld	s1,8(sp)
    80001b06:	6902                	ld	s2,0(sp)
    80001b08:	6105                	addi	sp,sp,32
    80001b0a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b0c:	4581                	li	a1,0
    80001b0e:	8526                	mv	a0,s1
    80001b10:	00000097          	auipc	ra,0x0
    80001b14:	a52080e7          	jalr	-1454(ra) # 80001562 <uvmfree>
    return 0;
    80001b18:	4481                	li	s1,0
    80001b1a:	b7d5                	j	80001afe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	8526                	mv	a0,s1
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	770080e7          	jalr	1904(ra) # 8000129a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b32:	4581                	li	a1,0
    80001b34:	8526                	mv	a0,s1
    80001b36:	00000097          	auipc	ra,0x0
    80001b3a:	a2c080e7          	jalr	-1492(ra) # 80001562 <uvmfree>
    return 0;
    80001b3e:	4481                	li	s1,0
    80001b40:	bf7d                	j	80001afe <proc_pagetable+0x58>

0000000080001b42 <proc_freepagetable>:
{
    80001b42:	1101                	addi	sp,sp,-32
    80001b44:	ec06                	sd	ra,24(sp)
    80001b46:	e822                	sd	s0,16(sp)
    80001b48:	e426                	sd	s1,8(sp)
    80001b4a:	e04a                	sd	s2,0(sp)
    80001b4c:	1000                	addi	s0,sp,32
    80001b4e:	84aa                	mv	s1,a0
    80001b50:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b52:	4681                	li	a3,0
    80001b54:	4605                	li	a2,1
    80001b56:	040005b7          	lui	a1,0x4000
    80001b5a:	15fd                	addi	a1,a1,-1
    80001b5c:	05b2                	slli	a1,a1,0xc
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	73c080e7          	jalr	1852(ra) # 8000129a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	020005b7          	lui	a1,0x2000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b6                	slli	a1,a1,0xd
    80001b72:	8526                	mv	a0,s1
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	726080e7          	jalr	1830(ra) # 8000129a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b7c:	85ca                	mv	a1,s2
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	9e2080e7          	jalr	-1566(ra) # 80001562 <uvmfree>
}
    80001b88:	60e2                	ld	ra,24(sp)
    80001b8a:	6442                	ld	s0,16(sp)
    80001b8c:	64a2                	ld	s1,8(sp)
    80001b8e:	6902                	ld	s2,0(sp)
    80001b90:	6105                	addi	sp,sp,32
    80001b92:	8082                	ret

0000000080001b94 <freeproc>:
{
    80001b94:	1101                	addi	sp,sp,-32
    80001b96:	ec06                	sd	ra,24(sp)
    80001b98:	e822                	sd	s0,16(sp)
    80001b9a:	e426                	sd	s1,8(sp)
    80001b9c:	1000                	addi	s0,sp,32
    80001b9e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ba0:	6d28                	ld	a0,88(a0)
    80001ba2:	c509                	beqz	a0,80001bac <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	e46080e7          	jalr	-442(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bac:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bb0:	68a8                	ld	a0,80(s1)
    80001bb2:	c511                	beqz	a0,80001bbe <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb4:	64ac                	ld	a1,72(s1)
    80001bb6:	00000097          	auipc	ra,0x0
    80001bba:	f8c080e7          	jalr	-116(ra) # 80001b42 <proc_freepagetable>
  p->pagetable = 0;
    80001bbe:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bc2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bca:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bce:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bd2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bd6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bda:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bde:	0004ac23          	sw	zero,24(s1)
}
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <allocproc>:
{
    80001bec:	1101                	addi	sp,sp,-32
    80001bee:	ec06                	sd	ra,24(sp)
    80001bf0:	e822                	sd	s0,16(sp)
    80001bf2:	e426                	sd	s1,8(sp)
    80001bf4:	e04a                	sd	s2,0(sp)
    80001bf6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf8:	00010497          	auipc	s1,0x10
    80001bfc:	d0848493          	addi	s1,s1,-760 # 80011900 <proc>
    80001c00:	00015917          	auipc	s2,0x15
    80001c04:	70090913          	addi	s2,s2,1792 # 80017300 <tickslock>
    acquire(&p->lock);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	fcc080e7          	jalr	-52(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001c12:	4c9c                	lw	a5,24(s1)
    80001c14:	cf81                	beqz	a5,80001c2c <allocproc+0x40>
      release(&p->lock);
    80001c16:	8526                	mv	a0,s1
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	072080e7          	jalr	114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c20:	16848493          	addi	s1,s1,360
    80001c24:	ff2492e3          	bne	s1,s2,80001c08 <allocproc+0x1c>
  return 0;
    80001c28:	4481                	li	s1,0
    80001c2a:	a889                	j	80001c7c <allocproc+0x90>
  p->pid = allocpid();
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	e34080e7          	jalr	-460(ra) # 80001a60 <allocpid>
    80001c34:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c36:	4785                	li	a5,1
    80001c38:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	eac080e7          	jalr	-340(ra) # 80000ae6 <kalloc>
    80001c42:	892a                	mv	s2,a0
    80001c44:	eca8                	sd	a0,88(s1)
    80001c46:	c131                	beqz	a0,80001c8a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c48:	8526                	mv	a0,s1
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	e5c080e7          	jalr	-420(ra) # 80001aa6 <proc_pagetable>
    80001c52:	892a                	mv	s2,a0
    80001c54:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c56:	c531                	beqz	a0,80001ca2 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c58:	07000613          	li	a2,112
    80001c5c:	4581                	li	a1,0
    80001c5e:	06048513          	addi	a0,s1,96
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	070080e7          	jalr	112(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c6a:	00000797          	auipc	a5,0x0
    80001c6e:	db078793          	addi	a5,a5,-592 # 80001a1a <forkret>
    80001c72:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c74:	60bc                	ld	a5,64(s1)
    80001c76:	6705                	lui	a4,0x1
    80001c78:	97ba                	add	a5,a5,a4
    80001c7a:	f4bc                	sd	a5,104(s1)
}
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6902                	ld	s2,0(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret
    freeproc(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	f08080e7          	jalr	-248(ra) # 80001b94 <freeproc>
    release(&p->lock);
    80001c94:	8526                	mv	a0,s1
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
    return 0;
    80001c9e:	84ca                	mv	s1,s2
    80001ca0:	bff1                	j	80001c7c <allocproc+0x90>
    freeproc(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	ef0080e7          	jalr	-272(ra) # 80001b94 <freeproc>
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	fdc080e7          	jalr	-36(ra) # 80000c8a <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	b7d1                	j	80001c7c <allocproc+0x90>

0000000080001cba <userinit>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	f28080e7          	jalr	-216(ra) # 80001bec <allocproc>
    80001ccc:	84aa                	mv	s1,a0
  initproc = p;
    80001cce:	00007797          	auipc	a5,0x7
    80001cd2:	58a7b523          	sd	a0,1418(a5) # 80009258 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd6:	03400613          	li	a2,52
    80001cda:	00007597          	auipc	a1,0x7
    80001cde:	4f658593          	addi	a1,a1,1270 # 800091d0 <initcode>
    80001ce2:	6928                	ld	a0,80(a0)
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	6a8080e7          	jalr	1704(ra) # 8000138c <uvmfirst>
  p->sz = PGSIZE;
    80001cec:	6785                	lui	a5,0x1
    80001cee:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cf0:	6cb8                	ld	a4,88(s1)
    80001cf2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf6:	6cb8                	ld	a4,88(s1)
    80001cf8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfa:	4641                	li	a2,16
    80001cfc:	00006597          	auipc	a1,0x6
    80001d00:	51458593          	addi	a1,a1,1300 # 80008210 <digits+0x1d0>
    80001d04:	15848513          	addi	a0,s1,344
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	114080e7          	jalr	276(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d10:	00006517          	auipc	a0,0x6
    80001d14:	51050513          	addi	a0,a0,1296 # 80008220 <digits+0x1e0>
    80001d18:	00002097          	auipc	ra,0x2
    80001d1c:	2d4080e7          	jalr	724(ra) # 80003fec <namei>
    80001d20:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d24:	478d                	li	a5,3
    80001d26:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d28:	8526                	mv	a0,s1
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	f60080e7          	jalr	-160(ra) # 80000c8a <release>
}
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret

0000000080001d3c <kproc_create>:
{
    80001d3c:	7179                	addi	sp,sp,-48
    80001d3e:	f406                	sd	ra,40(sp)
    80001d40:	f022                	sd	s0,32(sp)
    80001d42:	ec26                	sd	s1,24(sp)
    80001d44:	e84a                	sd	s2,16(sp)
    80001d46:	e44e                	sd	s3,8(sp)
    80001d48:	1800                	addi	s0,sp,48
    80001d4a:	89aa                	mv	s3,a0
    80001d4c:	892e                	mv	s2,a1
  struct proc *p = allocproc();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	e9e080e7          	jalr	-354(ra) # 80001bec <allocproc>
  if(p == 0)
    80001d56:	cd15                	beqz	a0,80001d92 <kproc_create+0x56>
    80001d58:	84aa                	mv	s1,a0
  p->context.ra = (uint64)fn;
    80001d5a:	07353023          	sd	s3,96(a0)
  p->context.sp = p->kstack + PGSIZE;
    80001d5e:	613c                	ld	a5,64(a0)
    80001d60:	6705                	lui	a4,0x1
    80001d62:	97ba                	add	a5,a5,a4
    80001d64:	f53c                	sd	a5,104(a0)
  safestrcpy(p->name, name, sizeof(p->name));
    80001d66:	4641                	li	a2,16
    80001d68:	85ca                	mv	a1,s2
    80001d6a:	15850513          	addi	a0,a0,344
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	0ae080e7          	jalr	174(ra) # 80000e1c <safestrcpy>
  p->state = RUNNABLE;
    80001d76:	478d                	li	a5,3
    80001d78:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f0e080e7          	jalr	-242(ra) # 80000c8a <release>
}
    80001d84:	70a2                	ld	ra,40(sp)
    80001d86:	7402                	ld	s0,32(sp)
    80001d88:	64e2                	ld	s1,24(sp)
    80001d8a:	6942                	ld	s2,16(sp)
    80001d8c:	69a2                	ld	s3,8(sp)
    80001d8e:	6145                	addi	sp,sp,48
    80001d90:	8082                	ret
    panic("kproc_create");
    80001d92:	00006517          	auipc	a0,0x6
    80001d96:	49650513          	addi	a0,a0,1174 # 80008228 <digits+0x1e8>
    80001d9a:	ffffe097          	auipc	ra,0xffffe
    80001d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>

0000000080001da2 <growproc>:
{
    80001da2:	1101                	addi	sp,sp,-32
    80001da4:	ec06                	sd	ra,24(sp)
    80001da6:	e822                	sd	s0,16(sp)
    80001da8:	e426                	sd	s1,8(sp)
    80001daa:	e04a                	sd	s2,0(sp)
    80001dac:	1000                	addi	s0,sp,32
    80001dae:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001db0:	00000097          	auipc	ra,0x0
    80001db4:	c32080e7          	jalr	-974(ra) # 800019e2 <myproc>
    80001db8:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dba:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dbc:	01204c63          	bgtz	s2,80001dd4 <growproc+0x32>
  } else if(n < 0){
    80001dc0:	02094663          	bltz	s2,80001dec <growproc+0x4a>
  p->sz = sz;
    80001dc4:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dc6:	4501                	li	a0,0
}
    80001dc8:	60e2                	ld	ra,24(sp)
    80001dca:	6442                	ld	s0,16(sp)
    80001dcc:	64a2                	ld	s1,8(sp)
    80001dce:	6902                	ld	s2,0(sp)
    80001dd0:	6105                	addi	sp,sp,32
    80001dd2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dd4:	4691                	li	a3,4
    80001dd6:	00b90633          	add	a2,s2,a1
    80001dda:	6928                	ld	a0,80(a0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	66a080e7          	jalr	1642(ra) # 80001446 <uvmalloc>
    80001de4:	85aa                	mv	a1,a0
    80001de6:	fd79                	bnez	a0,80001dc4 <growproc+0x22>
      return -1;
    80001de8:	557d                	li	a0,-1
    80001dea:	bff9                	j	80001dc8 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dec:	00b90633          	add	a2,s2,a1
    80001df0:	6928                	ld	a0,80(a0)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	60c080e7          	jalr	1548(ra) # 800013fe <uvmdealloc>
    80001dfa:	85aa                	mv	a1,a0
    80001dfc:	b7e1                	j	80001dc4 <growproc+0x22>

0000000080001dfe <fork>:
{
    80001dfe:	7139                	addi	sp,sp,-64
    80001e00:	fc06                	sd	ra,56(sp)
    80001e02:	f822                	sd	s0,48(sp)
    80001e04:	f426                	sd	s1,40(sp)
    80001e06:	f04a                	sd	s2,32(sp)
    80001e08:	ec4e                	sd	s3,24(sp)
    80001e0a:	e852                	sd	s4,16(sp)
    80001e0c:	e456                	sd	s5,8(sp)
    80001e0e:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	bd2080e7          	jalr	-1070(ra) # 800019e2 <myproc>
    80001e18:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	dd2080e7          	jalr	-558(ra) # 80001bec <allocproc>
    80001e22:	10050c63          	beqz	a0,80001f3a <fork+0x13c>
    80001e26:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e28:	048ab603          	ld	a2,72(s5)
    80001e2c:	692c                	ld	a1,80(a0)
    80001e2e:	050ab503          	ld	a0,80(s5)
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	768080e7          	jalr	1896(ra) # 8000159a <uvmcopy>
    80001e3a:	04054863          	bltz	a0,80001e8a <fork+0x8c>
  np->sz = p->sz;
    80001e3e:	048ab783          	ld	a5,72(s5)
    80001e42:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e46:	058ab683          	ld	a3,88(s5)
    80001e4a:	87b6                	mv	a5,a3
    80001e4c:	058a3703          	ld	a4,88(s4)
    80001e50:	12068693          	addi	a3,a3,288
    80001e54:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e58:	6788                	ld	a0,8(a5)
    80001e5a:	6b8c                	ld	a1,16(a5)
    80001e5c:	6f90                	ld	a2,24(a5)
    80001e5e:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001e62:	e708                	sd	a0,8(a4)
    80001e64:	eb0c                	sd	a1,16(a4)
    80001e66:	ef10                	sd	a2,24(a4)
    80001e68:	02078793          	addi	a5,a5,32
    80001e6c:	02070713          	addi	a4,a4,32
    80001e70:	fed792e3          	bne	a5,a3,80001e54 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e74:	058a3783          	ld	a5,88(s4)
    80001e78:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e7c:	0d0a8493          	addi	s1,s5,208
    80001e80:	0d0a0913          	addi	s2,s4,208
    80001e84:	150a8993          	addi	s3,s5,336
    80001e88:	a00d                	j	80001eaa <fork+0xac>
    freeproc(np);
    80001e8a:	8552                	mv	a0,s4
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	d08080e7          	jalr	-760(ra) # 80001b94 <freeproc>
    release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	a059                	j	80001f26 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001ea2:	04a1                	addi	s1,s1,8
    80001ea4:	0921                	addi	s2,s2,8
    80001ea6:	01348b63          	beq	s1,s3,80001ebc <fork+0xbe>
    if(p->ofile[i])
    80001eaa:	6088                	ld	a0,0(s1)
    80001eac:	d97d                	beqz	a0,80001ea2 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eae:	00002097          	auipc	ra,0x2
    80001eb2:	7d4080e7          	jalr	2004(ra) # 80004682 <filedup>
    80001eb6:	00a93023          	sd	a0,0(s2)
    80001eba:	b7e5                	j	80001ea2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ebc:	150ab503          	ld	a0,336(s5)
    80001ec0:	00002097          	auipc	ra,0x2
    80001ec4:	948080e7          	jalr	-1720(ra) # 80003808 <idup>
    80001ec8:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ecc:	4641                	li	a2,16
    80001ece:	158a8593          	addi	a1,s5,344
    80001ed2:	158a0513          	addi	a0,s4,344
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	f46080e7          	jalr	-186(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001ede:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ee2:	8552                	mv	a0,s4
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	da6080e7          	jalr	-602(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001eec:	0000f497          	auipc	s1,0xf
    80001ef0:	5fc48493          	addi	s1,s1,1532 # 800114e8 <wait_lock>
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	ce0080e7          	jalr	-800(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001efe:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	d86080e7          	jalr	-634(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f0c:	8552                	mv	a0,s4
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	cc8080e7          	jalr	-824(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f16:	478d                	li	a5,3
    80001f18:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f1c:	8552                	mv	a0,s4
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d6c080e7          	jalr	-660(ra) # 80000c8a <release>
}
    80001f26:	854a                	mv	a0,s2
    80001f28:	70e2                	ld	ra,56(sp)
    80001f2a:	7442                	ld	s0,48(sp)
    80001f2c:	74a2                	ld	s1,40(sp)
    80001f2e:	7902                	ld	s2,32(sp)
    80001f30:	69e2                	ld	s3,24(sp)
    80001f32:	6a42                	ld	s4,16(sp)
    80001f34:	6aa2                	ld	s5,8(sp)
    80001f36:	6121                	addi	sp,sp,64
    80001f38:	8082                	ret
    return -1;
    80001f3a:	597d                	li	s2,-1
    80001f3c:	b7ed                	j	80001f26 <fork+0x128>

0000000080001f3e <scheduler>:
{
    80001f3e:	7139                	addi	sp,sp,-64
    80001f40:	fc06                	sd	ra,56(sp)
    80001f42:	f822                	sd	s0,48(sp)
    80001f44:	f426                	sd	s1,40(sp)
    80001f46:	f04a                	sd	s2,32(sp)
    80001f48:	ec4e                	sd	s3,24(sp)
    80001f4a:	e852                	sd	s4,16(sp)
    80001f4c:	e456                	sd	s5,8(sp)
    80001f4e:	e05a                	sd	s6,0(sp)
    80001f50:	0080                	addi	s0,sp,64
    80001f52:	8792                	mv	a5,tp
  int id = r_tp();
    80001f54:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f56:	00779a93          	slli	s5,a5,0x7
    80001f5a:	0000f717          	auipc	a4,0xf
    80001f5e:	57670713          	addi	a4,a4,1398 # 800114d0 <pid_lock>
    80001f62:	9756                	add	a4,a4,s5
    80001f64:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f68:	0000f717          	auipc	a4,0xf
    80001f6c:	5a070713          	addi	a4,a4,1440 # 80011508 <cpus+0x8>
    80001f70:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f72:	498d                	li	s3,3
        p->state = RUNNING;
    80001f74:	4b11                	li	s6,4
        c->proc = p;
    80001f76:	079e                	slli	a5,a5,0x7
    80001f78:	0000fa17          	auipc	s4,0xf
    80001f7c:	558a0a13          	addi	s4,s4,1368 # 800114d0 <pid_lock>
    80001f80:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f82:	00015917          	auipc	s2,0x15
    80001f86:	37e90913          	addi	s2,s2,894 # 80017300 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f8e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f92:	10079073          	csrw	sstatus,a5
    80001f96:	00010497          	auipc	s1,0x10
    80001f9a:	96a48493          	addi	s1,s1,-1686 # 80011900 <proc>
    80001f9e:	a811                	j	80001fb2 <scheduler+0x74>
      release(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	ce8080e7          	jalr	-792(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001faa:	16848493          	addi	s1,s1,360
    80001fae:	fd248ee3          	beq	s1,s2,80001f8a <scheduler+0x4c>
      acquire(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	c22080e7          	jalr	-990(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001fbc:	4c9c                	lw	a5,24(s1)
    80001fbe:	ff3791e3          	bne	a5,s3,80001fa0 <scheduler+0x62>
        p->state = RUNNING;
    80001fc2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fc6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fca:	06048593          	addi	a1,s1,96
    80001fce:	8556                	mv	a0,s5
    80001fd0:	00000097          	auipc	ra,0x0
    80001fd4:	682080e7          	jalr	1666(ra) # 80002652 <swtch>
        c->proc = 0;
    80001fd8:	020a3823          	sd	zero,48(s4)
    80001fdc:	b7d1                	j	80001fa0 <scheduler+0x62>

0000000080001fde <sched>:
{
    80001fde:	7179                	addi	sp,sp,-48
    80001fe0:	f406                	sd	ra,40(sp)
    80001fe2:	f022                	sd	s0,32(sp)
    80001fe4:	ec26                	sd	s1,24(sp)
    80001fe6:	e84a                	sd	s2,16(sp)
    80001fe8:	e44e                	sd	s3,8(sp)
    80001fea:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	9f6080e7          	jalr	-1546(ra) # 800019e2 <myproc>
    80001ff4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	b66080e7          	jalr	-1178(ra) # 80000b5c <holding>
    80001ffe:	c93d                	beqz	a0,80002074 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002000:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002002:	2781                	sext.w	a5,a5
    80002004:	079e                	slli	a5,a5,0x7
    80002006:	0000f717          	auipc	a4,0xf
    8000200a:	4ca70713          	addi	a4,a4,1226 # 800114d0 <pid_lock>
    8000200e:	97ba                	add	a5,a5,a4
    80002010:	0a87a703          	lw	a4,168(a5)
    80002014:	4785                	li	a5,1
    80002016:	06f71763          	bne	a4,a5,80002084 <sched+0xa6>
  if(p->state == RUNNING)
    8000201a:	4c98                	lw	a4,24(s1)
    8000201c:	4791                	li	a5,4
    8000201e:	06f70b63          	beq	a4,a5,80002094 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002022:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002026:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002028:	efb5                	bnez	a5,800020a4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000202a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000202c:	0000f917          	auipc	s2,0xf
    80002030:	4a490913          	addi	s2,s2,1188 # 800114d0 <pid_lock>
    80002034:	2781                	sext.w	a5,a5
    80002036:	079e                	slli	a5,a5,0x7
    80002038:	97ca                	add	a5,a5,s2
    8000203a:	0ac7a983          	lw	s3,172(a5)
    8000203e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002040:	2781                	sext.w	a5,a5
    80002042:	079e                	slli	a5,a5,0x7
    80002044:	0000f597          	auipc	a1,0xf
    80002048:	4c458593          	addi	a1,a1,1220 # 80011508 <cpus+0x8>
    8000204c:	95be                	add	a1,a1,a5
    8000204e:	06048513          	addi	a0,s1,96
    80002052:	00000097          	auipc	ra,0x0
    80002056:	600080e7          	jalr	1536(ra) # 80002652 <swtch>
    8000205a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000205c:	2781                	sext.w	a5,a5
    8000205e:	079e                	slli	a5,a5,0x7
    80002060:	97ca                	add	a5,a5,s2
    80002062:	0b37a623          	sw	s3,172(a5)
}
    80002066:	70a2                	ld	ra,40(sp)
    80002068:	7402                	ld	s0,32(sp)
    8000206a:	64e2                	ld	s1,24(sp)
    8000206c:	6942                	ld	s2,16(sp)
    8000206e:	69a2                	ld	s3,8(sp)
    80002070:	6145                	addi	sp,sp,48
    80002072:	8082                	ret
    panic("sched p->lock");
    80002074:	00006517          	auipc	a0,0x6
    80002078:	1c450513          	addi	a0,a0,452 # 80008238 <digits+0x1f8>
    8000207c:	ffffe097          	auipc	ra,0xffffe
    80002080:	4c2080e7          	jalr	1218(ra) # 8000053e <panic>
    panic("sched locks");
    80002084:	00006517          	auipc	a0,0x6
    80002088:	1c450513          	addi	a0,a0,452 # 80008248 <digits+0x208>
    8000208c:	ffffe097          	auipc	ra,0xffffe
    80002090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>
    panic("sched running");
    80002094:	00006517          	auipc	a0,0x6
    80002098:	1c450513          	addi	a0,a0,452 # 80008258 <digits+0x218>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	4a2080e7          	jalr	1186(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020a4:	00006517          	auipc	a0,0x6
    800020a8:	1c450513          	addi	a0,a0,452 # 80008268 <digits+0x228>
    800020ac:	ffffe097          	auipc	ra,0xffffe
    800020b0:	492080e7          	jalr	1170(ra) # 8000053e <panic>

00000000800020b4 <yield>:
{
    800020b4:	1101                	addi	sp,sp,-32
    800020b6:	ec06                	sd	ra,24(sp)
    800020b8:	e822                	sd	s0,16(sp)
    800020ba:	e426                	sd	s1,8(sp)
    800020bc:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	924080e7          	jalr	-1756(ra) # 800019e2 <myproc>
    800020c6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	b0e080e7          	jalr	-1266(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020d0:	478d                	li	a5,3
    800020d2:	cc9c                	sw	a5,24(s1)
  sched();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	f0a080e7          	jalr	-246(ra) # 80001fde <sched>
  release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	bac080e7          	jalr	-1108(ra) # 80000c8a <release>
}
    800020e6:	60e2                	ld	ra,24(sp)
    800020e8:	6442                	ld	s0,16(sp)
    800020ea:	64a2                	ld	s1,8(sp)
    800020ec:	6105                	addi	sp,sp,32
    800020ee:	8082                	ret

00000000800020f0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020f0:	7179                	addi	sp,sp,-48
    800020f2:	f406                	sd	ra,40(sp)
    800020f4:	f022                	sd	s0,32(sp)
    800020f6:	ec26                	sd	s1,24(sp)
    800020f8:	e84a                	sd	s2,16(sp)
    800020fa:	e44e                	sd	s3,8(sp)
    800020fc:	1800                	addi	s0,sp,48
    800020fe:	89aa                	mv	s3,a0
    80002100:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	8e0080e7          	jalr	-1824(ra) # 800019e2 <myproc>
    8000210a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	aca080e7          	jalr	-1334(ra) # 80000bd6 <acquire>
  release(lk);
    80002114:	854a                	mv	a0,s2
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b74080e7          	jalr	-1164(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000211e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002122:	4789                	li	a5,2
    80002124:	cc9c                	sw	a5,24(s1)

  sched();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	eb8080e7          	jalr	-328(ra) # 80001fde <sched>

  // Tidy up.
  p->chan = 0;
    8000212e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002132:	8526                	mv	a0,s1
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	b56080e7          	jalr	-1194(ra) # 80000c8a <release>
  acquire(lk);
    8000213c:	854a                	mv	a0,s2
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	a98080e7          	jalr	-1384(ra) # 80000bd6 <acquire>
}
    80002146:	70a2                	ld	ra,40(sp)
    80002148:	7402                	ld	s0,32(sp)
    8000214a:	64e2                	ld	s1,24(sp)
    8000214c:	6942                	ld	s2,16(sp)
    8000214e:	69a2                	ld	s3,8(sp)
    80002150:	6145                	addi	sp,sp,48
    80002152:	8082                	ret

0000000080002154 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002154:	7139                	addi	sp,sp,-64
    80002156:	fc06                	sd	ra,56(sp)
    80002158:	f822                	sd	s0,48(sp)
    8000215a:	f426                	sd	s1,40(sp)
    8000215c:	f04a                	sd	s2,32(sp)
    8000215e:	ec4e                	sd	s3,24(sp)
    80002160:	e852                	sd	s4,16(sp)
    80002162:	e456                	sd	s5,8(sp)
    80002164:	0080                	addi	s0,sp,64
    80002166:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002168:	0000f497          	auipc	s1,0xf
    8000216c:	79848493          	addi	s1,s1,1944 # 80011900 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002170:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002172:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002174:	00015917          	auipc	s2,0x15
    80002178:	18c90913          	addi	s2,s2,396 # 80017300 <tickslock>
    8000217c:	a811                	j	80002190 <wakeup+0x3c>
      }
      release(&p->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	b0a080e7          	jalr	-1270(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002188:	16848493          	addi	s1,s1,360
    8000218c:	03248663          	beq	s1,s2,800021b8 <wakeup+0x64>
    if(p != myproc()){
    80002190:	00000097          	auipc	ra,0x0
    80002194:	852080e7          	jalr	-1966(ra) # 800019e2 <myproc>
    80002198:	fea488e3          	beq	s1,a0,80002188 <wakeup+0x34>
      acquire(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	a38080e7          	jalr	-1480(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021a6:	4c9c                	lw	a5,24(s1)
    800021a8:	fd379be3          	bne	a5,s3,8000217e <wakeup+0x2a>
    800021ac:	709c                	ld	a5,32(s1)
    800021ae:	fd4798e3          	bne	a5,s4,8000217e <wakeup+0x2a>
        p->state = RUNNABLE;
    800021b2:	0154ac23          	sw	s5,24(s1)
    800021b6:	b7e1                	j	8000217e <wakeup+0x2a>
    }
  }
}
    800021b8:	70e2                	ld	ra,56(sp)
    800021ba:	7442                	ld	s0,48(sp)
    800021bc:	74a2                	ld	s1,40(sp)
    800021be:	7902                	ld	s2,32(sp)
    800021c0:	69e2                	ld	s3,24(sp)
    800021c2:	6a42                	ld	s4,16(sp)
    800021c4:	6aa2                	ld	s5,8(sp)
    800021c6:	6121                	addi	sp,sp,64
    800021c8:	8082                	ret

00000000800021ca <reparent>:
{
    800021ca:	7179                	addi	sp,sp,-48
    800021cc:	f406                	sd	ra,40(sp)
    800021ce:	f022                	sd	s0,32(sp)
    800021d0:	ec26                	sd	s1,24(sp)
    800021d2:	e84a                	sd	s2,16(sp)
    800021d4:	e44e                	sd	s3,8(sp)
    800021d6:	e052                	sd	s4,0(sp)
    800021d8:	1800                	addi	s0,sp,48
    800021da:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021dc:	0000f497          	auipc	s1,0xf
    800021e0:	72448493          	addi	s1,s1,1828 # 80011900 <proc>
      pp->parent = initproc;
    800021e4:	00007a17          	auipc	s4,0x7
    800021e8:	074a0a13          	addi	s4,s4,116 # 80009258 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ec:	00015997          	auipc	s3,0x15
    800021f0:	11498993          	addi	s3,s3,276 # 80017300 <tickslock>
    800021f4:	a029                	j	800021fe <reparent+0x34>
    800021f6:	16848493          	addi	s1,s1,360
    800021fa:	01348d63          	beq	s1,s3,80002214 <reparent+0x4a>
    if(pp->parent == p){
    800021fe:	7c9c                	ld	a5,56(s1)
    80002200:	ff279be3          	bne	a5,s2,800021f6 <reparent+0x2c>
      pp->parent = initproc;
    80002204:	000a3503          	ld	a0,0(s4)
    80002208:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	f4a080e7          	jalr	-182(ra) # 80002154 <wakeup>
    80002212:	b7d5                	j	800021f6 <reparent+0x2c>
}
    80002214:	70a2                	ld	ra,40(sp)
    80002216:	7402                	ld	s0,32(sp)
    80002218:	64e2                	ld	s1,24(sp)
    8000221a:	6942                	ld	s2,16(sp)
    8000221c:	69a2                	ld	s3,8(sp)
    8000221e:	6a02                	ld	s4,0(sp)
    80002220:	6145                	addi	sp,sp,48
    80002222:	8082                	ret

0000000080002224 <exit>:
{
    80002224:	7179                	addi	sp,sp,-48
    80002226:	f406                	sd	ra,40(sp)
    80002228:	f022                	sd	s0,32(sp)
    8000222a:	ec26                	sd	s1,24(sp)
    8000222c:	e84a                	sd	s2,16(sp)
    8000222e:	e44e                	sd	s3,8(sp)
    80002230:	e052                	sd	s4,0(sp)
    80002232:	1800                	addi	s0,sp,48
    80002234:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	7ac080e7          	jalr	1964(ra) # 800019e2 <myproc>
    8000223e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002240:	00007797          	auipc	a5,0x7
    80002244:	0187b783          	ld	a5,24(a5) # 80009258 <initproc>
    80002248:	0d050493          	addi	s1,a0,208
    8000224c:	15050913          	addi	s2,a0,336
    80002250:	02a79363          	bne	a5,a0,80002276 <exit+0x52>
    panic("init exiting");
    80002254:	00006517          	auipc	a0,0x6
    80002258:	02c50513          	addi	a0,a0,44 # 80008280 <digits+0x240>
    8000225c:	ffffe097          	auipc	ra,0xffffe
    80002260:	2e2080e7          	jalr	738(ra) # 8000053e <panic>
      fileclose(f);
    80002264:	00002097          	auipc	ra,0x2
    80002268:	470080e7          	jalr	1136(ra) # 800046d4 <fileclose>
      p->ofile[fd] = 0;
    8000226c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002270:	04a1                	addi	s1,s1,8
    80002272:	01248563          	beq	s1,s2,8000227c <exit+0x58>
    if(p->ofile[fd]){
    80002276:	6088                	ld	a0,0(s1)
    80002278:	f575                	bnez	a0,80002264 <exit+0x40>
    8000227a:	bfdd                	j	80002270 <exit+0x4c>
  begin_op();
    8000227c:	00002097          	auipc	ra,0x2
    80002280:	f8c080e7          	jalr	-116(ra) # 80004208 <begin_op>
  iput(p->cwd);
    80002284:	1509b503          	ld	a0,336(s3)
    80002288:	00001097          	auipc	ra,0x1
    8000228c:	778080e7          	jalr	1912(ra) # 80003a00 <iput>
  end_op();
    80002290:	00002097          	auipc	ra,0x2
    80002294:	ff8080e7          	jalr	-8(ra) # 80004288 <end_op>
  p->cwd = 0;
    80002298:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000229c:	0000f497          	auipc	s1,0xf
    800022a0:	24c48493          	addi	s1,s1,588 # 800114e8 <wait_lock>
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	930080e7          	jalr	-1744(ra) # 80000bd6 <acquire>
  reparent(p);
    800022ae:	854e                	mv	a0,s3
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	f1a080e7          	jalr	-230(ra) # 800021ca <reparent>
  wakeup(p->parent);
    800022b8:	0389b503          	ld	a0,56(s3)
    800022bc:	00000097          	auipc	ra,0x0
    800022c0:	e98080e7          	jalr	-360(ra) # 80002154 <wakeup>
  acquire(&p->lock);
    800022c4:	854e                	mv	a0,s3
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022ce:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022d2:	4795                	li	a5,5
    800022d4:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9b0080e7          	jalr	-1616(ra) # 80000c8a <release>
  sched();
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	cfc080e7          	jalr	-772(ra) # 80001fde <sched>
  panic("zombie exit");
    800022ea:	00006517          	auipc	a0,0x6
    800022ee:	fa650513          	addi	a0,a0,-90 # 80008290 <digits+0x250>
    800022f2:	ffffe097          	auipc	ra,0xffffe
    800022f6:	24c080e7          	jalr	588(ra) # 8000053e <panic>

00000000800022fa <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022fa:	7179                	addi	sp,sp,-48
    800022fc:	f406                	sd	ra,40(sp)
    800022fe:	f022                	sd	s0,32(sp)
    80002300:	ec26                	sd	s1,24(sp)
    80002302:	e84a                	sd	s2,16(sp)
    80002304:	e44e                	sd	s3,8(sp)
    80002306:	1800                	addi	s0,sp,48
    80002308:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000230a:	0000f497          	auipc	s1,0xf
    8000230e:	5f648493          	addi	s1,s1,1526 # 80011900 <proc>
    80002312:	00015997          	auipc	s3,0x15
    80002316:	fee98993          	addi	s3,s3,-18 # 80017300 <tickslock>
    acquire(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	8ba080e7          	jalr	-1862(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002324:	589c                	lw	a5,48(s1)
    80002326:	01278d63          	beq	a5,s2,80002340 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	95e080e7          	jalr	-1698(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002334:	16848493          	addi	s1,s1,360
    80002338:	ff3491e3          	bne	s1,s3,8000231a <kill+0x20>
  }
  return -1;
    8000233c:	557d                	li	a0,-1
    8000233e:	a829                	j	80002358 <kill+0x5e>
      p->killed = 1;
    80002340:	4785                	li	a5,1
    80002342:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002344:	4c98                	lw	a4,24(s1)
    80002346:	4789                	li	a5,2
    80002348:	00f70f63          	beq	a4,a5,80002366 <kill+0x6c>
      release(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
      return 0;
    80002356:	4501                	li	a0,0
}
    80002358:	70a2                	ld	ra,40(sp)
    8000235a:	7402                	ld	s0,32(sp)
    8000235c:	64e2                	ld	s1,24(sp)
    8000235e:	6942                	ld	s2,16(sp)
    80002360:	69a2                	ld	s3,8(sp)
    80002362:	6145                	addi	sp,sp,48
    80002364:	8082                	ret
        p->state = RUNNABLE;
    80002366:	478d                	li	a5,3
    80002368:	cc9c                	sw	a5,24(s1)
    8000236a:	b7cd                	j	8000234c <kill+0x52>

000000008000236c <setkilled>:

void
setkilled(struct proc *p)
{
    8000236c:	1101                	addi	sp,sp,-32
    8000236e:	ec06                	sd	ra,24(sp)
    80002370:	e822                	sd	s0,16(sp)
    80002372:	e426                	sd	s1,8(sp)
    80002374:	1000                	addi	s0,sp,32
    80002376:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	85e080e7          	jalr	-1954(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002380:	4785                	li	a5,1
    80002382:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	904080e7          	jalr	-1788(ra) # 80000c8a <release>
}
    8000238e:	60e2                	ld	ra,24(sp)
    80002390:	6442                	ld	s0,16(sp)
    80002392:	64a2                	ld	s1,8(sp)
    80002394:	6105                	addi	sp,sp,32
    80002396:	8082                	ret

0000000080002398 <killed>:

int
killed(struct proc *p)
{
    80002398:	1101                	addi	sp,sp,-32
    8000239a:	ec06                	sd	ra,24(sp)
    8000239c:	e822                	sd	s0,16(sp)
    8000239e:	e426                	sd	s1,8(sp)
    800023a0:	e04a                	sd	s2,0(sp)
    800023a2:	1000                	addi	s0,sp,32
    800023a4:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023ae:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
  return k;
}
    800023bc:	854a                	mv	a0,s2
    800023be:	60e2                	ld	ra,24(sp)
    800023c0:	6442                	ld	s0,16(sp)
    800023c2:	64a2                	ld	s1,8(sp)
    800023c4:	6902                	ld	s2,0(sp)
    800023c6:	6105                	addi	sp,sp,32
    800023c8:	8082                	ret

00000000800023ca <wait>:
{
    800023ca:	715d                	addi	sp,sp,-80
    800023cc:	e486                	sd	ra,72(sp)
    800023ce:	e0a2                	sd	s0,64(sp)
    800023d0:	fc26                	sd	s1,56(sp)
    800023d2:	f84a                	sd	s2,48(sp)
    800023d4:	f44e                	sd	s3,40(sp)
    800023d6:	f052                	sd	s4,32(sp)
    800023d8:	ec56                	sd	s5,24(sp)
    800023da:	e85a                	sd	s6,16(sp)
    800023dc:	e45e                	sd	s7,8(sp)
    800023de:	e062                	sd	s8,0(sp)
    800023e0:	0880                	addi	s0,sp,80
    800023e2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	5fe080e7          	jalr	1534(ra) # 800019e2 <myproc>
    800023ec:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ee:	0000f517          	auipc	a0,0xf
    800023f2:	0fa50513          	addi	a0,a0,250 # 800114e8 <wait_lock>
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7e0080e7          	jalr	2016(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023fe:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002400:	4a15                	li	s4,5
        havekids = 1;
    80002402:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002404:	00015997          	auipc	s3,0x15
    80002408:	efc98993          	addi	s3,s3,-260 # 80017300 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000240c:	0000fc17          	auipc	s8,0xf
    80002410:	0dcc0c13          	addi	s8,s8,220 # 800114e8 <wait_lock>
    havekids = 0;
    80002414:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002416:	0000f497          	auipc	s1,0xf
    8000241a:	4ea48493          	addi	s1,s1,1258 # 80011900 <proc>
    8000241e:	a0bd                	j	8000248c <wait+0xc2>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x76>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	26a080e7          	jalr	618(ra) # 8000169e <copyout>
    8000243c:	02054563          	bltz	a0,80002466 <wait+0x9c>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	752080e7          	jalr	1874(ra) # 80001b94 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
          release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	09450513          	addi	a0,a0,148 # 800114e8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	82e080e7          	jalr	-2002(ra) # 80000c8a <release>
          return pid;
    80002464:	a0b5                	j	800024d0 <wait+0x106>
            release(&pp->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	822080e7          	jalr	-2014(ra) # 80000c8a <release>
            release(&wait_lock);
    80002470:	0000f517          	auipc	a0,0xf
    80002474:	07850513          	addi	a0,a0,120 # 800114e8 <wait_lock>
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	812080e7          	jalr	-2030(ra) # 80000c8a <release>
            return -1;
    80002480:	59fd                	li	s3,-1
    80002482:	a0b9                	j	800024d0 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002484:	16848493          	addi	s1,s1,360
    80002488:	03348463          	beq	s1,s3,800024b0 <wait+0xe6>
      if(pp->parent == p){
    8000248c:	7c9c                	ld	a5,56(s1)
    8000248e:	ff279be3          	bne	a5,s2,80002484 <wait+0xba>
        acquire(&pp->lock);
    80002492:	8526                	mv	a0,s1
    80002494:	ffffe097          	auipc	ra,0xffffe
    80002498:	742080e7          	jalr	1858(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000249c:	4c9c                	lw	a5,24(s1)
    8000249e:	f94781e3          	beq	a5,s4,80002420 <wait+0x56>
        release(&pp->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	7e6080e7          	jalr	2022(ra) # 80000c8a <release>
        havekids = 1;
    800024ac:	8756                	mv	a4,s5
    800024ae:	bfd9                	j	80002484 <wait+0xba>
    if(!havekids || killed(p)){
    800024b0:	c719                	beqz	a4,800024be <wait+0xf4>
    800024b2:	854a                	mv	a0,s2
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	ee4080e7          	jalr	-284(ra) # 80002398 <killed>
    800024bc:	c51d                	beqz	a0,800024ea <wait+0x120>
      release(&wait_lock);
    800024be:	0000f517          	auipc	a0,0xf
    800024c2:	02a50513          	addi	a0,a0,42 # 800114e8 <wait_lock>
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	7c4080e7          	jalr	1988(ra) # 80000c8a <release>
      return -1;
    800024ce:	59fd                	li	s3,-1
}
    800024d0:	854e                	mv	a0,s3
    800024d2:	60a6                	ld	ra,72(sp)
    800024d4:	6406                	ld	s0,64(sp)
    800024d6:	74e2                	ld	s1,56(sp)
    800024d8:	7942                	ld	s2,48(sp)
    800024da:	79a2                	ld	s3,40(sp)
    800024dc:	7a02                	ld	s4,32(sp)
    800024de:	6ae2                	ld	s5,24(sp)
    800024e0:	6b42                	ld	s6,16(sp)
    800024e2:	6ba2                	ld	s7,8(sp)
    800024e4:	6c02                	ld	s8,0(sp)
    800024e6:	6161                	addi	sp,sp,80
    800024e8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024ea:	85e2                	mv	a1,s8
    800024ec:	854a                	mv	a0,s2
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	c02080e7          	jalr	-1022(ra) # 800020f0 <sleep>
    havekids = 0;
    800024f6:	bf39                	j	80002414 <wait+0x4a>

00000000800024f8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f8:	7179                	addi	sp,sp,-48
    800024fa:	f406                	sd	ra,40(sp)
    800024fc:	f022                	sd	s0,32(sp)
    800024fe:	ec26                	sd	s1,24(sp)
    80002500:	e84a                	sd	s2,16(sp)
    80002502:	e44e                	sd	s3,8(sp)
    80002504:	e052                	sd	s4,0(sp)
    80002506:	1800                	addi	s0,sp,48
    80002508:	84aa                	mv	s1,a0
    8000250a:	892e                	mv	s2,a1
    8000250c:	89b2                	mv	s3,a2
    8000250e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	4d2080e7          	jalr	1234(ra) # 800019e2 <myproc>
  if(user_dst){
    80002518:	c08d                	beqz	s1,8000253a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000251a:	86d2                	mv	a3,s4
    8000251c:	864e                	mv	a2,s3
    8000251e:	85ca                	mv	a1,s2
    80002520:	6928                	ld	a0,80(a0)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	17c080e7          	jalr	380(ra) # 8000169e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6a02                	ld	s4,0(sp)
    80002536:	6145                	addi	sp,sp,48
    80002538:	8082                	ret
    memmove((char *)dst, src, len);
    8000253a:	000a061b          	sext.w	a2,s4
    8000253e:	85ce                	mv	a1,s3
    80002540:	854a                	mv	a0,s2
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	7ec080e7          	jalr	2028(ra) # 80000d2e <memmove>
    return 0;
    8000254a:	8526                	mv	a0,s1
    8000254c:	bff9                	j	8000252a <either_copyout+0x32>

000000008000254e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254e:	7179                	addi	sp,sp,-48
    80002550:	f406                	sd	ra,40(sp)
    80002552:	f022                	sd	s0,32(sp)
    80002554:	ec26                	sd	s1,24(sp)
    80002556:	e84a                	sd	s2,16(sp)
    80002558:	e44e                	sd	s3,8(sp)
    8000255a:	e052                	sd	s4,0(sp)
    8000255c:	1800                	addi	s0,sp,48
    8000255e:	892a                	mv	s2,a0
    80002560:	84ae                	mv	s1,a1
    80002562:	89b2                	mv	s3,a2
    80002564:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	47c080e7          	jalr	1148(ra) # 800019e2 <myproc>
  if(user_src){
    8000256e:	c08d                	beqz	s1,80002590 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002570:	86d2                	mv	a3,s4
    80002572:	864e                	mv	a2,s3
    80002574:	85ca                	mv	a1,s2
    80002576:	6928                	ld	a0,80(a0)
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	1b2080e7          	jalr	434(ra) # 8000172a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002580:	70a2                	ld	ra,40(sp)
    80002582:	7402                	ld	s0,32(sp)
    80002584:	64e2                	ld	s1,24(sp)
    80002586:	6942                	ld	s2,16(sp)
    80002588:	69a2                	ld	s3,8(sp)
    8000258a:	6a02                	ld	s4,0(sp)
    8000258c:	6145                	addi	sp,sp,48
    8000258e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002590:	000a061b          	sext.w	a2,s4
    80002594:	85ce                	mv	a1,s3
    80002596:	854a                	mv	a0,s2
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	796080e7          	jalr	1942(ra) # 80000d2e <memmove>
    return 0;
    800025a0:	8526                	mv	a0,s1
    800025a2:	bff9                	j	80002580 <either_copyin+0x32>

00000000800025a4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a4:	715d                	addi	sp,sp,-80
    800025a6:	e486                	sd	ra,72(sp)
    800025a8:	e0a2                	sd	s0,64(sp)
    800025aa:	fc26                	sd	s1,56(sp)
    800025ac:	f84a                	sd	s2,48(sp)
    800025ae:	f44e                	sd	s3,40(sp)
    800025b0:	f052                	sd	s4,32(sp)
    800025b2:	ec56                	sd	s5,24(sp)
    800025b4:	e85a                	sd	s6,16(sp)
    800025b6:	e45e                	sd	s7,8(sp)
    800025b8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ba:	00006517          	auipc	a0,0x6
    800025be:	b1e50513          	addi	a0,a0,-1250 # 800080d8 <digits+0x98>
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	fc6080e7          	jalr	-58(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ca:	0000f497          	auipc	s1,0xf
    800025ce:	48e48493          	addi	s1,s1,1166 # 80011a58 <proc+0x158>
    800025d2:	00015917          	auipc	s2,0x15
    800025d6:	e8690913          	addi	s2,s2,-378 # 80017458 <fb_va_by_pid+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025da:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025dc:	00006997          	auipc	s3,0x6
    800025e0:	cc498993          	addi	s3,s3,-828 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    800025e4:	00006a97          	auipc	s5,0x6
    800025e8:	cc4a8a93          	addi	s5,s5,-828 # 800082a8 <digits+0x268>
    printf("\n");
    800025ec:	00006a17          	auipc	s4,0x6
    800025f0:	aeca0a13          	addi	s4,s4,-1300 # 800080d8 <digits+0x98>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f4:	00006b97          	auipc	s7,0x6
    800025f8:	cf4b8b93          	addi	s7,s7,-780 # 800082e8 <states.0>
    800025fc:	a00d                	j	8000261e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025fe:	ed86a583          	lw	a1,-296(a3)
    80002602:	8556                	mv	a0,s5
    80002604:	ffffe097          	auipc	ra,0xffffe
    80002608:	f84080e7          	jalr	-124(ra) # 80000588 <printf>
    printf("\n");
    8000260c:	8552                	mv	a0,s4
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7a080e7          	jalr	-134(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002616:	16848493          	addi	s1,s1,360
    8000261a:	03248163          	beq	s1,s2,8000263c <procdump+0x98>
    if(p->state == UNUSED)
    8000261e:	86a6                	mv	a3,s1
    80002620:	ec04a783          	lw	a5,-320(s1)
    80002624:	dbed                	beqz	a5,80002616 <procdump+0x72>
      state = "???";
    80002626:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002628:	fcfb6be3          	bltu	s6,a5,800025fe <procdump+0x5a>
    8000262c:	1782                	slli	a5,a5,0x20
    8000262e:	9381                	srli	a5,a5,0x20
    80002630:	078e                	slli	a5,a5,0x3
    80002632:	97de                	add	a5,a5,s7
    80002634:	6390                	ld	a2,0(a5)
    80002636:	f661                	bnez	a2,800025fe <procdump+0x5a>
      state = "???";
    80002638:	864e                	mv	a2,s3
    8000263a:	b7d1                	j	800025fe <procdump+0x5a>
  }
}
    8000263c:	60a6                	ld	ra,72(sp)
    8000263e:	6406                	ld	s0,64(sp)
    80002640:	74e2                	ld	s1,56(sp)
    80002642:	7942                	ld	s2,48(sp)
    80002644:	79a2                	ld	s3,40(sp)
    80002646:	7a02                	ld	s4,32(sp)
    80002648:	6ae2                	ld	s5,24(sp)
    8000264a:	6b42                	ld	s6,16(sp)
    8000264c:	6ba2                	ld	s7,8(sp)
    8000264e:	6161                	addi	sp,sp,80
    80002650:	8082                	ret

0000000080002652 <swtch>:
    80002652:	00153023          	sd	ra,0(a0)
    80002656:	00253423          	sd	sp,8(a0)
    8000265a:	e900                	sd	s0,16(a0)
    8000265c:	ed04                	sd	s1,24(a0)
    8000265e:	03253023          	sd	s2,32(a0)
    80002662:	03353423          	sd	s3,40(a0)
    80002666:	03453823          	sd	s4,48(a0)
    8000266a:	03553c23          	sd	s5,56(a0)
    8000266e:	05653023          	sd	s6,64(a0)
    80002672:	05753423          	sd	s7,72(a0)
    80002676:	05853823          	sd	s8,80(a0)
    8000267a:	05953c23          	sd	s9,88(a0)
    8000267e:	07a53023          	sd	s10,96(a0)
    80002682:	07b53423          	sd	s11,104(a0)
    80002686:	0005b083          	ld	ra,0(a1)
    8000268a:	0085b103          	ld	sp,8(a1)
    8000268e:	6980                	ld	s0,16(a1)
    80002690:	6d84                	ld	s1,24(a1)
    80002692:	0205b903          	ld	s2,32(a1)
    80002696:	0285b983          	ld	s3,40(a1)
    8000269a:	0305ba03          	ld	s4,48(a1)
    8000269e:	0385ba83          	ld	s5,56(a1)
    800026a2:	0405bb03          	ld	s6,64(a1)
    800026a6:	0485bb83          	ld	s7,72(a1)
    800026aa:	0505bc03          	ld	s8,80(a1)
    800026ae:	0585bc83          	ld	s9,88(a1)
    800026b2:	0605bd03          	ld	s10,96(a1)
    800026b6:	0685bd83          	ld	s11,104(a1)
    800026ba:	8082                	ret

00000000800026bc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026bc:	1141                	addi	sp,sp,-16
    800026be:	e406                	sd	ra,8(sp)
    800026c0:	e022                	sd	s0,0(sp)
    800026c2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c4:	00006597          	auipc	a1,0x6
    800026c8:	c5458593          	addi	a1,a1,-940 # 80008318 <states.0+0x30>
    800026cc:	00015517          	auipc	a0,0x15
    800026d0:	c3450513          	addi	a0,a0,-972 # 80017300 <tickslock>
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	472080e7          	jalr	1138(ra) # 80000b46 <initlock>
}
    800026dc:	60a2                	ld	ra,8(sp)
    800026de:	6402                	ld	s0,0(sp)
    800026e0:	0141                	addi	sp,sp,16
    800026e2:	8082                	ret

00000000800026e4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e4:	1141                	addi	sp,sp,-16
    800026e6:	e422                	sd	s0,8(sp)
    800026e8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ea:	00003797          	auipc	a5,0x3
    800026ee:	63678793          	addi	a5,a5,1590 # 80005d20 <kernelvec>
    800026f2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f6:	6422                	ld	s0,8(sp)
    800026f8:	0141                	addi	sp,sp,16
    800026fa:	8082                	ret

00000000800026fc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026fc:	1141                	addi	sp,sp,-16
    800026fe:	e406                	sd	ra,8(sp)
    80002700:	e022                	sd	s0,0(sp)
    80002702:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	2de080e7          	jalr	734(ra) # 800019e2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002710:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002712:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002716:	00005617          	auipc	a2,0x5
    8000271a:	8ea60613          	addi	a2,a2,-1814 # 80007000 <_trampoline>
    8000271e:	00005697          	auipc	a3,0x5
    80002722:	8e268693          	addi	a3,a3,-1822 # 80007000 <_trampoline>
    80002726:	8e91                	sub	a3,a3,a2
    80002728:	040007b7          	lui	a5,0x4000
    8000272c:	17fd                	addi	a5,a5,-1
    8000272e:	07b2                	slli	a5,a5,0xc
    80002730:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002732:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002736:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002738:	180026f3          	csrr	a3,satp
    8000273c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273e:	6d38                	ld	a4,88(a0)
    80002740:	6134                	ld	a3,64(a0)
    80002742:	6585                	lui	a1,0x1
    80002744:	96ae                	add	a3,a3,a1
    80002746:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002748:	6d38                	ld	a4,88(a0)
    8000274a:	00000697          	auipc	a3,0x0
    8000274e:	13068693          	addi	a3,a3,304 # 8000287a <usertrap>
    80002752:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002754:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002756:	8692                	mv	a3,tp
    80002758:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000275a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002762:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002766:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000276a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000276c:	6f18                	ld	a4,24(a4)
    8000276e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002772:	6928                	ld	a0,80(a0)
    80002774:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002776:	00005717          	auipc	a4,0x5
    8000277a:	92670713          	addi	a4,a4,-1754 # 8000709c <userret>
    8000277e:	8f11                	sub	a4,a4,a2
    80002780:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002782:	577d                	li	a4,-1
    80002784:	177e                	slli	a4,a4,0x3f
    80002786:	8d59                	or	a0,a0,a4
    80002788:	9782                	jalr	a5
}
    8000278a:	60a2                	ld	ra,8(sp)
    8000278c:	6402                	ld	s0,0(sp)
    8000278e:	0141                	addi	sp,sp,16
    80002790:	8082                	ret

0000000080002792 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002792:	1101                	addi	sp,sp,-32
    80002794:	ec06                	sd	ra,24(sp)
    80002796:	e822                	sd	s0,16(sp)
    80002798:	e426                	sd	s1,8(sp)
    8000279a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000279c:	00015497          	auipc	s1,0x15
    800027a0:	b6448493          	addi	s1,s1,-1180 # 80017300 <tickslock>
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	430080e7          	jalr	1072(ra) # 80000bd6 <acquire>
  ticks++;
    800027ae:	00007517          	auipc	a0,0x7
    800027b2:	ab250513          	addi	a0,a0,-1358 # 80009260 <ticks>
    800027b6:	411c                	lw	a5,0(a0)
    800027b8:	2785                	addiw	a5,a5,1
    800027ba:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027bc:	00000097          	auipc	ra,0x0
    800027c0:	998080e7          	jalr	-1640(ra) # 80002154 <wakeup>
  release(&tickslock);
    800027c4:	8526                	mv	a0,s1
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	4c4080e7          	jalr	1220(ra) # 80000c8a <release>
}
    800027ce:	60e2                	ld	ra,24(sp)
    800027d0:	6442                	ld	s0,16(sp)
    800027d2:	64a2                	ld	s1,8(sp)
    800027d4:	6105                	addi	sp,sp,32
    800027d6:	8082                	ret

00000000800027d8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027d8:	1101                	addi	sp,sp,-32
    800027da:	ec06                	sd	ra,24(sp)
    800027dc:	e822                	sd	s0,16(sp)
    800027de:	e426                	sd	s1,8(sp)
    800027e0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027e6:	00074d63          	bltz	a4,80002800 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ea:	57fd                	li	a5,-1
    800027ec:	17fe                	slli	a5,a5,0x3f
    800027ee:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f2:	06f70363          	beq	a4,a5,80002858 <devintr+0x80>
  }
}
    800027f6:	60e2                	ld	ra,24(sp)
    800027f8:	6442                	ld	s0,16(sp)
    800027fa:	64a2                	ld	s1,8(sp)
    800027fc:	6105                	addi	sp,sp,32
    800027fe:	8082                	ret
     (scause & 0xff) == 9){
    80002800:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002804:	46a5                	li	a3,9
    80002806:	fed792e3          	bne	a5,a3,800027ea <devintr+0x12>
    int irq = plic_claim();
    8000280a:	00003097          	auipc	ra,0x3
    8000280e:	61e080e7          	jalr	1566(ra) # 80005e28 <plic_claim>
    80002812:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002814:	47a9                	li	a5,10
    80002816:	02f50763          	beq	a0,a5,80002844 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000281a:	4785                	li	a5,1
    8000281c:	02f50963          	beq	a0,a5,8000284e <devintr+0x76>
    return 1;
    80002820:	4505                	li	a0,1
    } else if(irq){
    80002822:	d8f1                	beqz	s1,800027f6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002824:	85a6                	mv	a1,s1
    80002826:	00006517          	auipc	a0,0x6
    8000282a:	afa50513          	addi	a0,a0,-1286 # 80008320 <states.0+0x38>
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	d5a080e7          	jalr	-678(ra) # 80000588 <printf>
      plic_complete(irq);
    80002836:	8526                	mv	a0,s1
    80002838:	00003097          	auipc	ra,0x3
    8000283c:	614080e7          	jalr	1556(ra) # 80005e4c <plic_complete>
    return 1;
    80002840:	4505                	li	a0,1
    80002842:	bf55                	j	800027f6 <devintr+0x1e>
      uartintr();
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	156080e7          	jalr	342(ra) # 8000099a <uartintr>
    8000284c:	b7ed                	j	80002836 <devintr+0x5e>
      virtio_disk_intr();
    8000284e:	00004097          	auipc	ra,0x4
    80002852:	aca080e7          	jalr	-1334(ra) # 80006318 <virtio_disk_intr>
    80002856:	b7c5                	j	80002836 <devintr+0x5e>
    if(cpuid() == 0){
    80002858:	fffff097          	auipc	ra,0xfffff
    8000285c:	15e080e7          	jalr	350(ra) # 800019b6 <cpuid>
    80002860:	c901                	beqz	a0,80002870 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002862:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002866:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002868:	14479073          	csrw	sip,a5
    return 2;
    8000286c:	4509                	li	a0,2
    8000286e:	b761                	j	800027f6 <devintr+0x1e>
      clockintr();
    80002870:	00000097          	auipc	ra,0x0
    80002874:	f22080e7          	jalr	-222(ra) # 80002792 <clockintr>
    80002878:	b7ed                	j	80002862 <devintr+0x8a>

000000008000287a <usertrap>:
{
    8000287a:	1101                	addi	sp,sp,-32
    8000287c:	ec06                	sd	ra,24(sp)
    8000287e:	e822                	sd	s0,16(sp)
    80002880:	e426                	sd	s1,8(sp)
    80002882:	e04a                	sd	s2,0(sp)
    80002884:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002886:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000288a:	1007f793          	andi	a5,a5,256
    8000288e:	e3b1                	bnez	a5,800028d2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002890:	00003797          	auipc	a5,0x3
    80002894:	49078793          	addi	a5,a5,1168 # 80005d20 <kernelvec>
    80002898:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	146080e7          	jalr	326(ra) # 800019e2 <myproc>
    800028a4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028a6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a8:	14102773          	csrr	a4,sepc
    800028ac:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ae:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028b2:	47a1                	li	a5,8
    800028b4:	02f70763          	beq	a4,a5,800028e2 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028b8:	00000097          	auipc	ra,0x0
    800028bc:	f20080e7          	jalr	-224(ra) # 800027d8 <devintr>
    800028c0:	892a                	mv	s2,a0
    800028c2:	c151                	beqz	a0,80002946 <usertrap+0xcc>
  if(killed(p))
    800028c4:	8526                	mv	a0,s1
    800028c6:	00000097          	auipc	ra,0x0
    800028ca:	ad2080e7          	jalr	-1326(ra) # 80002398 <killed>
    800028ce:	c929                	beqz	a0,80002920 <usertrap+0xa6>
    800028d0:	a099                	j	80002916 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028d2:	00006517          	auipc	a0,0x6
    800028d6:	a6e50513          	addi	a0,a0,-1426 # 80008340 <states.0+0x58>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	c64080e7          	jalr	-924(ra) # 8000053e <panic>
    if(killed(p))
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	ab6080e7          	jalr	-1354(ra) # 80002398 <killed>
    800028ea:	e921                	bnez	a0,8000293a <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028ec:	6cb8                	ld	a4,88(s1)
    800028ee:	6f1c                	ld	a5,24(a4)
    800028f0:	0791                	addi	a5,a5,4
    800028f2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028f8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028fc:	10079073          	csrw	sstatus,a5
    syscall();
    80002900:	00000097          	auipc	ra,0x0
    80002904:	2d4080e7          	jalr	724(ra) # 80002bd4 <syscall>
  if(killed(p))
    80002908:	8526                	mv	a0,s1
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	a8e080e7          	jalr	-1394(ra) # 80002398 <killed>
    80002912:	c911                	beqz	a0,80002926 <usertrap+0xac>
    80002914:	4901                	li	s2,0
    exit(-1);
    80002916:	557d                	li	a0,-1
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	90c080e7          	jalr	-1780(ra) # 80002224 <exit>
  if(which_dev == 2)
    80002920:	4789                	li	a5,2
    80002922:	04f90f63          	beq	s2,a5,80002980 <usertrap+0x106>
  usertrapret();
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	dd6080e7          	jalr	-554(ra) # 800026fc <usertrapret>
}
    8000292e:	60e2                	ld	ra,24(sp)
    80002930:	6442                	ld	s0,16(sp)
    80002932:	64a2                	ld	s1,8(sp)
    80002934:	6902                	ld	s2,0(sp)
    80002936:	6105                	addi	sp,sp,32
    80002938:	8082                	ret
      exit(-1);
    8000293a:	557d                	li	a0,-1
    8000293c:	00000097          	auipc	ra,0x0
    80002940:	8e8080e7          	jalr	-1816(ra) # 80002224 <exit>
    80002944:	b765                	j	800028ec <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002946:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000294a:	5890                	lw	a2,48(s1)
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	a1450513          	addi	a0,a0,-1516 # 80008360 <states.0+0x78>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c34080e7          	jalr	-972(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002960:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002964:	00006517          	auipc	a0,0x6
    80002968:	a2c50513          	addi	a0,a0,-1492 # 80008390 <states.0+0xa8>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c1c080e7          	jalr	-996(ra) # 80000588 <printf>
    setkilled(p);
    80002974:	8526                	mv	a0,s1
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	9f6080e7          	jalr	-1546(ra) # 8000236c <setkilled>
    8000297e:	b769                	j	80002908 <usertrap+0x8e>
    yield();
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	734080e7          	jalr	1844(ra) # 800020b4 <yield>
    80002988:	bf79                	j	80002926 <usertrap+0xac>

000000008000298a <kerneltrap>:
{
    8000298a:	7179                	addi	sp,sp,-48
    8000298c:	f406                	sd	ra,40(sp)
    8000298e:	f022                	sd	s0,32(sp)
    80002990:	ec26                	sd	s1,24(sp)
    80002992:	e84a                	sd	s2,16(sp)
    80002994:	e44e                	sd	s3,8(sp)
    80002996:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002998:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000299c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a4:	1004f793          	andi	a5,s1,256
    800029a8:	cb85                	beqz	a5,800029d8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029aa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ae:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029b0:	ef85                	bnez	a5,800029e8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029b2:	00000097          	auipc	ra,0x0
    800029b6:	e26080e7          	jalr	-474(ra) # 800027d8 <devintr>
    800029ba:	cd1d                	beqz	a0,800029f8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029bc:	4789                	li	a5,2
    800029be:	06f50a63          	beq	a0,a5,80002a32 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029c2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c6:	10049073          	csrw	sstatus,s1
}
    800029ca:	70a2                	ld	ra,40(sp)
    800029cc:	7402                	ld	s0,32(sp)
    800029ce:	64e2                	ld	s1,24(sp)
    800029d0:	6942                	ld	s2,16(sp)
    800029d2:	69a2                	ld	s3,8(sp)
    800029d4:	6145                	addi	sp,sp,48
    800029d6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	9d850513          	addi	a0,a0,-1576 # 800083b0 <states.0+0xc8>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029e8:	00006517          	auipc	a0,0x6
    800029ec:	9f050513          	addi	a0,a0,-1552 # 800083d8 <states.0+0xf0>
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029f8:	85ce                	mv	a1,s3
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	9fe50513          	addi	a0,a0,-1538 # 800083f8 <states.0+0x110>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b86080e7          	jalr	-1146(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	9f650513          	addi	a0,a0,-1546 # 80008408 <states.0+0x120>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b6e080e7          	jalr	-1170(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	9fe50513          	addi	a0,a0,-1538 # 80008420 <states.0+0x138>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b14080e7          	jalr	-1260(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	fb0080e7          	jalr	-80(ra) # 800019e2 <myproc>
    80002a3a:	d541                	beqz	a0,800029c2 <kerneltrap+0x38>
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	fa6080e7          	jalr	-90(ra) # 800019e2 <myproc>
    80002a44:	4d18                	lw	a4,24(a0)
    80002a46:	4791                	li	a5,4
    80002a48:	f6f71de3          	bne	a4,a5,800029c2 <kerneltrap+0x38>
    yield();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	668080e7          	jalr	1640(ra) # 800020b4 <yield>
    80002a54:	b7bd                	j	800029c2 <kerneltrap+0x38>

0000000080002a56 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	1000                	addi	s0,sp,32
    80002a60:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	f80080e7          	jalr	-128(ra) # 800019e2 <myproc>
  switch (n) {
    80002a6a:	4795                	li	a5,5
    80002a6c:	0497e163          	bltu	a5,s1,80002aae <argraw+0x58>
    80002a70:	048a                	slli	s1,s1,0x2
    80002a72:	00006717          	auipc	a4,0x6
    80002a76:	9e670713          	addi	a4,a4,-1562 # 80008458 <states.0+0x170>
    80002a7a:	94ba                	add	s1,s1,a4
    80002a7c:	409c                	lw	a5,0(s1)
    80002a7e:	97ba                	add	a5,a5,a4
    80002a80:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a82:	6d3c                	ld	a5,88(a0)
    80002a84:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a86:	60e2                	ld	ra,24(sp)
    80002a88:	6442                	ld	s0,16(sp)
    80002a8a:	64a2                	ld	s1,8(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    return p->trapframe->a1;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	7fa8                	ld	a0,120(a5)
    80002a94:	bfcd                	j	80002a86 <argraw+0x30>
    return p->trapframe->a2;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	63c8                	ld	a0,128(a5)
    80002a9a:	b7f5                	j	80002a86 <argraw+0x30>
    return p->trapframe->a3;
    80002a9c:	6d3c                	ld	a5,88(a0)
    80002a9e:	67c8                	ld	a0,136(a5)
    80002aa0:	b7dd                	j	80002a86 <argraw+0x30>
    return p->trapframe->a4;
    80002aa2:	6d3c                	ld	a5,88(a0)
    80002aa4:	6bc8                	ld	a0,144(a5)
    80002aa6:	b7c5                	j	80002a86 <argraw+0x30>
    return p->trapframe->a5;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	6fc8                	ld	a0,152(a5)
    80002aac:	bfe9                	j	80002a86 <argraw+0x30>
  panic("argraw");
    80002aae:	00006517          	auipc	a0,0x6
    80002ab2:	98250513          	addi	a0,a0,-1662 # 80008430 <states.0+0x148>
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>

0000000080002abe <fetchaddr>:
{
    80002abe:	1101                	addi	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	e04a                	sd	s2,0(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84aa                	mv	s1,a0
    80002acc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	f14080e7          	jalr	-236(ra) # 800019e2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ad6:	653c                	ld	a5,72(a0)
    80002ad8:	02f4f863          	bgeu	s1,a5,80002b08 <fetchaddr+0x4a>
    80002adc:	00848713          	addi	a4,s1,8
    80002ae0:	02e7e663          	bltu	a5,a4,80002b0c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae4:	46a1                	li	a3,8
    80002ae6:	8626                	mv	a2,s1
    80002ae8:	85ca                	mv	a1,s2
    80002aea:	6928                	ld	a0,80(a0)
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	c3e080e7          	jalr	-962(ra) # 8000172a <copyin>
    80002af4:	00a03533          	snez	a0,a0
    80002af8:	40a00533          	neg	a0,a0
}
    80002afc:	60e2                	ld	ra,24(sp)
    80002afe:	6442                	ld	s0,16(sp)
    80002b00:	64a2                	ld	s1,8(sp)
    80002b02:	6902                	ld	s2,0(sp)
    80002b04:	6105                	addi	sp,sp,32
    80002b06:	8082                	ret
    return -1;
    80002b08:	557d                	li	a0,-1
    80002b0a:	bfcd                	j	80002afc <fetchaddr+0x3e>
    80002b0c:	557d                	li	a0,-1
    80002b0e:	b7fd                	j	80002afc <fetchaddr+0x3e>

0000000080002b10 <fetchstr>:
{
    80002b10:	7179                	addi	sp,sp,-48
    80002b12:	f406                	sd	ra,40(sp)
    80002b14:	f022                	sd	s0,32(sp)
    80002b16:	ec26                	sd	s1,24(sp)
    80002b18:	e84a                	sd	s2,16(sp)
    80002b1a:	e44e                	sd	s3,8(sp)
    80002b1c:	1800                	addi	s0,sp,48
    80002b1e:	892a                	mv	s2,a0
    80002b20:	84ae                	mv	s1,a1
    80002b22:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	ebe080e7          	jalr	-322(ra) # 800019e2 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b2c:	86ce                	mv	a3,s3
    80002b2e:	864a                	mv	a2,s2
    80002b30:	85a6                	mv	a1,s1
    80002b32:	6928                	ld	a0,80(a0)
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	c84080e7          	jalr	-892(ra) # 800017b8 <copyinstr>
    80002b3c:	00054e63          	bltz	a0,80002b58 <fetchstr+0x48>
  return strlen(buf);
    80002b40:	8526                	mv	a0,s1
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	30c080e7          	jalr	780(ra) # 80000e4e <strlen>
}
    80002b4a:	70a2                	ld	ra,40(sp)
    80002b4c:	7402                	ld	s0,32(sp)
    80002b4e:	64e2                	ld	s1,24(sp)
    80002b50:	6942                	ld	s2,16(sp)
    80002b52:	69a2                	ld	s3,8(sp)
    80002b54:	6145                	addi	sp,sp,48
    80002b56:	8082                	ret
    return -1;
    80002b58:	557d                	li	a0,-1
    80002b5a:	bfc5                	j	80002b4a <fetchstr+0x3a>

0000000080002b5c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
    80002b66:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	eee080e7          	jalr	-274(ra) # 80002a56 <argraw>
    80002b70:	c088                	sw	a0,0(s1)
}
    80002b72:	60e2                	ld	ra,24(sp)
    80002b74:	6442                	ld	s0,16(sp)
    80002b76:	64a2                	ld	s1,8(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret

0000000080002b7c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b7c:	1101                	addi	sp,sp,-32
    80002b7e:	ec06                	sd	ra,24(sp)
    80002b80:	e822                	sd	s0,16(sp)
    80002b82:	e426                	sd	s1,8(sp)
    80002b84:	1000                	addi	s0,sp,32
    80002b86:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	ece080e7          	jalr	-306(ra) # 80002a56 <argraw>
    80002b90:	e088                	sd	a0,0(s1)
}
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret

0000000080002b9c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b9c:	7179                	addi	sp,sp,-48
    80002b9e:	f406                	sd	ra,40(sp)
    80002ba0:	f022                	sd	s0,32(sp)
    80002ba2:	ec26                	sd	s1,24(sp)
    80002ba4:	e84a                	sd	s2,16(sp)
    80002ba6:	1800                	addi	s0,sp,48
    80002ba8:	84ae                	mv	s1,a1
    80002baa:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bac:	fd840593          	addi	a1,s0,-40
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	fcc080e7          	jalr	-52(ra) # 80002b7c <argaddr>
  return fetchstr(addr, buf, max);
    80002bb8:	864a                	mv	a2,s2
    80002bba:	85a6                	mv	a1,s1
    80002bbc:	fd843503          	ld	a0,-40(s0)
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	f50080e7          	jalr	-176(ra) # 80002b10 <fetchstr>
}
    80002bc8:	70a2                	ld	ra,40(sp)
    80002bca:	7402                	ld	s0,32(sp)
    80002bcc:	64e2                	ld	s1,24(sp)
    80002bce:	6942                	ld	s2,16(sp)
    80002bd0:	6145                	addi	sp,sp,48
    80002bd2:	8082                	ret

0000000080002bd4 <syscall>:
[SYS_map_display]    sys_map_display,
};

void
syscall(void)
{
    80002bd4:	1101                	addi	sp,sp,-32
    80002bd6:	ec06                	sd	ra,24(sp)
    80002bd8:	e822                	sd	s0,16(sp)
    80002bda:	e426                	sd	s1,8(sp)
    80002bdc:	e04a                	sd	s2,0(sp)
    80002bde:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	e02080e7          	jalr	-510(ra) # 800019e2 <myproc>
    80002be8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bea:	05853903          	ld	s2,88(a0)
    80002bee:	0a893783          	ld	a5,168(s2)
    80002bf2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bf6:	37fd                	addiw	a5,a5,-1
    80002bf8:	4759                	li	a4,22
    80002bfa:	00f76f63          	bltu	a4,a5,80002c18 <syscall+0x44>
    80002bfe:	00369713          	slli	a4,a3,0x3
    80002c02:	00006797          	auipc	a5,0x6
    80002c06:	86e78793          	addi	a5,a5,-1938 # 80008470 <syscalls>
    80002c0a:	97ba                	add	a5,a5,a4
    80002c0c:	639c                	ld	a5,0(a5)
    80002c0e:	c789                	beqz	a5,80002c18 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c10:	9782                	jalr	a5
    80002c12:	06a93823          	sd	a0,112(s2)
    80002c16:	a839                	j	80002c34 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c18:	15848613          	addi	a2,s1,344
    80002c1c:	588c                	lw	a1,48(s1)
    80002c1e:	00006517          	auipc	a0,0x6
    80002c22:	81a50513          	addi	a0,a0,-2022 # 80008438 <states.0+0x150>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	962080e7          	jalr	-1694(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c2e:	6cbc                	ld	a5,88(s1)
    80002c30:	577d                	li	a4,-1
    80002c32:	fbb8                	sd	a4,112(a5)
  }
}
    80002c34:	60e2                	ld	ra,24(sp)
    80002c36:	6442                	ld	s0,16(sp)
    80002c38:	64a2                	ld	s1,8(sp)
    80002c3a:	6902                	ld	s2,0(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <sys_exit>:
// Used by sys_exit to unmap before the page table is freed.
static uint64 fb_va_by_pid[NPROC];

uint64
sys_exit(void)
{
    80002c40:	7179                	addi	sp,sp,-48
    80002c42:	f406                	sd	ra,40(sp)
    80002c44:	f022                	sd	s0,32(sp)
    80002c46:	ec26                	sd	s1,24(sp)
    80002c48:	1800                	addi	s0,sp,48
  int n;
  argint(0, &n);
    80002c4a:	fdc40593          	addi	a1,s0,-36
    80002c4e:	4501                	li	a0,0
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	f0c080e7          	jalr	-244(ra) # 80002b5c <argint>

  // Unmap the GPU framebuffer before the page table is freed so that
  // freewalk() does not panic on the dangling leaf PTEs.  do_free=0
  // because the pages are kernel-owned (fb[] in virtio_gpu.c).
  struct proc *p = myproc();
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	d8a080e7          	jalr	-630(ra) # 800019e2 <myproc>
  int idx = p->pid % NPROC;
    80002c60:	591c                	lw	a5,48(a0)
    80002c62:	41f7d49b          	sraiw	s1,a5,0x1f
    80002c66:	01a4d71b          	srliw	a4,s1,0x1a
    80002c6a:	00e784bb          	addw	s1,a5,a4
    80002c6e:	03f4f493          	andi	s1,s1,63
    80002c72:	9c99                	subw	s1,s1,a4
  if (fb_va_by_pid[idx] != 0) {
    80002c74:	00349713          	slli	a4,s1,0x3
    80002c78:	00014797          	auipc	a5,0x14
    80002c7c:	6a078793          	addi	a5,a5,1696 # 80017318 <fb_va_by_pid>
    80002c80:	97ba                	add	a5,a5,a4
    80002c82:	638c                	ld	a1,0(a5)
    80002c84:	ed89                	bnez	a1,80002c9e <sys_exit+0x5e>
    uvmunmap(p->pagetable, fb_va_by_pid[idx], GPU_FB_PAGES, 0);
    fb_va_by_pid[idx] = 0;
  }

  exit(n);
    80002c86:	fdc42503          	lw	a0,-36(s0)
    80002c8a:	fffff097          	auipc	ra,0xfffff
    80002c8e:	59a080e7          	jalr	1434(ra) # 80002224 <exit>
  return 0;  // not reached
}
    80002c92:	4501                	li	a0,0
    80002c94:	70a2                	ld	ra,40(sp)
    80002c96:	7402                	ld	s0,32(sp)
    80002c98:	64e2                	ld	s1,24(sp)
    80002c9a:	6145                	addi	sp,sp,48
    80002c9c:	8082                	ret
    uvmunmap(p->pagetable, fb_va_by_pid[idx], GPU_FB_PAGES, 0);
    80002c9e:	4681                	li	a3,0
    80002ca0:	12c00613          	li	a2,300
    80002ca4:	6928                	ld	a0,80(a0)
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	5f4080e7          	jalr	1524(ra) # 8000129a <uvmunmap>
    fb_va_by_pid[idx] = 0;
    80002cae:	048e                	slli	s1,s1,0x3
    80002cb0:	00014797          	auipc	a5,0x14
    80002cb4:	66878793          	addi	a5,a5,1640 # 80017318 <fb_va_by_pid>
    80002cb8:	94be                	add	s1,s1,a5
    80002cba:	0004b023          	sd	zero,0(s1)
    80002cbe:	b7e1                	j	80002c86 <sys_exit+0x46>

0000000080002cc0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc0:	1141                	addi	sp,sp,-16
    80002cc2:	e406                	sd	ra,8(sp)
    80002cc4:	e022                	sd	s0,0(sp)
    80002cc6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	d1a080e7          	jalr	-742(ra) # 800019e2 <myproc>
}
    80002cd0:	5908                	lw	a0,48(a0)
    80002cd2:	60a2                	ld	ra,8(sp)
    80002cd4:	6402                	ld	s0,0(sp)
    80002cd6:	0141                	addi	sp,sp,16
    80002cd8:	8082                	ret

0000000080002cda <sys_fork>:

uint64
sys_fork(void)
{
    80002cda:	1141                	addi	sp,sp,-16
    80002cdc:	e406                	sd	ra,8(sp)
    80002cde:	e022                	sd	s0,0(sp)
    80002ce0:	0800                	addi	s0,sp,16
  return fork();
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	11c080e7          	jalr	284(ra) # 80001dfe <fork>
}
    80002cea:	60a2                	ld	ra,8(sp)
    80002cec:	6402                	ld	s0,0(sp)
    80002cee:	0141                	addi	sp,sp,16
    80002cf0:	8082                	ret

0000000080002cf2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf2:	1101                	addi	sp,sp,-32
    80002cf4:	ec06                	sd	ra,24(sp)
    80002cf6:	e822                	sd	s0,16(sp)
    80002cf8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002cfa:	fe840593          	addi	a1,s0,-24
    80002cfe:	4501                	li	a0,0
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	e7c080e7          	jalr	-388(ra) # 80002b7c <argaddr>
  return wait(p);
    80002d08:	fe843503          	ld	a0,-24(s0)
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	6be080e7          	jalr	1726(ra) # 800023ca <wait>
}
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret

0000000080002d1c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d1c:	7179                	addi	sp,sp,-48
    80002d1e:	f406                	sd	ra,40(sp)
    80002d20:	f022                	sd	s0,32(sp)
    80002d22:	ec26                	sd	s1,24(sp)
    80002d24:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d26:	fdc40593          	addi	a1,s0,-36
    80002d2a:	4501                	li	a0,0
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	e30080e7          	jalr	-464(ra) # 80002b5c <argint>
  addr = myproc()->sz;
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	cae080e7          	jalr	-850(ra) # 800019e2 <myproc>
    80002d3c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d3e:	fdc42503          	lw	a0,-36(s0)
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	060080e7          	jalr	96(ra) # 80001da2 <growproc>
    80002d4a:	00054863          	bltz	a0,80002d5a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d4e:	8526                	mv	a0,s1
    80002d50:	70a2                	ld	ra,40(sp)
    80002d52:	7402                	ld	s0,32(sp)
    80002d54:	64e2                	ld	s1,24(sp)
    80002d56:	6145                	addi	sp,sp,48
    80002d58:	8082                	ret
    return -1;
    80002d5a:	54fd                	li	s1,-1
    80002d5c:	bfcd                	j	80002d4e <sys_sbrk+0x32>

0000000080002d5e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d5e:	7139                	addi	sp,sp,-64
    80002d60:	fc06                	sd	ra,56(sp)
    80002d62:	f822                	sd	s0,48(sp)
    80002d64:	f426                	sd	s1,40(sp)
    80002d66:	f04a                	sd	s2,32(sp)
    80002d68:	ec4e                	sd	s3,24(sp)
    80002d6a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d6c:	fcc40593          	addi	a1,s0,-52
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	dea080e7          	jalr	-534(ra) # 80002b5c <argint>
  acquire(&tickslock);
    80002d7a:	00014517          	auipc	a0,0x14
    80002d7e:	58650513          	addi	a0,a0,1414 # 80017300 <tickslock>
    80002d82:	ffffe097          	auipc	ra,0xffffe
    80002d86:	e54080e7          	jalr	-428(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d8a:	00006917          	auipc	s2,0x6
    80002d8e:	4d692903          	lw	s2,1238(s2) # 80009260 <ticks>
  while(ticks - ticks0 < n){
    80002d92:	fcc42783          	lw	a5,-52(s0)
    80002d96:	cf9d                	beqz	a5,80002dd4 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d98:	00014997          	auipc	s3,0x14
    80002d9c:	56898993          	addi	s3,s3,1384 # 80017300 <tickslock>
    80002da0:	00006497          	auipc	s1,0x6
    80002da4:	4c048493          	addi	s1,s1,1216 # 80009260 <ticks>
    if(killed(myproc())){
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	c3a080e7          	jalr	-966(ra) # 800019e2 <myproc>
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	5e8080e7          	jalr	1512(ra) # 80002398 <killed>
    80002db8:	ed15                	bnez	a0,80002df4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dba:	85ce                	mv	a1,s3
    80002dbc:	8526                	mv	a0,s1
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	332080e7          	jalr	818(ra) # 800020f0 <sleep>
  while(ticks - ticks0 < n){
    80002dc6:	409c                	lw	a5,0(s1)
    80002dc8:	412787bb          	subw	a5,a5,s2
    80002dcc:	fcc42703          	lw	a4,-52(s0)
    80002dd0:	fce7ece3          	bltu	a5,a4,80002da8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dd4:	00014517          	auipc	a0,0x14
    80002dd8:	52c50513          	addi	a0,a0,1324 # 80017300 <tickslock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	eae080e7          	jalr	-338(ra) # 80000c8a <release>
  return 0;
    80002de4:	4501                	li	a0,0
}
    80002de6:	70e2                	ld	ra,56(sp)
    80002de8:	7442                	ld	s0,48(sp)
    80002dea:	74a2                	ld	s1,40(sp)
    80002dec:	7902                	ld	s2,32(sp)
    80002dee:	69e2                	ld	s3,24(sp)
    80002df0:	6121                	addi	sp,sp,64
    80002df2:	8082                	ret
      release(&tickslock);
    80002df4:	00014517          	auipc	a0,0x14
    80002df8:	50c50513          	addi	a0,a0,1292 # 80017300 <tickslock>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	e8e080e7          	jalr	-370(ra) # 80000c8a <release>
      return -1;
    80002e04:	557d                	li	a0,-1
    80002e06:	b7c5                	j	80002de6 <sys_sleep+0x88>

0000000080002e08 <sys_kill>:

uint64
sys_kill(void)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e10:	fec40593          	addi	a1,s0,-20
    80002e14:	4501                	li	a0,0
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	d46080e7          	jalr	-698(ra) # 80002b5c <argint>
  return kill(pid);
    80002e1e:	fec42503          	lw	a0,-20(s0)
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	4d8080e7          	jalr	1240(ra) # 800022fa <kill>
}
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	6105                	addi	sp,sp,32
    80002e30:	8082                	ret

0000000080002e32 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	e426                	sd	s1,8(sp)
    80002e3a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e3c:	00014517          	auipc	a0,0x14
    80002e40:	4c450513          	addi	a0,a0,1220 # 80017300 <tickslock>
    80002e44:	ffffe097          	auipc	ra,0xffffe
    80002e48:	d92080e7          	jalr	-622(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e4c:	00006497          	auipc	s1,0x6
    80002e50:	4144a483          	lw	s1,1044(s1) # 80009260 <ticks>
  release(&tickslock);
    80002e54:	00014517          	auipc	a0,0x14
    80002e58:	4ac50513          	addi	a0,a0,1196 # 80017300 <tickslock>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
  return xticks;
}
    80002e64:	02049513          	slli	a0,s1,0x20
    80002e68:	9101                	srli	a0,a0,0x20
    80002e6a:	60e2                	ld	ra,24(sp)
    80002e6c:	6442                	ld	s0,16(sp)
    80002e6e:	64a2                	ld	s1,8(sp)
    80002e70:	6105                	addi	sp,sp,32
    80002e72:	8082                	ret

0000000080002e74 <sys_flip_display>:
// calling process's address space.
//
// TODO: Students implement this syscall.
uint64
sys_flip_display(void)
{
    80002e74:	1141                	addi	sp,sp,-16
    80002e76:	e422                	sd	s0,8(sp)
    80002e78:	0800                	addi	s0,sp,16
  return -1;
}
    80002e7a:	557d                	li	a0,-1
    80002e7c:	6422                	ld	s0,8(sp)
    80002e7e:	0141                	addi	sp,sp,16
    80002e80:	8082                	ret

0000000080002e82 <sys_map_display>:
//   Pass 0 to let the kernel auto-select the next available VA above p->sz.
//
// Returns the mapped virtual address on success, (uint64)-1 on failure.
uint64
sys_map_display(void)
{
    80002e82:	715d                	addi	sp,sp,-80
    80002e84:	e486                	sd	ra,72(sp)
    80002e86:	e0a2                	sd	s0,64(sp)
    80002e88:	fc26                	sd	s1,56(sp)
    80002e8a:	f84a                	sd	s2,48(sp)
    80002e8c:	f44e                	sd	s3,40(sp)
    80002e8e:	f052                	sd	s4,32(sp)
    80002e90:	ec56                	sd	s5,24(sp)
    80002e92:	0880                	addi	s0,sp,80
  uint64 addr;
  struct proc *p = myproc();
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	b4e080e7          	jalr	-1202(ra) # 800019e2 <myproc>
    80002e9c:	892a                	mv	s2,a0

  argaddr(0, &addr);
    80002e9e:	fb840593          	addi	a1,s0,-72
    80002ea2:	4501                	li	a0,0
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	cd8080e7          	jalr	-808(ra) # 80002b7c <argaddr>

  // User-supplied address must be page-aligned.
  if (addr != 0 && addr % PGSIZE != 0)
    80002eac:	fb843783          	ld	a5,-72(s0)
    80002eb0:	c781                	beqz	a5,80002eb8 <sys_map_display+0x36>
    80002eb2:	17d2                	slli	a5,a5,0x34
    return -1;
    80002eb4:	557d                	li	a0,-1
  if (addr != 0 && addr % PGSIZE != 0)
    80002eb6:	efb9                	bnez	a5,80002f14 <sys_map_display+0x92>

  void **fb = virtio_gpu_fb_pages();
    80002eb8:	00004097          	auipc	ra,0x4
    80002ebc:	ba0080e7          	jalr	-1120(ra) # 80006a58 <virtio_gpu_fb_pages>
    80002ec0:	89aa                	mv	s3,a0
  uint64 fb_size = (uint64)GPU_FB_PAGES * PGSIZE;

  if (addr == 0) {
    80002ec2:	fb843783          	ld	a5,-72(s0)
    80002ec6:	eb91                	bnez	a5,80002eda <sys_map_display+0x58>
    // Auto-select: first page-aligned VA above the heap.
    addr = PGROUNDUP(p->sz);
    80002ec8:	04893783          	ld	a5,72(s2)
    80002ecc:	6705                	lui	a4,0x1
    80002ece:	177d                	addi	a4,a4,-1
    80002ed0:	97ba                	add	a5,a5,a4
    80002ed2:	777d                	lui	a4,0xfffff
    80002ed4:	8ff9                	and	a5,a5,a4
    80002ed6:	faf43c23          	sd	a5,-72(s0)
  }

  // Verify [addr, addr+fb_size) does not overlap any existing mapping.
  for (uint64 va = addr; va < addr + fb_size; va += PGSIZE) {
    80002eda:	fb843483          	ld	s1,-72(s0)
    80002ede:	ffed47b7          	lui	a5,0xffed4
    80002ee2:	04f4f263          	bgeu	s1,a5,80002f26 <sys_map_display+0xa4>
    80002ee6:	6a85                	lui	s5,0x1
    80002ee8:	0012ca37          	lui	s4,0x12c
    80002eec:	a039                	j	80002efa <sys_map_display+0x78>
    80002eee:	94d6                	add	s1,s1,s5
    80002ef0:	fb843783          	ld	a5,-72(s0)
    80002ef4:	97d2                	add	a5,a5,s4
    80002ef6:	02f4f863          	bgeu	s1,a5,80002f26 <sys_map_display+0xa4>
    pte_t *pte = walk(p->pagetable, va, 0);
    80002efa:	4601                	li	a2,0
    80002efc:	85a6                	mv	a1,s1
    80002efe:	05093503          	ld	a0,80(s2)
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	0d4080e7          	jalr	212(ra) # 80000fd6 <walk>
    if (pte && (*pte & PTE_V))
    80002f0a:	d175                	beqz	a0,80002eee <sys_map_display+0x6c>
    80002f0c:	611c                	ld	a5,0(a0)
    80002f0e:	8b85                	andi	a5,a5,1
    80002f10:	dff9                	beqz	a5,80002eee <sys_map_display+0x6c>
      return -1;
    80002f12:	557d                	li	a0,-1

  // Record the mapping so sys_exit can remove it before freewalk runs.
  fb_va_by_pid[p->pid % NPROC] = addr;

  return addr;
}
    80002f14:	60a6                	ld	ra,72(sp)
    80002f16:	6406                	ld	s0,64(sp)
    80002f18:	74e2                	ld	s1,56(sp)
    80002f1a:	7942                	ld	s2,48(sp)
    80002f1c:	79a2                	ld	s3,40(sp)
    80002f1e:	7a02                	ld	s4,32(sp)
    80002f20:	6ae2                	ld	s5,24(sp)
    80002f22:	6161                	addi	sp,sp,80
    80002f24:	8082                	ret
{
    80002f26:	4481                	li	s1,0
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    80002f28:	12c00a93          	li	s5,300
    80002f2c:	00048a1b          	sext.w	s4,s1
    if (mappages(p->pagetable, addr + (uint64)i * PGSIZE, PGSIZE,
    80002f30:	00c49793          	slli	a5,s1,0xc
    80002f34:	4759                	li	a4,22
    80002f36:	0009b683          	ld	a3,0(s3)
    80002f3a:	6605                	lui	a2,0x1
    80002f3c:	fb843583          	ld	a1,-72(s0)
    80002f40:	95be                	add	a1,a1,a5
    80002f42:	05093503          	ld	a0,80(s2)
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	178080e7          	jalr	376(ra) # 800010be <mappages>
    80002f4e:	e90d                	bnez	a0,80002f80 <sys_map_display+0xfe>
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    80002f50:	0485                	addi	s1,s1,1
    80002f52:	09a1                	addi	s3,s3,8
    80002f54:	fd549ce3          	bne	s1,s5,80002f2c <sys_map_display+0xaa>
  fb_va_by_pid[p->pid % NPROC] = addr;
    80002f58:	fb843503          	ld	a0,-72(s0)
    80002f5c:	03092783          	lw	a5,48(s2)
    80002f60:	41f7d71b          	sraiw	a4,a5,0x1f
    80002f64:	01a7571b          	srliw	a4,a4,0x1a
    80002f68:	9fb9                	addw	a5,a5,a4
    80002f6a:	03f7f793          	andi	a5,a5,63
    80002f6e:	9f99                	subw	a5,a5,a4
    80002f70:	078e                	slli	a5,a5,0x3
    80002f72:	00014717          	auipc	a4,0x14
    80002f76:	3a670713          	addi	a4,a4,934 # 80017318 <fb_va_by_pid>
    80002f7a:	97ba                	add	a5,a5,a4
    80002f7c:	e388                	sd	a0,0(a5)
  return addr;
    80002f7e:	bf59                	j	80002f14 <sys_map_display+0x92>
      return -1;
    80002f80:	557d                	li	a0,-1
      if (i > 0)
    80002f82:	f94059e3          	blez	s4,80002f14 <sys_map_display+0x92>
        uvmunmap(p->pagetable, addr, i, 0);
    80002f86:	4681                	li	a3,0
    80002f88:	8626                	mv	a2,s1
    80002f8a:	fb843583          	ld	a1,-72(s0)
    80002f8e:	05093503          	ld	a0,80(s2)
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	308080e7          	jalr	776(ra) # 8000129a <uvmunmap>
      return -1;
    80002f9a:	557d                	li	a0,-1
    80002f9c:	bfa5                	j	80002f14 <sys_map_display+0x92>

0000000080002f9e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f9e:	7179                	addi	sp,sp,-48
    80002fa0:	f406                	sd	ra,40(sp)
    80002fa2:	f022                	sd	s0,32(sp)
    80002fa4:	ec26                	sd	s1,24(sp)
    80002fa6:	e84a                	sd	s2,16(sp)
    80002fa8:	e44e                	sd	s3,8(sp)
    80002faa:	e052                	sd	s4,0(sp)
    80002fac:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fae:	00005597          	auipc	a1,0x5
    80002fb2:	58258593          	addi	a1,a1,1410 # 80008530 <syscalls+0xc0>
    80002fb6:	00014517          	auipc	a0,0x14
    80002fba:	56250513          	addi	a0,a0,1378 # 80017518 <bcache>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	b88080e7          	jalr	-1144(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fc6:	0001c797          	auipc	a5,0x1c
    80002fca:	55278793          	addi	a5,a5,1362 # 8001f518 <bcache+0x8000>
    80002fce:	0001c717          	auipc	a4,0x1c
    80002fd2:	7b270713          	addi	a4,a4,1970 # 8001f780 <bcache+0x8268>
    80002fd6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fda:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fde:	00014497          	auipc	s1,0x14
    80002fe2:	55248493          	addi	s1,s1,1362 # 80017530 <bcache+0x18>
    b->next = bcache.head.next;
    80002fe6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fe8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fea:	00005a17          	auipc	s4,0x5
    80002fee:	54ea0a13          	addi	s4,s4,1358 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002ff2:	2b893783          	ld	a5,696(s2)
    80002ff6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ff8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ffc:	85d2                	mv	a1,s4
    80002ffe:	01048513          	addi	a0,s1,16
    80003002:	00001097          	auipc	ra,0x1
    80003006:	4c4080e7          	jalr	1220(ra) # 800044c6 <initsleeplock>
    bcache.head.next->prev = b;
    8000300a:	2b893783          	ld	a5,696(s2)
    8000300e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003010:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003014:	45848493          	addi	s1,s1,1112
    80003018:	fd349de3          	bne	s1,s3,80002ff2 <binit+0x54>
  }
}
    8000301c:	70a2                	ld	ra,40(sp)
    8000301e:	7402                	ld	s0,32(sp)
    80003020:	64e2                	ld	s1,24(sp)
    80003022:	6942                	ld	s2,16(sp)
    80003024:	69a2                	ld	s3,8(sp)
    80003026:	6a02                	ld	s4,0(sp)
    80003028:	6145                	addi	sp,sp,48
    8000302a:	8082                	ret

000000008000302c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000302c:	7179                	addi	sp,sp,-48
    8000302e:	f406                	sd	ra,40(sp)
    80003030:	f022                	sd	s0,32(sp)
    80003032:	ec26                	sd	s1,24(sp)
    80003034:	e84a                	sd	s2,16(sp)
    80003036:	e44e                	sd	s3,8(sp)
    80003038:	1800                	addi	s0,sp,48
    8000303a:	892a                	mv	s2,a0
    8000303c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	4da50513          	addi	a0,a0,1242 # 80017518 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	b90080e7          	jalr	-1136(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000304e:	0001c497          	auipc	s1,0x1c
    80003052:	7824b483          	ld	s1,1922(s1) # 8001f7d0 <bcache+0x82b8>
    80003056:	0001c797          	auipc	a5,0x1c
    8000305a:	72a78793          	addi	a5,a5,1834 # 8001f780 <bcache+0x8268>
    8000305e:	02f48f63          	beq	s1,a5,8000309c <bread+0x70>
    80003062:	873e                	mv	a4,a5
    80003064:	a021                	j	8000306c <bread+0x40>
    80003066:	68a4                	ld	s1,80(s1)
    80003068:	02e48a63          	beq	s1,a4,8000309c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000306c:	449c                	lw	a5,8(s1)
    8000306e:	ff279ce3          	bne	a5,s2,80003066 <bread+0x3a>
    80003072:	44dc                	lw	a5,12(s1)
    80003074:	ff3799e3          	bne	a5,s3,80003066 <bread+0x3a>
      b->refcnt++;
    80003078:	40bc                	lw	a5,64(s1)
    8000307a:	2785                	addiw	a5,a5,1
    8000307c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000307e:	00014517          	auipc	a0,0x14
    80003082:	49a50513          	addi	a0,a0,1178 # 80017518 <bcache>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	c04080e7          	jalr	-1020(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000308e:	01048513          	addi	a0,s1,16
    80003092:	00001097          	auipc	ra,0x1
    80003096:	46e080e7          	jalr	1134(ra) # 80004500 <acquiresleep>
      return b;
    8000309a:	a8b9                	j	800030f8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000309c:	0001c497          	auipc	s1,0x1c
    800030a0:	72c4b483          	ld	s1,1836(s1) # 8001f7c8 <bcache+0x82b0>
    800030a4:	0001c797          	auipc	a5,0x1c
    800030a8:	6dc78793          	addi	a5,a5,1756 # 8001f780 <bcache+0x8268>
    800030ac:	00f48863          	beq	s1,a5,800030bc <bread+0x90>
    800030b0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	cf81                	beqz	a5,800030cc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030b6:	64a4                	ld	s1,72(s1)
    800030b8:	fee49de3          	bne	s1,a4,800030b2 <bread+0x86>
  panic("bget: no buffers");
    800030bc:	00005517          	auipc	a0,0x5
    800030c0:	48450513          	addi	a0,a0,1156 # 80008540 <syscalls+0xd0>
    800030c4:	ffffd097          	auipc	ra,0xffffd
    800030c8:	47a080e7          	jalr	1146(ra) # 8000053e <panic>
      b->dev = dev;
    800030cc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030d0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030d4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030d8:	4785                	li	a5,1
    800030da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030dc:	00014517          	auipc	a0,0x14
    800030e0:	43c50513          	addi	a0,a0,1084 # 80017518 <bcache>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030ec:	01048513          	addi	a0,s1,16
    800030f0:	00001097          	auipc	ra,0x1
    800030f4:	410080e7          	jalr	1040(ra) # 80004500 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030f8:	409c                	lw	a5,0(s1)
    800030fa:	cb89                	beqz	a5,8000310c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030fc:	8526                	mv	a0,s1
    800030fe:	70a2                	ld	ra,40(sp)
    80003100:	7402                	ld	s0,32(sp)
    80003102:	64e2                	ld	s1,24(sp)
    80003104:	6942                	ld	s2,16(sp)
    80003106:	69a2                	ld	s3,8(sp)
    80003108:	6145                	addi	sp,sp,48
    8000310a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000310c:	4581                	li	a1,0
    8000310e:	8526                	mv	a0,s1
    80003110:	00003097          	auipc	ra,0x3
    80003114:	fd4080e7          	jalr	-44(ra) # 800060e4 <virtio_disk_rw>
    b->valid = 1;
    80003118:	4785                	li	a5,1
    8000311a:	c09c                	sw	a5,0(s1)
  return b;
    8000311c:	b7c5                	j	800030fc <bread+0xd0>

000000008000311e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000312a:	0541                	addi	a0,a0,16
    8000312c:	00001097          	auipc	ra,0x1
    80003130:	46e080e7          	jalr	1134(ra) # 8000459a <holdingsleep>
    80003134:	cd01                	beqz	a0,8000314c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003136:	4585                	li	a1,1
    80003138:	8526                	mv	a0,s1
    8000313a:	00003097          	auipc	ra,0x3
    8000313e:	faa080e7          	jalr	-86(ra) # 800060e4 <virtio_disk_rw>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6105                	addi	sp,sp,32
    8000314a:	8082                	ret
    panic("bwrite");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	40c50513          	addi	a0,a0,1036 # 80008558 <syscalls+0xe8>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3ea080e7          	jalr	1002(ra) # 8000053e <panic>

000000008000315c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	e04a                	sd	s2,0(sp)
    80003166:	1000                	addi	s0,sp,32
    80003168:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000316a:	01050913          	addi	s2,a0,16
    8000316e:	854a                	mv	a0,s2
    80003170:	00001097          	auipc	ra,0x1
    80003174:	42a080e7          	jalr	1066(ra) # 8000459a <holdingsleep>
    80003178:	c92d                	beqz	a0,800031ea <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000317a:	854a                	mv	a0,s2
    8000317c:	00001097          	auipc	ra,0x1
    80003180:	3da080e7          	jalr	986(ra) # 80004556 <releasesleep>

  acquire(&bcache.lock);
    80003184:	00014517          	auipc	a0,0x14
    80003188:	39450513          	addi	a0,a0,916 # 80017518 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a4a080e7          	jalr	-1462(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003194:	40bc                	lw	a5,64(s1)
    80003196:	37fd                	addiw	a5,a5,-1
    80003198:	0007871b          	sext.w	a4,a5
    8000319c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000319e:	eb05                	bnez	a4,800031ce <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031a0:	68bc                	ld	a5,80(s1)
    800031a2:	64b8                	ld	a4,72(s1)
    800031a4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031a6:	64bc                	ld	a5,72(s1)
    800031a8:	68b8                	ld	a4,80(s1)
    800031aa:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031ac:	0001c797          	auipc	a5,0x1c
    800031b0:	36c78793          	addi	a5,a5,876 # 8001f518 <bcache+0x8000>
    800031b4:	2b87b703          	ld	a4,696(a5)
    800031b8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ba:	0001c717          	auipc	a4,0x1c
    800031be:	5c670713          	addi	a4,a4,1478 # 8001f780 <bcache+0x8268>
    800031c2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031c4:	2b87b703          	ld	a4,696(a5)
    800031c8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ca:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ce:	00014517          	auipc	a0,0x14
    800031d2:	34a50513          	addi	a0,a0,842 # 80017518 <bcache>
    800031d6:	ffffe097          	auipc	ra,0xffffe
    800031da:	ab4080e7          	jalr	-1356(ra) # 80000c8a <release>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6902                	ld	s2,0(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret
    panic("brelse");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	37650513          	addi	a0,a0,886 # 80008560 <syscalls+0xf0>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	34c080e7          	jalr	844(ra) # 8000053e <panic>

00000000800031fa <bpin>:

void
bpin(struct buf *b) {
    800031fa:	1101                	addi	sp,sp,-32
    800031fc:	ec06                	sd	ra,24(sp)
    800031fe:	e822                	sd	s0,16(sp)
    80003200:	e426                	sd	s1,8(sp)
    80003202:	1000                	addi	s0,sp,32
    80003204:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003206:	00014517          	auipc	a0,0x14
    8000320a:	31250513          	addi	a0,a0,786 # 80017518 <bcache>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	9c8080e7          	jalr	-1592(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003216:	40bc                	lw	a5,64(s1)
    80003218:	2785                	addiw	a5,a5,1
    8000321a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000321c:	00014517          	auipc	a0,0x14
    80003220:	2fc50513          	addi	a0,a0,764 # 80017518 <bcache>
    80003224:	ffffe097          	auipc	ra,0xffffe
    80003228:	a66080e7          	jalr	-1434(ra) # 80000c8a <release>
}
    8000322c:	60e2                	ld	ra,24(sp)
    8000322e:	6442                	ld	s0,16(sp)
    80003230:	64a2                	ld	s1,8(sp)
    80003232:	6105                	addi	sp,sp,32
    80003234:	8082                	ret

0000000080003236 <bunpin>:

void
bunpin(struct buf *b) {
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	e426                	sd	s1,8(sp)
    8000323e:	1000                	addi	s0,sp,32
    80003240:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003242:	00014517          	auipc	a0,0x14
    80003246:	2d650513          	addi	a0,a0,726 # 80017518 <bcache>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	98c080e7          	jalr	-1652(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003252:	40bc                	lw	a5,64(s1)
    80003254:	37fd                	addiw	a5,a5,-1
    80003256:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003258:	00014517          	auipc	a0,0x14
    8000325c:	2c050513          	addi	a0,a0,704 # 80017518 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	e04a                	sd	s2,0(sp)
    8000327c:	1000                	addi	s0,sp,32
    8000327e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003280:	00d5d59b          	srliw	a1,a1,0xd
    80003284:	0001d797          	auipc	a5,0x1d
    80003288:	9707a783          	lw	a5,-1680(a5) # 8001fbf4 <sb+0x1c>
    8000328c:	9dbd                	addw	a1,a1,a5
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	d9e080e7          	jalr	-610(ra) # 8000302c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003296:	0074f713          	andi	a4,s1,7
    8000329a:	4785                	li	a5,1
    8000329c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032a0:	14ce                	slli	s1,s1,0x33
    800032a2:	90d9                	srli	s1,s1,0x36
    800032a4:	00950733          	add	a4,a0,s1
    800032a8:	05874703          	lbu	a4,88(a4)
    800032ac:	00e7f6b3          	and	a3,a5,a4
    800032b0:	c69d                	beqz	a3,800032de <bfree+0x6c>
    800032b2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032b4:	94aa                	add	s1,s1,a0
    800032b6:	fff7c793          	not	a5,a5
    800032ba:	8ff9                	and	a5,a5,a4
    800032bc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032c0:	00001097          	auipc	ra,0x1
    800032c4:	120080e7          	jalr	288(ra) # 800043e0 <log_write>
  brelse(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	e92080e7          	jalr	-366(ra) # 8000315c <brelse>
}
    800032d2:	60e2                	ld	ra,24(sp)
    800032d4:	6442                	ld	s0,16(sp)
    800032d6:	64a2                	ld	s1,8(sp)
    800032d8:	6902                	ld	s2,0(sp)
    800032da:	6105                	addi	sp,sp,32
    800032dc:	8082                	ret
    panic("freeing free block");
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	28a50513          	addi	a0,a0,650 # 80008568 <syscalls+0xf8>
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	258080e7          	jalr	600(ra) # 8000053e <panic>

00000000800032ee <balloc>:
{
    800032ee:	711d                	addi	sp,sp,-96
    800032f0:	ec86                	sd	ra,88(sp)
    800032f2:	e8a2                	sd	s0,80(sp)
    800032f4:	e4a6                	sd	s1,72(sp)
    800032f6:	e0ca                	sd	s2,64(sp)
    800032f8:	fc4e                	sd	s3,56(sp)
    800032fa:	f852                	sd	s4,48(sp)
    800032fc:	f456                	sd	s5,40(sp)
    800032fe:	f05a                	sd	s6,32(sp)
    80003300:	ec5e                	sd	s7,24(sp)
    80003302:	e862                	sd	s8,16(sp)
    80003304:	e466                	sd	s9,8(sp)
    80003306:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003308:	0001d797          	auipc	a5,0x1d
    8000330c:	8d47a783          	lw	a5,-1836(a5) # 8001fbdc <sb+0x4>
    80003310:	10078163          	beqz	a5,80003412 <balloc+0x124>
    80003314:	8baa                	mv	s7,a0
    80003316:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003318:	0001db17          	auipc	s6,0x1d
    8000331c:	8c0b0b13          	addi	s6,s6,-1856 # 8001fbd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003320:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003322:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003324:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003326:	6c89                	lui	s9,0x2
    80003328:	a061                	j	800033b0 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000332a:	974a                	add	a4,a4,s2
    8000332c:	8fd5                	or	a5,a5,a3
    8000332e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003332:	854a                	mv	a0,s2
    80003334:	00001097          	auipc	ra,0x1
    80003338:	0ac080e7          	jalr	172(ra) # 800043e0 <log_write>
        brelse(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	e1e080e7          	jalr	-482(ra) # 8000315c <brelse>
  bp = bread(dev, bno);
    80003346:	85a6                	mv	a1,s1
    80003348:	855e                	mv	a0,s7
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	ce2080e7          	jalr	-798(ra) # 8000302c <bread>
    80003352:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003354:	40000613          	li	a2,1024
    80003358:	4581                	li	a1,0
    8000335a:	05850513          	addi	a0,a0,88
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	974080e7          	jalr	-1676(ra) # 80000cd2 <memset>
  log_write(bp);
    80003366:	854a                	mv	a0,s2
    80003368:	00001097          	auipc	ra,0x1
    8000336c:	078080e7          	jalr	120(ra) # 800043e0 <log_write>
  brelse(bp);
    80003370:	854a                	mv	a0,s2
    80003372:	00000097          	auipc	ra,0x0
    80003376:	dea080e7          	jalr	-534(ra) # 8000315c <brelse>
}
    8000337a:	8526                	mv	a0,s1
    8000337c:	60e6                	ld	ra,88(sp)
    8000337e:	6446                	ld	s0,80(sp)
    80003380:	64a6                	ld	s1,72(sp)
    80003382:	6906                	ld	s2,64(sp)
    80003384:	79e2                	ld	s3,56(sp)
    80003386:	7a42                	ld	s4,48(sp)
    80003388:	7aa2                	ld	s5,40(sp)
    8000338a:	7b02                	ld	s6,32(sp)
    8000338c:	6be2                	ld	s7,24(sp)
    8000338e:	6c42                	ld	s8,16(sp)
    80003390:	6ca2                	ld	s9,8(sp)
    80003392:	6125                	addi	sp,sp,96
    80003394:	8082                	ret
    brelse(bp);
    80003396:	854a                	mv	a0,s2
    80003398:	00000097          	auipc	ra,0x0
    8000339c:	dc4080e7          	jalr	-572(ra) # 8000315c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033a0:	015c87bb          	addw	a5,s9,s5
    800033a4:	00078a9b          	sext.w	s5,a5
    800033a8:	004b2703          	lw	a4,4(s6)
    800033ac:	06eaf363          	bgeu	s5,a4,80003412 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800033b0:	41fad79b          	sraiw	a5,s5,0x1f
    800033b4:	0137d79b          	srliw	a5,a5,0x13
    800033b8:	015787bb          	addw	a5,a5,s5
    800033bc:	40d7d79b          	sraiw	a5,a5,0xd
    800033c0:	01cb2583          	lw	a1,28(s6)
    800033c4:	9dbd                	addw	a1,a1,a5
    800033c6:	855e                	mv	a0,s7
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	c64080e7          	jalr	-924(ra) # 8000302c <bread>
    800033d0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d2:	004b2503          	lw	a0,4(s6)
    800033d6:	000a849b          	sext.w	s1,s5
    800033da:	8662                	mv	a2,s8
    800033dc:	faa4fde3          	bgeu	s1,a0,80003396 <balloc+0xa8>
      m = 1 << (bi % 8);
    800033e0:	41f6579b          	sraiw	a5,a2,0x1f
    800033e4:	01d7d69b          	srliw	a3,a5,0x1d
    800033e8:	00c6873b          	addw	a4,a3,a2
    800033ec:	00777793          	andi	a5,a4,7
    800033f0:	9f95                	subw	a5,a5,a3
    800033f2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033f6:	4037571b          	sraiw	a4,a4,0x3
    800033fa:	00e906b3          	add	a3,s2,a4
    800033fe:	0586c683          	lbu	a3,88(a3)
    80003402:	00d7f5b3          	and	a1,a5,a3
    80003406:	d195                	beqz	a1,8000332a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003408:	2605                	addiw	a2,a2,1
    8000340a:	2485                	addiw	s1,s1,1
    8000340c:	fd4618e3          	bne	a2,s4,800033dc <balloc+0xee>
    80003410:	b759                	j	80003396 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	16e50513          	addi	a0,a0,366 # 80008580 <syscalls+0x110>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	16e080e7          	jalr	366(ra) # 80000588 <printf>
  return 0;
    80003422:	4481                	li	s1,0
    80003424:	bf99                	j	8000337a <balloc+0x8c>

0000000080003426 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003426:	7179                	addi	sp,sp,-48
    80003428:	f406                	sd	ra,40(sp)
    8000342a:	f022                	sd	s0,32(sp)
    8000342c:	ec26                	sd	s1,24(sp)
    8000342e:	e84a                	sd	s2,16(sp)
    80003430:	e44e                	sd	s3,8(sp)
    80003432:	e052                	sd	s4,0(sp)
    80003434:	1800                	addi	s0,sp,48
    80003436:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003438:	47ad                	li	a5,11
    8000343a:	02b7e763          	bltu	a5,a1,80003468 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000343e:	02059493          	slli	s1,a1,0x20
    80003442:	9081                	srli	s1,s1,0x20
    80003444:	048a                	slli	s1,s1,0x2
    80003446:	94aa                	add	s1,s1,a0
    80003448:	0504a903          	lw	s2,80(s1)
    8000344c:	06091e63          	bnez	s2,800034c8 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003450:	4108                	lw	a0,0(a0)
    80003452:	00000097          	auipc	ra,0x0
    80003456:	e9c080e7          	jalr	-356(ra) # 800032ee <balloc>
    8000345a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000345e:	06090563          	beqz	s2,800034c8 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003462:	0524a823          	sw	s2,80(s1)
    80003466:	a08d                	j	800034c8 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003468:	ff45849b          	addiw	s1,a1,-12
    8000346c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003470:	0ff00793          	li	a5,255
    80003474:	08e7e563          	bltu	a5,a4,800034fe <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003478:	08052903          	lw	s2,128(a0)
    8000347c:	00091d63          	bnez	s2,80003496 <bmap+0x70>
      addr = balloc(ip->dev);
    80003480:	4108                	lw	a0,0(a0)
    80003482:	00000097          	auipc	ra,0x0
    80003486:	e6c080e7          	jalr	-404(ra) # 800032ee <balloc>
    8000348a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000348e:	02090d63          	beqz	s2,800034c8 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003492:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003496:	85ca                	mv	a1,s2
    80003498:	0009a503          	lw	a0,0(s3)
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	b90080e7          	jalr	-1136(ra) # 8000302c <bread>
    800034a4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034a6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034aa:	02049593          	slli	a1,s1,0x20
    800034ae:	9181                	srli	a1,a1,0x20
    800034b0:	058a                	slli	a1,a1,0x2
    800034b2:	00b784b3          	add	s1,a5,a1
    800034b6:	0004a903          	lw	s2,0(s1)
    800034ba:	02090063          	beqz	s2,800034da <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034be:	8552                	mv	a0,s4
    800034c0:	00000097          	auipc	ra,0x0
    800034c4:	c9c080e7          	jalr	-868(ra) # 8000315c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034c8:	854a                	mv	a0,s2
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6a02                	ld	s4,0(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret
      addr = balloc(ip->dev);
    800034da:	0009a503          	lw	a0,0(s3)
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e10080e7          	jalr	-496(ra) # 800032ee <balloc>
    800034e6:	0005091b          	sext.w	s2,a0
      if(addr){
    800034ea:	fc090ae3          	beqz	s2,800034be <bmap+0x98>
        a[bn] = addr;
    800034ee:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034f2:	8552                	mv	a0,s4
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	eec080e7          	jalr	-276(ra) # 800043e0 <log_write>
    800034fc:	b7c9                	j	800034be <bmap+0x98>
  panic("bmap: out of range");
    800034fe:	00005517          	auipc	a0,0x5
    80003502:	09a50513          	addi	a0,a0,154 # 80008598 <syscalls+0x128>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	038080e7          	jalr	56(ra) # 8000053e <panic>

000000008000350e <iget>:
{
    8000350e:	7179                	addi	sp,sp,-48
    80003510:	f406                	sd	ra,40(sp)
    80003512:	f022                	sd	s0,32(sp)
    80003514:	ec26                	sd	s1,24(sp)
    80003516:	e84a                	sd	s2,16(sp)
    80003518:	e44e                	sd	s3,8(sp)
    8000351a:	e052                	sd	s4,0(sp)
    8000351c:	1800                	addi	s0,sp,48
    8000351e:	89aa                	mv	s3,a0
    80003520:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003522:	0001c517          	auipc	a0,0x1c
    80003526:	6d650513          	addi	a0,a0,1750 # 8001fbf8 <itable>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	6ac080e7          	jalr	1708(ra) # 80000bd6 <acquire>
  empty = 0;
    80003532:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003534:	0001c497          	auipc	s1,0x1c
    80003538:	6dc48493          	addi	s1,s1,1756 # 8001fc10 <itable+0x18>
    8000353c:	0001e697          	auipc	a3,0x1e
    80003540:	16468693          	addi	a3,a3,356 # 800216a0 <log>
    80003544:	a039                	j	80003552 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003546:	02090b63          	beqz	s2,8000357c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000354a:	08848493          	addi	s1,s1,136
    8000354e:	02d48a63          	beq	s1,a3,80003582 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003552:	449c                	lw	a5,8(s1)
    80003554:	fef059e3          	blez	a5,80003546 <iget+0x38>
    80003558:	4098                	lw	a4,0(s1)
    8000355a:	ff3716e3          	bne	a4,s3,80003546 <iget+0x38>
    8000355e:	40d8                	lw	a4,4(s1)
    80003560:	ff4713e3          	bne	a4,s4,80003546 <iget+0x38>
      ip->ref++;
    80003564:	2785                	addiw	a5,a5,1
    80003566:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003568:	0001c517          	auipc	a0,0x1c
    8000356c:	69050513          	addi	a0,a0,1680 # 8001fbf8 <itable>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	71a080e7          	jalr	1818(ra) # 80000c8a <release>
      return ip;
    80003578:	8926                	mv	s2,s1
    8000357a:	a03d                	j	800035a8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357c:	f7f9                	bnez	a5,8000354a <iget+0x3c>
    8000357e:	8926                	mv	s2,s1
    80003580:	b7e9                	j	8000354a <iget+0x3c>
  if(empty == 0)
    80003582:	02090c63          	beqz	s2,800035ba <iget+0xac>
  ip->dev = dev;
    80003586:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000358a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000358e:	4785                	li	a5,1
    80003590:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003594:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003598:	0001c517          	auipc	a0,0x1c
    8000359c:	66050513          	addi	a0,a0,1632 # 8001fbf8 <itable>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	6ea080e7          	jalr	1770(ra) # 80000c8a <release>
}
    800035a8:	854a                	mv	a0,s2
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6942                	ld	s2,16(sp)
    800035b2:	69a2                	ld	s3,8(sp)
    800035b4:	6a02                	ld	s4,0(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret
    panic("iget: no inodes");
    800035ba:	00005517          	auipc	a0,0x5
    800035be:	ff650513          	addi	a0,a0,-10 # 800085b0 <syscalls+0x140>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	f7c080e7          	jalr	-132(ra) # 8000053e <panic>

00000000800035ca <fsinit>:
fsinit(int dev) {
    800035ca:	7179                	addi	sp,sp,-48
    800035cc:	f406                	sd	ra,40(sp)
    800035ce:	f022                	sd	s0,32(sp)
    800035d0:	ec26                	sd	s1,24(sp)
    800035d2:	e84a                	sd	s2,16(sp)
    800035d4:	e44e                	sd	s3,8(sp)
    800035d6:	1800                	addi	s0,sp,48
    800035d8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035da:	4585                	li	a1,1
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	a50080e7          	jalr	-1456(ra) # 8000302c <bread>
    800035e4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035e6:	0001c997          	auipc	s3,0x1c
    800035ea:	5f298993          	addi	s3,s3,1522 # 8001fbd8 <sb>
    800035ee:	02000613          	li	a2,32
    800035f2:	05850593          	addi	a1,a0,88
    800035f6:	854e                	mv	a0,s3
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	736080e7          	jalr	1846(ra) # 80000d2e <memmove>
  brelse(bp);
    80003600:	8526                	mv	a0,s1
    80003602:	00000097          	auipc	ra,0x0
    80003606:	b5a080e7          	jalr	-1190(ra) # 8000315c <brelse>
  if(sb.magic != FSMAGIC)
    8000360a:	0009a703          	lw	a4,0(s3)
    8000360e:	102037b7          	lui	a5,0x10203
    80003612:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003616:	02f71263          	bne	a4,a5,8000363a <fsinit+0x70>
  initlog(dev, &sb);
    8000361a:	0001c597          	auipc	a1,0x1c
    8000361e:	5be58593          	addi	a1,a1,1470 # 8001fbd8 <sb>
    80003622:	854a                	mv	a0,s2
    80003624:	00001097          	auipc	ra,0x1
    80003628:	b40080e7          	jalr	-1216(ra) # 80004164 <initlog>
}
    8000362c:	70a2                	ld	ra,40(sp)
    8000362e:	7402                	ld	s0,32(sp)
    80003630:	64e2                	ld	s1,24(sp)
    80003632:	6942                	ld	s2,16(sp)
    80003634:	69a2                	ld	s3,8(sp)
    80003636:	6145                	addi	sp,sp,48
    80003638:	8082                	ret
    panic("invalid file system");
    8000363a:	00005517          	auipc	a0,0x5
    8000363e:	f8650513          	addi	a0,a0,-122 # 800085c0 <syscalls+0x150>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>

000000008000364a <iinit>:
{
    8000364a:	7179                	addi	sp,sp,-48
    8000364c:	f406                	sd	ra,40(sp)
    8000364e:	f022                	sd	s0,32(sp)
    80003650:	ec26                	sd	s1,24(sp)
    80003652:	e84a                	sd	s2,16(sp)
    80003654:	e44e                	sd	s3,8(sp)
    80003656:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003658:	00005597          	auipc	a1,0x5
    8000365c:	f8058593          	addi	a1,a1,-128 # 800085d8 <syscalls+0x168>
    80003660:	0001c517          	auipc	a0,0x1c
    80003664:	59850513          	addi	a0,a0,1432 # 8001fbf8 <itable>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	4de080e7          	jalr	1246(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003670:	0001c497          	auipc	s1,0x1c
    80003674:	5b048493          	addi	s1,s1,1456 # 8001fc20 <itable+0x28>
    80003678:	0001e997          	auipc	s3,0x1e
    8000367c:	03898993          	addi	s3,s3,56 # 800216b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003680:	00005917          	auipc	s2,0x5
    80003684:	f6090913          	addi	s2,s2,-160 # 800085e0 <syscalls+0x170>
    80003688:	85ca                	mv	a1,s2
    8000368a:	8526                	mv	a0,s1
    8000368c:	00001097          	auipc	ra,0x1
    80003690:	e3a080e7          	jalr	-454(ra) # 800044c6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003694:	08848493          	addi	s1,s1,136
    80003698:	ff3498e3          	bne	s1,s3,80003688 <iinit+0x3e>
}
    8000369c:	70a2                	ld	ra,40(sp)
    8000369e:	7402                	ld	s0,32(sp)
    800036a0:	64e2                	ld	s1,24(sp)
    800036a2:	6942                	ld	s2,16(sp)
    800036a4:	69a2                	ld	s3,8(sp)
    800036a6:	6145                	addi	sp,sp,48
    800036a8:	8082                	ret

00000000800036aa <ialloc>:
{
    800036aa:	715d                	addi	sp,sp,-80
    800036ac:	e486                	sd	ra,72(sp)
    800036ae:	e0a2                	sd	s0,64(sp)
    800036b0:	fc26                	sd	s1,56(sp)
    800036b2:	f84a                	sd	s2,48(sp)
    800036b4:	f44e                	sd	s3,40(sp)
    800036b6:	f052                	sd	s4,32(sp)
    800036b8:	ec56                	sd	s5,24(sp)
    800036ba:	e85a                	sd	s6,16(sp)
    800036bc:	e45e                	sd	s7,8(sp)
    800036be:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036c0:	0001c717          	auipc	a4,0x1c
    800036c4:	52472703          	lw	a4,1316(a4) # 8001fbe4 <sb+0xc>
    800036c8:	4785                	li	a5,1
    800036ca:	04e7fa63          	bgeu	a5,a4,8000371e <ialloc+0x74>
    800036ce:	8aaa                	mv	s5,a0
    800036d0:	8bae                	mv	s7,a1
    800036d2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036d4:	0001ca17          	auipc	s4,0x1c
    800036d8:	504a0a13          	addi	s4,s4,1284 # 8001fbd8 <sb>
    800036dc:	00048b1b          	sext.w	s6,s1
    800036e0:	0044d793          	srli	a5,s1,0x4
    800036e4:	018a2583          	lw	a1,24(s4)
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	8556                	mv	a0,s5
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	940080e7          	jalr	-1728(ra) # 8000302c <bread>
    800036f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036f6:	05850993          	addi	s3,a0,88
    800036fa:	00f4f793          	andi	a5,s1,15
    800036fe:	079a                	slli	a5,a5,0x6
    80003700:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003702:	00099783          	lh	a5,0(s3)
    80003706:	c3a1                	beqz	a5,80003746 <ialloc+0x9c>
    brelse(bp);
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	a54080e7          	jalr	-1452(ra) # 8000315c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003710:	0485                	addi	s1,s1,1
    80003712:	00ca2703          	lw	a4,12(s4)
    80003716:	0004879b          	sext.w	a5,s1
    8000371a:	fce7e1e3          	bltu	a5,a4,800036dc <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	eca50513          	addi	a0,a0,-310 # 800085e8 <syscalls+0x178>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e62080e7          	jalr	-414(ra) # 80000588 <printf>
  return 0;
    8000372e:	4501                	li	a0,0
}
    80003730:	60a6                	ld	ra,72(sp)
    80003732:	6406                	ld	s0,64(sp)
    80003734:	74e2                	ld	s1,56(sp)
    80003736:	7942                	ld	s2,48(sp)
    80003738:	79a2                	ld	s3,40(sp)
    8000373a:	7a02                	ld	s4,32(sp)
    8000373c:	6ae2                	ld	s5,24(sp)
    8000373e:	6b42                	ld	s6,16(sp)
    80003740:	6ba2                	ld	s7,8(sp)
    80003742:	6161                	addi	sp,sp,80
    80003744:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003746:	04000613          	li	a2,64
    8000374a:	4581                	li	a1,0
    8000374c:	854e                	mv	a0,s3
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	584080e7          	jalr	1412(ra) # 80000cd2 <memset>
      dip->type = type;
    80003756:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	c84080e7          	jalr	-892(ra) # 800043e0 <log_write>
      brelse(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	9f6080e7          	jalr	-1546(ra) # 8000315c <brelse>
      return iget(dev, inum);
    8000376e:	85da                	mv	a1,s6
    80003770:	8556                	mv	a0,s5
    80003772:	00000097          	auipc	ra,0x0
    80003776:	d9c080e7          	jalr	-612(ra) # 8000350e <iget>
    8000377a:	bf5d                	j	80003730 <ialloc+0x86>

000000008000377c <iupdate>:
{
    8000377c:	1101                	addi	sp,sp,-32
    8000377e:	ec06                	sd	ra,24(sp)
    80003780:	e822                	sd	s0,16(sp)
    80003782:	e426                	sd	s1,8(sp)
    80003784:	e04a                	sd	s2,0(sp)
    80003786:	1000                	addi	s0,sp,32
    80003788:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000378a:	415c                	lw	a5,4(a0)
    8000378c:	0047d79b          	srliw	a5,a5,0x4
    80003790:	0001c597          	auipc	a1,0x1c
    80003794:	4605a583          	lw	a1,1120(a1) # 8001fbf0 <sb+0x18>
    80003798:	9dbd                	addw	a1,a1,a5
    8000379a:	4108                	lw	a0,0(a0)
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	890080e7          	jalr	-1904(ra) # 8000302c <bread>
    800037a4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a6:	05850793          	addi	a5,a0,88
    800037aa:	40c8                	lw	a0,4(s1)
    800037ac:	893d                	andi	a0,a0,15
    800037ae:	051a                	slli	a0,a0,0x6
    800037b0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037b2:	04449703          	lh	a4,68(s1)
    800037b6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037ba:	04649703          	lh	a4,70(s1)
    800037be:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037c2:	04849703          	lh	a4,72(s1)
    800037c6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037ca:	04a49703          	lh	a4,74(s1)
    800037ce:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037d2:	44f8                	lw	a4,76(s1)
    800037d4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037d6:	03400613          	li	a2,52
    800037da:	05048593          	addi	a1,s1,80
    800037de:	0531                	addi	a0,a0,12
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	54e080e7          	jalr	1358(ra) # 80000d2e <memmove>
  log_write(bp);
    800037e8:	854a                	mv	a0,s2
    800037ea:	00001097          	auipc	ra,0x1
    800037ee:	bf6080e7          	jalr	-1034(ra) # 800043e0 <log_write>
  brelse(bp);
    800037f2:	854a                	mv	a0,s2
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	968080e7          	jalr	-1688(ra) # 8000315c <brelse>
}
    800037fc:	60e2                	ld	ra,24(sp)
    800037fe:	6442                	ld	s0,16(sp)
    80003800:	64a2                	ld	s1,8(sp)
    80003802:	6902                	ld	s2,0(sp)
    80003804:	6105                	addi	sp,sp,32
    80003806:	8082                	ret

0000000080003808 <idup>:
{
    80003808:	1101                	addi	sp,sp,-32
    8000380a:	ec06                	sd	ra,24(sp)
    8000380c:	e822                	sd	s0,16(sp)
    8000380e:	e426                	sd	s1,8(sp)
    80003810:	1000                	addi	s0,sp,32
    80003812:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	3e450513          	addi	a0,a0,996 # 8001fbf8 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	3ba080e7          	jalr	954(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003824:	449c                	lw	a5,8(s1)
    80003826:	2785                	addiw	a5,a5,1
    80003828:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000382a:	0001c517          	auipc	a0,0x1c
    8000382e:	3ce50513          	addi	a0,a0,974 # 8001fbf8 <itable>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	458080e7          	jalr	1112(ra) # 80000c8a <release>
}
    8000383a:	8526                	mv	a0,s1
    8000383c:	60e2                	ld	ra,24(sp)
    8000383e:	6442                	ld	s0,16(sp)
    80003840:	64a2                	ld	s1,8(sp)
    80003842:	6105                	addi	sp,sp,32
    80003844:	8082                	ret

0000000080003846 <ilock>:
{
    80003846:	1101                	addi	sp,sp,-32
    80003848:	ec06                	sd	ra,24(sp)
    8000384a:	e822                	sd	s0,16(sp)
    8000384c:	e426                	sd	s1,8(sp)
    8000384e:	e04a                	sd	s2,0(sp)
    80003850:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003852:	c115                	beqz	a0,80003876 <ilock+0x30>
    80003854:	84aa                	mv	s1,a0
    80003856:	451c                	lw	a5,8(a0)
    80003858:	00f05f63          	blez	a5,80003876 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000385c:	0541                	addi	a0,a0,16
    8000385e:	00001097          	auipc	ra,0x1
    80003862:	ca2080e7          	jalr	-862(ra) # 80004500 <acquiresleep>
  if(ip->valid == 0){
    80003866:	40bc                	lw	a5,64(s1)
    80003868:	cf99                	beqz	a5,80003886 <ilock+0x40>
}
    8000386a:	60e2                	ld	ra,24(sp)
    8000386c:	6442                	ld	s0,16(sp)
    8000386e:	64a2                	ld	s1,8(sp)
    80003870:	6902                	ld	s2,0(sp)
    80003872:	6105                	addi	sp,sp,32
    80003874:	8082                	ret
    panic("ilock");
    80003876:	00005517          	auipc	a0,0x5
    8000387a:	d8a50513          	addi	a0,a0,-630 # 80008600 <syscalls+0x190>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	cc0080e7          	jalr	-832(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003886:	40dc                	lw	a5,4(s1)
    80003888:	0047d79b          	srliw	a5,a5,0x4
    8000388c:	0001c597          	auipc	a1,0x1c
    80003890:	3645a583          	lw	a1,868(a1) # 8001fbf0 <sb+0x18>
    80003894:	9dbd                	addw	a1,a1,a5
    80003896:	4088                	lw	a0,0(s1)
    80003898:	fffff097          	auipc	ra,0xfffff
    8000389c:	794080e7          	jalr	1940(ra) # 8000302c <bread>
    800038a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038a2:	05850593          	addi	a1,a0,88
    800038a6:	40dc                	lw	a5,4(s1)
    800038a8:	8bbd                	andi	a5,a5,15
    800038aa:	079a                	slli	a5,a5,0x6
    800038ac:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038ae:	00059783          	lh	a5,0(a1)
    800038b2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038b6:	00259783          	lh	a5,2(a1)
    800038ba:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038be:	00459783          	lh	a5,4(a1)
    800038c2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038c6:	00659783          	lh	a5,6(a1)
    800038ca:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038ce:	459c                	lw	a5,8(a1)
    800038d0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038d2:	03400613          	li	a2,52
    800038d6:	05b1                	addi	a1,a1,12
    800038d8:	05048513          	addi	a0,s1,80
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	452080e7          	jalr	1106(ra) # 80000d2e <memmove>
    brelse(bp);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	876080e7          	jalr	-1930(ra) # 8000315c <brelse>
    ip->valid = 1;
    800038ee:	4785                	li	a5,1
    800038f0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038f2:	04449783          	lh	a5,68(s1)
    800038f6:	fbb5                	bnez	a5,8000386a <ilock+0x24>
      panic("ilock: no type");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	d1050513          	addi	a0,a0,-752 # 80008608 <syscalls+0x198>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c3e080e7          	jalr	-962(ra) # 8000053e <panic>

0000000080003908 <iunlock>:
{
    80003908:	1101                	addi	sp,sp,-32
    8000390a:	ec06                	sd	ra,24(sp)
    8000390c:	e822                	sd	s0,16(sp)
    8000390e:	e426                	sd	s1,8(sp)
    80003910:	e04a                	sd	s2,0(sp)
    80003912:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003914:	c905                	beqz	a0,80003944 <iunlock+0x3c>
    80003916:	84aa                	mv	s1,a0
    80003918:	01050913          	addi	s2,a0,16
    8000391c:	854a                	mv	a0,s2
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	c7c080e7          	jalr	-900(ra) # 8000459a <holdingsleep>
    80003926:	cd19                	beqz	a0,80003944 <iunlock+0x3c>
    80003928:	449c                	lw	a5,8(s1)
    8000392a:	00f05d63          	blez	a5,80003944 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000392e:	854a                	mv	a0,s2
    80003930:	00001097          	auipc	ra,0x1
    80003934:	c26080e7          	jalr	-986(ra) # 80004556 <releasesleep>
}
    80003938:	60e2                	ld	ra,24(sp)
    8000393a:	6442                	ld	s0,16(sp)
    8000393c:	64a2                	ld	s1,8(sp)
    8000393e:	6902                	ld	s2,0(sp)
    80003940:	6105                	addi	sp,sp,32
    80003942:	8082                	ret
    panic("iunlock");
    80003944:	00005517          	auipc	a0,0x5
    80003948:	cd450513          	addi	a0,a0,-812 # 80008618 <syscalls+0x1a8>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>

0000000080003954 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003954:	7179                	addi	sp,sp,-48
    80003956:	f406                	sd	ra,40(sp)
    80003958:	f022                	sd	s0,32(sp)
    8000395a:	ec26                	sd	s1,24(sp)
    8000395c:	e84a                	sd	s2,16(sp)
    8000395e:	e44e                	sd	s3,8(sp)
    80003960:	e052                	sd	s4,0(sp)
    80003962:	1800                	addi	s0,sp,48
    80003964:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003966:	05050493          	addi	s1,a0,80
    8000396a:	08050913          	addi	s2,a0,128
    8000396e:	a021                	j	80003976 <itrunc+0x22>
    80003970:	0491                	addi	s1,s1,4
    80003972:	01248d63          	beq	s1,s2,8000398c <itrunc+0x38>
    if(ip->addrs[i]){
    80003976:	408c                	lw	a1,0(s1)
    80003978:	dde5                	beqz	a1,80003970 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000397a:	0009a503          	lw	a0,0(s3)
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	8f4080e7          	jalr	-1804(ra) # 80003272 <bfree>
      ip->addrs[i] = 0;
    80003986:	0004a023          	sw	zero,0(s1)
    8000398a:	b7dd                	j	80003970 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000398c:	0809a583          	lw	a1,128(s3)
    80003990:	e185                	bnez	a1,800039b0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003992:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003996:	854e                	mv	a0,s3
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	de4080e7          	jalr	-540(ra) # 8000377c <iupdate>
}
    800039a0:	70a2                	ld	ra,40(sp)
    800039a2:	7402                	ld	s0,32(sp)
    800039a4:	64e2                	ld	s1,24(sp)
    800039a6:	6942                	ld	s2,16(sp)
    800039a8:	69a2                	ld	s3,8(sp)
    800039aa:	6a02                	ld	s4,0(sp)
    800039ac:	6145                	addi	sp,sp,48
    800039ae:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039b0:	0009a503          	lw	a0,0(s3)
    800039b4:	fffff097          	auipc	ra,0xfffff
    800039b8:	678080e7          	jalr	1656(ra) # 8000302c <bread>
    800039bc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039be:	05850493          	addi	s1,a0,88
    800039c2:	45850913          	addi	s2,a0,1112
    800039c6:	a021                	j	800039ce <itrunc+0x7a>
    800039c8:	0491                	addi	s1,s1,4
    800039ca:	01248b63          	beq	s1,s2,800039e0 <itrunc+0x8c>
      if(a[j])
    800039ce:	408c                	lw	a1,0(s1)
    800039d0:	dde5                	beqz	a1,800039c8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039d2:	0009a503          	lw	a0,0(s3)
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	89c080e7          	jalr	-1892(ra) # 80003272 <bfree>
    800039de:	b7ed                	j	800039c8 <itrunc+0x74>
    brelse(bp);
    800039e0:	8552                	mv	a0,s4
    800039e2:	fffff097          	auipc	ra,0xfffff
    800039e6:	77a080e7          	jalr	1914(ra) # 8000315c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039ea:	0809a583          	lw	a1,128(s3)
    800039ee:	0009a503          	lw	a0,0(s3)
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	880080e7          	jalr	-1920(ra) # 80003272 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039fa:	0809a023          	sw	zero,128(s3)
    800039fe:	bf51                	j	80003992 <itrunc+0x3e>

0000000080003a00 <iput>:
{
    80003a00:	1101                	addi	sp,sp,-32
    80003a02:	ec06                	sd	ra,24(sp)
    80003a04:	e822                	sd	s0,16(sp)
    80003a06:	e426                	sd	s1,8(sp)
    80003a08:	e04a                	sd	s2,0(sp)
    80003a0a:	1000                	addi	s0,sp,32
    80003a0c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a0e:	0001c517          	auipc	a0,0x1c
    80003a12:	1ea50513          	addi	a0,a0,490 # 8001fbf8 <itable>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	1c0080e7          	jalr	448(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a1e:	4498                	lw	a4,8(s1)
    80003a20:	4785                	li	a5,1
    80003a22:	02f70363          	beq	a4,a5,80003a48 <iput+0x48>
  ip->ref--;
    80003a26:	449c                	lw	a5,8(s1)
    80003a28:	37fd                	addiw	a5,a5,-1
    80003a2a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a2c:	0001c517          	auipc	a0,0x1c
    80003a30:	1cc50513          	addi	a0,a0,460 # 8001fbf8 <itable>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	256080e7          	jalr	598(ra) # 80000c8a <release>
}
    80003a3c:	60e2                	ld	ra,24(sp)
    80003a3e:	6442                	ld	s0,16(sp)
    80003a40:	64a2                	ld	s1,8(sp)
    80003a42:	6902                	ld	s2,0(sp)
    80003a44:	6105                	addi	sp,sp,32
    80003a46:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a48:	40bc                	lw	a5,64(s1)
    80003a4a:	dff1                	beqz	a5,80003a26 <iput+0x26>
    80003a4c:	04a49783          	lh	a5,74(s1)
    80003a50:	fbf9                	bnez	a5,80003a26 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a52:	01048913          	addi	s2,s1,16
    80003a56:	854a                	mv	a0,s2
    80003a58:	00001097          	auipc	ra,0x1
    80003a5c:	aa8080e7          	jalr	-1368(ra) # 80004500 <acquiresleep>
    release(&itable.lock);
    80003a60:	0001c517          	auipc	a0,0x1c
    80003a64:	19850513          	addi	a0,a0,408 # 8001fbf8 <itable>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	222080e7          	jalr	546(ra) # 80000c8a <release>
    itrunc(ip);
    80003a70:	8526                	mv	a0,s1
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	ee2080e7          	jalr	-286(ra) # 80003954 <itrunc>
    ip->type = 0;
    80003a7a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a7e:	8526                	mv	a0,s1
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	cfc080e7          	jalr	-772(ra) # 8000377c <iupdate>
    ip->valid = 0;
    80003a88:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	ac8080e7          	jalr	-1336(ra) # 80004556 <releasesleep>
    acquire(&itable.lock);
    80003a96:	0001c517          	auipc	a0,0x1c
    80003a9a:	16250513          	addi	a0,a0,354 # 8001fbf8 <itable>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	138080e7          	jalr	312(ra) # 80000bd6 <acquire>
    80003aa6:	b741                	j	80003a26 <iput+0x26>

0000000080003aa8 <iunlockput>:
{
    80003aa8:	1101                	addi	sp,sp,-32
    80003aaa:	ec06                	sd	ra,24(sp)
    80003aac:	e822                	sd	s0,16(sp)
    80003aae:	e426                	sd	s1,8(sp)
    80003ab0:	1000                	addi	s0,sp,32
    80003ab2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	e54080e7          	jalr	-428(ra) # 80003908 <iunlock>
  iput(ip);
    80003abc:	8526                	mv	a0,s1
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	f42080e7          	jalr	-190(ra) # 80003a00 <iput>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6105                	addi	sp,sp,32
    80003ace:	8082                	ret

0000000080003ad0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ad0:	1141                	addi	sp,sp,-16
    80003ad2:	e422                	sd	s0,8(sp)
    80003ad4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ad6:	411c                	lw	a5,0(a0)
    80003ad8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ada:	415c                	lw	a5,4(a0)
    80003adc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ade:	04451783          	lh	a5,68(a0)
    80003ae2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ae6:	04a51783          	lh	a5,74(a0)
    80003aea:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aee:	04c56783          	lwu	a5,76(a0)
    80003af2:	e99c                	sd	a5,16(a1)
}
    80003af4:	6422                	ld	s0,8(sp)
    80003af6:	0141                	addi	sp,sp,16
    80003af8:	8082                	ret

0000000080003afa <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003afa:	457c                	lw	a5,76(a0)
    80003afc:	0ed7e963          	bltu	a5,a3,80003bee <readi+0xf4>
{
    80003b00:	7159                	addi	sp,sp,-112
    80003b02:	f486                	sd	ra,104(sp)
    80003b04:	f0a2                	sd	s0,96(sp)
    80003b06:	eca6                	sd	s1,88(sp)
    80003b08:	e8ca                	sd	s2,80(sp)
    80003b0a:	e4ce                	sd	s3,72(sp)
    80003b0c:	e0d2                	sd	s4,64(sp)
    80003b0e:	fc56                	sd	s5,56(sp)
    80003b10:	f85a                	sd	s6,48(sp)
    80003b12:	f45e                	sd	s7,40(sp)
    80003b14:	f062                	sd	s8,32(sp)
    80003b16:	ec66                	sd	s9,24(sp)
    80003b18:	e86a                	sd	s10,16(sp)
    80003b1a:	e46e                	sd	s11,8(sp)
    80003b1c:	1880                	addi	s0,sp,112
    80003b1e:	8b2a                	mv	s6,a0
    80003b20:	8bae                	mv	s7,a1
    80003b22:	8a32                	mv	s4,a2
    80003b24:	84b6                	mv	s1,a3
    80003b26:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b28:	9f35                	addw	a4,a4,a3
    return 0;
    80003b2a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b2c:	0ad76063          	bltu	a4,a3,80003bcc <readi+0xd2>
  if(off + n > ip->size)
    80003b30:	00e7f463          	bgeu	a5,a4,80003b38 <readi+0x3e>
    n = ip->size - off;
    80003b34:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b38:	0a0a8963          	beqz	s5,80003bea <readi+0xf0>
    80003b3c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b3e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b42:	5c7d                	li	s8,-1
    80003b44:	a82d                	j	80003b7e <readi+0x84>
    80003b46:	020d1d93          	slli	s11,s10,0x20
    80003b4a:	020ddd93          	srli	s11,s11,0x20
    80003b4e:	05890793          	addi	a5,s2,88
    80003b52:	86ee                	mv	a3,s11
    80003b54:	963e                	add	a2,a2,a5
    80003b56:	85d2                	mv	a1,s4
    80003b58:	855e                	mv	a0,s7
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	99e080e7          	jalr	-1634(ra) # 800024f8 <either_copyout>
    80003b62:	05850d63          	beq	a0,s8,80003bbc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b66:	854a                	mv	a0,s2
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	5f4080e7          	jalr	1524(ra) # 8000315c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b70:	013d09bb          	addw	s3,s10,s3
    80003b74:	009d04bb          	addw	s1,s10,s1
    80003b78:	9a6e                	add	s4,s4,s11
    80003b7a:	0559f763          	bgeu	s3,s5,80003bc8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b7e:	00a4d59b          	srliw	a1,s1,0xa
    80003b82:	855a                	mv	a0,s6
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	8a2080e7          	jalr	-1886(ra) # 80003426 <bmap>
    80003b8c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b90:	cd85                	beqz	a1,80003bc8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b92:	000b2503          	lw	a0,0(s6)
    80003b96:	fffff097          	auipc	ra,0xfffff
    80003b9a:	496080e7          	jalr	1174(ra) # 8000302c <bread>
    80003b9e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba0:	3ff4f613          	andi	a2,s1,1023
    80003ba4:	40cc87bb          	subw	a5,s9,a2
    80003ba8:	413a873b          	subw	a4,s5,s3
    80003bac:	8d3e                	mv	s10,a5
    80003bae:	2781                	sext.w	a5,a5
    80003bb0:	0007069b          	sext.w	a3,a4
    80003bb4:	f8f6f9e3          	bgeu	a3,a5,80003b46 <readi+0x4c>
    80003bb8:	8d3a                	mv	s10,a4
    80003bba:	b771                	j	80003b46 <readi+0x4c>
      brelse(bp);
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	fffff097          	auipc	ra,0xfffff
    80003bc2:	59e080e7          	jalr	1438(ra) # 8000315c <brelse>
      tot = -1;
    80003bc6:	59fd                	li	s3,-1
  }
  return tot;
    80003bc8:	0009851b          	sext.w	a0,s3
}
    80003bcc:	70a6                	ld	ra,104(sp)
    80003bce:	7406                	ld	s0,96(sp)
    80003bd0:	64e6                	ld	s1,88(sp)
    80003bd2:	6946                	ld	s2,80(sp)
    80003bd4:	69a6                	ld	s3,72(sp)
    80003bd6:	6a06                	ld	s4,64(sp)
    80003bd8:	7ae2                	ld	s5,56(sp)
    80003bda:	7b42                	ld	s6,48(sp)
    80003bdc:	7ba2                	ld	s7,40(sp)
    80003bde:	7c02                	ld	s8,32(sp)
    80003be0:	6ce2                	ld	s9,24(sp)
    80003be2:	6d42                	ld	s10,16(sp)
    80003be4:	6da2                	ld	s11,8(sp)
    80003be6:	6165                	addi	sp,sp,112
    80003be8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bea:	89d6                	mv	s3,s5
    80003bec:	bff1                	j	80003bc8 <readi+0xce>
    return 0;
    80003bee:	4501                	li	a0,0
}
    80003bf0:	8082                	ret

0000000080003bf2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bf2:	457c                	lw	a5,76(a0)
    80003bf4:	10d7e863          	bltu	a5,a3,80003d04 <writei+0x112>
{
    80003bf8:	7159                	addi	sp,sp,-112
    80003bfa:	f486                	sd	ra,104(sp)
    80003bfc:	f0a2                	sd	s0,96(sp)
    80003bfe:	eca6                	sd	s1,88(sp)
    80003c00:	e8ca                	sd	s2,80(sp)
    80003c02:	e4ce                	sd	s3,72(sp)
    80003c04:	e0d2                	sd	s4,64(sp)
    80003c06:	fc56                	sd	s5,56(sp)
    80003c08:	f85a                	sd	s6,48(sp)
    80003c0a:	f45e                	sd	s7,40(sp)
    80003c0c:	f062                	sd	s8,32(sp)
    80003c0e:	ec66                	sd	s9,24(sp)
    80003c10:	e86a                	sd	s10,16(sp)
    80003c12:	e46e                	sd	s11,8(sp)
    80003c14:	1880                	addi	s0,sp,112
    80003c16:	8aaa                	mv	s5,a0
    80003c18:	8bae                	mv	s7,a1
    80003c1a:	8a32                	mv	s4,a2
    80003c1c:	8936                	mv	s2,a3
    80003c1e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c20:	00e687bb          	addw	a5,a3,a4
    80003c24:	0ed7e263          	bltu	a5,a3,80003d08 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c28:	00043737          	lui	a4,0x43
    80003c2c:	0ef76063          	bltu	a4,a5,80003d0c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c30:	0c0b0863          	beqz	s6,80003d00 <writei+0x10e>
    80003c34:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c36:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c3a:	5c7d                	li	s8,-1
    80003c3c:	a091                	j	80003c80 <writei+0x8e>
    80003c3e:	020d1d93          	slli	s11,s10,0x20
    80003c42:	020ddd93          	srli	s11,s11,0x20
    80003c46:	05848793          	addi	a5,s1,88
    80003c4a:	86ee                	mv	a3,s11
    80003c4c:	8652                	mv	a2,s4
    80003c4e:	85de                	mv	a1,s7
    80003c50:	953e                	add	a0,a0,a5
    80003c52:	fffff097          	auipc	ra,0xfffff
    80003c56:	8fc080e7          	jalr	-1796(ra) # 8000254e <either_copyin>
    80003c5a:	07850263          	beq	a0,s8,80003cbe <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c5e:	8526                	mv	a0,s1
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	780080e7          	jalr	1920(ra) # 800043e0 <log_write>
    brelse(bp);
    80003c68:	8526                	mv	a0,s1
    80003c6a:	fffff097          	auipc	ra,0xfffff
    80003c6e:	4f2080e7          	jalr	1266(ra) # 8000315c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c72:	013d09bb          	addw	s3,s10,s3
    80003c76:	012d093b          	addw	s2,s10,s2
    80003c7a:	9a6e                	add	s4,s4,s11
    80003c7c:	0569f663          	bgeu	s3,s6,80003cc8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c80:	00a9559b          	srliw	a1,s2,0xa
    80003c84:	8556                	mv	a0,s5
    80003c86:	fffff097          	auipc	ra,0xfffff
    80003c8a:	7a0080e7          	jalr	1952(ra) # 80003426 <bmap>
    80003c8e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c92:	c99d                	beqz	a1,80003cc8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c94:	000aa503          	lw	a0,0(s5) # 1000 <_entry-0x7ffff000>
    80003c98:	fffff097          	auipc	ra,0xfffff
    80003c9c:	394080e7          	jalr	916(ra) # 8000302c <bread>
    80003ca0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca2:	3ff97513          	andi	a0,s2,1023
    80003ca6:	40ac87bb          	subw	a5,s9,a0
    80003caa:	413b073b          	subw	a4,s6,s3
    80003cae:	8d3e                	mv	s10,a5
    80003cb0:	2781                	sext.w	a5,a5
    80003cb2:	0007069b          	sext.w	a3,a4
    80003cb6:	f8f6f4e3          	bgeu	a3,a5,80003c3e <writei+0x4c>
    80003cba:	8d3a                	mv	s10,a4
    80003cbc:	b749                	j	80003c3e <writei+0x4c>
      brelse(bp);
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	fffff097          	auipc	ra,0xfffff
    80003cc4:	49c080e7          	jalr	1180(ra) # 8000315c <brelse>
  }

  if(off > ip->size)
    80003cc8:	04caa783          	lw	a5,76(s5)
    80003ccc:	0127f463          	bgeu	a5,s2,80003cd4 <writei+0xe2>
    ip->size = off;
    80003cd0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cd4:	8556                	mv	a0,s5
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	aa6080e7          	jalr	-1370(ra) # 8000377c <iupdate>

  return tot;
    80003cde:	0009851b          	sext.w	a0,s3
}
    80003ce2:	70a6                	ld	ra,104(sp)
    80003ce4:	7406                	ld	s0,96(sp)
    80003ce6:	64e6                	ld	s1,88(sp)
    80003ce8:	6946                	ld	s2,80(sp)
    80003cea:	69a6                	ld	s3,72(sp)
    80003cec:	6a06                	ld	s4,64(sp)
    80003cee:	7ae2                	ld	s5,56(sp)
    80003cf0:	7b42                	ld	s6,48(sp)
    80003cf2:	7ba2                	ld	s7,40(sp)
    80003cf4:	7c02                	ld	s8,32(sp)
    80003cf6:	6ce2                	ld	s9,24(sp)
    80003cf8:	6d42                	ld	s10,16(sp)
    80003cfa:	6da2                	ld	s11,8(sp)
    80003cfc:	6165                	addi	sp,sp,112
    80003cfe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d00:	89da                	mv	s3,s6
    80003d02:	bfc9                	j	80003cd4 <writei+0xe2>
    return -1;
    80003d04:	557d                	li	a0,-1
}
    80003d06:	8082                	ret
    return -1;
    80003d08:	557d                	li	a0,-1
    80003d0a:	bfe1                	j	80003ce2 <writei+0xf0>
    return -1;
    80003d0c:	557d                	li	a0,-1
    80003d0e:	bfd1                	j	80003ce2 <writei+0xf0>

0000000080003d10 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d10:	1141                	addi	sp,sp,-16
    80003d12:	e406                	sd	ra,8(sp)
    80003d14:	e022                	sd	s0,0(sp)
    80003d16:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d18:	4639                	li	a2,14
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	088080e7          	jalr	136(ra) # 80000da2 <strncmp>
}
    80003d22:	60a2                	ld	ra,8(sp)
    80003d24:	6402                	ld	s0,0(sp)
    80003d26:	0141                	addi	sp,sp,16
    80003d28:	8082                	ret

0000000080003d2a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d2a:	7139                	addi	sp,sp,-64
    80003d2c:	fc06                	sd	ra,56(sp)
    80003d2e:	f822                	sd	s0,48(sp)
    80003d30:	f426                	sd	s1,40(sp)
    80003d32:	f04a                	sd	s2,32(sp)
    80003d34:	ec4e                	sd	s3,24(sp)
    80003d36:	e852                	sd	s4,16(sp)
    80003d38:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d3a:	04451703          	lh	a4,68(a0)
    80003d3e:	4785                	li	a5,1
    80003d40:	00f71a63          	bne	a4,a5,80003d54 <dirlookup+0x2a>
    80003d44:	892a                	mv	s2,a0
    80003d46:	89ae                	mv	s3,a1
    80003d48:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4a:	457c                	lw	a5,76(a0)
    80003d4c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d4e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d50:	e79d                	bnez	a5,80003d7e <dirlookup+0x54>
    80003d52:	a8a5                	j	80003dca <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d54:	00005517          	auipc	a0,0x5
    80003d58:	8cc50513          	addi	a0,a0,-1844 # 80008620 <syscalls+0x1b0>
    80003d5c:	ffffc097          	auipc	ra,0xffffc
    80003d60:	7e2080e7          	jalr	2018(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d64:	00005517          	auipc	a0,0x5
    80003d68:	8d450513          	addi	a0,a0,-1836 # 80008638 <syscalls+0x1c8>
    80003d6c:	ffffc097          	auipc	ra,0xffffc
    80003d70:	7d2080e7          	jalr	2002(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d74:	24c1                	addiw	s1,s1,16
    80003d76:	04c92783          	lw	a5,76(s2)
    80003d7a:	04f4f763          	bgeu	s1,a5,80003dc8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d7e:	4741                	li	a4,16
    80003d80:	86a6                	mv	a3,s1
    80003d82:	fc040613          	addi	a2,s0,-64
    80003d86:	4581                	li	a1,0
    80003d88:	854a                	mv	a0,s2
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	d70080e7          	jalr	-656(ra) # 80003afa <readi>
    80003d92:	47c1                	li	a5,16
    80003d94:	fcf518e3          	bne	a0,a5,80003d64 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d98:	fc045783          	lhu	a5,-64(s0)
    80003d9c:	dfe1                	beqz	a5,80003d74 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d9e:	fc240593          	addi	a1,s0,-62
    80003da2:	854e                	mv	a0,s3
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	f6c080e7          	jalr	-148(ra) # 80003d10 <namecmp>
    80003dac:	f561                	bnez	a0,80003d74 <dirlookup+0x4a>
      if(poff)
    80003dae:	000a0463          	beqz	s4,80003db6 <dirlookup+0x8c>
        *poff = off;
    80003db2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003db6:	fc045583          	lhu	a1,-64(s0)
    80003dba:	00092503          	lw	a0,0(s2)
    80003dbe:	fffff097          	auipc	ra,0xfffff
    80003dc2:	750080e7          	jalr	1872(ra) # 8000350e <iget>
    80003dc6:	a011                	j	80003dca <dirlookup+0xa0>
  return 0;
    80003dc8:	4501                	li	a0,0
}
    80003dca:	70e2                	ld	ra,56(sp)
    80003dcc:	7442                	ld	s0,48(sp)
    80003dce:	74a2                	ld	s1,40(sp)
    80003dd0:	7902                	ld	s2,32(sp)
    80003dd2:	69e2                	ld	s3,24(sp)
    80003dd4:	6a42                	ld	s4,16(sp)
    80003dd6:	6121                	addi	sp,sp,64
    80003dd8:	8082                	ret

0000000080003dda <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dda:	711d                	addi	sp,sp,-96
    80003ddc:	ec86                	sd	ra,88(sp)
    80003dde:	e8a2                	sd	s0,80(sp)
    80003de0:	e4a6                	sd	s1,72(sp)
    80003de2:	e0ca                	sd	s2,64(sp)
    80003de4:	fc4e                	sd	s3,56(sp)
    80003de6:	f852                	sd	s4,48(sp)
    80003de8:	f456                	sd	s5,40(sp)
    80003dea:	f05a                	sd	s6,32(sp)
    80003dec:	ec5e                	sd	s7,24(sp)
    80003dee:	e862                	sd	s8,16(sp)
    80003df0:	e466                	sd	s9,8(sp)
    80003df2:	1080                	addi	s0,sp,96
    80003df4:	84aa                	mv	s1,a0
    80003df6:	8aae                	mv	s5,a1
    80003df8:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dfa:	00054703          	lbu	a4,0(a0)
    80003dfe:	02f00793          	li	a5,47
    80003e02:	02f70363          	beq	a4,a5,80003e28 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e06:	ffffe097          	auipc	ra,0xffffe
    80003e0a:	bdc080e7          	jalr	-1060(ra) # 800019e2 <myproc>
    80003e0e:	15053503          	ld	a0,336(a0)
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	9f6080e7          	jalr	-1546(ra) # 80003808 <idup>
    80003e1a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e1c:	02f00913          	li	s2,47
  len = path - s;
    80003e20:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e22:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e24:	4b85                	li	s7,1
    80003e26:	a865                	j	80003ede <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e28:	4585                	li	a1,1
    80003e2a:	4505                	li	a0,1
    80003e2c:	fffff097          	auipc	ra,0xfffff
    80003e30:	6e2080e7          	jalr	1762(ra) # 8000350e <iget>
    80003e34:	89aa                	mv	s3,a0
    80003e36:	b7dd                	j	80003e1c <namex+0x42>
      iunlockput(ip);
    80003e38:	854e                	mv	a0,s3
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	c6e080e7          	jalr	-914(ra) # 80003aa8 <iunlockput>
      return 0;
    80003e42:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e44:	854e                	mv	a0,s3
    80003e46:	60e6                	ld	ra,88(sp)
    80003e48:	6446                	ld	s0,80(sp)
    80003e4a:	64a6                	ld	s1,72(sp)
    80003e4c:	6906                	ld	s2,64(sp)
    80003e4e:	79e2                	ld	s3,56(sp)
    80003e50:	7a42                	ld	s4,48(sp)
    80003e52:	7aa2                	ld	s5,40(sp)
    80003e54:	7b02                	ld	s6,32(sp)
    80003e56:	6be2                	ld	s7,24(sp)
    80003e58:	6c42                	ld	s8,16(sp)
    80003e5a:	6ca2                	ld	s9,8(sp)
    80003e5c:	6125                	addi	sp,sp,96
    80003e5e:	8082                	ret
      iunlock(ip);
    80003e60:	854e                	mv	a0,s3
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	aa6080e7          	jalr	-1370(ra) # 80003908 <iunlock>
      return ip;
    80003e6a:	bfe9                	j	80003e44 <namex+0x6a>
      iunlockput(ip);
    80003e6c:	854e                	mv	a0,s3
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	c3a080e7          	jalr	-966(ra) # 80003aa8 <iunlockput>
      return 0;
    80003e76:	89e6                	mv	s3,s9
    80003e78:	b7f1                	j	80003e44 <namex+0x6a>
  len = path - s;
    80003e7a:	40b48633          	sub	a2,s1,a1
    80003e7e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e82:	099c5463          	bge	s8,s9,80003f0a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e86:	4639                	li	a2,14
    80003e88:	8552                	mv	a0,s4
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	ea4080e7          	jalr	-348(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003e92:	0004c783          	lbu	a5,0(s1)
    80003e96:	01279763          	bne	a5,s2,80003ea4 <namex+0xca>
    path++;
    80003e9a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	ff278de3          	beq	a5,s2,80003e9a <namex+0xc0>
    ilock(ip);
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	9a0080e7          	jalr	-1632(ra) # 80003846 <ilock>
    if(ip->type != T_DIR){
    80003eae:	04499783          	lh	a5,68(s3)
    80003eb2:	f97793e3          	bne	a5,s7,80003e38 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eb6:	000a8563          	beqz	s5,80003ec0 <namex+0xe6>
    80003eba:	0004c783          	lbu	a5,0(s1)
    80003ebe:	d3cd                	beqz	a5,80003e60 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ec0:	865a                	mv	a2,s6
    80003ec2:	85d2                	mv	a1,s4
    80003ec4:	854e                	mv	a0,s3
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	e64080e7          	jalr	-412(ra) # 80003d2a <dirlookup>
    80003ece:	8caa                	mv	s9,a0
    80003ed0:	dd51                	beqz	a0,80003e6c <namex+0x92>
    iunlockput(ip);
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	bd4080e7          	jalr	-1068(ra) # 80003aa8 <iunlockput>
    ip = next;
    80003edc:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ede:	0004c783          	lbu	a5,0(s1)
    80003ee2:	05279763          	bne	a5,s2,80003f30 <namex+0x156>
    path++;
    80003ee6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ee8:	0004c783          	lbu	a5,0(s1)
    80003eec:	ff278de3          	beq	a5,s2,80003ee6 <namex+0x10c>
  if(*path == 0)
    80003ef0:	c79d                	beqz	a5,80003f1e <namex+0x144>
    path++;
    80003ef2:	85a6                	mv	a1,s1
  len = path - s;
    80003ef4:	8cda                	mv	s9,s6
    80003ef6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003ef8:	01278963          	beq	a5,s2,80003f0a <namex+0x130>
    80003efc:	dfbd                	beqz	a5,80003e7a <namex+0xa0>
    path++;
    80003efe:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f00:	0004c783          	lbu	a5,0(s1)
    80003f04:	ff279ce3          	bne	a5,s2,80003efc <namex+0x122>
    80003f08:	bf8d                	j	80003e7a <namex+0xa0>
    memmove(name, s, len);
    80003f0a:	2601                	sext.w	a2,a2
    80003f0c:	8552                	mv	a0,s4
    80003f0e:	ffffd097          	auipc	ra,0xffffd
    80003f12:	e20080e7          	jalr	-480(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003f16:	9cd2                	add	s9,s9,s4
    80003f18:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f1c:	bf9d                	j	80003e92 <namex+0xb8>
  if(nameiparent){
    80003f1e:	f20a83e3          	beqz	s5,80003e44 <namex+0x6a>
    iput(ip);
    80003f22:	854e                	mv	a0,s3
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	adc080e7          	jalr	-1316(ra) # 80003a00 <iput>
    return 0;
    80003f2c:	4981                	li	s3,0
    80003f2e:	bf19                	j	80003e44 <namex+0x6a>
  if(*path == 0)
    80003f30:	d7fd                	beqz	a5,80003f1e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f32:	0004c783          	lbu	a5,0(s1)
    80003f36:	85a6                	mv	a1,s1
    80003f38:	b7d1                	j	80003efc <namex+0x122>

0000000080003f3a <dirlink>:
{
    80003f3a:	7139                	addi	sp,sp,-64
    80003f3c:	fc06                	sd	ra,56(sp)
    80003f3e:	f822                	sd	s0,48(sp)
    80003f40:	f426                	sd	s1,40(sp)
    80003f42:	f04a                	sd	s2,32(sp)
    80003f44:	ec4e                	sd	s3,24(sp)
    80003f46:	e852                	sd	s4,16(sp)
    80003f48:	0080                	addi	s0,sp,64
    80003f4a:	892a                	mv	s2,a0
    80003f4c:	8a2e                	mv	s4,a1
    80003f4e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f50:	4601                	li	a2,0
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	dd8080e7          	jalr	-552(ra) # 80003d2a <dirlookup>
    80003f5a:	e93d                	bnez	a0,80003fd0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5c:	04c92483          	lw	s1,76(s2)
    80003f60:	c49d                	beqz	s1,80003f8e <dirlink+0x54>
    80003f62:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f64:	4741                	li	a4,16
    80003f66:	86a6                	mv	a3,s1
    80003f68:	fc040613          	addi	a2,s0,-64
    80003f6c:	4581                	li	a1,0
    80003f6e:	854a                	mv	a0,s2
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	b8a080e7          	jalr	-1142(ra) # 80003afa <readi>
    80003f78:	47c1                	li	a5,16
    80003f7a:	06f51163          	bne	a0,a5,80003fdc <dirlink+0xa2>
    if(de.inum == 0)
    80003f7e:	fc045783          	lhu	a5,-64(s0)
    80003f82:	c791                	beqz	a5,80003f8e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f84:	24c1                	addiw	s1,s1,16
    80003f86:	04c92783          	lw	a5,76(s2)
    80003f8a:	fcf4ede3          	bltu	s1,a5,80003f64 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f8e:	4639                	li	a2,14
    80003f90:	85d2                	mv	a1,s4
    80003f92:	fc240513          	addi	a0,s0,-62
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	e48080e7          	jalr	-440(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f9e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa2:	4741                	li	a4,16
    80003fa4:	86a6                	mv	a3,s1
    80003fa6:	fc040613          	addi	a2,s0,-64
    80003faa:	4581                	li	a1,0
    80003fac:	854a                	mv	a0,s2
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	c44080e7          	jalr	-956(ra) # 80003bf2 <writei>
    80003fb6:	1541                	addi	a0,a0,-16
    80003fb8:	00a03533          	snez	a0,a0
    80003fbc:	40a00533          	neg	a0,a0
}
    80003fc0:	70e2                	ld	ra,56(sp)
    80003fc2:	7442                	ld	s0,48(sp)
    80003fc4:	74a2                	ld	s1,40(sp)
    80003fc6:	7902                	ld	s2,32(sp)
    80003fc8:	69e2                	ld	s3,24(sp)
    80003fca:	6a42                	ld	s4,16(sp)
    80003fcc:	6121                	addi	sp,sp,64
    80003fce:	8082                	ret
    iput(ip);
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	a30080e7          	jalr	-1488(ra) # 80003a00 <iput>
    return -1;
    80003fd8:	557d                	li	a0,-1
    80003fda:	b7dd                	j	80003fc0 <dirlink+0x86>
      panic("dirlink read");
    80003fdc:	00004517          	auipc	a0,0x4
    80003fe0:	66c50513          	addi	a0,a0,1644 # 80008648 <syscalls+0x1d8>
    80003fe4:	ffffc097          	auipc	ra,0xffffc
    80003fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>

0000000080003fec <namei>:

struct inode*
namei(char *path)
{
    80003fec:	1101                	addi	sp,sp,-32
    80003fee:	ec06                	sd	ra,24(sp)
    80003ff0:	e822                	sd	s0,16(sp)
    80003ff2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ff4:	fe040613          	addi	a2,s0,-32
    80003ff8:	4581                	li	a1,0
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	de0080e7          	jalr	-544(ra) # 80003dda <namex>
}
    80004002:	60e2                	ld	ra,24(sp)
    80004004:	6442                	ld	s0,16(sp)
    80004006:	6105                	addi	sp,sp,32
    80004008:	8082                	ret

000000008000400a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000400a:	1141                	addi	sp,sp,-16
    8000400c:	e406                	sd	ra,8(sp)
    8000400e:	e022                	sd	s0,0(sp)
    80004010:	0800                	addi	s0,sp,16
    80004012:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004014:	4585                	li	a1,1
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	dc4080e7          	jalr	-572(ra) # 80003dda <namex>
}
    8000401e:	60a2                	ld	ra,8(sp)
    80004020:	6402                	ld	s0,0(sp)
    80004022:	0141                	addi	sp,sp,16
    80004024:	8082                	ret

0000000080004026 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004026:	1101                	addi	sp,sp,-32
    80004028:	ec06                	sd	ra,24(sp)
    8000402a:	e822                	sd	s0,16(sp)
    8000402c:	e426                	sd	s1,8(sp)
    8000402e:	e04a                	sd	s2,0(sp)
    80004030:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004032:	0001d917          	auipc	s2,0x1d
    80004036:	66e90913          	addi	s2,s2,1646 # 800216a0 <log>
    8000403a:	01892583          	lw	a1,24(s2)
    8000403e:	02892503          	lw	a0,40(s2)
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	fea080e7          	jalr	-22(ra) # 8000302c <bread>
    8000404a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000404c:	02c92683          	lw	a3,44(s2)
    80004050:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004052:	02d05763          	blez	a3,80004080 <write_head+0x5a>
    80004056:	0001d797          	auipc	a5,0x1d
    8000405a:	67a78793          	addi	a5,a5,1658 # 800216d0 <log+0x30>
    8000405e:	05c50713          	addi	a4,a0,92
    80004062:	36fd                	addiw	a3,a3,-1
    80004064:	1682                	slli	a3,a3,0x20
    80004066:	9281                	srli	a3,a3,0x20
    80004068:	068a                	slli	a3,a3,0x2
    8000406a:	0001d617          	auipc	a2,0x1d
    8000406e:	66a60613          	addi	a2,a2,1642 # 800216d4 <log+0x34>
    80004072:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004074:	4390                	lw	a2,0(a5)
    80004076:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004078:	0791                	addi	a5,a5,4
    8000407a:	0711                	addi	a4,a4,4
    8000407c:	fed79ce3          	bne	a5,a3,80004074 <write_head+0x4e>
  }
  bwrite(buf);
    80004080:	8526                	mv	a0,s1
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	09c080e7          	jalr	156(ra) # 8000311e <bwrite>
  brelse(buf);
    8000408a:	8526                	mv	a0,s1
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	0d0080e7          	jalr	208(ra) # 8000315c <brelse>
}
    80004094:	60e2                	ld	ra,24(sp)
    80004096:	6442                	ld	s0,16(sp)
    80004098:	64a2                	ld	s1,8(sp)
    8000409a:	6902                	ld	s2,0(sp)
    8000409c:	6105                	addi	sp,sp,32
    8000409e:	8082                	ret

00000000800040a0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a0:	0001d797          	auipc	a5,0x1d
    800040a4:	62c7a783          	lw	a5,1580(a5) # 800216cc <log+0x2c>
    800040a8:	0af05d63          	blez	a5,80004162 <install_trans+0xc2>
{
    800040ac:	7139                	addi	sp,sp,-64
    800040ae:	fc06                	sd	ra,56(sp)
    800040b0:	f822                	sd	s0,48(sp)
    800040b2:	f426                	sd	s1,40(sp)
    800040b4:	f04a                	sd	s2,32(sp)
    800040b6:	ec4e                	sd	s3,24(sp)
    800040b8:	e852                	sd	s4,16(sp)
    800040ba:	e456                	sd	s5,8(sp)
    800040bc:	e05a                	sd	s6,0(sp)
    800040be:	0080                	addi	s0,sp,64
    800040c0:	8b2a                	mv	s6,a0
    800040c2:	0001da97          	auipc	s5,0x1d
    800040c6:	60ea8a93          	addi	s5,s5,1550 # 800216d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ca:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040cc:	0001d997          	auipc	s3,0x1d
    800040d0:	5d498993          	addi	s3,s3,1492 # 800216a0 <log>
    800040d4:	a00d                	j	800040f6 <install_trans+0x56>
    brelse(lbuf);
    800040d6:	854a                	mv	a0,s2
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	084080e7          	jalr	132(ra) # 8000315c <brelse>
    brelse(dbuf);
    800040e0:	8526                	mv	a0,s1
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	07a080e7          	jalr	122(ra) # 8000315c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ea:	2a05                	addiw	s4,s4,1
    800040ec:	0a91                	addi	s5,s5,4
    800040ee:	02c9a783          	lw	a5,44(s3)
    800040f2:	04fa5e63          	bge	s4,a5,8000414e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040f6:	0189a583          	lw	a1,24(s3)
    800040fa:	014585bb          	addw	a1,a1,s4
    800040fe:	2585                	addiw	a1,a1,1
    80004100:	0289a503          	lw	a0,40(s3)
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	f28080e7          	jalr	-216(ra) # 8000302c <bread>
    8000410c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000410e:	000aa583          	lw	a1,0(s5)
    80004112:	0289a503          	lw	a0,40(s3)
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	f16080e7          	jalr	-234(ra) # 8000302c <bread>
    8000411e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004120:	40000613          	li	a2,1024
    80004124:	05890593          	addi	a1,s2,88
    80004128:	05850513          	addi	a0,a0,88
    8000412c:	ffffd097          	auipc	ra,0xffffd
    80004130:	c02080e7          	jalr	-1022(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004134:	8526                	mv	a0,s1
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	fe8080e7          	jalr	-24(ra) # 8000311e <bwrite>
    if(recovering == 0)
    8000413e:	f80b1ce3          	bnez	s6,800040d6 <install_trans+0x36>
      bunpin(dbuf);
    80004142:	8526                	mv	a0,s1
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	0f2080e7          	jalr	242(ra) # 80003236 <bunpin>
    8000414c:	b769                	j	800040d6 <install_trans+0x36>
}
    8000414e:	70e2                	ld	ra,56(sp)
    80004150:	7442                	ld	s0,48(sp)
    80004152:	74a2                	ld	s1,40(sp)
    80004154:	7902                	ld	s2,32(sp)
    80004156:	69e2                	ld	s3,24(sp)
    80004158:	6a42                	ld	s4,16(sp)
    8000415a:	6aa2                	ld	s5,8(sp)
    8000415c:	6b02                	ld	s6,0(sp)
    8000415e:	6121                	addi	sp,sp,64
    80004160:	8082                	ret
    80004162:	8082                	ret

0000000080004164 <initlog>:
{
    80004164:	7179                	addi	sp,sp,-48
    80004166:	f406                	sd	ra,40(sp)
    80004168:	f022                	sd	s0,32(sp)
    8000416a:	ec26                	sd	s1,24(sp)
    8000416c:	e84a                	sd	s2,16(sp)
    8000416e:	e44e                	sd	s3,8(sp)
    80004170:	1800                	addi	s0,sp,48
    80004172:	892a                	mv	s2,a0
    80004174:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004176:	0001d497          	auipc	s1,0x1d
    8000417a:	52a48493          	addi	s1,s1,1322 # 800216a0 <log>
    8000417e:	00004597          	auipc	a1,0x4
    80004182:	4da58593          	addi	a1,a1,1242 # 80008658 <syscalls+0x1e8>
    80004186:	8526                	mv	a0,s1
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	9be080e7          	jalr	-1602(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004190:	0149a583          	lw	a1,20(s3)
    80004194:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004196:	0109a783          	lw	a5,16(s3)
    8000419a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000419c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041a0:	854a                	mv	a0,s2
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	e8a080e7          	jalr	-374(ra) # 8000302c <bread>
  log.lh.n = lh->n;
    800041aa:	4d34                	lw	a3,88(a0)
    800041ac:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041ae:	02d05563          	blez	a3,800041d8 <initlog+0x74>
    800041b2:	05c50793          	addi	a5,a0,92
    800041b6:	0001d717          	auipc	a4,0x1d
    800041ba:	51a70713          	addi	a4,a4,1306 # 800216d0 <log+0x30>
    800041be:	36fd                	addiw	a3,a3,-1
    800041c0:	1682                	slli	a3,a3,0x20
    800041c2:	9281                	srli	a3,a3,0x20
    800041c4:	068a                	slli	a3,a3,0x2
    800041c6:	06050613          	addi	a2,a0,96
    800041ca:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041cc:	4390                	lw	a2,0(a5)
    800041ce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d0:	0791                	addi	a5,a5,4
    800041d2:	0711                	addi	a4,a4,4
    800041d4:	fed79ce3          	bne	a5,a3,800041cc <initlog+0x68>
  brelse(buf);
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	f84080e7          	jalr	-124(ra) # 8000315c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041e0:	4505                	li	a0,1
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	ebe080e7          	jalr	-322(ra) # 800040a0 <install_trans>
  log.lh.n = 0;
    800041ea:	0001d797          	auipc	a5,0x1d
    800041ee:	4e07a123          	sw	zero,1250(a5) # 800216cc <log+0x2c>
  write_head(); // clear the log
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	e34080e7          	jalr	-460(ra) # 80004026 <write_head>
}
    800041fa:	70a2                	ld	ra,40(sp)
    800041fc:	7402                	ld	s0,32(sp)
    800041fe:	64e2                	ld	s1,24(sp)
    80004200:	6942                	ld	s2,16(sp)
    80004202:	69a2                	ld	s3,8(sp)
    80004204:	6145                	addi	sp,sp,48
    80004206:	8082                	ret

0000000080004208 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004208:	1101                	addi	sp,sp,-32
    8000420a:	ec06                	sd	ra,24(sp)
    8000420c:	e822                	sd	s0,16(sp)
    8000420e:	e426                	sd	s1,8(sp)
    80004210:	e04a                	sd	s2,0(sp)
    80004212:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004214:	0001d517          	auipc	a0,0x1d
    80004218:	48c50513          	addi	a0,a0,1164 # 800216a0 <log>
    8000421c:	ffffd097          	auipc	ra,0xffffd
    80004220:	9ba080e7          	jalr	-1606(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004224:	0001d497          	auipc	s1,0x1d
    80004228:	47c48493          	addi	s1,s1,1148 # 800216a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000422c:	4979                	li	s2,30
    8000422e:	a039                	j	8000423c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004230:	85a6                	mv	a1,s1
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	ebc080e7          	jalr	-324(ra) # 800020f0 <sleep>
    if(log.committing){
    8000423c:	50dc                	lw	a5,36(s1)
    8000423e:	fbed                	bnez	a5,80004230 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004240:	509c                	lw	a5,32(s1)
    80004242:	0017871b          	addiw	a4,a5,1
    80004246:	0007069b          	sext.w	a3,a4
    8000424a:	0027179b          	slliw	a5,a4,0x2
    8000424e:	9fb9                	addw	a5,a5,a4
    80004250:	0017979b          	slliw	a5,a5,0x1
    80004254:	54d8                	lw	a4,44(s1)
    80004256:	9fb9                	addw	a5,a5,a4
    80004258:	00f95963          	bge	s2,a5,8000426a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000425c:	85a6                	mv	a1,s1
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffe097          	auipc	ra,0xffffe
    80004264:	e90080e7          	jalr	-368(ra) # 800020f0 <sleep>
    80004268:	bfd1                	j	8000423c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000426a:	0001d517          	auipc	a0,0x1d
    8000426e:	43650513          	addi	a0,a0,1078 # 800216a0 <log>
    80004272:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004274:	ffffd097          	auipc	ra,0xffffd
    80004278:	a16080e7          	jalr	-1514(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000427c:	60e2                	ld	ra,24(sp)
    8000427e:	6442                	ld	s0,16(sp)
    80004280:	64a2                	ld	s1,8(sp)
    80004282:	6902                	ld	s2,0(sp)
    80004284:	6105                	addi	sp,sp,32
    80004286:	8082                	ret

0000000080004288 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004288:	7139                	addi	sp,sp,-64
    8000428a:	fc06                	sd	ra,56(sp)
    8000428c:	f822                	sd	s0,48(sp)
    8000428e:	f426                	sd	s1,40(sp)
    80004290:	f04a                	sd	s2,32(sp)
    80004292:	ec4e                	sd	s3,24(sp)
    80004294:	e852                	sd	s4,16(sp)
    80004296:	e456                	sd	s5,8(sp)
    80004298:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000429a:	0001d497          	auipc	s1,0x1d
    8000429e:	40648493          	addi	s1,s1,1030 # 800216a0 <log>
    800042a2:	8526                	mv	a0,s1
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	932080e7          	jalr	-1742(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800042ac:	509c                	lw	a5,32(s1)
    800042ae:	37fd                	addiw	a5,a5,-1
    800042b0:	0007891b          	sext.w	s2,a5
    800042b4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042b6:	50dc                	lw	a5,36(s1)
    800042b8:	e7b9                	bnez	a5,80004306 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042ba:	04091e63          	bnez	s2,80004316 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042be:	0001d497          	auipc	s1,0x1d
    800042c2:	3e248493          	addi	s1,s1,994 # 800216a0 <log>
    800042c6:	4785                	li	a5,1
    800042c8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	9be080e7          	jalr	-1602(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042d4:	54dc                	lw	a5,44(s1)
    800042d6:	06f04763          	bgtz	a5,80004344 <end_op+0xbc>
    acquire(&log.lock);
    800042da:	0001d497          	auipc	s1,0x1d
    800042de:	3c648493          	addi	s1,s1,966 # 800216a0 <log>
    800042e2:	8526                	mv	a0,s1
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	8f2080e7          	jalr	-1806(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800042ec:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042f0:	8526                	mv	a0,s1
    800042f2:	ffffe097          	auipc	ra,0xffffe
    800042f6:	e62080e7          	jalr	-414(ra) # 80002154 <wakeup>
    release(&log.lock);
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	98e080e7          	jalr	-1650(ra) # 80000c8a <release>
}
    80004304:	a03d                	j	80004332 <end_op+0xaa>
    panic("log.committing");
    80004306:	00004517          	auipc	a0,0x4
    8000430a:	35a50513          	addi	a0,a0,858 # 80008660 <syscalls+0x1f0>
    8000430e:	ffffc097          	auipc	ra,0xffffc
    80004312:	230080e7          	jalr	560(ra) # 8000053e <panic>
    wakeup(&log);
    80004316:	0001d497          	auipc	s1,0x1d
    8000431a:	38a48493          	addi	s1,s1,906 # 800216a0 <log>
    8000431e:	8526                	mv	a0,s1
    80004320:	ffffe097          	auipc	ra,0xffffe
    80004324:	e34080e7          	jalr	-460(ra) # 80002154 <wakeup>
  release(&log.lock);
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	960080e7          	jalr	-1696(ra) # 80000c8a <release>
}
    80004332:	70e2                	ld	ra,56(sp)
    80004334:	7442                	ld	s0,48(sp)
    80004336:	74a2                	ld	s1,40(sp)
    80004338:	7902                	ld	s2,32(sp)
    8000433a:	69e2                	ld	s3,24(sp)
    8000433c:	6a42                	ld	s4,16(sp)
    8000433e:	6aa2                	ld	s5,8(sp)
    80004340:	6121                	addi	sp,sp,64
    80004342:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004344:	0001da97          	auipc	s5,0x1d
    80004348:	38ca8a93          	addi	s5,s5,908 # 800216d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000434c:	0001da17          	auipc	s4,0x1d
    80004350:	354a0a13          	addi	s4,s4,852 # 800216a0 <log>
    80004354:	018a2583          	lw	a1,24(s4)
    80004358:	012585bb          	addw	a1,a1,s2
    8000435c:	2585                	addiw	a1,a1,1
    8000435e:	028a2503          	lw	a0,40(s4)
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	cca080e7          	jalr	-822(ra) # 8000302c <bread>
    8000436a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000436c:	000aa583          	lw	a1,0(s5)
    80004370:	028a2503          	lw	a0,40(s4)
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	cb8080e7          	jalr	-840(ra) # 8000302c <bread>
    8000437c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000437e:	40000613          	li	a2,1024
    80004382:	05850593          	addi	a1,a0,88
    80004386:	05848513          	addi	a0,s1,88
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	9a4080e7          	jalr	-1628(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004392:	8526                	mv	a0,s1
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	d8a080e7          	jalr	-630(ra) # 8000311e <bwrite>
    brelse(from);
    8000439c:	854e                	mv	a0,s3
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	dbe080e7          	jalr	-578(ra) # 8000315c <brelse>
    brelse(to);
    800043a6:	8526                	mv	a0,s1
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	db4080e7          	jalr	-588(ra) # 8000315c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b0:	2905                	addiw	s2,s2,1
    800043b2:	0a91                	addi	s5,s5,4
    800043b4:	02ca2783          	lw	a5,44(s4)
    800043b8:	f8f94ee3          	blt	s2,a5,80004354 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	c6a080e7          	jalr	-918(ra) # 80004026 <write_head>
    install_trans(0); // Now install writes to home locations
    800043c4:	4501                	li	a0,0
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	cda080e7          	jalr	-806(ra) # 800040a0 <install_trans>
    log.lh.n = 0;
    800043ce:	0001d797          	auipc	a5,0x1d
    800043d2:	2e07af23          	sw	zero,766(a5) # 800216cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	c50080e7          	jalr	-944(ra) # 80004026 <write_head>
    800043de:	bdf5                	j	800042da <end_op+0x52>

00000000800043e0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043e0:	1101                	addi	sp,sp,-32
    800043e2:	ec06                	sd	ra,24(sp)
    800043e4:	e822                	sd	s0,16(sp)
    800043e6:	e426                	sd	s1,8(sp)
    800043e8:	e04a                	sd	s2,0(sp)
    800043ea:	1000                	addi	s0,sp,32
    800043ec:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043ee:	0001d917          	auipc	s2,0x1d
    800043f2:	2b290913          	addi	s2,s2,690 # 800216a0 <log>
    800043f6:	854a                	mv	a0,s2
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004400:	02c92603          	lw	a2,44(s2)
    80004404:	47f5                	li	a5,29
    80004406:	06c7c563          	blt	a5,a2,80004470 <log_write+0x90>
    8000440a:	0001d797          	auipc	a5,0x1d
    8000440e:	2b27a783          	lw	a5,690(a5) # 800216bc <log+0x1c>
    80004412:	37fd                	addiw	a5,a5,-1
    80004414:	04f65e63          	bge	a2,a5,80004470 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004418:	0001d797          	auipc	a5,0x1d
    8000441c:	2a87a783          	lw	a5,680(a5) # 800216c0 <log+0x20>
    80004420:	06f05063          	blez	a5,80004480 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004424:	4781                	li	a5,0
    80004426:	06c05563          	blez	a2,80004490 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000442a:	44cc                	lw	a1,12(s1)
    8000442c:	0001d717          	auipc	a4,0x1d
    80004430:	2a470713          	addi	a4,a4,676 # 800216d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004434:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004436:	4314                	lw	a3,0(a4)
    80004438:	04b68c63          	beq	a3,a1,80004490 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000443c:	2785                	addiw	a5,a5,1
    8000443e:	0711                	addi	a4,a4,4
    80004440:	fef61be3          	bne	a2,a5,80004436 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004444:	0621                	addi	a2,a2,8
    80004446:	060a                	slli	a2,a2,0x2
    80004448:	0001d797          	auipc	a5,0x1d
    8000444c:	25878793          	addi	a5,a5,600 # 800216a0 <log>
    80004450:	963e                	add	a2,a2,a5
    80004452:	44dc                	lw	a5,12(s1)
    80004454:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004456:	8526                	mv	a0,s1
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	da2080e7          	jalr	-606(ra) # 800031fa <bpin>
    log.lh.n++;
    80004460:	0001d717          	auipc	a4,0x1d
    80004464:	24070713          	addi	a4,a4,576 # 800216a0 <log>
    80004468:	575c                	lw	a5,44(a4)
    8000446a:	2785                	addiw	a5,a5,1
    8000446c:	d75c                	sw	a5,44(a4)
    8000446e:	a835                	j	800044aa <log_write+0xca>
    panic("too big a transaction");
    80004470:	00004517          	auipc	a0,0x4
    80004474:	20050513          	addi	a0,a0,512 # 80008670 <syscalls+0x200>
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	0c6080e7          	jalr	198(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004480:	00004517          	auipc	a0,0x4
    80004484:	20850513          	addi	a0,a0,520 # 80008688 <syscalls+0x218>
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	0b6080e7          	jalr	182(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004490:	00878713          	addi	a4,a5,8
    80004494:	00271693          	slli	a3,a4,0x2
    80004498:	0001d717          	auipc	a4,0x1d
    8000449c:	20870713          	addi	a4,a4,520 # 800216a0 <log>
    800044a0:	9736                	add	a4,a4,a3
    800044a2:	44d4                	lw	a3,12(s1)
    800044a4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044a6:	faf608e3          	beq	a2,a5,80004456 <log_write+0x76>
  }
  release(&log.lock);
    800044aa:	0001d517          	auipc	a0,0x1d
    800044ae:	1f650513          	addi	a0,a0,502 # 800216a0 <log>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	7d8080e7          	jalr	2008(ra) # 80000c8a <release>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	64a2                	ld	s1,8(sp)
    800044c0:	6902                	ld	s2,0(sp)
    800044c2:	6105                	addi	sp,sp,32
    800044c4:	8082                	ret

00000000800044c6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044c6:	1101                	addi	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	e426                	sd	s1,8(sp)
    800044ce:	e04a                	sd	s2,0(sp)
    800044d0:	1000                	addi	s0,sp,32
    800044d2:	84aa                	mv	s1,a0
    800044d4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044d6:	00004597          	auipc	a1,0x4
    800044da:	1d258593          	addi	a1,a1,466 # 800086a8 <syscalls+0x238>
    800044de:	0521                	addi	a0,a0,8
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	666080e7          	jalr	1638(ra) # 80000b46 <initlock>
  lk->name = name;
    800044e8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f0:	0204a423          	sw	zero,40(s1)
}
    800044f4:	60e2                	ld	ra,24(sp)
    800044f6:	6442                	ld	s0,16(sp)
    800044f8:	64a2                	ld	s1,8(sp)
    800044fa:	6902                	ld	s2,0(sp)
    800044fc:	6105                	addi	sp,sp,32
    800044fe:	8082                	ret

0000000080004500 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004500:	1101                	addi	sp,sp,-32
    80004502:	ec06                	sd	ra,24(sp)
    80004504:	e822                	sd	s0,16(sp)
    80004506:	e426                	sd	s1,8(sp)
    80004508:	e04a                	sd	s2,0(sp)
    8000450a:	1000                	addi	s0,sp,32
    8000450c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000450e:	00850913          	addi	s2,a0,8
    80004512:	854a                	mv	a0,s2
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	6c2080e7          	jalr	1730(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000451c:	409c                	lw	a5,0(s1)
    8000451e:	cb89                	beqz	a5,80004530 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004520:	85ca                	mv	a1,s2
    80004522:	8526                	mv	a0,s1
    80004524:	ffffe097          	auipc	ra,0xffffe
    80004528:	bcc080e7          	jalr	-1076(ra) # 800020f0 <sleep>
  while (lk->locked) {
    8000452c:	409c                	lw	a5,0(s1)
    8000452e:	fbed                	bnez	a5,80004520 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004530:	4785                	li	a5,1
    80004532:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004534:	ffffd097          	auipc	ra,0xffffd
    80004538:	4ae080e7          	jalr	1198(ra) # 800019e2 <myproc>
    8000453c:	591c                	lw	a5,48(a0)
    8000453e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004540:	854a                	mv	a0,s2
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	748080e7          	jalr	1864(ra) # 80000c8a <release>
}
    8000454a:	60e2                	ld	ra,24(sp)
    8000454c:	6442                	ld	s0,16(sp)
    8000454e:	64a2                	ld	s1,8(sp)
    80004550:	6902                	ld	s2,0(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004556:	1101                	addi	sp,sp,-32
    80004558:	ec06                	sd	ra,24(sp)
    8000455a:	e822                	sd	s0,16(sp)
    8000455c:	e426                	sd	s1,8(sp)
    8000455e:	e04a                	sd	s2,0(sp)
    80004560:	1000                	addi	s0,sp,32
    80004562:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004564:	00850913          	addi	s2,a0,8
    80004568:	854a                	mv	a0,s2
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	66c080e7          	jalr	1644(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004572:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004576:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000457a:	8526                	mv	a0,s1
    8000457c:	ffffe097          	auipc	ra,0xffffe
    80004580:	bd8080e7          	jalr	-1064(ra) # 80002154 <wakeup>
  release(&lk->lk);
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	704080e7          	jalr	1796(ra) # 80000c8a <release>
}
    8000458e:	60e2                	ld	ra,24(sp)
    80004590:	6442                	ld	s0,16(sp)
    80004592:	64a2                	ld	s1,8(sp)
    80004594:	6902                	ld	s2,0(sp)
    80004596:	6105                	addi	sp,sp,32
    80004598:	8082                	ret

000000008000459a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000459a:	7179                	addi	sp,sp,-48
    8000459c:	f406                	sd	ra,40(sp)
    8000459e:	f022                	sd	s0,32(sp)
    800045a0:	ec26                	sd	s1,24(sp)
    800045a2:	e84a                	sd	s2,16(sp)
    800045a4:	e44e                	sd	s3,8(sp)
    800045a6:	1800                	addi	s0,sp,48
    800045a8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045aa:	00850913          	addi	s2,a0,8
    800045ae:	854a                	mv	a0,s2
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	626080e7          	jalr	1574(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b8:	409c                	lw	a5,0(s1)
    800045ba:	ef99                	bnez	a5,800045d8 <holdingsleep+0x3e>
    800045bc:	4481                	li	s1,0
  release(&lk->lk);
    800045be:	854a                	mv	a0,s2
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6ca080e7          	jalr	1738(ra) # 80000c8a <release>
  return r;
}
    800045c8:	8526                	mv	a0,s1
    800045ca:	70a2                	ld	ra,40(sp)
    800045cc:	7402                	ld	s0,32(sp)
    800045ce:	64e2                	ld	s1,24(sp)
    800045d0:	6942                	ld	s2,16(sp)
    800045d2:	69a2                	ld	s3,8(sp)
    800045d4:	6145                	addi	sp,sp,48
    800045d6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d8:	0284a983          	lw	s3,40(s1)
    800045dc:	ffffd097          	auipc	ra,0xffffd
    800045e0:	406080e7          	jalr	1030(ra) # 800019e2 <myproc>
    800045e4:	5904                	lw	s1,48(a0)
    800045e6:	413484b3          	sub	s1,s1,s3
    800045ea:	0014b493          	seqz	s1,s1
    800045ee:	bfc1                	j	800045be <holdingsleep+0x24>

00000000800045f0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045f0:	1141                	addi	sp,sp,-16
    800045f2:	e406                	sd	ra,8(sp)
    800045f4:	e022                	sd	s0,0(sp)
    800045f6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045f8:	00004597          	auipc	a1,0x4
    800045fc:	0c058593          	addi	a1,a1,192 # 800086b8 <syscalls+0x248>
    80004600:	0001d517          	auipc	a0,0x1d
    80004604:	1e850513          	addi	a0,a0,488 # 800217e8 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	53e080e7          	jalr	1342(ra) # 80000b46 <initlock>
}
    80004610:	60a2                	ld	ra,8(sp)
    80004612:	6402                	ld	s0,0(sp)
    80004614:	0141                	addi	sp,sp,16
    80004616:	8082                	ret

0000000080004618 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004618:	1101                	addi	sp,sp,-32
    8000461a:	ec06                	sd	ra,24(sp)
    8000461c:	e822                	sd	s0,16(sp)
    8000461e:	e426                	sd	s1,8(sp)
    80004620:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004622:	0001d517          	auipc	a0,0x1d
    80004626:	1c650513          	addi	a0,a0,454 # 800217e8 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	5ac080e7          	jalr	1452(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004632:	0001d497          	auipc	s1,0x1d
    80004636:	1ce48493          	addi	s1,s1,462 # 80021800 <ftable+0x18>
    8000463a:	0001e717          	auipc	a4,0x1e
    8000463e:	16670713          	addi	a4,a4,358 # 800227a0 <disk>
    if(f->ref == 0){
    80004642:	40dc                	lw	a5,4(s1)
    80004644:	cf99                	beqz	a5,80004662 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004646:	02848493          	addi	s1,s1,40
    8000464a:	fee49ce3          	bne	s1,a4,80004642 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000464e:	0001d517          	auipc	a0,0x1d
    80004652:	19a50513          	addi	a0,a0,410 # 800217e8 <ftable>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	634080e7          	jalr	1588(ra) # 80000c8a <release>
  return 0;
    8000465e:	4481                	li	s1,0
    80004660:	a819                	j	80004676 <filealloc+0x5e>
      f->ref = 1;
    80004662:	4785                	li	a5,1
    80004664:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004666:	0001d517          	auipc	a0,0x1d
    8000466a:	18250513          	addi	a0,a0,386 # 800217e8 <ftable>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	61c080e7          	jalr	1564(ra) # 80000c8a <release>
}
    80004676:	8526                	mv	a0,s1
    80004678:	60e2                	ld	ra,24(sp)
    8000467a:	6442                	ld	s0,16(sp)
    8000467c:	64a2                	ld	s1,8(sp)
    8000467e:	6105                	addi	sp,sp,32
    80004680:	8082                	ret

0000000080004682 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004682:	1101                	addi	sp,sp,-32
    80004684:	ec06                	sd	ra,24(sp)
    80004686:	e822                	sd	s0,16(sp)
    80004688:	e426                	sd	s1,8(sp)
    8000468a:	1000                	addi	s0,sp,32
    8000468c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000468e:	0001d517          	auipc	a0,0x1d
    80004692:	15a50513          	addi	a0,a0,346 # 800217e8 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	540080e7          	jalr	1344(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000469e:	40dc                	lw	a5,4(s1)
    800046a0:	02f05263          	blez	a5,800046c4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046a4:	2785                	addiw	a5,a5,1
    800046a6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046a8:	0001d517          	auipc	a0,0x1d
    800046ac:	14050513          	addi	a0,a0,320 # 800217e8 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5da080e7          	jalr	1498(ra) # 80000c8a <release>
  return f;
}
    800046b8:	8526                	mv	a0,s1
    800046ba:	60e2                	ld	ra,24(sp)
    800046bc:	6442                	ld	s0,16(sp)
    800046be:	64a2                	ld	s1,8(sp)
    800046c0:	6105                	addi	sp,sp,32
    800046c2:	8082                	ret
    panic("filedup");
    800046c4:	00004517          	auipc	a0,0x4
    800046c8:	ffc50513          	addi	a0,a0,-4 # 800086c0 <syscalls+0x250>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>

00000000800046d4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046d4:	7139                	addi	sp,sp,-64
    800046d6:	fc06                	sd	ra,56(sp)
    800046d8:	f822                	sd	s0,48(sp)
    800046da:	f426                	sd	s1,40(sp)
    800046dc:	f04a                	sd	s2,32(sp)
    800046de:	ec4e                	sd	s3,24(sp)
    800046e0:	e852                	sd	s4,16(sp)
    800046e2:	e456                	sd	s5,8(sp)
    800046e4:	0080                	addi	s0,sp,64
    800046e6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	10050513          	addi	a0,a0,256 # 800217e8 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	4e6080e7          	jalr	1254(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046f8:	40dc                	lw	a5,4(s1)
    800046fa:	06f05163          	blez	a5,8000475c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046fe:	37fd                	addiw	a5,a5,-1
    80004700:	0007871b          	sext.w	a4,a5
    80004704:	c0dc                	sw	a5,4(s1)
    80004706:	06e04363          	bgtz	a4,8000476c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000470a:	0004a903          	lw	s2,0(s1)
    8000470e:	0094ca83          	lbu	s5,9(s1)
    80004712:	0104ba03          	ld	s4,16(s1)
    80004716:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000471a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000471e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004722:	0001d517          	auipc	a0,0x1d
    80004726:	0c650513          	addi	a0,a0,198 # 800217e8 <ftable>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	560080e7          	jalr	1376(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004732:	4785                	li	a5,1
    80004734:	04f90d63          	beq	s2,a5,8000478e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004738:	3979                	addiw	s2,s2,-2
    8000473a:	4785                	li	a5,1
    8000473c:	0527e063          	bltu	a5,s2,8000477c <fileclose+0xa8>
    begin_op();
    80004740:	00000097          	auipc	ra,0x0
    80004744:	ac8080e7          	jalr	-1336(ra) # 80004208 <begin_op>
    iput(ff.ip);
    80004748:	854e                	mv	a0,s3
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	2b6080e7          	jalr	694(ra) # 80003a00 <iput>
    end_op();
    80004752:	00000097          	auipc	ra,0x0
    80004756:	b36080e7          	jalr	-1226(ra) # 80004288 <end_op>
    8000475a:	a00d                	j	8000477c <fileclose+0xa8>
    panic("fileclose");
    8000475c:	00004517          	auipc	a0,0x4
    80004760:	f6c50513          	addi	a0,a0,-148 # 800086c8 <syscalls+0x258>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	dda080e7          	jalr	-550(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000476c:	0001d517          	auipc	a0,0x1d
    80004770:	07c50513          	addi	a0,a0,124 # 800217e8 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	516080e7          	jalr	1302(ra) # 80000c8a <release>
  }
}
    8000477c:	70e2                	ld	ra,56(sp)
    8000477e:	7442                	ld	s0,48(sp)
    80004780:	74a2                	ld	s1,40(sp)
    80004782:	7902                	ld	s2,32(sp)
    80004784:	69e2                	ld	s3,24(sp)
    80004786:	6a42                	ld	s4,16(sp)
    80004788:	6aa2                	ld	s5,8(sp)
    8000478a:	6121                	addi	sp,sp,64
    8000478c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000478e:	85d6                	mv	a1,s5
    80004790:	8552                	mv	a0,s4
    80004792:	00000097          	auipc	ra,0x0
    80004796:	34c080e7          	jalr	844(ra) # 80004ade <pipeclose>
    8000479a:	b7cd                	j	8000477c <fileclose+0xa8>

000000008000479c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000479c:	715d                	addi	sp,sp,-80
    8000479e:	e486                	sd	ra,72(sp)
    800047a0:	e0a2                	sd	s0,64(sp)
    800047a2:	fc26                	sd	s1,56(sp)
    800047a4:	f84a                	sd	s2,48(sp)
    800047a6:	f44e                	sd	s3,40(sp)
    800047a8:	0880                	addi	s0,sp,80
    800047aa:	84aa                	mv	s1,a0
    800047ac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ae:	ffffd097          	auipc	ra,0xffffd
    800047b2:	234080e7          	jalr	564(ra) # 800019e2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047b6:	409c                	lw	a5,0(s1)
    800047b8:	37f9                	addiw	a5,a5,-2
    800047ba:	4705                	li	a4,1
    800047bc:	04f76763          	bltu	a4,a5,8000480a <filestat+0x6e>
    800047c0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047c2:	6c88                	ld	a0,24(s1)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	082080e7          	jalr	130(ra) # 80003846 <ilock>
    stati(f->ip, &st);
    800047cc:	fb840593          	addi	a1,s0,-72
    800047d0:	6c88                	ld	a0,24(s1)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	2fe080e7          	jalr	766(ra) # 80003ad0 <stati>
    iunlock(f->ip);
    800047da:	6c88                	ld	a0,24(s1)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	12c080e7          	jalr	300(ra) # 80003908 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047e4:	46e1                	li	a3,24
    800047e6:	fb840613          	addi	a2,s0,-72
    800047ea:	85ce                	mv	a1,s3
    800047ec:	05093503          	ld	a0,80(s2)
    800047f0:	ffffd097          	auipc	ra,0xffffd
    800047f4:	eae080e7          	jalr	-338(ra) # 8000169e <copyout>
    800047f8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047fc:	60a6                	ld	ra,72(sp)
    800047fe:	6406                	ld	s0,64(sp)
    80004800:	74e2                	ld	s1,56(sp)
    80004802:	7942                	ld	s2,48(sp)
    80004804:	79a2                	ld	s3,40(sp)
    80004806:	6161                	addi	sp,sp,80
    80004808:	8082                	ret
  return -1;
    8000480a:	557d                	li	a0,-1
    8000480c:	bfc5                	j	800047fc <filestat+0x60>

000000008000480e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000480e:	7179                	addi	sp,sp,-48
    80004810:	f406                	sd	ra,40(sp)
    80004812:	f022                	sd	s0,32(sp)
    80004814:	ec26                	sd	s1,24(sp)
    80004816:	e84a                	sd	s2,16(sp)
    80004818:	e44e                	sd	s3,8(sp)
    8000481a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000481c:	00854783          	lbu	a5,8(a0)
    80004820:	c3d5                	beqz	a5,800048c4 <fileread+0xb6>
    80004822:	84aa                	mv	s1,a0
    80004824:	89ae                	mv	s3,a1
    80004826:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004828:	411c                	lw	a5,0(a0)
    8000482a:	4705                	li	a4,1
    8000482c:	04e78963          	beq	a5,a4,8000487e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004830:	470d                	li	a4,3
    80004832:	04e78d63          	beq	a5,a4,8000488c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004836:	4709                	li	a4,2
    80004838:	06e79e63          	bne	a5,a4,800048b4 <fileread+0xa6>
    ilock(f->ip);
    8000483c:	6d08                	ld	a0,24(a0)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	008080e7          	jalr	8(ra) # 80003846 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004846:	874a                	mv	a4,s2
    80004848:	5094                	lw	a3,32(s1)
    8000484a:	864e                	mv	a2,s3
    8000484c:	4585                	li	a1,1
    8000484e:	6c88                	ld	a0,24(s1)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	2aa080e7          	jalr	682(ra) # 80003afa <readi>
    80004858:	892a                	mv	s2,a0
    8000485a:	00a05563          	blez	a0,80004864 <fileread+0x56>
      f->off += r;
    8000485e:	509c                	lw	a5,32(s1)
    80004860:	9fa9                	addw	a5,a5,a0
    80004862:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004864:	6c88                	ld	a0,24(s1)
    80004866:	fffff097          	auipc	ra,0xfffff
    8000486a:	0a2080e7          	jalr	162(ra) # 80003908 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000486e:	854a                	mv	a0,s2
    80004870:	70a2                	ld	ra,40(sp)
    80004872:	7402                	ld	s0,32(sp)
    80004874:	64e2                	ld	s1,24(sp)
    80004876:	6942                	ld	s2,16(sp)
    80004878:	69a2                	ld	s3,8(sp)
    8000487a:	6145                	addi	sp,sp,48
    8000487c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000487e:	6908                	ld	a0,16(a0)
    80004880:	00000097          	auipc	ra,0x0
    80004884:	3c6080e7          	jalr	966(ra) # 80004c46 <piperead>
    80004888:	892a                	mv	s2,a0
    8000488a:	b7d5                	j	8000486e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000488c:	02451783          	lh	a5,36(a0)
    80004890:	03079693          	slli	a3,a5,0x30
    80004894:	92c1                	srli	a3,a3,0x30
    80004896:	4725                	li	a4,9
    80004898:	02d76863          	bltu	a4,a3,800048c8 <fileread+0xba>
    8000489c:	0792                	slli	a5,a5,0x4
    8000489e:	0001d717          	auipc	a4,0x1d
    800048a2:	eaa70713          	addi	a4,a4,-342 # 80021748 <devsw>
    800048a6:	97ba                	add	a5,a5,a4
    800048a8:	639c                	ld	a5,0(a5)
    800048aa:	c38d                	beqz	a5,800048cc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048ac:	4505                	li	a0,1
    800048ae:	9782                	jalr	a5
    800048b0:	892a                	mv	s2,a0
    800048b2:	bf75                	j	8000486e <fileread+0x60>
    panic("fileread");
    800048b4:	00004517          	auipc	a0,0x4
    800048b8:	e2450513          	addi	a0,a0,-476 # 800086d8 <syscalls+0x268>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>
    return -1;
    800048c4:	597d                	li	s2,-1
    800048c6:	b765                	j	8000486e <fileread+0x60>
      return -1;
    800048c8:	597d                	li	s2,-1
    800048ca:	b755                	j	8000486e <fileread+0x60>
    800048cc:	597d                	li	s2,-1
    800048ce:	b745                	j	8000486e <fileread+0x60>

00000000800048d0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048d0:	715d                	addi	sp,sp,-80
    800048d2:	e486                	sd	ra,72(sp)
    800048d4:	e0a2                	sd	s0,64(sp)
    800048d6:	fc26                	sd	s1,56(sp)
    800048d8:	f84a                	sd	s2,48(sp)
    800048da:	f44e                	sd	s3,40(sp)
    800048dc:	f052                	sd	s4,32(sp)
    800048de:	ec56                	sd	s5,24(sp)
    800048e0:	e85a                	sd	s6,16(sp)
    800048e2:	e45e                	sd	s7,8(sp)
    800048e4:	e062                	sd	s8,0(sp)
    800048e6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048e8:	00954783          	lbu	a5,9(a0)
    800048ec:	10078663          	beqz	a5,800049f8 <filewrite+0x128>
    800048f0:	892a                	mv	s2,a0
    800048f2:	8aae                	mv	s5,a1
    800048f4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048f6:	411c                	lw	a5,0(a0)
    800048f8:	4705                	li	a4,1
    800048fa:	02e78263          	beq	a5,a4,8000491e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048fe:	470d                	li	a4,3
    80004900:	02e78663          	beq	a5,a4,8000492c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004904:	4709                	li	a4,2
    80004906:	0ee79163          	bne	a5,a4,800049e8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000490a:	0ac05d63          	blez	a2,800049c4 <filewrite+0xf4>
    int i = 0;
    8000490e:	4981                	li	s3,0
    80004910:	6b05                	lui	s6,0x1
    80004912:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004916:	6b85                	lui	s7,0x1
    80004918:	c00b8b9b          	addiw	s7,s7,-1024
    8000491c:	a861                	j	800049b4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000491e:	6908                	ld	a0,16(a0)
    80004920:	00000097          	auipc	ra,0x0
    80004924:	22e080e7          	jalr	558(ra) # 80004b4e <pipewrite>
    80004928:	8a2a                	mv	s4,a0
    8000492a:	a045                	j	800049ca <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000492c:	02451783          	lh	a5,36(a0)
    80004930:	03079693          	slli	a3,a5,0x30
    80004934:	92c1                	srli	a3,a3,0x30
    80004936:	4725                	li	a4,9
    80004938:	0cd76263          	bltu	a4,a3,800049fc <filewrite+0x12c>
    8000493c:	0792                	slli	a5,a5,0x4
    8000493e:	0001d717          	auipc	a4,0x1d
    80004942:	e0a70713          	addi	a4,a4,-502 # 80021748 <devsw>
    80004946:	97ba                	add	a5,a5,a4
    80004948:	679c                	ld	a5,8(a5)
    8000494a:	cbdd                	beqz	a5,80004a00 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000494c:	4505                	li	a0,1
    8000494e:	9782                	jalr	a5
    80004950:	8a2a                	mv	s4,a0
    80004952:	a8a5                	j	800049ca <filewrite+0xfa>
    80004954:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	8b0080e7          	jalr	-1872(ra) # 80004208 <begin_op>
      ilock(f->ip);
    80004960:	01893503          	ld	a0,24(s2)
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	ee2080e7          	jalr	-286(ra) # 80003846 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000496c:	8762                	mv	a4,s8
    8000496e:	02092683          	lw	a3,32(s2)
    80004972:	01598633          	add	a2,s3,s5
    80004976:	4585                	li	a1,1
    80004978:	01893503          	ld	a0,24(s2)
    8000497c:	fffff097          	auipc	ra,0xfffff
    80004980:	276080e7          	jalr	630(ra) # 80003bf2 <writei>
    80004984:	84aa                	mv	s1,a0
    80004986:	00a05763          	blez	a0,80004994 <filewrite+0xc4>
        f->off += r;
    8000498a:	02092783          	lw	a5,32(s2)
    8000498e:	9fa9                	addw	a5,a5,a0
    80004990:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004994:	01893503          	ld	a0,24(s2)
    80004998:	fffff097          	auipc	ra,0xfffff
    8000499c:	f70080e7          	jalr	-144(ra) # 80003908 <iunlock>
      end_op();
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	8e8080e7          	jalr	-1816(ra) # 80004288 <end_op>

      if(r != n1){
    800049a8:	009c1f63          	bne	s8,s1,800049c6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049ac:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049b0:	0149db63          	bge	s3,s4,800049c6 <filewrite+0xf6>
      int n1 = n - i;
    800049b4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049b8:	84be                	mv	s1,a5
    800049ba:	2781                	sext.w	a5,a5
    800049bc:	f8fb5ce3          	bge	s6,a5,80004954 <filewrite+0x84>
    800049c0:	84de                	mv	s1,s7
    800049c2:	bf49                	j	80004954 <filewrite+0x84>
    int i = 0;
    800049c4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049c6:	013a1f63          	bne	s4,s3,800049e4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049ca:	8552                	mv	a0,s4
    800049cc:	60a6                	ld	ra,72(sp)
    800049ce:	6406                	ld	s0,64(sp)
    800049d0:	74e2                	ld	s1,56(sp)
    800049d2:	7942                	ld	s2,48(sp)
    800049d4:	79a2                	ld	s3,40(sp)
    800049d6:	7a02                	ld	s4,32(sp)
    800049d8:	6ae2                	ld	s5,24(sp)
    800049da:	6b42                	ld	s6,16(sp)
    800049dc:	6ba2                	ld	s7,8(sp)
    800049de:	6c02                	ld	s8,0(sp)
    800049e0:	6161                	addi	sp,sp,80
    800049e2:	8082                	ret
    ret = (i == n ? n : -1);
    800049e4:	5a7d                	li	s4,-1
    800049e6:	b7d5                	j	800049ca <filewrite+0xfa>
    panic("filewrite");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	d0050513          	addi	a0,a0,-768 # 800086e8 <syscalls+0x278>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>
    return -1;
    800049f8:	5a7d                	li	s4,-1
    800049fa:	bfc1                	j	800049ca <filewrite+0xfa>
      return -1;
    800049fc:	5a7d                	li	s4,-1
    800049fe:	b7f1                	j	800049ca <filewrite+0xfa>
    80004a00:	5a7d                	li	s4,-1
    80004a02:	b7e1                	j	800049ca <filewrite+0xfa>

0000000080004a04 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a04:	7179                	addi	sp,sp,-48
    80004a06:	f406                	sd	ra,40(sp)
    80004a08:	f022                	sd	s0,32(sp)
    80004a0a:	ec26                	sd	s1,24(sp)
    80004a0c:	e84a                	sd	s2,16(sp)
    80004a0e:	e44e                	sd	s3,8(sp)
    80004a10:	e052                	sd	s4,0(sp)
    80004a12:	1800                	addi	s0,sp,48
    80004a14:	84aa                	mv	s1,a0
    80004a16:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a18:	0005b023          	sd	zero,0(a1)
    80004a1c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	bf8080e7          	jalr	-1032(ra) # 80004618 <filealloc>
    80004a28:	e088                	sd	a0,0(s1)
    80004a2a:	c551                	beqz	a0,80004ab6 <pipealloc+0xb2>
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	bec080e7          	jalr	-1044(ra) # 80004618 <filealloc>
    80004a34:	00aa3023          	sd	a0,0(s4)
    80004a38:	c92d                	beqz	a0,80004aaa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	0ac080e7          	jalr	172(ra) # 80000ae6 <kalloc>
    80004a42:	892a                	mv	s2,a0
    80004a44:	c125                	beqz	a0,80004aa4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a46:	4985                	li	s3,1
    80004a48:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a4c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a50:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a54:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a58:	00004597          	auipc	a1,0x4
    80004a5c:	ca058593          	addi	a1,a1,-864 # 800086f8 <syscalls+0x288>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	0e6080e7          	jalr	230(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a68:	609c                	ld	a5,0(s1)
    80004a6a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a6e:	609c                	ld	a5,0(s1)
    80004a70:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a74:	609c                	ld	a5,0(s1)
    80004a76:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a7a:	609c                	ld	a5,0(s1)
    80004a7c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a80:	000a3783          	ld	a5,0(s4)
    80004a84:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a88:	000a3783          	ld	a5,0(s4)
    80004a8c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a90:	000a3783          	ld	a5,0(s4)
    80004a94:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a98:	000a3783          	ld	a5,0(s4)
    80004a9c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aa0:	4501                	li	a0,0
    80004aa2:	a025                	j	80004aca <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aa4:	6088                	ld	a0,0(s1)
    80004aa6:	e501                	bnez	a0,80004aae <pipealloc+0xaa>
    80004aa8:	a039                	j	80004ab6 <pipealloc+0xb2>
    80004aaa:	6088                	ld	a0,0(s1)
    80004aac:	c51d                	beqz	a0,80004ada <pipealloc+0xd6>
    fileclose(*f0);
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	c26080e7          	jalr	-986(ra) # 800046d4 <fileclose>
  if(*f1)
    80004ab6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aba:	557d                	li	a0,-1
  if(*f1)
    80004abc:	c799                	beqz	a5,80004aca <pipealloc+0xc6>
    fileclose(*f1);
    80004abe:	853e                	mv	a0,a5
    80004ac0:	00000097          	auipc	ra,0x0
    80004ac4:	c14080e7          	jalr	-1004(ra) # 800046d4 <fileclose>
  return -1;
    80004ac8:	557d                	li	a0,-1
}
    80004aca:	70a2                	ld	ra,40(sp)
    80004acc:	7402                	ld	s0,32(sp)
    80004ace:	64e2                	ld	s1,24(sp)
    80004ad0:	6942                	ld	s2,16(sp)
    80004ad2:	69a2                	ld	s3,8(sp)
    80004ad4:	6a02                	ld	s4,0(sp)
    80004ad6:	6145                	addi	sp,sp,48
    80004ad8:	8082                	ret
  return -1;
    80004ada:	557d                	li	a0,-1
    80004adc:	b7fd                	j	80004aca <pipealloc+0xc6>

0000000080004ade <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ade:	1101                	addi	sp,sp,-32
    80004ae0:	ec06                	sd	ra,24(sp)
    80004ae2:	e822                	sd	s0,16(sp)
    80004ae4:	e426                	sd	s1,8(sp)
    80004ae6:	e04a                	sd	s2,0(sp)
    80004ae8:	1000                	addi	s0,sp,32
    80004aea:	84aa                	mv	s1,a0
    80004aec:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	0e8080e7          	jalr	232(ra) # 80000bd6 <acquire>
  if(writable){
    80004af6:	02090d63          	beqz	s2,80004b30 <pipeclose+0x52>
    pi->writeopen = 0;
    80004afa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004afe:	21848513          	addi	a0,s1,536
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	652080e7          	jalr	1618(ra) # 80002154 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b0a:	2204b783          	ld	a5,544(s1)
    80004b0e:	eb95                	bnez	a5,80004b42 <pipeclose+0x64>
    release(&pi->lock);
    80004b10:	8526                	mv	a0,s1
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	178080e7          	jalr	376(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	ece080e7          	jalr	-306(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	64a2                	ld	s1,8(sp)
    80004b2a:	6902                	ld	s2,0(sp)
    80004b2c:	6105                	addi	sp,sp,32
    80004b2e:	8082                	ret
    pi->readopen = 0;
    80004b30:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b34:	21c48513          	addi	a0,s1,540
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	61c080e7          	jalr	1564(ra) # 80002154 <wakeup>
    80004b40:	b7e9                	j	80004b0a <pipeclose+0x2c>
    release(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	146080e7          	jalr	326(ra) # 80000c8a <release>
}
    80004b4c:	bfe1                	j	80004b24 <pipeclose+0x46>

0000000080004b4e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b4e:	711d                	addi	sp,sp,-96
    80004b50:	ec86                	sd	ra,88(sp)
    80004b52:	e8a2                	sd	s0,80(sp)
    80004b54:	e4a6                	sd	s1,72(sp)
    80004b56:	e0ca                	sd	s2,64(sp)
    80004b58:	fc4e                	sd	s3,56(sp)
    80004b5a:	f852                	sd	s4,48(sp)
    80004b5c:	f456                	sd	s5,40(sp)
    80004b5e:	f05a                	sd	s6,32(sp)
    80004b60:	ec5e                	sd	s7,24(sp)
    80004b62:	e862                	sd	s8,16(sp)
    80004b64:	1080                	addi	s0,sp,96
    80004b66:	84aa                	mv	s1,a0
    80004b68:	8aae                	mv	s5,a1
    80004b6a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	e76080e7          	jalr	-394(ra) # 800019e2 <myproc>
    80004b74:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b76:	8526                	mv	a0,s1
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	05e080e7          	jalr	94(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b80:	0b405663          	blez	s4,80004c2c <pipewrite+0xde>
  int i = 0;
    80004b84:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b86:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b88:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b8c:	21c48b93          	addi	s7,s1,540
    80004b90:	a089                	j	80004bd2 <pipewrite+0x84>
      release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	0f6080e7          	jalr	246(ra) # 80000c8a <release>
      return -1;
    80004b9c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b9e:	854a                	mv	a0,s2
    80004ba0:	60e6                	ld	ra,88(sp)
    80004ba2:	6446                	ld	s0,80(sp)
    80004ba4:	64a6                	ld	s1,72(sp)
    80004ba6:	6906                	ld	s2,64(sp)
    80004ba8:	79e2                	ld	s3,56(sp)
    80004baa:	7a42                	ld	s4,48(sp)
    80004bac:	7aa2                	ld	s5,40(sp)
    80004bae:	7b02                	ld	s6,32(sp)
    80004bb0:	6be2                	ld	s7,24(sp)
    80004bb2:	6c42                	ld	s8,16(sp)
    80004bb4:	6125                	addi	sp,sp,96
    80004bb6:	8082                	ret
      wakeup(&pi->nread);
    80004bb8:	8562                	mv	a0,s8
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	59a080e7          	jalr	1434(ra) # 80002154 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bc2:	85a6                	mv	a1,s1
    80004bc4:	855e                	mv	a0,s7
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	52a080e7          	jalr	1322(ra) # 800020f0 <sleep>
  while(i < n){
    80004bce:	07495063          	bge	s2,s4,80004c2e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004bd2:	2204a783          	lw	a5,544(s1)
    80004bd6:	dfd5                	beqz	a5,80004b92 <pipewrite+0x44>
    80004bd8:	854e                	mv	a0,s3
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	7be080e7          	jalr	1982(ra) # 80002398 <killed>
    80004be2:	f945                	bnez	a0,80004b92 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004be4:	2184a783          	lw	a5,536(s1)
    80004be8:	21c4a703          	lw	a4,540(s1)
    80004bec:	2007879b          	addiw	a5,a5,512
    80004bf0:	fcf704e3          	beq	a4,a5,80004bb8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf4:	4685                	li	a3,1
    80004bf6:	01590633          	add	a2,s2,s5
    80004bfa:	faf40593          	addi	a1,s0,-81
    80004bfe:	0509b503          	ld	a0,80(s3)
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	b28080e7          	jalr	-1240(ra) # 8000172a <copyin>
    80004c0a:	03650263          	beq	a0,s6,80004c2e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c0e:	21c4a783          	lw	a5,540(s1)
    80004c12:	0017871b          	addiw	a4,a5,1
    80004c16:	20e4ae23          	sw	a4,540(s1)
    80004c1a:	1ff7f793          	andi	a5,a5,511
    80004c1e:	97a6                	add	a5,a5,s1
    80004c20:	faf44703          	lbu	a4,-81(s0)
    80004c24:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c28:	2905                	addiw	s2,s2,1
    80004c2a:	b755                	j	80004bce <pipewrite+0x80>
  int i = 0;
    80004c2c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c2e:	21848513          	addi	a0,s1,536
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	522080e7          	jalr	1314(ra) # 80002154 <wakeup>
  release(&pi->lock);
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	04e080e7          	jalr	78(ra) # 80000c8a <release>
  return i;
    80004c44:	bfa9                	j	80004b9e <pipewrite+0x50>

0000000080004c46 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c46:	715d                	addi	sp,sp,-80
    80004c48:	e486                	sd	ra,72(sp)
    80004c4a:	e0a2                	sd	s0,64(sp)
    80004c4c:	fc26                	sd	s1,56(sp)
    80004c4e:	f84a                	sd	s2,48(sp)
    80004c50:	f44e                	sd	s3,40(sp)
    80004c52:	f052                	sd	s4,32(sp)
    80004c54:	ec56                	sd	s5,24(sp)
    80004c56:	e85a                	sd	s6,16(sp)
    80004c58:	0880                	addi	s0,sp,80
    80004c5a:	84aa                	mv	s1,a0
    80004c5c:	892e                	mv	s2,a1
    80004c5e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c60:	ffffd097          	auipc	ra,0xffffd
    80004c64:	d82080e7          	jalr	-638(ra) # 800019e2 <myproc>
    80004c68:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	f6a080e7          	jalr	-150(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c74:	2184a703          	lw	a4,536(s1)
    80004c78:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c7c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c80:	02f71763          	bne	a4,a5,80004cae <piperead+0x68>
    80004c84:	2244a783          	lw	a5,548(s1)
    80004c88:	c39d                	beqz	a5,80004cae <piperead+0x68>
    if(killed(pr)){
    80004c8a:	8552                	mv	a0,s4
    80004c8c:	ffffd097          	auipc	ra,0xffffd
    80004c90:	70c080e7          	jalr	1804(ra) # 80002398 <killed>
    80004c94:	e941                	bnez	a0,80004d24 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c96:	85a6                	mv	a1,s1
    80004c98:	854e                	mv	a0,s3
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	456080e7          	jalr	1110(ra) # 800020f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca2:	2184a703          	lw	a4,536(s1)
    80004ca6:	21c4a783          	lw	a5,540(s1)
    80004caa:	fcf70de3          	beq	a4,a5,80004c84 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cae:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cb0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb2:	05505363          	blez	s5,80004cf8 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004cb6:	2184a783          	lw	a5,536(s1)
    80004cba:	21c4a703          	lw	a4,540(s1)
    80004cbe:	02f70d63          	beq	a4,a5,80004cf8 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cc2:	0017871b          	addiw	a4,a5,1
    80004cc6:	20e4ac23          	sw	a4,536(s1)
    80004cca:	1ff7f793          	andi	a5,a5,511
    80004cce:	97a6                	add	a5,a5,s1
    80004cd0:	0187c783          	lbu	a5,24(a5)
    80004cd4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cd8:	4685                	li	a3,1
    80004cda:	fbf40613          	addi	a2,s0,-65
    80004cde:	85ca                	mv	a1,s2
    80004ce0:	050a3503          	ld	a0,80(s4)
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	9ba080e7          	jalr	-1606(ra) # 8000169e <copyout>
    80004cec:	01650663          	beq	a0,s6,80004cf8 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf0:	2985                	addiw	s3,s3,1
    80004cf2:	0905                	addi	s2,s2,1
    80004cf4:	fd3a91e3          	bne	s5,s3,80004cb6 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cf8:	21c48513          	addi	a0,s1,540
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	458080e7          	jalr	1112(ra) # 80002154 <wakeup>
  release(&pi->lock);
    80004d04:	8526                	mv	a0,s1
    80004d06:	ffffc097          	auipc	ra,0xffffc
    80004d0a:	f84080e7          	jalr	-124(ra) # 80000c8a <release>
  return i;
}
    80004d0e:	854e                	mv	a0,s3
    80004d10:	60a6                	ld	ra,72(sp)
    80004d12:	6406                	ld	s0,64(sp)
    80004d14:	74e2                	ld	s1,56(sp)
    80004d16:	7942                	ld	s2,48(sp)
    80004d18:	79a2                	ld	s3,40(sp)
    80004d1a:	7a02                	ld	s4,32(sp)
    80004d1c:	6ae2                	ld	s5,24(sp)
    80004d1e:	6b42                	ld	s6,16(sp)
    80004d20:	6161                	addi	sp,sp,80
    80004d22:	8082                	ret
      release(&pi->lock);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f64080e7          	jalr	-156(ra) # 80000c8a <release>
      return -1;
    80004d2e:	59fd                	li	s3,-1
    80004d30:	bff9                	j	80004d0e <piperead+0xc8>

0000000080004d32 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d32:	1141                	addi	sp,sp,-16
    80004d34:	e422                	sd	s0,8(sp)
    80004d36:	0800                	addi	s0,sp,16
    80004d38:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d3a:	8905                	andi	a0,a0,1
    80004d3c:	c111                	beqz	a0,80004d40 <flags2perm+0xe>
      perm = PTE_X;
    80004d3e:	4521                	li	a0,8
    if(flags & 0x2)
    80004d40:	8b89                	andi	a5,a5,2
    80004d42:	c399                	beqz	a5,80004d48 <flags2perm+0x16>
      perm |= PTE_W;
    80004d44:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d48:	6422                	ld	s0,8(sp)
    80004d4a:	0141                	addi	sp,sp,16
    80004d4c:	8082                	ret

0000000080004d4e <exec>:

int
exec(char *path, char **argv)
{
    80004d4e:	de010113          	addi	sp,sp,-544
    80004d52:	20113c23          	sd	ra,536(sp)
    80004d56:	20813823          	sd	s0,528(sp)
    80004d5a:	20913423          	sd	s1,520(sp)
    80004d5e:	21213023          	sd	s2,512(sp)
    80004d62:	ffce                	sd	s3,504(sp)
    80004d64:	fbd2                	sd	s4,496(sp)
    80004d66:	f7d6                	sd	s5,488(sp)
    80004d68:	f3da                	sd	s6,480(sp)
    80004d6a:	efde                	sd	s7,472(sp)
    80004d6c:	ebe2                	sd	s8,464(sp)
    80004d6e:	e7e6                	sd	s9,456(sp)
    80004d70:	e3ea                	sd	s10,448(sp)
    80004d72:	ff6e                	sd	s11,440(sp)
    80004d74:	1400                	addi	s0,sp,544
    80004d76:	892a                	mv	s2,a0
    80004d78:	dea43423          	sd	a0,-536(s0)
    80004d7c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	c62080e7          	jalr	-926(ra) # 800019e2 <myproc>
    80004d88:	84aa                	mv	s1,a0

  begin_op();
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	47e080e7          	jalr	1150(ra) # 80004208 <begin_op>

  if((ip = namei(path)) == 0){
    80004d92:	854a                	mv	a0,s2
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	258080e7          	jalr	600(ra) # 80003fec <namei>
    80004d9c:	c93d                	beqz	a0,80004e12 <exec+0xc4>
    80004d9e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004da0:	fffff097          	auipc	ra,0xfffff
    80004da4:	aa6080e7          	jalr	-1370(ra) # 80003846 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004da8:	04000713          	li	a4,64
    80004dac:	4681                	li	a3,0
    80004dae:	e5040613          	addi	a2,s0,-432
    80004db2:	4581                	li	a1,0
    80004db4:	8556                	mv	a0,s5
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	d44080e7          	jalr	-700(ra) # 80003afa <readi>
    80004dbe:	04000793          	li	a5,64
    80004dc2:	00f51a63          	bne	a0,a5,80004dd6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004dc6:	e5042703          	lw	a4,-432(s0)
    80004dca:	464c47b7          	lui	a5,0x464c4
    80004dce:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dd2:	04f70663          	beq	a4,a5,80004e1e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dd6:	8556                	mv	a0,s5
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	cd0080e7          	jalr	-816(ra) # 80003aa8 <iunlockput>
    end_op();
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	4a8080e7          	jalr	1192(ra) # 80004288 <end_op>
  }
  return -1;
    80004de8:	557d                	li	a0,-1
}
    80004dea:	21813083          	ld	ra,536(sp)
    80004dee:	21013403          	ld	s0,528(sp)
    80004df2:	20813483          	ld	s1,520(sp)
    80004df6:	20013903          	ld	s2,512(sp)
    80004dfa:	79fe                	ld	s3,504(sp)
    80004dfc:	7a5e                	ld	s4,496(sp)
    80004dfe:	7abe                	ld	s5,488(sp)
    80004e00:	7b1e                	ld	s6,480(sp)
    80004e02:	6bfe                	ld	s7,472(sp)
    80004e04:	6c5e                	ld	s8,464(sp)
    80004e06:	6cbe                	ld	s9,456(sp)
    80004e08:	6d1e                	ld	s10,448(sp)
    80004e0a:	7dfa                	ld	s11,440(sp)
    80004e0c:	22010113          	addi	sp,sp,544
    80004e10:	8082                	ret
    end_op();
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	476080e7          	jalr	1142(ra) # 80004288 <end_op>
    return -1;
    80004e1a:	557d                	li	a0,-1
    80004e1c:	b7f9                	j	80004dea <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e1e:	8526                	mv	a0,s1
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	c86080e7          	jalr	-890(ra) # 80001aa6 <proc_pagetable>
    80004e28:	8b2a                	mv	s6,a0
    80004e2a:	d555                	beqz	a0,80004dd6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e2c:	e7042783          	lw	a5,-400(s0)
    80004e30:	e8845703          	lhu	a4,-376(s0)
    80004e34:	c735                	beqz	a4,80004ea0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e36:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e38:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e3c:	6a05                	lui	s4,0x1
    80004e3e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e42:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e46:	6d85                	lui	s11,0x1
    80004e48:	7d7d                	lui	s10,0xfffff
    80004e4a:	a481                	j	8000508a <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e4c:	00004517          	auipc	a0,0x4
    80004e50:	8b450513          	addi	a0,a0,-1868 # 80008700 <syscalls+0x290>
    80004e54:	ffffb097          	auipc	ra,0xffffb
    80004e58:	6ea080e7          	jalr	1770(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e5c:	874a                	mv	a4,s2
    80004e5e:	009c86bb          	addw	a3,s9,s1
    80004e62:	4581                	li	a1,0
    80004e64:	8556                	mv	a0,s5
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	c94080e7          	jalr	-876(ra) # 80003afa <readi>
    80004e6e:	2501                	sext.w	a0,a0
    80004e70:	1aa91a63          	bne	s2,a0,80005024 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e74:	009d84bb          	addw	s1,s11,s1
    80004e78:	013d09bb          	addw	s3,s10,s3
    80004e7c:	1f74f763          	bgeu	s1,s7,8000506a <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004e80:	02049593          	slli	a1,s1,0x20
    80004e84:	9181                	srli	a1,a1,0x20
    80004e86:	95e2                	add	a1,a1,s8
    80004e88:	855a                	mv	a0,s6
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	1f2080e7          	jalr	498(ra) # 8000107c <walkaddr>
    80004e92:	862a                	mv	a2,a0
    if(pa == 0)
    80004e94:	dd45                	beqz	a0,80004e4c <exec+0xfe>
      n = PGSIZE;
    80004e96:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e98:	fd49f2e3          	bgeu	s3,s4,80004e5c <exec+0x10e>
      n = sz - i;
    80004e9c:	894e                	mv	s2,s3
    80004e9e:	bf7d                	j	80004e5c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ea0:	4901                	li	s2,0
  iunlockput(ip);
    80004ea2:	8556                	mv	a0,s5
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	c04080e7          	jalr	-1020(ra) # 80003aa8 <iunlockput>
  end_op();
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	3dc080e7          	jalr	988(ra) # 80004288 <end_op>
  p = myproc();
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	b2e080e7          	jalr	-1234(ra) # 800019e2 <myproc>
    80004ebc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ebe:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ec2:	6785                	lui	a5,0x1
    80004ec4:	17fd                	addi	a5,a5,-1
    80004ec6:	993e                	add	s2,s2,a5
    80004ec8:	77fd                	lui	a5,0xfffff
    80004eca:	00f977b3          	and	a5,s2,a5
    80004ece:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ed2:	4691                	li	a3,4
    80004ed4:	6609                	lui	a2,0x2
    80004ed6:	963e                	add	a2,a2,a5
    80004ed8:	85be                	mv	a1,a5
    80004eda:	855a                	mv	a0,s6
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	56a080e7          	jalr	1386(ra) # 80001446 <uvmalloc>
    80004ee4:	8c2a                	mv	s8,a0
  ip = 0;
    80004ee6:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ee8:	12050e63          	beqz	a0,80005024 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eec:	75f9                	lui	a1,0xffffe
    80004eee:	95aa                	add	a1,a1,a0
    80004ef0:	855a                	mv	a0,s6
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	77a080e7          	jalr	1914(ra) # 8000166c <uvmclear>
  stackbase = sp - PGSIZE;
    80004efa:	7afd                	lui	s5,0xfffff
    80004efc:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004efe:	df043783          	ld	a5,-528(s0)
    80004f02:	6388                	ld	a0,0(a5)
    80004f04:	c925                	beqz	a0,80004f74 <exec+0x226>
    80004f06:	e9040993          	addi	s3,s0,-368
    80004f0a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f0e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f10:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f12:	ffffc097          	auipc	ra,0xffffc
    80004f16:	f3c080e7          	jalr	-196(ra) # 80000e4e <strlen>
    80004f1a:	0015079b          	addiw	a5,a0,1
    80004f1e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f22:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f26:	13596663          	bltu	s2,s5,80005052 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f2a:	df043d83          	ld	s11,-528(s0)
    80004f2e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f32:	8552                	mv	a0,s4
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	f1a080e7          	jalr	-230(ra) # 80000e4e <strlen>
    80004f3c:	0015069b          	addiw	a3,a0,1
    80004f40:	8652                	mv	a2,s4
    80004f42:	85ca                	mv	a1,s2
    80004f44:	855a                	mv	a0,s6
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	758080e7          	jalr	1880(ra) # 8000169e <copyout>
    80004f4e:	10054663          	bltz	a0,8000505a <exec+0x30c>
    ustack[argc] = sp;
    80004f52:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f56:	0485                	addi	s1,s1,1
    80004f58:	008d8793          	addi	a5,s11,8
    80004f5c:	def43823          	sd	a5,-528(s0)
    80004f60:	008db503          	ld	a0,8(s11)
    80004f64:	c911                	beqz	a0,80004f78 <exec+0x22a>
    if(argc >= MAXARG)
    80004f66:	09a1                	addi	s3,s3,8
    80004f68:	fb3c95e3          	bne	s9,s3,80004f12 <exec+0x1c4>
  sz = sz1;
    80004f6c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f70:	4a81                	li	s5,0
    80004f72:	a84d                	j	80005024 <exec+0x2d6>
  sp = sz;
    80004f74:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f76:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f78:	00349793          	slli	a5,s1,0x3
    80004f7c:	f9040713          	addi	a4,s0,-112
    80004f80:	97ba                	add	a5,a5,a4
    80004f82:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd9608>
  sp -= (argc+1) * sizeof(uint64);
    80004f86:	00148693          	addi	a3,s1,1
    80004f8a:	068e                	slli	a3,a3,0x3
    80004f8c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f90:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f94:	01597663          	bgeu	s2,s5,80004fa0 <exec+0x252>
  sz = sz1;
    80004f98:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9c:	4a81                	li	s5,0
    80004f9e:	a059                	j	80005024 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fa0:	e9040613          	addi	a2,s0,-368
    80004fa4:	85ca                	mv	a1,s2
    80004fa6:	855a                	mv	a0,s6
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	6f6080e7          	jalr	1782(ra) # 8000169e <copyout>
    80004fb0:	0a054963          	bltz	a0,80005062 <exec+0x314>
  p->trapframe->a1 = sp;
    80004fb4:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004fb8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fbc:	de843783          	ld	a5,-536(s0)
    80004fc0:	0007c703          	lbu	a4,0(a5)
    80004fc4:	cf11                	beqz	a4,80004fe0 <exec+0x292>
    80004fc6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fc8:	02f00693          	li	a3,47
    80004fcc:	a039                	j	80004fda <exec+0x28c>
      last = s+1;
    80004fce:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fd2:	0785                	addi	a5,a5,1
    80004fd4:	fff7c703          	lbu	a4,-1(a5)
    80004fd8:	c701                	beqz	a4,80004fe0 <exec+0x292>
    if(*s == '/')
    80004fda:	fed71ce3          	bne	a4,a3,80004fd2 <exec+0x284>
    80004fde:	bfc5                	j	80004fce <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fe0:	4641                	li	a2,16
    80004fe2:	de843583          	ld	a1,-536(s0)
    80004fe6:	158b8513          	addi	a0,s7,344
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	e32080e7          	jalr	-462(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004ff2:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ff6:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ffa:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ffe:	058bb783          	ld	a5,88(s7)
    80005002:	e6843703          	ld	a4,-408(s0)
    80005006:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005008:	058bb783          	ld	a5,88(s7)
    8000500c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005010:	85ea                	mv	a1,s10
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	b30080e7          	jalr	-1232(ra) # 80001b42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000501a:	0004851b          	sext.w	a0,s1
    8000501e:	b3f1                	j	80004dea <exec+0x9c>
    80005020:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005024:	df843583          	ld	a1,-520(s0)
    80005028:	855a                	mv	a0,s6
    8000502a:	ffffd097          	auipc	ra,0xffffd
    8000502e:	b18080e7          	jalr	-1256(ra) # 80001b42 <proc_freepagetable>
  if(ip){
    80005032:	da0a92e3          	bnez	s5,80004dd6 <exec+0x88>
  return -1;
    80005036:	557d                	li	a0,-1
    80005038:	bb4d                	j	80004dea <exec+0x9c>
    8000503a:	df243c23          	sd	s2,-520(s0)
    8000503e:	b7dd                	j	80005024 <exec+0x2d6>
    80005040:	df243c23          	sd	s2,-520(s0)
    80005044:	b7c5                	j	80005024 <exec+0x2d6>
    80005046:	df243c23          	sd	s2,-520(s0)
    8000504a:	bfe9                	j	80005024 <exec+0x2d6>
    8000504c:	df243c23          	sd	s2,-520(s0)
    80005050:	bfd1                	j	80005024 <exec+0x2d6>
  sz = sz1;
    80005052:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005056:	4a81                	li	s5,0
    80005058:	b7f1                	j	80005024 <exec+0x2d6>
  sz = sz1;
    8000505a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000505e:	4a81                	li	s5,0
    80005060:	b7d1                	j	80005024 <exec+0x2d6>
  sz = sz1;
    80005062:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005066:	4a81                	li	s5,0
    80005068:	bf75                	j	80005024 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000506a:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000506e:	e0843783          	ld	a5,-504(s0)
    80005072:	0017869b          	addiw	a3,a5,1
    80005076:	e0d43423          	sd	a3,-504(s0)
    8000507a:	e0043783          	ld	a5,-512(s0)
    8000507e:	0387879b          	addiw	a5,a5,56
    80005082:	e8845703          	lhu	a4,-376(s0)
    80005086:	e0e6dee3          	bge	a3,a4,80004ea2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000508a:	2781                	sext.w	a5,a5
    8000508c:	e0f43023          	sd	a5,-512(s0)
    80005090:	03800713          	li	a4,56
    80005094:	86be                	mv	a3,a5
    80005096:	e1840613          	addi	a2,s0,-488
    8000509a:	4581                	li	a1,0
    8000509c:	8556                	mv	a0,s5
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	a5c080e7          	jalr	-1444(ra) # 80003afa <readi>
    800050a6:	03800793          	li	a5,56
    800050aa:	f6f51be3          	bne	a0,a5,80005020 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    800050ae:	e1842783          	lw	a5,-488(s0)
    800050b2:	4705                	li	a4,1
    800050b4:	fae79de3          	bne	a5,a4,8000506e <exec+0x320>
    if(ph.memsz < ph.filesz)
    800050b8:	e4043483          	ld	s1,-448(s0)
    800050bc:	e3843783          	ld	a5,-456(s0)
    800050c0:	f6f4ede3          	bltu	s1,a5,8000503a <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050c4:	e2843783          	ld	a5,-472(s0)
    800050c8:	94be                	add	s1,s1,a5
    800050ca:	f6f4ebe3          	bltu	s1,a5,80005040 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800050ce:	de043703          	ld	a4,-544(s0)
    800050d2:	8ff9                	and	a5,a5,a4
    800050d4:	fbad                	bnez	a5,80005046 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050d6:	e1c42503          	lw	a0,-484(s0)
    800050da:	00000097          	auipc	ra,0x0
    800050de:	c58080e7          	jalr	-936(ra) # 80004d32 <flags2perm>
    800050e2:	86aa                	mv	a3,a0
    800050e4:	8626                	mv	a2,s1
    800050e6:	85ca                	mv	a1,s2
    800050e8:	855a                	mv	a0,s6
    800050ea:	ffffc097          	auipc	ra,0xffffc
    800050ee:	35c080e7          	jalr	860(ra) # 80001446 <uvmalloc>
    800050f2:	dea43c23          	sd	a0,-520(s0)
    800050f6:	d939                	beqz	a0,8000504c <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050f8:	e2843c03          	ld	s8,-472(s0)
    800050fc:	e2042c83          	lw	s9,-480(s0)
    80005100:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005104:	f60b83e3          	beqz	s7,8000506a <exec+0x31c>
    80005108:	89de                	mv	s3,s7
    8000510a:	4481                	li	s1,0
    8000510c:	bb95                	j	80004e80 <exec+0x132>

000000008000510e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000510e:	7179                	addi	sp,sp,-48
    80005110:	f406                	sd	ra,40(sp)
    80005112:	f022                	sd	s0,32(sp)
    80005114:	ec26                	sd	s1,24(sp)
    80005116:	e84a                	sd	s2,16(sp)
    80005118:	1800                	addi	s0,sp,48
    8000511a:	892e                	mv	s2,a1
    8000511c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000511e:	fdc40593          	addi	a1,s0,-36
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	a3a080e7          	jalr	-1478(ra) # 80002b5c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000512a:	fdc42703          	lw	a4,-36(s0)
    8000512e:	47bd                	li	a5,15
    80005130:	02e7eb63          	bltu	a5,a4,80005166 <argfd+0x58>
    80005134:	ffffd097          	auipc	ra,0xffffd
    80005138:	8ae080e7          	jalr	-1874(ra) # 800019e2 <myproc>
    8000513c:	fdc42703          	lw	a4,-36(s0)
    80005140:	01a70793          	addi	a5,a4,26
    80005144:	078e                	slli	a5,a5,0x3
    80005146:	953e                	add	a0,a0,a5
    80005148:	611c                	ld	a5,0(a0)
    8000514a:	c385                	beqz	a5,8000516a <argfd+0x5c>
    return -1;
  if(pfd)
    8000514c:	00090463          	beqz	s2,80005154 <argfd+0x46>
    *pfd = fd;
    80005150:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005154:	4501                	li	a0,0
  if(pf)
    80005156:	c091                	beqz	s1,8000515a <argfd+0x4c>
    *pf = f;
    80005158:	e09c                	sd	a5,0(s1)
}
    8000515a:	70a2                	ld	ra,40(sp)
    8000515c:	7402                	ld	s0,32(sp)
    8000515e:	64e2                	ld	s1,24(sp)
    80005160:	6942                	ld	s2,16(sp)
    80005162:	6145                	addi	sp,sp,48
    80005164:	8082                	ret
    return -1;
    80005166:	557d                	li	a0,-1
    80005168:	bfcd                	j	8000515a <argfd+0x4c>
    8000516a:	557d                	li	a0,-1
    8000516c:	b7fd                	j	8000515a <argfd+0x4c>

000000008000516e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000516e:	1101                	addi	sp,sp,-32
    80005170:	ec06                	sd	ra,24(sp)
    80005172:	e822                	sd	s0,16(sp)
    80005174:	e426                	sd	s1,8(sp)
    80005176:	1000                	addi	s0,sp,32
    80005178:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000517a:	ffffd097          	auipc	ra,0xffffd
    8000517e:	868080e7          	jalr	-1944(ra) # 800019e2 <myproc>
    80005182:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005184:	0d050793          	addi	a5,a0,208
    80005188:	4501                	li	a0,0
    8000518a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000518c:	6398                	ld	a4,0(a5)
    8000518e:	cb19                	beqz	a4,800051a4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005190:	2505                	addiw	a0,a0,1
    80005192:	07a1                	addi	a5,a5,8
    80005194:	fed51ce3          	bne	a0,a3,8000518c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005198:	557d                	li	a0,-1
}
    8000519a:	60e2                	ld	ra,24(sp)
    8000519c:	6442                	ld	s0,16(sp)
    8000519e:	64a2                	ld	s1,8(sp)
    800051a0:	6105                	addi	sp,sp,32
    800051a2:	8082                	ret
      p->ofile[fd] = f;
    800051a4:	01a50793          	addi	a5,a0,26
    800051a8:	078e                	slli	a5,a5,0x3
    800051aa:	963e                	add	a2,a2,a5
    800051ac:	e204                	sd	s1,0(a2)
      return fd;
    800051ae:	b7f5                	j	8000519a <fdalloc+0x2c>

00000000800051b0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051b0:	715d                	addi	sp,sp,-80
    800051b2:	e486                	sd	ra,72(sp)
    800051b4:	e0a2                	sd	s0,64(sp)
    800051b6:	fc26                	sd	s1,56(sp)
    800051b8:	f84a                	sd	s2,48(sp)
    800051ba:	f44e                	sd	s3,40(sp)
    800051bc:	f052                	sd	s4,32(sp)
    800051be:	ec56                	sd	s5,24(sp)
    800051c0:	e85a                	sd	s6,16(sp)
    800051c2:	0880                	addi	s0,sp,80
    800051c4:	8b2e                	mv	s6,a1
    800051c6:	89b2                	mv	s3,a2
    800051c8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051ca:	fb040593          	addi	a1,s0,-80
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	e3c080e7          	jalr	-452(ra) # 8000400a <nameiparent>
    800051d6:	84aa                	mv	s1,a0
    800051d8:	14050f63          	beqz	a0,80005336 <create+0x186>
    return 0;

  ilock(dp);
    800051dc:	ffffe097          	auipc	ra,0xffffe
    800051e0:	66a080e7          	jalr	1642(ra) # 80003846 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051e4:	4601                	li	a2,0
    800051e6:	fb040593          	addi	a1,s0,-80
    800051ea:	8526                	mv	a0,s1
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	b3e080e7          	jalr	-1218(ra) # 80003d2a <dirlookup>
    800051f4:	8aaa                	mv	s5,a0
    800051f6:	c931                	beqz	a0,8000524a <create+0x9a>
    iunlockput(dp);
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	8ae080e7          	jalr	-1874(ra) # 80003aa8 <iunlockput>
    ilock(ip);
    80005202:	8556                	mv	a0,s5
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	642080e7          	jalr	1602(ra) # 80003846 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000520c:	000b059b          	sext.w	a1,s6
    80005210:	4789                	li	a5,2
    80005212:	02f59563          	bne	a1,a5,8000523c <create+0x8c>
    80005216:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd974c>
    8000521a:	37f9                	addiw	a5,a5,-2
    8000521c:	17c2                	slli	a5,a5,0x30
    8000521e:	93c1                	srli	a5,a5,0x30
    80005220:	4705                	li	a4,1
    80005222:	00f76d63          	bltu	a4,a5,8000523c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005226:	8556                	mv	a0,s5
    80005228:	60a6                	ld	ra,72(sp)
    8000522a:	6406                	ld	s0,64(sp)
    8000522c:	74e2                	ld	s1,56(sp)
    8000522e:	7942                	ld	s2,48(sp)
    80005230:	79a2                	ld	s3,40(sp)
    80005232:	7a02                	ld	s4,32(sp)
    80005234:	6ae2                	ld	s5,24(sp)
    80005236:	6b42                	ld	s6,16(sp)
    80005238:	6161                	addi	sp,sp,80
    8000523a:	8082                	ret
    iunlockput(ip);
    8000523c:	8556                	mv	a0,s5
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	86a080e7          	jalr	-1942(ra) # 80003aa8 <iunlockput>
    return 0;
    80005246:	4a81                	li	s5,0
    80005248:	bff9                	j	80005226 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000524a:	85da                	mv	a1,s6
    8000524c:	4088                	lw	a0,0(s1)
    8000524e:	ffffe097          	auipc	ra,0xffffe
    80005252:	45c080e7          	jalr	1116(ra) # 800036aa <ialloc>
    80005256:	8a2a                	mv	s4,a0
    80005258:	c539                	beqz	a0,800052a6 <create+0xf6>
  ilock(ip);
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	5ec080e7          	jalr	1516(ra) # 80003846 <ilock>
  ip->major = major;
    80005262:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005266:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000526a:	4905                	li	s2,1
    8000526c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005270:	8552                	mv	a0,s4
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	50a080e7          	jalr	1290(ra) # 8000377c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000527a:	000b059b          	sext.w	a1,s6
    8000527e:	03258b63          	beq	a1,s2,800052b4 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005282:	004a2603          	lw	a2,4(s4)
    80005286:	fb040593          	addi	a1,s0,-80
    8000528a:	8526                	mv	a0,s1
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	cae080e7          	jalr	-850(ra) # 80003f3a <dirlink>
    80005294:	06054f63          	bltz	a0,80005312 <create+0x162>
  iunlockput(dp);
    80005298:	8526                	mv	a0,s1
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	80e080e7          	jalr	-2034(ra) # 80003aa8 <iunlockput>
  return ip;
    800052a2:	8ad2                	mv	s5,s4
    800052a4:	b749                	j	80005226 <create+0x76>
    iunlockput(dp);
    800052a6:	8526                	mv	a0,s1
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	800080e7          	jalr	-2048(ra) # 80003aa8 <iunlockput>
    return 0;
    800052b0:	8ad2                	mv	s5,s4
    800052b2:	bf95                	j	80005226 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052b4:	004a2603          	lw	a2,4(s4)
    800052b8:	00003597          	auipc	a1,0x3
    800052bc:	46858593          	addi	a1,a1,1128 # 80008720 <syscalls+0x2b0>
    800052c0:	8552                	mv	a0,s4
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	c78080e7          	jalr	-904(ra) # 80003f3a <dirlink>
    800052ca:	04054463          	bltz	a0,80005312 <create+0x162>
    800052ce:	40d0                	lw	a2,4(s1)
    800052d0:	00003597          	auipc	a1,0x3
    800052d4:	45858593          	addi	a1,a1,1112 # 80008728 <syscalls+0x2b8>
    800052d8:	8552                	mv	a0,s4
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	c60080e7          	jalr	-928(ra) # 80003f3a <dirlink>
    800052e2:	02054863          	bltz	a0,80005312 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800052e6:	004a2603          	lw	a2,4(s4)
    800052ea:	fb040593          	addi	a1,s0,-80
    800052ee:	8526                	mv	a0,s1
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	c4a080e7          	jalr	-950(ra) # 80003f3a <dirlink>
    800052f8:	00054d63          	bltz	a0,80005312 <create+0x162>
    dp->nlink++;  // for ".."
    800052fc:	04a4d783          	lhu	a5,74(s1)
    80005300:	2785                	addiw	a5,a5,1
    80005302:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005306:	8526                	mv	a0,s1
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	474080e7          	jalr	1140(ra) # 8000377c <iupdate>
    80005310:	b761                	j	80005298 <create+0xe8>
  ip->nlink = 0;
    80005312:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005316:	8552                	mv	a0,s4
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	464080e7          	jalr	1124(ra) # 8000377c <iupdate>
  iunlockput(ip);
    80005320:	8552                	mv	a0,s4
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	786080e7          	jalr	1926(ra) # 80003aa8 <iunlockput>
  iunlockput(dp);
    8000532a:	8526                	mv	a0,s1
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	77c080e7          	jalr	1916(ra) # 80003aa8 <iunlockput>
  return 0;
    80005334:	bdcd                	j	80005226 <create+0x76>
    return 0;
    80005336:	8aaa                	mv	s5,a0
    80005338:	b5fd                	j	80005226 <create+0x76>

000000008000533a <sys_dup>:
{
    8000533a:	7179                	addi	sp,sp,-48
    8000533c:	f406                	sd	ra,40(sp)
    8000533e:	f022                	sd	s0,32(sp)
    80005340:	ec26                	sd	s1,24(sp)
    80005342:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005344:	fd840613          	addi	a2,s0,-40
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	dc2080e7          	jalr	-574(ra) # 8000510e <argfd>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005356:	02054363          	bltz	a0,8000537c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000535a:	fd843503          	ld	a0,-40(s0)
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	e10080e7          	jalr	-496(ra) # 8000516e <fdalloc>
    80005366:	84aa                	mv	s1,a0
    return -1;
    80005368:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000536a:	00054963          	bltz	a0,8000537c <sys_dup+0x42>
  filedup(f);
    8000536e:	fd843503          	ld	a0,-40(s0)
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	310080e7          	jalr	784(ra) # 80004682 <filedup>
  return fd;
    8000537a:	87a6                	mv	a5,s1
}
    8000537c:	853e                	mv	a0,a5
    8000537e:	70a2                	ld	ra,40(sp)
    80005380:	7402                	ld	s0,32(sp)
    80005382:	64e2                	ld	s1,24(sp)
    80005384:	6145                	addi	sp,sp,48
    80005386:	8082                	ret

0000000080005388 <sys_read>:
{
    80005388:	7179                	addi	sp,sp,-48
    8000538a:	f406                	sd	ra,40(sp)
    8000538c:	f022                	sd	s0,32(sp)
    8000538e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005390:	fd840593          	addi	a1,s0,-40
    80005394:	4505                	li	a0,1
    80005396:	ffffd097          	auipc	ra,0xffffd
    8000539a:	7e6080e7          	jalr	2022(ra) # 80002b7c <argaddr>
  argint(2, &n);
    8000539e:	fe440593          	addi	a1,s0,-28
    800053a2:	4509                	li	a0,2
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	7b8080e7          	jalr	1976(ra) # 80002b5c <argint>
  if(argfd(0, 0, &f) < 0)
    800053ac:	fe840613          	addi	a2,s0,-24
    800053b0:	4581                	li	a1,0
    800053b2:	4501                	li	a0,0
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	d5a080e7          	jalr	-678(ra) # 8000510e <argfd>
    800053bc:	87aa                	mv	a5,a0
    return -1;
    800053be:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053c0:	0007cc63          	bltz	a5,800053d8 <sys_read+0x50>
  return fileread(f, p, n);
    800053c4:	fe442603          	lw	a2,-28(s0)
    800053c8:	fd843583          	ld	a1,-40(s0)
    800053cc:	fe843503          	ld	a0,-24(s0)
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	43e080e7          	jalr	1086(ra) # 8000480e <fileread>
}
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	6145                	addi	sp,sp,48
    800053de:	8082                	ret

00000000800053e0 <sys_write>:
{
    800053e0:	7179                	addi	sp,sp,-48
    800053e2:	f406                	sd	ra,40(sp)
    800053e4:	f022                	sd	s0,32(sp)
    800053e6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053e8:	fd840593          	addi	a1,s0,-40
    800053ec:	4505                	li	a0,1
    800053ee:	ffffd097          	auipc	ra,0xffffd
    800053f2:	78e080e7          	jalr	1934(ra) # 80002b7c <argaddr>
  argint(2, &n);
    800053f6:	fe440593          	addi	a1,s0,-28
    800053fa:	4509                	li	a0,2
    800053fc:	ffffd097          	auipc	ra,0xffffd
    80005400:	760080e7          	jalr	1888(ra) # 80002b5c <argint>
  if(argfd(0, 0, &f) < 0)
    80005404:	fe840613          	addi	a2,s0,-24
    80005408:	4581                	li	a1,0
    8000540a:	4501                	li	a0,0
    8000540c:	00000097          	auipc	ra,0x0
    80005410:	d02080e7          	jalr	-766(ra) # 8000510e <argfd>
    80005414:	87aa                	mv	a5,a0
    return -1;
    80005416:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005418:	0007cc63          	bltz	a5,80005430 <sys_write+0x50>
  return filewrite(f, p, n);
    8000541c:	fe442603          	lw	a2,-28(s0)
    80005420:	fd843583          	ld	a1,-40(s0)
    80005424:	fe843503          	ld	a0,-24(s0)
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	4a8080e7          	jalr	1192(ra) # 800048d0 <filewrite>
}
    80005430:	70a2                	ld	ra,40(sp)
    80005432:	7402                	ld	s0,32(sp)
    80005434:	6145                	addi	sp,sp,48
    80005436:	8082                	ret

0000000080005438 <sys_close>:
{
    80005438:	1101                	addi	sp,sp,-32
    8000543a:	ec06                	sd	ra,24(sp)
    8000543c:	e822                	sd	s0,16(sp)
    8000543e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005440:	fe040613          	addi	a2,s0,-32
    80005444:	fec40593          	addi	a1,s0,-20
    80005448:	4501                	li	a0,0
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	cc4080e7          	jalr	-828(ra) # 8000510e <argfd>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005454:	02054463          	bltz	a0,8000547c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	58a080e7          	jalr	1418(ra) # 800019e2 <myproc>
    80005460:	fec42783          	lw	a5,-20(s0)
    80005464:	07e9                	addi	a5,a5,26
    80005466:	078e                	slli	a5,a5,0x3
    80005468:	97aa                	add	a5,a5,a0
    8000546a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000546e:	fe043503          	ld	a0,-32(s0)
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	262080e7          	jalr	610(ra) # 800046d4 <fileclose>
  return 0;
    8000547a:	4781                	li	a5,0
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	60e2                	ld	ra,24(sp)
    80005480:	6442                	ld	s0,16(sp)
    80005482:	6105                	addi	sp,sp,32
    80005484:	8082                	ret

0000000080005486 <sys_fstat>:
{
    80005486:	1101                	addi	sp,sp,-32
    80005488:	ec06                	sd	ra,24(sp)
    8000548a:	e822                	sd	s0,16(sp)
    8000548c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000548e:	fe040593          	addi	a1,s0,-32
    80005492:	4505                	li	a0,1
    80005494:	ffffd097          	auipc	ra,0xffffd
    80005498:	6e8080e7          	jalr	1768(ra) # 80002b7c <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000549c:	fe840613          	addi	a2,s0,-24
    800054a0:	4581                	li	a1,0
    800054a2:	4501                	li	a0,0
    800054a4:	00000097          	auipc	ra,0x0
    800054a8:	c6a080e7          	jalr	-918(ra) # 8000510e <argfd>
    800054ac:	87aa                	mv	a5,a0
    return -1;
    800054ae:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054b0:	0007ca63          	bltz	a5,800054c4 <sys_fstat+0x3e>
  return filestat(f, st);
    800054b4:	fe043583          	ld	a1,-32(s0)
    800054b8:	fe843503          	ld	a0,-24(s0)
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	2e0080e7          	jalr	736(ra) # 8000479c <filestat>
}
    800054c4:	60e2                	ld	ra,24(sp)
    800054c6:	6442                	ld	s0,16(sp)
    800054c8:	6105                	addi	sp,sp,32
    800054ca:	8082                	ret

00000000800054cc <sys_link>:
{
    800054cc:	7169                	addi	sp,sp,-304
    800054ce:	f606                	sd	ra,296(sp)
    800054d0:	f222                	sd	s0,288(sp)
    800054d2:	ee26                	sd	s1,280(sp)
    800054d4:	ea4a                	sd	s2,272(sp)
    800054d6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d8:	08000613          	li	a2,128
    800054dc:	ed040593          	addi	a1,s0,-304
    800054e0:	4501                	li	a0,0
    800054e2:	ffffd097          	auipc	ra,0xffffd
    800054e6:	6ba080e7          	jalr	1722(ra) # 80002b9c <argstr>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ec:	10054e63          	bltz	a0,80005608 <sys_link+0x13c>
    800054f0:	08000613          	li	a2,128
    800054f4:	f5040593          	addi	a1,s0,-176
    800054f8:	4505                	li	a0,1
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	6a2080e7          	jalr	1698(ra) # 80002b9c <argstr>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005504:	10054263          	bltz	a0,80005608 <sys_link+0x13c>
  begin_op();
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	d00080e7          	jalr	-768(ra) # 80004208 <begin_op>
  if((ip = namei(old)) == 0){
    80005510:	ed040513          	addi	a0,s0,-304
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	ad8080e7          	jalr	-1320(ra) # 80003fec <namei>
    8000551c:	84aa                	mv	s1,a0
    8000551e:	c551                	beqz	a0,800055aa <sys_link+0xde>
  ilock(ip);
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	326080e7          	jalr	806(ra) # 80003846 <ilock>
  if(ip->type == T_DIR){
    80005528:	04449703          	lh	a4,68(s1)
    8000552c:	4785                	li	a5,1
    8000552e:	08f70463          	beq	a4,a5,800055b6 <sys_link+0xea>
  ip->nlink++;
    80005532:	04a4d783          	lhu	a5,74(s1)
    80005536:	2785                	addiw	a5,a5,1
    80005538:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	23e080e7          	jalr	574(ra) # 8000377c <iupdate>
  iunlock(ip);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	3c0080e7          	jalr	960(ra) # 80003908 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005550:	fd040593          	addi	a1,s0,-48
    80005554:	f5040513          	addi	a0,s0,-176
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	ab2080e7          	jalr	-1358(ra) # 8000400a <nameiparent>
    80005560:	892a                	mv	s2,a0
    80005562:	c935                	beqz	a0,800055d6 <sys_link+0x10a>
  ilock(dp);
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	2e2080e7          	jalr	738(ra) # 80003846 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000556c:	00092703          	lw	a4,0(s2)
    80005570:	409c                	lw	a5,0(s1)
    80005572:	04f71d63          	bne	a4,a5,800055cc <sys_link+0x100>
    80005576:	40d0                	lw	a2,4(s1)
    80005578:	fd040593          	addi	a1,s0,-48
    8000557c:	854a                	mv	a0,s2
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	9bc080e7          	jalr	-1604(ra) # 80003f3a <dirlink>
    80005586:	04054363          	bltz	a0,800055cc <sys_link+0x100>
  iunlockput(dp);
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	51c080e7          	jalr	1308(ra) # 80003aa8 <iunlockput>
  iput(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	46a080e7          	jalr	1130(ra) # 80003a00 <iput>
  end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	cea080e7          	jalr	-790(ra) # 80004288 <end_op>
  return 0;
    800055a6:	4781                	li	a5,0
    800055a8:	a085                	j	80005608 <sys_link+0x13c>
    end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	cde080e7          	jalr	-802(ra) # 80004288 <end_op>
    return -1;
    800055b2:	57fd                	li	a5,-1
    800055b4:	a891                	j	80005608 <sys_link+0x13c>
    iunlockput(ip);
    800055b6:	8526                	mv	a0,s1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	4f0080e7          	jalr	1264(ra) # 80003aa8 <iunlockput>
    end_op();
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	cc8080e7          	jalr	-824(ra) # 80004288 <end_op>
    return -1;
    800055c8:	57fd                	li	a5,-1
    800055ca:	a83d                	j	80005608 <sys_link+0x13c>
    iunlockput(dp);
    800055cc:	854a                	mv	a0,s2
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	4da080e7          	jalr	1242(ra) # 80003aa8 <iunlockput>
  ilock(ip);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	26e080e7          	jalr	622(ra) # 80003846 <ilock>
  ip->nlink--;
    800055e0:	04a4d783          	lhu	a5,74(s1)
    800055e4:	37fd                	addiw	a5,a5,-1
    800055e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	190080e7          	jalr	400(ra) # 8000377c <iupdate>
  iunlockput(ip);
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	4b2080e7          	jalr	1202(ra) # 80003aa8 <iunlockput>
  end_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	c8a080e7          	jalr	-886(ra) # 80004288 <end_op>
  return -1;
    80005606:	57fd                	li	a5,-1
}
    80005608:	853e                	mv	a0,a5
    8000560a:	70b2                	ld	ra,296(sp)
    8000560c:	7412                	ld	s0,288(sp)
    8000560e:	64f2                	ld	s1,280(sp)
    80005610:	6952                	ld	s2,272(sp)
    80005612:	6155                	addi	sp,sp,304
    80005614:	8082                	ret

0000000080005616 <sys_unlink>:
{
    80005616:	7151                	addi	sp,sp,-240
    80005618:	f586                	sd	ra,232(sp)
    8000561a:	f1a2                	sd	s0,224(sp)
    8000561c:	eda6                	sd	s1,216(sp)
    8000561e:	e9ca                	sd	s2,208(sp)
    80005620:	e5ce                	sd	s3,200(sp)
    80005622:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005624:	08000613          	li	a2,128
    80005628:	f3040593          	addi	a1,s0,-208
    8000562c:	4501                	li	a0,0
    8000562e:	ffffd097          	auipc	ra,0xffffd
    80005632:	56e080e7          	jalr	1390(ra) # 80002b9c <argstr>
    80005636:	18054163          	bltz	a0,800057b8 <sys_unlink+0x1a2>
  begin_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	bce080e7          	jalr	-1074(ra) # 80004208 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005642:	fb040593          	addi	a1,s0,-80
    80005646:	f3040513          	addi	a0,s0,-208
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	9c0080e7          	jalr	-1600(ra) # 8000400a <nameiparent>
    80005652:	84aa                	mv	s1,a0
    80005654:	c979                	beqz	a0,8000572a <sys_unlink+0x114>
  ilock(dp);
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	1f0080e7          	jalr	496(ra) # 80003846 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000565e:	00003597          	auipc	a1,0x3
    80005662:	0c258593          	addi	a1,a1,194 # 80008720 <syscalls+0x2b0>
    80005666:	fb040513          	addi	a0,s0,-80
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	6a6080e7          	jalr	1702(ra) # 80003d10 <namecmp>
    80005672:	14050a63          	beqz	a0,800057c6 <sys_unlink+0x1b0>
    80005676:	00003597          	auipc	a1,0x3
    8000567a:	0b258593          	addi	a1,a1,178 # 80008728 <syscalls+0x2b8>
    8000567e:	fb040513          	addi	a0,s0,-80
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	68e080e7          	jalr	1678(ra) # 80003d10 <namecmp>
    8000568a:	12050e63          	beqz	a0,800057c6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000568e:	f2c40613          	addi	a2,s0,-212
    80005692:	fb040593          	addi	a1,s0,-80
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	692080e7          	jalr	1682(ra) # 80003d2a <dirlookup>
    800056a0:	892a                	mv	s2,a0
    800056a2:	12050263          	beqz	a0,800057c6 <sys_unlink+0x1b0>
  ilock(ip);
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	1a0080e7          	jalr	416(ra) # 80003846 <ilock>
  if(ip->nlink < 1)
    800056ae:	04a91783          	lh	a5,74(s2)
    800056b2:	08f05263          	blez	a5,80005736 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056b6:	04491703          	lh	a4,68(s2)
    800056ba:	4785                	li	a5,1
    800056bc:	08f70563          	beq	a4,a5,80005746 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056c0:	4641                	li	a2,16
    800056c2:	4581                	li	a1,0
    800056c4:	fc040513          	addi	a0,s0,-64
    800056c8:	ffffb097          	auipc	ra,0xffffb
    800056cc:	60a080e7          	jalr	1546(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d0:	4741                	li	a4,16
    800056d2:	f2c42683          	lw	a3,-212(s0)
    800056d6:	fc040613          	addi	a2,s0,-64
    800056da:	4581                	li	a1,0
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	514080e7          	jalr	1300(ra) # 80003bf2 <writei>
    800056e6:	47c1                	li	a5,16
    800056e8:	0af51563          	bne	a0,a5,80005792 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056ec:	04491703          	lh	a4,68(s2)
    800056f0:	4785                	li	a5,1
    800056f2:	0af70863          	beq	a4,a5,800057a2 <sys_unlink+0x18c>
  iunlockput(dp);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	3b0080e7          	jalr	944(ra) # 80003aa8 <iunlockput>
  ip->nlink--;
    80005700:	04a95783          	lhu	a5,74(s2)
    80005704:	37fd                	addiw	a5,a5,-1
    80005706:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000570a:	854a                	mv	a0,s2
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	070080e7          	jalr	112(ra) # 8000377c <iupdate>
  iunlockput(ip);
    80005714:	854a                	mv	a0,s2
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	392080e7          	jalr	914(ra) # 80003aa8 <iunlockput>
  end_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	b6a080e7          	jalr	-1174(ra) # 80004288 <end_op>
  return 0;
    80005726:	4501                	li	a0,0
    80005728:	a84d                	j	800057da <sys_unlink+0x1c4>
    end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	b5e080e7          	jalr	-1186(ra) # 80004288 <end_op>
    return -1;
    80005732:	557d                	li	a0,-1
    80005734:	a05d                	j	800057da <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005736:	00003517          	auipc	a0,0x3
    8000573a:	ffa50513          	addi	a0,a0,-6 # 80008730 <syscalls+0x2c0>
    8000573e:	ffffb097          	auipc	ra,0xffffb
    80005742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005746:	04c92703          	lw	a4,76(s2)
    8000574a:	02000793          	li	a5,32
    8000574e:	f6e7f9e3          	bgeu	a5,a4,800056c0 <sys_unlink+0xaa>
    80005752:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005756:	4741                	li	a4,16
    80005758:	86ce                	mv	a3,s3
    8000575a:	f1840613          	addi	a2,s0,-232
    8000575e:	4581                	li	a1,0
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	398080e7          	jalr	920(ra) # 80003afa <readi>
    8000576a:	47c1                	li	a5,16
    8000576c:	00f51b63          	bne	a0,a5,80005782 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005770:	f1845783          	lhu	a5,-232(s0)
    80005774:	e7a1                	bnez	a5,800057bc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005776:	29c1                	addiw	s3,s3,16
    80005778:	04c92783          	lw	a5,76(s2)
    8000577c:	fcf9ede3          	bltu	s3,a5,80005756 <sys_unlink+0x140>
    80005780:	b781                	j	800056c0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005782:	00003517          	auipc	a0,0x3
    80005786:	fc650513          	addi	a0,a0,-58 # 80008748 <syscalls+0x2d8>
    8000578a:	ffffb097          	auipc	ra,0xffffb
    8000578e:	db4080e7          	jalr	-588(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005792:	00003517          	auipc	a0,0x3
    80005796:	fce50513          	addi	a0,a0,-50 # 80008760 <syscalls+0x2f0>
    8000579a:	ffffb097          	auipc	ra,0xffffb
    8000579e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>
    dp->nlink--;
    800057a2:	04a4d783          	lhu	a5,74(s1)
    800057a6:	37fd                	addiw	a5,a5,-1
    800057a8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	fce080e7          	jalr	-50(ra) # 8000377c <iupdate>
    800057b6:	b781                	j	800056f6 <sys_unlink+0xe0>
    return -1;
    800057b8:	557d                	li	a0,-1
    800057ba:	a005                	j	800057da <sys_unlink+0x1c4>
    iunlockput(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	2ea080e7          	jalr	746(ra) # 80003aa8 <iunlockput>
  iunlockput(dp);
    800057c6:	8526                	mv	a0,s1
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	2e0080e7          	jalr	736(ra) # 80003aa8 <iunlockput>
  end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	ab8080e7          	jalr	-1352(ra) # 80004288 <end_op>
  return -1;
    800057d8:	557d                	li	a0,-1
}
    800057da:	70ae                	ld	ra,232(sp)
    800057dc:	740e                	ld	s0,224(sp)
    800057de:	64ee                	ld	s1,216(sp)
    800057e0:	694e                	ld	s2,208(sp)
    800057e2:	69ae                	ld	s3,200(sp)
    800057e4:	616d                	addi	sp,sp,240
    800057e6:	8082                	ret

00000000800057e8 <sys_open>:

uint64
sys_open(void)
{
    800057e8:	7131                	addi	sp,sp,-192
    800057ea:	fd06                	sd	ra,184(sp)
    800057ec:	f922                	sd	s0,176(sp)
    800057ee:	f526                	sd	s1,168(sp)
    800057f0:	f14a                	sd	s2,160(sp)
    800057f2:	ed4e                	sd	s3,152(sp)
    800057f4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057f6:	f4c40593          	addi	a1,s0,-180
    800057fa:	4505                	li	a0,1
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	360080e7          	jalr	864(ra) # 80002b5c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005804:	08000613          	li	a2,128
    80005808:	f5040593          	addi	a1,s0,-176
    8000580c:	4501                	li	a0,0
    8000580e:	ffffd097          	auipc	ra,0xffffd
    80005812:	38e080e7          	jalr	910(ra) # 80002b9c <argstr>
    80005816:	87aa                	mv	a5,a0
    return -1;
    80005818:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000581a:	0a07c963          	bltz	a5,800058cc <sys_open+0xe4>

  begin_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	9ea080e7          	jalr	-1558(ra) # 80004208 <begin_op>

  if(omode & O_CREATE){
    80005826:	f4c42783          	lw	a5,-180(s0)
    8000582a:	2007f793          	andi	a5,a5,512
    8000582e:	cfc5                	beqz	a5,800058e6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005830:	4681                	li	a3,0
    80005832:	4601                	li	a2,0
    80005834:	4589                	li	a1,2
    80005836:	f5040513          	addi	a0,s0,-176
    8000583a:	00000097          	auipc	ra,0x0
    8000583e:	976080e7          	jalr	-1674(ra) # 800051b0 <create>
    80005842:	84aa                	mv	s1,a0
    if(ip == 0){
    80005844:	c959                	beqz	a0,800058da <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005846:	04449703          	lh	a4,68(s1)
    8000584a:	478d                	li	a5,3
    8000584c:	00f71763          	bne	a4,a5,8000585a <sys_open+0x72>
    80005850:	0464d703          	lhu	a4,70(s1)
    80005854:	47a5                	li	a5,9
    80005856:	0ce7ed63          	bltu	a5,a4,80005930 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	dbe080e7          	jalr	-578(ra) # 80004618 <filealloc>
    80005862:	89aa                	mv	s3,a0
    80005864:	10050363          	beqz	a0,8000596a <sys_open+0x182>
    80005868:	00000097          	auipc	ra,0x0
    8000586c:	906080e7          	jalr	-1786(ra) # 8000516e <fdalloc>
    80005870:	892a                	mv	s2,a0
    80005872:	0e054763          	bltz	a0,80005960 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005876:	04449703          	lh	a4,68(s1)
    8000587a:	478d                	li	a5,3
    8000587c:	0cf70563          	beq	a4,a5,80005946 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005880:	4789                	li	a5,2
    80005882:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005886:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000588a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000588e:	f4c42783          	lw	a5,-180(s0)
    80005892:	0017c713          	xori	a4,a5,1
    80005896:	8b05                	andi	a4,a4,1
    80005898:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000589c:	0037f713          	andi	a4,a5,3
    800058a0:	00e03733          	snez	a4,a4
    800058a4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058a8:	4007f793          	andi	a5,a5,1024
    800058ac:	c791                	beqz	a5,800058b8 <sys_open+0xd0>
    800058ae:	04449703          	lh	a4,68(s1)
    800058b2:	4789                	li	a5,2
    800058b4:	0af70063          	beq	a4,a5,80005954 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	04e080e7          	jalr	78(ra) # 80003908 <iunlock>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	9c6080e7          	jalr	-1594(ra) # 80004288 <end_op>

  return fd;
    800058ca:	854a                	mv	a0,s2
}
    800058cc:	70ea                	ld	ra,184(sp)
    800058ce:	744a                	ld	s0,176(sp)
    800058d0:	74aa                	ld	s1,168(sp)
    800058d2:	790a                	ld	s2,160(sp)
    800058d4:	69ea                	ld	s3,152(sp)
    800058d6:	6129                	addi	sp,sp,192
    800058d8:	8082                	ret
      end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	9ae080e7          	jalr	-1618(ra) # 80004288 <end_op>
      return -1;
    800058e2:	557d                	li	a0,-1
    800058e4:	b7e5                	j	800058cc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058e6:	f5040513          	addi	a0,s0,-176
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	702080e7          	jalr	1794(ra) # 80003fec <namei>
    800058f2:	84aa                	mv	s1,a0
    800058f4:	c905                	beqz	a0,80005924 <sys_open+0x13c>
    ilock(ip);
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	f50080e7          	jalr	-176(ra) # 80003846 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058fe:	04449703          	lh	a4,68(s1)
    80005902:	4785                	li	a5,1
    80005904:	f4f711e3          	bne	a4,a5,80005846 <sys_open+0x5e>
    80005908:	f4c42783          	lw	a5,-180(s0)
    8000590c:	d7b9                	beqz	a5,8000585a <sys_open+0x72>
      iunlockput(ip);
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	198080e7          	jalr	408(ra) # 80003aa8 <iunlockput>
      end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	970080e7          	jalr	-1680(ra) # 80004288 <end_op>
      return -1;
    80005920:	557d                	li	a0,-1
    80005922:	b76d                	j	800058cc <sys_open+0xe4>
      end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	964080e7          	jalr	-1692(ra) # 80004288 <end_op>
      return -1;
    8000592c:	557d                	li	a0,-1
    8000592e:	bf79                	j	800058cc <sys_open+0xe4>
    iunlockput(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	176080e7          	jalr	374(ra) # 80003aa8 <iunlockput>
    end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	94e080e7          	jalr	-1714(ra) # 80004288 <end_op>
    return -1;
    80005942:	557d                	li	a0,-1
    80005944:	b761                	j	800058cc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005946:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000594a:	04649783          	lh	a5,70(s1)
    8000594e:	02f99223          	sh	a5,36(s3)
    80005952:	bf25                	j	8000588a <sys_open+0xa2>
    itrunc(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	ffe080e7          	jalr	-2(ra) # 80003954 <itrunc>
    8000595e:	bfa9                	j	800058b8 <sys_open+0xd0>
      fileclose(f);
    80005960:	854e                	mv	a0,s3
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	d72080e7          	jalr	-654(ra) # 800046d4 <fileclose>
    iunlockput(ip);
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	13c080e7          	jalr	316(ra) # 80003aa8 <iunlockput>
    end_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	914080e7          	jalr	-1772(ra) # 80004288 <end_op>
    return -1;
    8000597c:	557d                	li	a0,-1
    8000597e:	b7b9                	j	800058cc <sys_open+0xe4>

0000000080005980 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005980:	7175                	addi	sp,sp,-144
    80005982:	e506                	sd	ra,136(sp)
    80005984:	e122                	sd	s0,128(sp)
    80005986:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	880080e7          	jalr	-1920(ra) # 80004208 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005990:	08000613          	li	a2,128
    80005994:	f7040593          	addi	a1,s0,-144
    80005998:	4501                	li	a0,0
    8000599a:	ffffd097          	auipc	ra,0xffffd
    8000599e:	202080e7          	jalr	514(ra) # 80002b9c <argstr>
    800059a2:	02054963          	bltz	a0,800059d4 <sys_mkdir+0x54>
    800059a6:	4681                	li	a3,0
    800059a8:	4601                	li	a2,0
    800059aa:	4585                	li	a1,1
    800059ac:	f7040513          	addi	a0,s0,-144
    800059b0:	00000097          	auipc	ra,0x0
    800059b4:	800080e7          	jalr	-2048(ra) # 800051b0 <create>
    800059b8:	cd11                	beqz	a0,800059d4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	0ee080e7          	jalr	238(ra) # 80003aa8 <iunlockput>
  end_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	8c6080e7          	jalr	-1850(ra) # 80004288 <end_op>
  return 0;
    800059ca:	4501                	li	a0,0
}
    800059cc:	60aa                	ld	ra,136(sp)
    800059ce:	640a                	ld	s0,128(sp)
    800059d0:	6149                	addi	sp,sp,144
    800059d2:	8082                	ret
    end_op();
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	8b4080e7          	jalr	-1868(ra) # 80004288 <end_op>
    return -1;
    800059dc:	557d                	li	a0,-1
    800059de:	b7fd                	j	800059cc <sys_mkdir+0x4c>

00000000800059e0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059e0:	7135                	addi	sp,sp,-160
    800059e2:	ed06                	sd	ra,152(sp)
    800059e4:	e922                	sd	s0,144(sp)
    800059e6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059e8:	fffff097          	auipc	ra,0xfffff
    800059ec:	820080e7          	jalr	-2016(ra) # 80004208 <begin_op>
  argint(1, &major);
    800059f0:	f6c40593          	addi	a1,s0,-148
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	166080e7          	jalr	358(ra) # 80002b5c <argint>
  argint(2, &minor);
    800059fe:	f6840593          	addi	a1,s0,-152
    80005a02:	4509                	li	a0,2
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	158080e7          	jalr	344(ra) # 80002b5c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a0c:	08000613          	li	a2,128
    80005a10:	f7040593          	addi	a1,s0,-144
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	186080e7          	jalr	390(ra) # 80002b9c <argstr>
    80005a1e:	02054b63          	bltz	a0,80005a54 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a22:	f6841683          	lh	a3,-152(s0)
    80005a26:	f6c41603          	lh	a2,-148(s0)
    80005a2a:	458d                	li	a1,3
    80005a2c:	f7040513          	addi	a0,s0,-144
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	780080e7          	jalr	1920(ra) # 800051b0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a38:	cd11                	beqz	a0,80005a54 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	06e080e7          	jalr	110(ra) # 80003aa8 <iunlockput>
  end_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	846080e7          	jalr	-1978(ra) # 80004288 <end_op>
  return 0;
    80005a4a:	4501                	li	a0,0
}
    80005a4c:	60ea                	ld	ra,152(sp)
    80005a4e:	644a                	ld	s0,144(sp)
    80005a50:	610d                	addi	sp,sp,160
    80005a52:	8082                	ret
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	834080e7          	jalr	-1996(ra) # 80004288 <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	b7fd                	j	80005a4c <sys_mknod+0x6c>

0000000080005a60 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a60:	7135                	addi	sp,sp,-160
    80005a62:	ed06                	sd	ra,152(sp)
    80005a64:	e922                	sd	s0,144(sp)
    80005a66:	e526                	sd	s1,136(sp)
    80005a68:	e14a                	sd	s2,128(sp)
    80005a6a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a6c:	ffffc097          	auipc	ra,0xffffc
    80005a70:	f76080e7          	jalr	-138(ra) # 800019e2 <myproc>
    80005a74:	892a                	mv	s2,a0
  
  begin_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	792080e7          	jalr	1938(ra) # 80004208 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a7e:	08000613          	li	a2,128
    80005a82:	f6040593          	addi	a1,s0,-160
    80005a86:	4501                	li	a0,0
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	114080e7          	jalr	276(ra) # 80002b9c <argstr>
    80005a90:	04054b63          	bltz	a0,80005ae6 <sys_chdir+0x86>
    80005a94:	f6040513          	addi	a0,s0,-160
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	554080e7          	jalr	1364(ra) # 80003fec <namei>
    80005aa0:	84aa                	mv	s1,a0
    80005aa2:	c131                	beqz	a0,80005ae6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	da2080e7          	jalr	-606(ra) # 80003846 <ilock>
  if(ip->type != T_DIR){
    80005aac:	04449703          	lh	a4,68(s1)
    80005ab0:	4785                	li	a5,1
    80005ab2:	04f71063          	bne	a4,a5,80005af2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ab6:	8526                	mv	a0,s1
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	e50080e7          	jalr	-432(ra) # 80003908 <iunlock>
  iput(p->cwd);
    80005ac0:	15093503          	ld	a0,336(s2)
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	f3c080e7          	jalr	-196(ra) # 80003a00 <iput>
  end_op();
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	7bc080e7          	jalr	1980(ra) # 80004288 <end_op>
  p->cwd = ip;
    80005ad4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ad8:	4501                	li	a0,0
}
    80005ada:	60ea                	ld	ra,152(sp)
    80005adc:	644a                	ld	s0,144(sp)
    80005ade:	64aa                	ld	s1,136(sp)
    80005ae0:	690a                	ld	s2,128(sp)
    80005ae2:	610d                	addi	sp,sp,160
    80005ae4:	8082                	ret
    end_op();
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	7a2080e7          	jalr	1954(ra) # 80004288 <end_op>
    return -1;
    80005aee:	557d                	li	a0,-1
    80005af0:	b7ed                	j	80005ada <sys_chdir+0x7a>
    iunlockput(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	fb4080e7          	jalr	-76(ra) # 80003aa8 <iunlockput>
    end_op();
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	78c080e7          	jalr	1932(ra) # 80004288 <end_op>
    return -1;
    80005b04:	557d                	li	a0,-1
    80005b06:	bfd1                	j	80005ada <sys_chdir+0x7a>

0000000080005b08 <sys_exec>:

uint64
sys_exec(void)
{
    80005b08:	7145                	addi	sp,sp,-464
    80005b0a:	e786                	sd	ra,456(sp)
    80005b0c:	e3a2                	sd	s0,448(sp)
    80005b0e:	ff26                	sd	s1,440(sp)
    80005b10:	fb4a                	sd	s2,432(sp)
    80005b12:	f74e                	sd	s3,424(sp)
    80005b14:	f352                	sd	s4,416(sp)
    80005b16:	ef56                	sd	s5,408(sp)
    80005b18:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b1a:	e3840593          	addi	a1,s0,-456
    80005b1e:	4505                	li	a0,1
    80005b20:	ffffd097          	auipc	ra,0xffffd
    80005b24:	05c080e7          	jalr	92(ra) # 80002b7c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b28:	08000613          	li	a2,128
    80005b2c:	f4040593          	addi	a1,s0,-192
    80005b30:	4501                	li	a0,0
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	06a080e7          	jalr	106(ra) # 80002b9c <argstr>
    80005b3a:	87aa                	mv	a5,a0
    return -1;
    80005b3c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b3e:	0c07c263          	bltz	a5,80005c02 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b42:	10000613          	li	a2,256
    80005b46:	4581                	li	a1,0
    80005b48:	e4040513          	addi	a0,s0,-448
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	186080e7          	jalr	390(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b54:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b58:	89a6                	mv	s3,s1
    80005b5a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b5c:	02000a13          	li	s4,32
    80005b60:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b64:	00391793          	slli	a5,s2,0x3
    80005b68:	e3040593          	addi	a1,s0,-464
    80005b6c:	e3843503          	ld	a0,-456(s0)
    80005b70:	953e                	add	a0,a0,a5
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	f4c080e7          	jalr	-180(ra) # 80002abe <fetchaddr>
    80005b7a:	02054a63          	bltz	a0,80005bae <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b7e:	e3043783          	ld	a5,-464(s0)
    80005b82:	c3b9                	beqz	a5,80005bc8 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b84:	ffffb097          	auipc	ra,0xffffb
    80005b88:	f62080e7          	jalr	-158(ra) # 80000ae6 <kalloc>
    80005b8c:	85aa                	mv	a1,a0
    80005b8e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b92:	cd11                	beqz	a0,80005bae <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b94:	6605                	lui	a2,0x1
    80005b96:	e3043503          	ld	a0,-464(s0)
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	f76080e7          	jalr	-138(ra) # 80002b10 <fetchstr>
    80005ba2:	00054663          	bltz	a0,80005bae <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ba6:	0905                	addi	s2,s2,1
    80005ba8:	09a1                	addi	s3,s3,8
    80005baa:	fb491be3          	bne	s2,s4,80005b60 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bae:	10048913          	addi	s2,s1,256
    80005bb2:	6088                	ld	a0,0(s1)
    80005bb4:	c531                	beqz	a0,80005c00 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bb6:	ffffb097          	auipc	ra,0xffffb
    80005bba:	e34080e7          	jalr	-460(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbe:	04a1                	addi	s1,s1,8
    80005bc0:	ff2499e3          	bne	s1,s2,80005bb2 <sys_exec+0xaa>
  return -1;
    80005bc4:	557d                	li	a0,-1
    80005bc6:	a835                	j	80005c02 <sys_exec+0xfa>
      argv[i] = 0;
    80005bc8:	0a8e                	slli	s5,s5,0x3
    80005bca:	fc040793          	addi	a5,s0,-64
    80005bce:	9abe                	add	s5,s5,a5
    80005bd0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bd4:	e4040593          	addi	a1,s0,-448
    80005bd8:	f4040513          	addi	a0,s0,-192
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	172080e7          	jalr	370(ra) # 80004d4e <exec>
    80005be4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be6:	10048993          	addi	s3,s1,256
    80005bea:	6088                	ld	a0,0(s1)
    80005bec:	c901                	beqz	a0,80005bfc <sys_exec+0xf4>
    kfree(argv[i]);
    80005bee:	ffffb097          	auipc	ra,0xffffb
    80005bf2:	dfc080e7          	jalr	-516(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf6:	04a1                	addi	s1,s1,8
    80005bf8:	ff3499e3          	bne	s1,s3,80005bea <sys_exec+0xe2>
  return ret;
    80005bfc:	854a                	mv	a0,s2
    80005bfe:	a011                	j	80005c02 <sys_exec+0xfa>
  return -1;
    80005c00:	557d                	li	a0,-1
}
    80005c02:	60be                	ld	ra,456(sp)
    80005c04:	641e                	ld	s0,448(sp)
    80005c06:	74fa                	ld	s1,440(sp)
    80005c08:	795a                	ld	s2,432(sp)
    80005c0a:	79ba                	ld	s3,424(sp)
    80005c0c:	7a1a                	ld	s4,416(sp)
    80005c0e:	6afa                	ld	s5,408(sp)
    80005c10:	6179                	addi	sp,sp,464
    80005c12:	8082                	ret

0000000080005c14 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c14:	7139                	addi	sp,sp,-64
    80005c16:	fc06                	sd	ra,56(sp)
    80005c18:	f822                	sd	s0,48(sp)
    80005c1a:	f426                	sd	s1,40(sp)
    80005c1c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c1e:	ffffc097          	auipc	ra,0xffffc
    80005c22:	dc4080e7          	jalr	-572(ra) # 800019e2 <myproc>
    80005c26:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c28:	fd840593          	addi	a1,s0,-40
    80005c2c:	4501                	li	a0,0
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	f4e080e7          	jalr	-178(ra) # 80002b7c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c36:	fc840593          	addi	a1,s0,-56
    80005c3a:	fd040513          	addi	a0,s0,-48
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	dc6080e7          	jalr	-570(ra) # 80004a04 <pipealloc>
    return -1;
    80005c46:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c48:	0c054463          	bltz	a0,80005d10 <sys_pipe+0xfc>
  fd0 = -1;
    80005c4c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c50:	fd043503          	ld	a0,-48(s0)
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	51a080e7          	jalr	1306(ra) # 8000516e <fdalloc>
    80005c5c:	fca42223          	sw	a0,-60(s0)
    80005c60:	08054b63          	bltz	a0,80005cf6 <sys_pipe+0xe2>
    80005c64:	fc843503          	ld	a0,-56(s0)
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	506080e7          	jalr	1286(ra) # 8000516e <fdalloc>
    80005c70:	fca42023          	sw	a0,-64(s0)
    80005c74:	06054863          	bltz	a0,80005ce4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c78:	4691                	li	a3,4
    80005c7a:	fc440613          	addi	a2,s0,-60
    80005c7e:	fd843583          	ld	a1,-40(s0)
    80005c82:	68a8                	ld	a0,80(s1)
    80005c84:	ffffc097          	auipc	ra,0xffffc
    80005c88:	a1a080e7          	jalr	-1510(ra) # 8000169e <copyout>
    80005c8c:	02054063          	bltz	a0,80005cac <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c90:	4691                	li	a3,4
    80005c92:	fc040613          	addi	a2,s0,-64
    80005c96:	fd843583          	ld	a1,-40(s0)
    80005c9a:	0591                	addi	a1,a1,4
    80005c9c:	68a8                	ld	a0,80(s1)
    80005c9e:	ffffc097          	auipc	ra,0xffffc
    80005ca2:	a00080e7          	jalr	-1536(ra) # 8000169e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ca6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca8:	06055463          	bgez	a0,80005d10 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005cac:	fc442783          	lw	a5,-60(s0)
    80005cb0:	07e9                	addi	a5,a5,26
    80005cb2:	078e                	slli	a5,a5,0x3
    80005cb4:	97a6                	add	a5,a5,s1
    80005cb6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cba:	fc042503          	lw	a0,-64(s0)
    80005cbe:	0569                	addi	a0,a0,26
    80005cc0:	050e                	slli	a0,a0,0x3
    80005cc2:	94aa                	add	s1,s1,a0
    80005cc4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cc8:	fd043503          	ld	a0,-48(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	a08080e7          	jalr	-1528(ra) # 800046d4 <fileclose>
    fileclose(wf);
    80005cd4:	fc843503          	ld	a0,-56(s0)
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	9fc080e7          	jalr	-1540(ra) # 800046d4 <fileclose>
    return -1;
    80005ce0:	57fd                	li	a5,-1
    80005ce2:	a03d                	j	80005d10 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ce4:	fc442783          	lw	a5,-60(s0)
    80005ce8:	0007c763          	bltz	a5,80005cf6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005cec:	07e9                	addi	a5,a5,26
    80005cee:	078e                	slli	a5,a5,0x3
    80005cf0:	94be                	add	s1,s1,a5
    80005cf2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cf6:	fd043503          	ld	a0,-48(s0)
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	9da080e7          	jalr	-1574(ra) # 800046d4 <fileclose>
    fileclose(wf);
    80005d02:	fc843503          	ld	a0,-56(s0)
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	9ce080e7          	jalr	-1586(ra) # 800046d4 <fileclose>
    return -1;
    80005d0e:	57fd                	li	a5,-1
}
    80005d10:	853e                	mv	a0,a5
    80005d12:	70e2                	ld	ra,56(sp)
    80005d14:	7442                	ld	s0,48(sp)
    80005d16:	74a2                	ld	s1,40(sp)
    80005d18:	6121                	addi	sp,sp,64
    80005d1a:	8082                	ret
    80005d1c:	0000                	unimp
	...

0000000080005d20 <kernelvec>:
    80005d20:	7111                	addi	sp,sp,-256
    80005d22:	e006                	sd	ra,0(sp)
    80005d24:	e40a                	sd	sp,8(sp)
    80005d26:	e80e                	sd	gp,16(sp)
    80005d28:	ec12                	sd	tp,24(sp)
    80005d2a:	f016                	sd	t0,32(sp)
    80005d2c:	f41a                	sd	t1,40(sp)
    80005d2e:	f81e                	sd	t2,48(sp)
    80005d30:	fc22                	sd	s0,56(sp)
    80005d32:	e0a6                	sd	s1,64(sp)
    80005d34:	e4aa                	sd	a0,72(sp)
    80005d36:	e8ae                	sd	a1,80(sp)
    80005d38:	ecb2                	sd	a2,88(sp)
    80005d3a:	f0b6                	sd	a3,96(sp)
    80005d3c:	f4ba                	sd	a4,104(sp)
    80005d3e:	f8be                	sd	a5,112(sp)
    80005d40:	fcc2                	sd	a6,120(sp)
    80005d42:	e146                	sd	a7,128(sp)
    80005d44:	e54a                	sd	s2,136(sp)
    80005d46:	e94e                	sd	s3,144(sp)
    80005d48:	ed52                	sd	s4,152(sp)
    80005d4a:	f156                	sd	s5,160(sp)
    80005d4c:	f55a                	sd	s6,168(sp)
    80005d4e:	f95e                	sd	s7,176(sp)
    80005d50:	fd62                	sd	s8,184(sp)
    80005d52:	e1e6                	sd	s9,192(sp)
    80005d54:	e5ea                	sd	s10,200(sp)
    80005d56:	e9ee                	sd	s11,208(sp)
    80005d58:	edf2                	sd	t3,216(sp)
    80005d5a:	f1f6                	sd	t4,224(sp)
    80005d5c:	f5fa                	sd	t5,232(sp)
    80005d5e:	f9fe                	sd	t6,240(sp)
    80005d60:	c2bfc0ef          	jal	ra,8000298a <kerneltrap>
    80005d64:	6082                	ld	ra,0(sp)
    80005d66:	6122                	ld	sp,8(sp)
    80005d68:	61c2                	ld	gp,16(sp)
    80005d6a:	7282                	ld	t0,32(sp)
    80005d6c:	7322                	ld	t1,40(sp)
    80005d6e:	73c2                	ld	t2,48(sp)
    80005d70:	7462                	ld	s0,56(sp)
    80005d72:	6486                	ld	s1,64(sp)
    80005d74:	6526                	ld	a0,72(sp)
    80005d76:	65c6                	ld	a1,80(sp)
    80005d78:	6666                	ld	a2,88(sp)
    80005d7a:	7686                	ld	a3,96(sp)
    80005d7c:	7726                	ld	a4,104(sp)
    80005d7e:	77c6                	ld	a5,112(sp)
    80005d80:	7866                	ld	a6,120(sp)
    80005d82:	688a                	ld	a7,128(sp)
    80005d84:	692a                	ld	s2,136(sp)
    80005d86:	69ca                	ld	s3,144(sp)
    80005d88:	6a6a                	ld	s4,152(sp)
    80005d8a:	7a8a                	ld	s5,160(sp)
    80005d8c:	7b2a                	ld	s6,168(sp)
    80005d8e:	7bca                	ld	s7,176(sp)
    80005d90:	7c6a                	ld	s8,184(sp)
    80005d92:	6c8e                	ld	s9,192(sp)
    80005d94:	6d2e                	ld	s10,200(sp)
    80005d96:	6dce                	ld	s11,208(sp)
    80005d98:	6e6e                	ld	t3,216(sp)
    80005d9a:	7e8e                	ld	t4,224(sp)
    80005d9c:	7f2e                	ld	t5,232(sp)
    80005d9e:	7fce                	ld	t6,240(sp)
    80005da0:	6111                	addi	sp,sp,256
    80005da2:	10200073          	sret
    80005da6:	00000013          	nop
    80005daa:	00000013          	nop
    80005dae:	0001                	nop

0000000080005db0 <timervec>:
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	e10c                	sd	a1,0(a0)
    80005db6:	e510                	sd	a2,8(a0)
    80005db8:	e914                	sd	a3,16(a0)
    80005dba:	6d0c                	ld	a1,24(a0)
    80005dbc:	7110                	ld	a2,32(a0)
    80005dbe:	6194                	ld	a3,0(a1)
    80005dc0:	96b2                	add	a3,a3,a2
    80005dc2:	e194                	sd	a3,0(a1)
    80005dc4:	4589                	li	a1,2
    80005dc6:	14459073          	csrw	sip,a1
    80005dca:	6914                	ld	a3,16(a0)
    80005dcc:	6510                	ld	a2,8(a0)
    80005dce:	610c                	ld	a1,0(a0)
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	30200073          	mret
	...

0000000080005dda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dda:	1141                	addi	sp,sp,-16
    80005ddc:	e422                	sd	s0,8(sp)
    80005dde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005de0:	0c0007b7          	lui	a5,0xc000
    80005de4:	4705                	li	a4,1
    80005de6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005de8:	c3d8                	sw	a4,4(a5)
}
    80005dea:	6422                	ld	s0,8(sp)
    80005dec:	0141                	addi	sp,sp,16
    80005dee:	8082                	ret

0000000080005df0 <plicinithart>:

void
plicinithart(void)
{
    80005df0:	1141                	addi	sp,sp,-16
    80005df2:	e406                	sd	ra,8(sp)
    80005df4:	e022                	sd	s0,0(sp)
    80005df6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	bbe080e7          	jalr	-1090(ra) # 800019b6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e00:	0085171b          	slliw	a4,a0,0x8
    80005e04:	0c0027b7          	lui	a5,0xc002
    80005e08:	97ba                	add	a5,a5,a4
    80005e0a:	40200713          	li	a4,1026
    80005e0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e12:	00d5151b          	slliw	a0,a0,0xd
    80005e16:	0c2017b7          	lui	a5,0xc201
    80005e1a:	953e                	add	a0,a0,a5
    80005e1c:	00052023          	sw	zero,0(a0)
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret

0000000080005e28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e28:	1141                	addi	sp,sp,-16
    80005e2a:	e406                	sd	ra,8(sp)
    80005e2c:	e022                	sd	s0,0(sp)
    80005e2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	b86080e7          	jalr	-1146(ra) # 800019b6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e38:	00d5179b          	slliw	a5,a0,0xd
    80005e3c:	0c201537          	lui	a0,0xc201
    80005e40:	953e                	add	a0,a0,a5
  return irq;
}
    80005e42:	4148                	lw	a0,4(a0)
    80005e44:	60a2                	ld	ra,8(sp)
    80005e46:	6402                	ld	s0,0(sp)
    80005e48:	0141                	addi	sp,sp,16
    80005e4a:	8082                	ret

0000000080005e4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e4c:	1101                	addi	sp,sp,-32
    80005e4e:	ec06                	sd	ra,24(sp)
    80005e50:	e822                	sd	s0,16(sp)
    80005e52:	e426                	sd	s1,8(sp)
    80005e54:	1000                	addi	s0,sp,32
    80005e56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b5e080e7          	jalr	-1186(ra) # 800019b6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e60:	00d5151b          	slliw	a0,a0,0xd
    80005e64:	0c2017b7          	lui	a5,0xc201
    80005e68:	97aa                	add	a5,a5,a0
    80005e6a:	c3c4                	sw	s1,4(a5)
}
    80005e6c:	60e2                	ld	ra,24(sp)
    80005e6e:	6442                	ld	s0,16(sp)
    80005e70:	64a2                	ld	s1,8(sp)
    80005e72:	6105                	addi	sp,sp,32
    80005e74:	8082                	ret

0000000080005e76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e76:	1141                	addi	sp,sp,-16
    80005e78:	e406                	sd	ra,8(sp)
    80005e7a:	e022                	sd	s0,0(sp)
    80005e7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e7e:	479d                	li	a5,7
    80005e80:	04a7cc63          	blt	a5,a0,80005ed8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e84:	0001d797          	auipc	a5,0x1d
    80005e88:	91c78793          	addi	a5,a5,-1764 # 800227a0 <disk>
    80005e8c:	97aa                	add	a5,a5,a0
    80005e8e:	0187c783          	lbu	a5,24(a5)
    80005e92:	ebb9                	bnez	a5,80005ee8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e94:	00451613          	slli	a2,a0,0x4
    80005e98:	0001d797          	auipc	a5,0x1d
    80005e9c:	90878793          	addi	a5,a5,-1784 # 800227a0 <disk>
    80005ea0:	6394                	ld	a3,0(a5)
    80005ea2:	96b2                	add	a3,a3,a2
    80005ea4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ea8:	6398                	ld	a4,0(a5)
    80005eaa:	9732                	add	a4,a4,a2
    80005eac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005eb0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005eb4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005eb8:	953e                	add	a0,a0,a5
    80005eba:	4785                	li	a5,1
    80005ebc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005ec0:	0001d517          	auipc	a0,0x1d
    80005ec4:	8f850513          	addi	a0,a0,-1800 # 800227b8 <disk+0x18>
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	28c080e7          	jalr	652(ra) # 80002154 <wakeup>
}
    80005ed0:	60a2                	ld	ra,8(sp)
    80005ed2:	6402                	ld	s0,0(sp)
    80005ed4:	0141                	addi	sp,sp,16
    80005ed6:	8082                	ret
    panic("free_desc 1");
    80005ed8:	00003517          	auipc	a0,0x3
    80005edc:	89850513          	addi	a0,a0,-1896 # 80008770 <syscalls+0x300>
    80005ee0:	ffffa097          	auipc	ra,0xffffa
    80005ee4:	65e080e7          	jalr	1630(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	89850513          	addi	a0,a0,-1896 # 80008780 <syscalls+0x310>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>

0000000080005ef8 <virtio_disk_init>:
{
    80005ef8:	1101                	addi	sp,sp,-32
    80005efa:	ec06                	sd	ra,24(sp)
    80005efc:	e822                	sd	s0,16(sp)
    80005efe:	e426                	sd	s1,8(sp)
    80005f00:	e04a                	sd	s2,0(sp)
    80005f02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f04:	00003597          	auipc	a1,0x3
    80005f08:	88c58593          	addi	a1,a1,-1908 # 80008790 <syscalls+0x320>
    80005f0c:	0001d517          	auipc	a0,0x1d
    80005f10:	9bc50513          	addi	a0,a0,-1604 # 800228c8 <disk+0x128>
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	c32080e7          	jalr	-974(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f1c:	100017b7          	lui	a5,0x10001
    80005f20:	4398                	lw	a4,0(a5)
    80005f22:	2701                	sext.w	a4,a4
    80005f24:	747277b7          	lui	a5,0x74727
    80005f28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f2c:	14f71c63          	bne	a4,a5,80006084 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f30:	100017b7          	lui	a5,0x10001
    80005f34:	43dc                	lw	a5,4(a5)
    80005f36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f38:	4709                	li	a4,2
    80005f3a:	14e79563          	bne	a5,a4,80006084 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	479c                	lw	a5,8(a5)
    80005f44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f46:	12e79f63          	bne	a5,a4,80006084 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f4a:	100017b7          	lui	a5,0x10001
    80005f4e:	47d8                	lw	a4,12(a5)
    80005f50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f52:	554d47b7          	lui	a5,0x554d4
    80005f56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f5a:	12f71563          	bne	a4,a5,80006084 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5e:	100017b7          	lui	a5,0x10001
    80005f62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f66:	4705                	li	a4,1
    80005f68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f6a:	470d                	li	a4,3
    80005f6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f6e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f70:	c7ffe737          	lui	a4,0xc7ffe
    80005f74:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd8e67>
    80005f78:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f7a:	2701                	sext.w	a4,a4
    80005f7c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f7e:	472d                	li	a4,11
    80005f80:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f82:	5bbc                	lw	a5,112(a5)
    80005f84:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f88:	8ba1                	andi	a5,a5,8
    80005f8a:	10078563          	beqz	a5,80006094 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f8e:	100017b7          	lui	a5,0x10001
    80005f92:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f96:	43fc                	lw	a5,68(a5)
    80005f98:	2781                	sext.w	a5,a5
    80005f9a:	10079563          	bnez	a5,800060a4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	5bdc                	lw	a5,52(a5)
    80005fa4:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fa6:	10078763          	beqz	a5,800060b4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005faa:	471d                	li	a4,7
    80005fac:	10f77c63          	bgeu	a4,a5,800060c4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005fb0:	ffffb097          	auipc	ra,0xffffb
    80005fb4:	b36080e7          	jalr	-1226(ra) # 80000ae6 <kalloc>
    80005fb8:	0001c497          	auipc	s1,0x1c
    80005fbc:	7e848493          	addi	s1,s1,2024 # 800227a0 <disk>
    80005fc0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005fc2:	ffffb097          	auipc	ra,0xffffb
    80005fc6:	b24080e7          	jalr	-1244(ra) # 80000ae6 <kalloc>
    80005fca:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	b1a080e7          	jalr	-1254(ra) # 80000ae6 <kalloc>
    80005fd4:	87aa                	mv	a5,a0
    80005fd6:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005fd8:	6088                	ld	a0,0(s1)
    80005fda:	cd6d                	beqz	a0,800060d4 <virtio_disk_init+0x1dc>
    80005fdc:	0001c717          	auipc	a4,0x1c
    80005fe0:	7cc73703          	ld	a4,1996(a4) # 800227a8 <disk+0x8>
    80005fe4:	cb65                	beqz	a4,800060d4 <virtio_disk_init+0x1dc>
    80005fe6:	c7fd                	beqz	a5,800060d4 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005fe8:	6605                	lui	a2,0x1
    80005fea:	4581                	li	a1,0
    80005fec:	ffffb097          	auipc	ra,0xffffb
    80005ff0:	ce6080e7          	jalr	-794(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ff4:	0001c497          	auipc	s1,0x1c
    80005ff8:	7ac48493          	addi	s1,s1,1964 # 800227a0 <disk>
    80005ffc:	6605                	lui	a2,0x1
    80005ffe:	4581                	li	a1,0
    80006000:	6488                	ld	a0,8(s1)
    80006002:	ffffb097          	auipc	ra,0xffffb
    80006006:	cd0080e7          	jalr	-816(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000600a:	6605                	lui	a2,0x1
    8000600c:	4581                	li	a1,0
    8000600e:	6888                	ld	a0,16(s1)
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	cc2080e7          	jalr	-830(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	4721                	li	a4,8
    8000601e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006020:	4098                	lw	a4,0(s1)
    80006022:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006026:	40d8                	lw	a4,4(s1)
    80006028:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000602c:	6498                	ld	a4,8(s1)
    8000602e:	0007069b          	sext.w	a3,a4
    80006032:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006036:	9701                	srai	a4,a4,0x20
    80006038:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000603c:	6898                	ld	a4,16(s1)
    8000603e:	0007069b          	sext.w	a3,a4
    80006042:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006046:	9701                	srai	a4,a4,0x20
    80006048:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000604c:	4705                	li	a4,1
    8000604e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006050:	00e48c23          	sb	a4,24(s1)
    80006054:	00e48ca3          	sb	a4,25(s1)
    80006058:	00e48d23          	sb	a4,26(s1)
    8000605c:	00e48da3          	sb	a4,27(s1)
    80006060:	00e48e23          	sb	a4,28(s1)
    80006064:	00e48ea3          	sb	a4,29(s1)
    80006068:	00e48f23          	sb	a4,30(s1)
    8000606c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006070:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006074:	0727a823          	sw	s2,112(a5)
}
    80006078:	60e2                	ld	ra,24(sp)
    8000607a:	6442                	ld	s0,16(sp)
    8000607c:	64a2                	ld	s1,8(sp)
    8000607e:	6902                	ld	s2,0(sp)
    80006080:	6105                	addi	sp,sp,32
    80006082:	8082                	ret
    panic("could not find virtio disk");
    80006084:	00002517          	auipc	a0,0x2
    80006088:	71c50513          	addi	a0,a0,1820 # 800087a0 <syscalls+0x330>
    8000608c:	ffffa097          	auipc	ra,0xffffa
    80006090:	4b2080e7          	jalr	1202(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006094:	00002517          	auipc	a0,0x2
    80006098:	72c50513          	addi	a0,a0,1836 # 800087c0 <syscalls+0x350>
    8000609c:	ffffa097          	auipc	ra,0xffffa
    800060a0:	4a2080e7          	jalr	1186(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800060a4:	00002517          	auipc	a0,0x2
    800060a8:	73c50513          	addi	a0,a0,1852 # 800087e0 <syscalls+0x370>
    800060ac:	ffffa097          	auipc	ra,0xffffa
    800060b0:	492080e7          	jalr	1170(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060b4:	00002517          	auipc	a0,0x2
    800060b8:	74c50513          	addi	a0,a0,1868 # 80008800 <syscalls+0x390>
    800060bc:	ffffa097          	auipc	ra,0xffffa
    800060c0:	482080e7          	jalr	1154(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060c4:	00002517          	auipc	a0,0x2
    800060c8:	75c50513          	addi	a0,a0,1884 # 80008820 <syscalls+0x3b0>
    800060cc:	ffffa097          	auipc	ra,0xffffa
    800060d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    800060d4:	00002517          	auipc	a0,0x2
    800060d8:	76c50513          	addi	a0,a0,1900 # 80008840 <syscalls+0x3d0>
    800060dc:	ffffa097          	auipc	ra,0xffffa
    800060e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>

00000000800060e4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060e4:	7119                	addi	sp,sp,-128
    800060e6:	fc86                	sd	ra,120(sp)
    800060e8:	f8a2                	sd	s0,112(sp)
    800060ea:	f4a6                	sd	s1,104(sp)
    800060ec:	f0ca                	sd	s2,96(sp)
    800060ee:	ecce                	sd	s3,88(sp)
    800060f0:	e8d2                	sd	s4,80(sp)
    800060f2:	e4d6                	sd	s5,72(sp)
    800060f4:	e0da                	sd	s6,64(sp)
    800060f6:	fc5e                	sd	s7,56(sp)
    800060f8:	f862                	sd	s8,48(sp)
    800060fa:	f466                	sd	s9,40(sp)
    800060fc:	f06a                	sd	s10,32(sp)
    800060fe:	ec6e                	sd	s11,24(sp)
    80006100:	0100                	addi	s0,sp,128
    80006102:	8aaa                	mv	s5,a0
    80006104:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006106:	00c52d03          	lw	s10,12(a0)
    8000610a:	001d1d1b          	slliw	s10,s10,0x1
    8000610e:	1d02                	slli	s10,s10,0x20
    80006110:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006114:	0001c517          	auipc	a0,0x1c
    80006118:	7b450513          	addi	a0,a0,1972 # 800228c8 <disk+0x128>
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	aba080e7          	jalr	-1350(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006124:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006126:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006128:	0001cb97          	auipc	s7,0x1c
    8000612c:	678b8b93          	addi	s7,s7,1656 # 800227a0 <disk>
  for(int i = 0; i < 3; i++){
    80006130:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006132:	0001cc97          	auipc	s9,0x1c
    80006136:	796c8c93          	addi	s9,s9,1942 # 800228c8 <disk+0x128>
    8000613a:	a08d                	j	8000619c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000613c:	00fb8733          	add	a4,s7,a5
    80006140:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006144:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006146:	0207c563          	bltz	a5,80006170 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000614a:	2905                	addiw	s2,s2,1
    8000614c:	0611                	addi	a2,a2,4
    8000614e:	05690c63          	beq	s2,s6,800061a6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006152:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006154:	0001c717          	auipc	a4,0x1c
    80006158:	64c70713          	addi	a4,a4,1612 # 800227a0 <disk>
    8000615c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000615e:	01874683          	lbu	a3,24(a4)
    80006162:	fee9                	bnez	a3,8000613c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006164:	2785                	addiw	a5,a5,1
    80006166:	0705                	addi	a4,a4,1
    80006168:	fe979be3          	bne	a5,s1,8000615e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000616c:	57fd                	li	a5,-1
    8000616e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006170:	01205d63          	blez	s2,8000618a <virtio_disk_rw+0xa6>
    80006174:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006176:	000a2503          	lw	a0,0(s4)
    8000617a:	00000097          	auipc	ra,0x0
    8000617e:	cfc080e7          	jalr	-772(ra) # 80005e76 <free_desc>
      for(int j = 0; j < i; j++)
    80006182:	2d85                	addiw	s11,s11,1
    80006184:	0a11                	addi	s4,s4,4
    80006186:	ffb918e3          	bne	s2,s11,80006176 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000618a:	85e6                	mv	a1,s9
    8000618c:	0001c517          	auipc	a0,0x1c
    80006190:	62c50513          	addi	a0,a0,1580 # 800227b8 <disk+0x18>
    80006194:	ffffc097          	auipc	ra,0xffffc
    80006198:	f5c080e7          	jalr	-164(ra) # 800020f0 <sleep>
  for(int i = 0; i < 3; i++){
    8000619c:	f8040a13          	addi	s4,s0,-128
{
    800061a0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061a2:	894e                	mv	s2,s3
    800061a4:	b77d                	j	80006152 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061a6:	f8042583          	lw	a1,-128(s0)
    800061aa:	00a58793          	addi	a5,a1,10
    800061ae:	0792                	slli	a5,a5,0x4

  if(write)
    800061b0:	0001c617          	auipc	a2,0x1c
    800061b4:	5f060613          	addi	a2,a2,1520 # 800227a0 <disk>
    800061b8:	00f60733          	add	a4,a2,a5
    800061bc:	018036b3          	snez	a3,s8
    800061c0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061c2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800061c6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061ca:	f6078693          	addi	a3,a5,-160
    800061ce:	6218                	ld	a4,0(a2)
    800061d0:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061d2:	00878513          	addi	a0,a5,8
    800061d6:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    800061d8:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061da:	6208                	ld	a0,0(a2)
    800061dc:	96aa                	add	a3,a3,a0
    800061de:	4741                	li	a4,16
    800061e0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061e2:	4705                	li	a4,1
    800061e4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800061e8:	f8442703          	lw	a4,-124(s0)
    800061ec:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061f0:	0712                	slli	a4,a4,0x4
    800061f2:	953a                	add	a0,a0,a4
    800061f4:	058a8693          	addi	a3,s5,88
    800061f8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800061fa:	6208                	ld	a0,0(a2)
    800061fc:	972a                	add	a4,a4,a0
    800061fe:	40000693          	li	a3,1024
    80006202:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006204:	001c3c13          	seqz	s8,s8
    80006208:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000620a:	001c6c13          	ori	s8,s8,1
    8000620e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006212:	f8842603          	lw	a2,-120(s0)
    80006216:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000621a:	0001c697          	auipc	a3,0x1c
    8000621e:	58668693          	addi	a3,a3,1414 # 800227a0 <disk>
    80006222:	00258713          	addi	a4,a1,2
    80006226:	0712                	slli	a4,a4,0x4
    80006228:	9736                	add	a4,a4,a3
    8000622a:	587d                	li	a6,-1
    8000622c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006230:	0612                	slli	a2,a2,0x4
    80006232:	9532                	add	a0,a0,a2
    80006234:	f9078793          	addi	a5,a5,-112
    80006238:	97b6                	add	a5,a5,a3
    8000623a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000623c:	629c                	ld	a5,0(a3)
    8000623e:	97b2                	add	a5,a5,a2
    80006240:	4605                	li	a2,1
    80006242:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006244:	4509                	li	a0,2
    80006246:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000624a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000624e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006252:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006256:	6698                	ld	a4,8(a3)
    80006258:	00275783          	lhu	a5,2(a4)
    8000625c:	8b9d                	andi	a5,a5,7
    8000625e:	0786                	slli	a5,a5,0x1
    80006260:	97ba                	add	a5,a5,a4
    80006262:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006266:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000626a:	6698                	ld	a4,8(a3)
    8000626c:	00275783          	lhu	a5,2(a4)
    80006270:	2785                	addiw	a5,a5,1
    80006272:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006276:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000627a:	100017b7          	lui	a5,0x10001
    8000627e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006282:	004aa783          	lw	a5,4(s5)
    80006286:	02c79163          	bne	a5,a2,800062a8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000628a:	0001c917          	auipc	s2,0x1c
    8000628e:	63e90913          	addi	s2,s2,1598 # 800228c8 <disk+0x128>
  while(b->disk == 1) {
    80006292:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006294:	85ca                	mv	a1,s2
    80006296:	8556                	mv	a0,s5
    80006298:	ffffc097          	auipc	ra,0xffffc
    8000629c:	e58080e7          	jalr	-424(ra) # 800020f0 <sleep>
  while(b->disk == 1) {
    800062a0:	004aa783          	lw	a5,4(s5)
    800062a4:	fe9788e3          	beq	a5,s1,80006294 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800062a8:	f8042903          	lw	s2,-128(s0)
    800062ac:	00290793          	addi	a5,s2,2
    800062b0:	00479713          	slli	a4,a5,0x4
    800062b4:	0001c797          	auipc	a5,0x1c
    800062b8:	4ec78793          	addi	a5,a5,1260 # 800227a0 <disk>
    800062bc:	97ba                	add	a5,a5,a4
    800062be:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800062c2:	0001c997          	auipc	s3,0x1c
    800062c6:	4de98993          	addi	s3,s3,1246 # 800227a0 <disk>
    800062ca:	00491713          	slli	a4,s2,0x4
    800062ce:	0009b783          	ld	a5,0(s3)
    800062d2:	97ba                	add	a5,a5,a4
    800062d4:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062d8:	854a                	mv	a0,s2
    800062da:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062de:	00000097          	auipc	ra,0x0
    800062e2:	b98080e7          	jalr	-1128(ra) # 80005e76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062e6:	8885                	andi	s1,s1,1
    800062e8:	f0ed                	bnez	s1,800062ca <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ea:	0001c517          	auipc	a0,0x1c
    800062ee:	5de50513          	addi	a0,a0,1502 # 800228c8 <disk+0x128>
    800062f2:	ffffb097          	auipc	ra,0xffffb
    800062f6:	998080e7          	jalr	-1640(ra) # 80000c8a <release>
}
    800062fa:	70e6                	ld	ra,120(sp)
    800062fc:	7446                	ld	s0,112(sp)
    800062fe:	74a6                	ld	s1,104(sp)
    80006300:	7906                	ld	s2,96(sp)
    80006302:	69e6                	ld	s3,88(sp)
    80006304:	6a46                	ld	s4,80(sp)
    80006306:	6aa6                	ld	s5,72(sp)
    80006308:	6b06                	ld	s6,64(sp)
    8000630a:	7be2                	ld	s7,56(sp)
    8000630c:	7c42                	ld	s8,48(sp)
    8000630e:	7ca2                	ld	s9,40(sp)
    80006310:	7d02                	ld	s10,32(sp)
    80006312:	6de2                	ld	s11,24(sp)
    80006314:	6109                	addi	sp,sp,128
    80006316:	8082                	ret

0000000080006318 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006318:	1101                	addi	sp,sp,-32
    8000631a:	ec06                	sd	ra,24(sp)
    8000631c:	e822                	sd	s0,16(sp)
    8000631e:	e426                	sd	s1,8(sp)
    80006320:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006322:	0001c497          	auipc	s1,0x1c
    80006326:	47e48493          	addi	s1,s1,1150 # 800227a0 <disk>
    8000632a:	0001c517          	auipc	a0,0x1c
    8000632e:	59e50513          	addi	a0,a0,1438 # 800228c8 <disk+0x128>
    80006332:	ffffb097          	auipc	ra,0xffffb
    80006336:	8a4080e7          	jalr	-1884(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000633a:	10001737          	lui	a4,0x10001
    8000633e:	533c                	lw	a5,96(a4)
    80006340:	8b8d                	andi	a5,a5,3
    80006342:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006344:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006348:	689c                	ld	a5,16(s1)
    8000634a:	0204d703          	lhu	a4,32(s1)
    8000634e:	0027d783          	lhu	a5,2(a5)
    80006352:	04f70863          	beq	a4,a5,800063a2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006356:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000635a:	6898                	ld	a4,16(s1)
    8000635c:	0204d783          	lhu	a5,32(s1)
    80006360:	8b9d                	andi	a5,a5,7
    80006362:	078e                	slli	a5,a5,0x3
    80006364:	97ba                	add	a5,a5,a4
    80006366:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006368:	00278713          	addi	a4,a5,2
    8000636c:	0712                	slli	a4,a4,0x4
    8000636e:	9726                	add	a4,a4,s1
    80006370:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006374:	e721                	bnez	a4,800063bc <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006376:	0789                	addi	a5,a5,2
    80006378:	0792                	slli	a5,a5,0x4
    8000637a:	97a6                	add	a5,a5,s1
    8000637c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000637e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	dd2080e7          	jalr	-558(ra) # 80002154 <wakeup>

    disk.used_idx += 1;
    8000638a:	0204d783          	lhu	a5,32(s1)
    8000638e:	2785                	addiw	a5,a5,1
    80006390:	17c2                	slli	a5,a5,0x30
    80006392:	93c1                	srli	a5,a5,0x30
    80006394:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006398:	6898                	ld	a4,16(s1)
    8000639a:	00275703          	lhu	a4,2(a4)
    8000639e:	faf71ce3          	bne	a4,a5,80006356 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063a2:	0001c517          	auipc	a0,0x1c
    800063a6:	52650513          	addi	a0,a0,1318 # 800228c8 <disk+0x128>
    800063aa:	ffffb097          	auipc	ra,0xffffb
    800063ae:	8e0080e7          	jalr	-1824(ra) # 80000c8a <release>
}
    800063b2:	60e2                	ld	ra,24(sp)
    800063b4:	6442                	ld	s0,16(sp)
    800063b6:	64a2                	ld	s1,8(sp)
    800063b8:	6105                	addi	sp,sp,32
    800063ba:	8082                	ret
      panic("virtio_disk_intr status");
    800063bc:	00002517          	auipc	a0,0x2
    800063c0:	49c50513          	addi	a0,a0,1180 # 80008858 <syscalls+0x3e8>
    800063c4:	ffffa097          	auipc	ra,0xffffa
    800063c8:	17a080e7          	jalr	378(ra) # 8000053e <panic>

00000000800063cc <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    800063cc:	1141                	addi	sp,sp,-16
    800063ce:	e422                	sd	s0,8(sp)
    800063d0:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    800063d2:	0001c717          	auipc	a4,0x1c
    800063d6:	50e70713          	addi	a4,a4,1294 # 800228e0 <gq>
    800063da:	00451693          	slli	a3,a0,0x4
    800063de:	631c                	ld	a5,0(a4)
    800063e0:	97b6                	add	a5,a5,a3
    800063e2:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    800063e6:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    800063ea:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    800063ee:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    800063f2:	972a                	add	a4,a4,a0
    800063f4:	4785                	li	a5,1
    800063f6:	00f70c23          	sb	a5,24(a4)
}
    800063fa:	6422                	ld	s0,8(sp)
    800063fc:	0141                	addi	sp,sp,16
    800063fe:	8082                	ret

0000000080006400 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    80006400:	0001c797          	auipc	a5,0x1c
    80006404:	4e078793          	addi	a5,a5,1248 # 800228e0 <gq>
    80006408:	4501                	li	a0,0
    8000640a:	46a1                	li	a3,8
        if (gq.free[i])
    8000640c:	0187c703          	lbu	a4,24(a5)
    80006410:	e30d                	bnez	a4,80006432 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    80006412:	2505                	addiw	a0,a0,1
    80006414:	0785                	addi	a5,a5,1
    80006416:	fed51be3          	bne	a0,a3,8000640c <alloc_desc+0xc>
{
    8000641a:	1141                	addi	sp,sp,-16
    8000641c:	e406                	sd	ra,8(sp)
    8000641e:	e022                	sd	s0,0(sp)
    80006420:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    80006422:	00002517          	auipc	a0,0x2
    80006426:	44e50513          	addi	a0,a0,1102 # 80008870 <syscalls+0x400>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	114080e7          	jalr	276(ra) # 8000053e <panic>
            gq.free[i] = 0;
    80006432:	0001c797          	auipc	a5,0x1c
    80006436:	4ae78793          	addi	a5,a5,1198 # 800228e0 <gq>
    8000643a:	97aa                	add	a5,a5,a0
    8000643c:	00078c23          	sb	zero,24(a5)
}
    80006440:	8082                	ret

0000000080006442 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    80006442:	7139                	addi	sp,sp,-64
    80006444:	fc06                	sd	ra,56(sp)
    80006446:	f822                	sd	s0,48(sp)
    80006448:	f426                	sd	s1,40(sp)
    8000644a:	f04a                	sd	s2,32(sp)
    8000644c:	ec4e                	sd	s3,24(sp)
    8000644e:	e852                	sd	s4,16(sp)
    80006450:	e456                	sd	s5,8(sp)
    80006452:	0080                	addi	s0,sp,64
    80006454:	8aaa                	mv	s5,a0
    80006456:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    80006458:	0001c997          	auipc	s3,0x1c
    8000645c:	48898993          	addi	s3,s3,1160 # 800228e0 <gq>
    80006460:	0001c517          	auipc	a0,0x1c
    80006464:	4a850513          	addi	a0,a0,1192 # 80022908 <gpu_lock>
    80006468:	ffffa097          	auipc	ra,0xffffa
    8000646c:	76e080e7          	jalr	1902(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    80006470:	00000097          	auipc	ra,0x0
    80006474:	f90080e7          	jalr	-112(ra) # 80006400 <alloc_desc>
    80006478:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    8000647a:	00000097          	auipc	ra,0x0
    8000647e:	f86080e7          	jalr	-122(ra) # 80006400 <alloc_desc>
    80006482:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    80006484:	00491793          	slli	a5,s2,0x4
    80006488:	0009b703          	ld	a4,0(s3)
    8000648c:	973e                	add	a4,a4,a5
    8000648e:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    80006492:	0009b703          	ld	a4,0(s3)
    80006496:	97ba                	add	a5,a5,a4
    80006498:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    8000649c:	4685                	li	a3,1
    8000649e:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    800064a2:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    800064a6:	00451693          	slli	a3,a0,0x4
    800064aa:	9736                	add	a4,a4,a3
    800064ac:	0001c797          	auipc	a5,0x1c
    800064b0:	47478793          	addi	a5,a5,1140 # 80022920 <cmd_resp>
    800064b4:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    800064b6:	0009b783          	ld	a5,0(s3)
    800064ba:	97b6                	add	a5,a5,a3
    800064bc:	4761                	li	a4,24
    800064be:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    800064c0:	4709                	li	a4,2
    800064c2:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    800064c6:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    800064ca:	0089b703          	ld	a4,8(s3)
    800064ce:	00275783          	lhu	a5,2(a4)
    800064d2:	8b9d                	andi	a5,a5,7
    800064d4:	0786                	slli	a5,a5,0x1
    800064d6:	97ba                	add	a5,a5,a4
    800064d8:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    800064dc:	0ff0000f          	fence
    gq.avail->idx++;
    800064e0:	0089b703          	ld	a4,8(s3)
    800064e4:	00275783          	lhu	a5,2(a4)
    800064e8:	2785                	addiw	a5,a5,1
    800064ea:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    800064ee:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    800064f2:	100027b7          	lui	a5,0x10002
    800064f6:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    800064fa:	874e                	mv	a4,s3
        __sync_synchronize();
    800064fc:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    80006500:	02075783          	lhu	a5,32(a4)
    80006504:	6b14                	ld	a3,16(a4)
    80006506:	0026d683          	lhu	a3,2(a3)
    8000650a:	fef689e3          	beq	a3,a5,800064fc <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    8000650e:	2785                	addiw	a5,a5,1
    80006510:	0001c717          	auipc	a4,0x1c
    80006514:	3ef71823          	sh	a5,1008(a4) # 80022900 <gq+0x20>

    free_desc(d0);
    80006518:	854a                	mv	a0,s2
    8000651a:	00000097          	auipc	ra,0x0
    8000651e:	eb2080e7          	jalr	-334(ra) # 800063cc <free_desc>
    free_desc(d1);
    80006522:	8526                	mv	a0,s1
    80006524:	00000097          	auipc	ra,0x0
    80006528:	ea8080e7          	jalr	-344(ra) # 800063cc <free_desc>
    release(&gpu_lock);
    8000652c:	0001c517          	auipc	a0,0x1c
    80006530:	3dc50513          	addi	a0,a0,988 # 80022908 <gpu_lock>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	756080e7          	jalr	1878(ra) # 80000c8a <release>
}
    8000653c:	70e2                	ld	ra,56(sp)
    8000653e:	7442                	ld	s0,48(sp)
    80006540:	74a2                	ld	s1,40(sp)
    80006542:	7902                	ld	s2,32(sp)
    80006544:	69e2                	ld	s3,24(sp)
    80006546:	6a42                	ld	s4,16(sp)
    80006548:	6aa2                	ld	s5,8(sp)
    8000654a:	6121                	addi	sp,sp,64
    8000654c:	8082                	ret

000000008000654e <gpu_transfer_flush>:
{
    8000654e:	7139                	addi	sp,sp,-64
    80006550:	fc06                	sd	ra,56(sp)
    80006552:	f822                	sd	s0,48(sp)
    80006554:	f426                	sd	s1,40(sp)
    80006556:	f04a                	sd	s2,32(sp)
    80006558:	ec4e                	sd	s3,24(sp)
    8000655a:	e852                	sd	s4,16(sp)
    8000655c:	e456                	sd	s5,8(sp)
    8000655e:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    80006560:	0001c497          	auipc	s1,0x1c
    80006564:	38048493          	addi	s1,s1,896 # 800228e0 <gq>
    80006568:	0001c917          	auipc	s2,0x1c
    8000656c:	3d090913          	addi	s2,s2,976 # 80022938 <xfer.1>
    80006570:	03800613          	li	a2,56
    80006574:	4581                	li	a1,0
    80006576:	854a                	mv	a0,s2
    80006578:	ffffa097          	auipc	ra,0xffffa
    8000657c:	75a080e7          	jalr	1882(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    80006580:	10500793          	li	a5,261
    80006584:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    80006586:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    8000658a:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    8000658e:	28000a93          	li	s5,640
    80006592:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006596:	1e000a13          	li	s4,480
    8000659a:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    8000659e:	4985                	li	s3,1
    800065a0:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    800065a4:	03800593          	li	a1,56
    800065a8:	854a                	mv	a0,s2
    800065aa:	00000097          	auipc	ra,0x0
    800065ae:	e98080e7          	jalr	-360(ra) # 80006442 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    800065b2:	0001c917          	auipc	s2,0x1c
    800065b6:	3be90913          	addi	s2,s2,958 # 80022970 <flush.0>
    800065ba:	03000613          	li	a2,48
    800065be:	4581                	li	a1,0
    800065c0:	854a                	mv	a0,s2
    800065c2:	ffffa097          	auipc	ra,0xffffa
    800065c6:	710080e7          	jalr	1808(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    800065ca:	10400793          	li	a5,260
    800065ce:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    800065d2:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    800065d6:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    800065da:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    800065de:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    800065e2:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    800065e6:	03000593          	li	a1,48
    800065ea:	854a                	mv	a0,s2
    800065ec:	00000097          	auipc	ra,0x0
    800065f0:	e56080e7          	jalr	-426(ra) # 80006442 <gpu_send>
}
    800065f4:	70e2                	ld	ra,56(sp)
    800065f6:	7442                	ld	s0,48(sp)
    800065f8:	74a2                	ld	s1,40(sp)
    800065fa:	7902                	ld	s2,32(sp)
    800065fc:	69e2                	ld	s3,24(sp)
    800065fe:	6a42                	ld	s4,16(sp)
    80006600:	6aa2                	ld	s5,8(sp)
    80006602:	6121                	addi	sp,sp,64
    80006604:	8082                	ret

0000000080006606 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    80006606:	7159                	addi	sp,sp,-112
    80006608:	f486                	sd	ra,104(sp)
    8000660a:	f0a2                	sd	s0,96(sp)
    8000660c:	eca6                	sd	s1,88(sp)
    8000660e:	e8ca                	sd	s2,80(sp)
    80006610:	e4ce                	sd	s3,72(sp)
    80006612:	e0d2                	sd	s4,64(sp)
    80006614:	fc56                	sd	s5,56(sp)
    80006616:	f85a                	sd	s6,48(sp)
    80006618:	f45e                	sd	s7,40(sp)
    8000661a:	f062                	sd	s8,32(sp)
    8000661c:	ec66                	sd	s9,24(sp)
    8000661e:	e86a                	sd	s10,16(sp)
    80006620:	e46e                	sd	s11,8(sp)
    80006622:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    80006624:	00002597          	auipc	a1,0x2
    80006628:	26c58593          	addi	a1,a1,620 # 80008890 <syscalls+0x420>
    8000662c:	0001c517          	auipc	a0,0x1c
    80006630:	2dc50513          	addi	a0,a0,732 # 80022908 <gpu_lock>
    80006634:	ffffa097          	auipc	ra,0xffffa
    80006638:	512080e7          	jalr	1298(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000663c:	100027b7          	lui	a5,0x10002
    80006640:	4398                	lw	a4,0(a5)
    80006642:	2701                	sext.w	a4,a4
    80006644:	747277b7          	lui	a5,0x74727
    80006648:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000664c:	02f71a63          	bne	a4,a5,80006680 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    80006650:	100027b7          	lui	a5,0x10002
    80006654:	43dc                	lw	a5,4(a5)
    80006656:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006658:	4709                	li	a4,2
    8000665a:	02e79363          	bne	a5,a4,80006680 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    8000665e:	100027b7          	lui	a5,0x10002
    80006662:	479c                	lw	a5,8(a5)
    80006664:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    80006666:	4741                	li	a4,16
    80006668:	00e79c63          	bne	a5,a4,80006680 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    8000666c:	100027b7          	lui	a5,0x10002
    80006670:	47d8                	lw	a4,12(a5)
    80006672:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    80006674:	554d47b7          	lui	a5,0x554d4
    80006678:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000667c:	02f70963          	beq	a4,a5,800066ae <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    80006680:	00002517          	auipc	a0,0x2
    80006684:	21850513          	addi	a0,a0,536 # 80008898 <syscalls+0x428>
    80006688:	ffffa097          	auipc	ra,0xffffa
    8000668c:	f00080e7          	jalr	-256(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    80006690:	70a6                	ld	ra,104(sp)
    80006692:	7406                	ld	s0,96(sp)
    80006694:	64e6                	ld	s1,88(sp)
    80006696:	6946                	ld	s2,80(sp)
    80006698:	69a6                	ld	s3,72(sp)
    8000669a:	6a06                	ld	s4,64(sp)
    8000669c:	7ae2                	ld	s5,56(sp)
    8000669e:	7b42                	ld	s6,48(sp)
    800066a0:	7ba2                	ld	s7,40(sp)
    800066a2:	7c02                	ld	s8,32(sp)
    800066a4:	6ce2                	ld	s9,24(sp)
    800066a6:	6d42                	ld	s10,16(sp)
    800066a8:	6da2                	ld	s11,8(sp)
    800066aa:	6165                	addi	sp,sp,112
    800066ac:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    800066ae:	100027b7          	lui	a5,0x10002
    800066b2:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    800066b6:	4705                	li	a4,1
    800066b8:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    800066ba:	470d                	li	a4,3
    800066bc:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    800066be:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    800066c2:	472d                	li	a4,11
    800066c4:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    800066c6:	5bbc                	lw	a5,112(a5)
    800066c8:	8ba1                	andi	a5,a5,8
    800066ca:	22078363          	beqz	a5,800068f0 <virtio_gpu_init+0x2ea>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800066ce:	100027b7          	lui	a5,0x10002
    800066d2:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    800066d6:	43fc                	lw	a5,68(a5)
    800066d8:	2781                	sext.w	a5,a5
    800066da:	22079363          	bnez	a5,80006900 <virtio_gpu_init+0x2fa>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    800066de:	100027b7          	lui	a5,0x10002
    800066e2:	5bdc                	lw	a5,52(a5)
    800066e4:	2781                	sext.w	a5,a5
    800066e6:	471d                	li	a4,7
    800066e8:	22f77463          	bgeu	a4,a5,80006910 <virtio_gpu_init+0x30a>
    gq.desc = kalloc();
    800066ec:	ffffa097          	auipc	ra,0xffffa
    800066f0:	3fa080e7          	jalr	1018(ra) # 80000ae6 <kalloc>
    800066f4:	0001c497          	auipc	s1,0x1c
    800066f8:	1ec48493          	addi	s1,s1,492 # 800228e0 <gq>
    800066fc:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	3e8080e7          	jalr	1000(ra) # 80000ae6 <kalloc>
    80006706:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    80006708:	ffffa097          	auipc	ra,0xffffa
    8000670c:	3de080e7          	jalr	990(ra) # 80000ae6 <kalloc>
    80006710:	87aa                	mv	a5,a0
    80006712:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    80006714:	6088                	ld	a0,0(s1)
    80006716:	20050563          	beqz	a0,80006920 <virtio_gpu_init+0x31a>
    8000671a:	0001c717          	auipc	a4,0x1c
    8000671e:	1ce73703          	ld	a4,462(a4) # 800228e8 <gq+0x8>
    80006722:	1e070f63          	beqz	a4,80006920 <virtio_gpu_init+0x31a>
    80006726:	1e078d63          	beqz	a5,80006920 <virtio_gpu_init+0x31a>
    memset(gq.desc, 0, PGSIZE);
    8000672a:	6605                	lui	a2,0x1
    8000672c:	4581                	li	a1,0
    8000672e:	ffffa097          	auipc	ra,0xffffa
    80006732:	5a4080e7          	jalr	1444(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    80006736:	0001c497          	auipc	s1,0x1c
    8000673a:	1aa48493          	addi	s1,s1,426 # 800228e0 <gq>
    8000673e:	6605                	lui	a2,0x1
    80006740:	4581                	li	a1,0
    80006742:	6488                	ld	a0,8(s1)
    80006744:	ffffa097          	auipc	ra,0xffffa
    80006748:	58e080e7          	jalr	1422(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    8000674c:	6605                	lui	a2,0x1
    8000674e:	4581                	li	a1,0
    80006750:	6888                	ld	a0,16(s1)
    80006752:	ffffa097          	auipc	ra,0xffffa
    80006756:	580080e7          	jalr	1408(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    8000675a:	100027b7          	lui	a5,0x10002
    8000675e:	4721                	li	a4,8
    80006760:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    80006762:	4098                	lw	a4,0(s1)
    80006764:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    80006768:	40d8                	lw	a4,4(s1)
    8000676a:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    8000676e:	6498                	ld	a4,8(s1)
    80006770:	0007069b          	sext.w	a3,a4
    80006774:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    80006778:	9701                	srai	a4,a4,0x20
    8000677a:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    8000677e:	6898                	ld	a4,16(s1)
    80006780:	0007069b          	sext.w	a3,a4
    80006784:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    80006788:	9701                	srai	a4,a4,0x20
    8000678a:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    8000678e:	4705                	li	a4,1
    80006790:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    80006792:	00e48c23          	sb	a4,24(s1)
    80006796:	00e48ca3          	sb	a4,25(s1)
    8000679a:	00e48d23          	sb	a4,26(s1)
    8000679e:	00e48da3          	sb	a4,27(s1)
    800067a2:	00e48e23          	sb	a4,28(s1)
    800067a6:	00e48ea3          	sb	a4,29(s1)
    800067aa:	00e48f23          	sb	a4,30(s1)
    800067ae:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    800067b2:	473d                	li	a4,15
    800067b4:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    800067b6:	0001e917          	auipc	s2,0x1e
    800067ba:	7e290913          	addi	s2,s2,2018 # 80024f98 <fb>
    800067be:	0001f997          	auipc	s3,0x1f
    800067c2:	13a98993          	addi	s3,s3,314 # 800258f8 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    800067c6:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    800067c8:	ffffa097          	auipc	ra,0xffffa
    800067cc:	31e080e7          	jalr	798(ra) # 80000ae6 <kalloc>
    800067d0:	e088                	sd	a0,0(s1)
        if (!fb[i])
    800067d2:	14050f63          	beqz	a0,80006930 <virtio_gpu_init+0x32a>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    800067d6:	6605                	lui	a2,0x1
    800067d8:	4581                	li	a1,0
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	4f8080e7          	jalr	1272(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    800067e2:	04a1                	addi	s1,s1,8
    800067e4:	ff3492e3          	bne	s1,s3,800067c8 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    800067e8:	0001c497          	auipc	s1,0x1c
    800067ec:	0f848493          	addi	s1,s1,248 # 800228e0 <gq>
    800067f0:	0001c997          	auipc	s3,0x1c
    800067f4:	1b098993          	addi	s3,s3,432 # 800229a0 <create_req.4>
    800067f8:	02800613          	li	a2,40
    800067fc:	4581                	li	a1,0
    800067fe:	854e                	mv	a0,s3
    80006800:	ffffa097          	auipc	ra,0xffffa
    80006804:	4d2080e7          	jalr	1234(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    80006808:	10100793          	li	a5,257
    8000680c:	0cf4a023          	sw	a5,192(s1)
    create_req.resource_id = RESOURCE_ID;
    80006810:	4785                	li	a5,1
    80006812:	0cf4ac23          	sw	a5,216(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    80006816:	4789                	li	a5,2
    80006818:	0cf4ae23          	sw	a5,220(s1)
    create_req.width = SCREEN_W;
    8000681c:	28000793          	li	a5,640
    80006820:	0ef4a023          	sw	a5,224(s1)
    create_req.height = SCREEN_H;
    80006824:	1e000793          	li	a5,480
    80006828:	0ef4a223          	sw	a5,228(s1)
    gpu_send(&create_req, sizeof(create_req));
    8000682c:	02800593          	li	a1,40
    80006830:	854e                	mv	a0,s3
    80006832:	00000097          	auipc	ra,0x0
    80006836:	c10080e7          	jalr	-1008(ra) # 80006442 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    8000683a:	0001c597          	auipc	a1,0x1c
    8000683e:	1be58593          	addi	a1,a1,446 # 800229f8 <fb_entries.3>
    80006842:	0001d697          	auipc	a3,0x1d
    80006846:	47668693          	addi	a3,a3,1142 # 80023cb8 <attach_buf>
    gpu_send(&create_req, sizeof(create_req));
    8000684a:	87ae                	mv	a5,a1
        fb_entries[i].length = PGSIZE;
    8000684c:	6605                	lui	a2,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    8000684e:	00093703          	ld	a4,0(s2)
    80006852:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    80006854:	c790                	sw	a2,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    80006856:	0921                	addi	s2,s2,8
    80006858:	07c1                	addi	a5,a5,16
    8000685a:	fed79ae3          	bne	a5,a3,8000684e <virtio_gpu_init+0x248>
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    8000685e:	0001d797          	auipc	a5,0x1d
    80006862:	45a78793          	addi	a5,a5,1114 # 80023cb8 <attach_buf>
    80006866:	10600713          	li	a4,262
    8000686a:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    8000686c:	4705                	li	a4,1
    8000686e:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    80006870:	12c00713          	li	a4,300
    80006874:	cfd8                	sw	a4,28(a5)
    for (int i = 0; i < n; i++)
    80006876:	0001d797          	auipc	a5,0x1d
    8000687a:	46278793          	addi	a5,a5,1122 # 80023cd8 <attach_buf+0x20>
        attach_buf.entries[i] = entries[i];
    8000687e:	6198                	ld	a4,0(a1)
    80006880:	e398                	sd	a4,0(a5)
    80006882:	6598                	ld	a4,8(a1)
    80006884:	e798                	sd	a4,8(a5)
    for (int i = 0; i < n; i++)
    80006886:	05c1                	addi	a1,a1,16
    80006888:	07c1                	addi	a5,a5,16
    8000688a:	fed59ae3          	bne	a1,a3,8000687e <virtio_gpu_init+0x278>
    gpu_send(&attach_buf, sizeof(attach_buf));
    8000688e:	6585                	lui	a1,0x1
    80006890:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    80006894:	0001d517          	auipc	a0,0x1d
    80006898:	42450513          	addi	a0,a0,1060 # 80023cb8 <attach_buf>
    8000689c:	00000097          	auipc	ra,0x0
    800068a0:	ba6080e7          	jalr	-1114(ra) # 80006442 <gpu_send>
        for (int i = 0; msg[i]; i++)
    800068a4:	00002c17          	auipc	s8,0x2
    800068a8:	0ccc0c13          	addi	s8,s8,204 # 80008970 <syscalls+0x500>
    gpu_send(&attach_buf, sizeof(attach_buf));
    800068ac:	0008cbb7          	lui	s7,0x8c
    800068b0:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    800068b4:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    800068b8:	00002c97          	auipc	s9,0x2
    800068bc:	100c8c93          	addi	s9,s9,256 # 800089b8 <font8x8>
    800068c0:	00024737          	lui	a4,0x24
    800068c4:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    800068c8:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800068ca:	010004b7          	lui	s1,0x1000
    800068ce:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    800068d0:	0001e897          	auipc	a7,0x1e
    800068d4:	6c888893          	addi	a7,a7,1736 # 80024f98 <fb>
    int off = byte_off % PGSIZE;
    800068d8:	6805                	lui	a6,0x1
    800068da:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    800068dc:	6e05                	lui	t3,0x1
    800068de:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    800068e2:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    800068e4:	6a8d                	lui	s5,0x3
    800068e6:	800a8a9b          	addiw	s5,s5,-2048
    800068ea:	10000b13          	li	s6,256
    800068ee:	a0f1                	j	800069ba <virtio_gpu_init+0x3b4>
        panic("virtio_gpu: FEATURES_OK not set");
    800068f0:	00002517          	auipc	a0,0x2
    800068f4:	fc850513          	addi	a0,a0,-56 # 800088b8 <syscalls+0x448>
    800068f8:	ffffa097          	auipc	ra,0xffffa
    800068fc:	c46080e7          	jalr	-954(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    80006900:	00002517          	auipc	a0,0x2
    80006904:	fd850513          	addi	a0,a0,-40 # 800088d8 <syscalls+0x468>
    80006908:	ffffa097          	auipc	ra,0xffffa
    8000690c:	c36080e7          	jalr	-970(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    80006910:	00002517          	auipc	a0,0x2
    80006914:	fe850513          	addi	a0,a0,-24 # 800088f8 <syscalls+0x488>
    80006918:	ffffa097          	auipc	ra,0xffffa
    8000691c:	c26080e7          	jalr	-986(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    80006920:	00002517          	auipc	a0,0x2
    80006924:	ff850513          	addi	a0,a0,-8 # 80008918 <syscalls+0x4a8>
    80006928:	ffffa097          	auipc	ra,0xffffa
    8000692c:	c16080e7          	jalr	-1002(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    80006930:	00002517          	auipc	a0,0x2
    80006934:	01050513          	addi	a0,a0,16 # 80008940 <syscalls+0x4d0>
    80006938:	ffffa097          	auipc	ra,0xffffa
    8000693c:	c06080e7          	jalr	-1018(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006940:	85fe                	mv	a1,t6
    80006942:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    80006944:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    80006948:	43f6d613          	srai	a2,a3,0x3f
    8000694c:	0146561b          	srliw	a2,a2,0x14
    80006950:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006954:	40c7d71b          	sraiw	a4,a5,0xc
    80006958:	070e                	slli	a4,a4,0x3
    8000695a:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    8000695c:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006960:	9f91                	subw	a5,a5,a2
    *p = color;
    80006962:	6310                	ld	a2,0(a4)
    80006964:	97b2                	add	a5,a5,a2
    80006966:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    80006968:	2691                	addiw	a3,a3,4
    8000696a:	fcd59fe3          	bne	a1,a3,80006948 <virtio_gpu_init+0x342>
            for (int dy = 0; dy < SCALE; dy++)
    8000696e:	2803031b          	addiw	t1,t1,640
    80006972:	00be05bb          	addw	a1,t3,a1
    80006976:	fdd317e3          	bne	t1,t4,80006944 <virtio_gpu_init+0x33e>
        for (int col = 0; col < 8; col++)
    8000697a:	2f05                	addiw	t5,t5,1
    8000697c:	2fc1                	addiw	t6,t6,16
    8000697e:	001f0a63          	beq	t5,ra,80006992 <virtio_gpu_init+0x38c>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006982:	0002c503          	lbu	a0,0(t0)
    80006986:	01e5553b          	srlw	a0,a0,t5
    8000698a:	8905                	andi	a0,a0,1
    8000698c:	d955                	beqz	a0,80006940 <virtio_gpu_init+0x33a>
    8000698e:	8526                	mv	a0,s1
    80006990:	bf45                	j	80006940 <virtio_gpu_init+0x33a>
    for (int row = 0; row < 8; row++)
    80006992:	01de0ebb          	addw	t4,t3,t4
    80006996:	012e093b          	addw	s2,t3,s2
    8000699a:	2991                	addiw	s3,s3,4
    8000699c:	014a8a3b          	addw	s4,s5,s4
    800069a0:	0285                	addi	t0,t0,1
    800069a2:	01698663          	beq	s3,s6,800069ae <virtio_gpu_init+0x3a8>
        for (int i = 0; msg[i]; i++)
    800069a6:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    800069a8:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800069aa:	83ca                	mv	t2,s2
    800069ac:	bfd9                	j	80006982 <virtio_gpu_init+0x37c>
        for (int i = 0; msg[i]; i++)
    800069ae:	001c4783          	lbu	a5,1(s8)
    800069b2:	0c05                	addi	s8,s8,1
    800069b4:	080b8b9b          	addiw	s7,s7,128
    800069b8:	cb99                	beqz	a5,800069ce <virtio_gpu_init+0x3c8>
    const uint8 *rows = font8x8[ch];
    800069ba:	078e                	slli	a5,a5,0x3
    800069bc:	019782b3          	add	t0,a5,s9
    800069c0:	8a5e                	mv	s4,s7
    800069c2:	0e000993          	li	s3,224
    800069c6:	00023937          	lui	s2,0x23
    800069ca:	8eee                	mv	t4,s11
    800069cc:	bfe9                	j	800069a6 <virtio_gpu_init+0x3a0>
    memset(&scanout_req, 0, sizeof(scanout_req));
    800069ce:	0001c497          	auipc	s1,0x1c
    800069d2:	f1248493          	addi	s1,s1,-238 # 800228e0 <gq>
    800069d6:	0001c917          	auipc	s2,0x1c
    800069da:	ff290913          	addi	s2,s2,-14 # 800229c8 <scanout_req.2>
    800069de:	03000613          	li	a2,48
    800069e2:	4581                	li	a1,0
    800069e4:	854a                	mv	a0,s2
    800069e6:	ffffa097          	auipc	ra,0xffffa
    800069ea:	2ec080e7          	jalr	748(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    800069ee:	10300793          	li	a5,259
    800069f2:	0ef4a423          	sw	a5,232(s1)
    scanout_req.r.x = 0;
    800069f6:	1004a023          	sw	zero,256(s1)
    scanout_req.r.y = 0;
    800069fa:	1004a223          	sw	zero,260(s1)
    scanout_req.r.width = SCREEN_W;
    800069fe:	28000793          	li	a5,640
    80006a02:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.height = SCREEN_H;
    80006a06:	1e000793          	li	a5,480
    80006a0a:	10f4a623          	sw	a5,268(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    80006a0e:	1004a823          	sw	zero,272(s1)
    scanout_req.resource_id = RESOURCE_ID;
    80006a12:	4785                	li	a5,1
    80006a14:	10f4aa23          	sw	a5,276(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    80006a18:	03000593          	li	a1,48
    80006a1c:	854a                	mv	a0,s2
    80006a1e:	00000097          	auipc	ra,0x0
    80006a22:	a24080e7          	jalr	-1500(ra) # 80006442 <gpu_send>
    gpu_transfer_flush();
    80006a26:	00000097          	auipc	ra,0x0
    80006a2a:	b28080e7          	jalr	-1240(ra) # 8000654e <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    80006a2e:	00002517          	auipc	a0,0x2
    80006a32:	f5250513          	addi	a0,a0,-174 # 80008980 <syscalls+0x510>
    80006a36:	ffffa097          	auipc	ra,0xffffa
    80006a3a:	b52080e7          	jalr	-1198(ra) # 80000588 <printf>
    80006a3e:	b989                	j	80006690 <virtio_gpu_init+0x8a>

0000000080006a40 <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    80006a40:	1141                	addi	sp,sp,-16
    80006a42:	e406                	sd	ra,8(sp)
    80006a44:	e022                	sd	s0,0(sp)
    80006a46:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    80006a48:	00000097          	auipc	ra,0x0
    80006a4c:	b06080e7          	jalr	-1274(ra) # 8000654e <gpu_transfer_flush>
}
    80006a50:	60a2                	ld	ra,8(sp)
    80006a52:	6402                	ld	s0,0(sp)
    80006a54:	0141                	addi	sp,sp,16
    80006a56:	8082                	ret

0000000080006a58 <virtio_gpu_fb_pages>:
// Each fb[i] is a kernel virtual address of one 4 KB page; there are
// GPU_FB_PAGES (300) of them.  sys_map_display uses this to install the
// pages into a user process's page table.
void **
virtio_gpu_fb_pages(void)
{
    80006a58:	1141                	addi	sp,sp,-16
    80006a5a:	e422                	sd	s0,8(sp)
    80006a5c:	0800                	addi	s0,sp,16
    return fb;
}
    80006a5e:	0001e517          	auipc	a0,0x1e
    80006a62:	53a50513          	addi	a0,a0,1338 # 80024f98 <fb>
    80006a66:	6422                	ld	s0,8(sp)
    80006a68:	0141                	addi	sp,sp,16
    80006a6a:	8082                	ret

0000000080006a6c <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    80006a6c:	7179                	addi	sp,sp,-48
    80006a6e:	f406                	sd	ra,40(sp)
    80006a70:	f022                	sd	s0,32(sp)
    80006a72:	ec26                	sd	s1,24(sp)
    80006a74:	e84a                	sd	s2,16(sp)
    80006a76:	e44e                	sd	s3,8(sp)
    80006a78:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    80006a7a:	ffffb097          	auipc	ra,0xffffb
    80006a7e:	f68080e7          	jalr	-152(ra) # 800019e2 <myproc>
    release(&p->lock);
    80006a82:	ffffa097          	auipc	ra,0xffffa
    80006a86:	208080e7          	jalr	520(ra) # 80000c8a <release>

    acquire(&tickslock);
    80006a8a:	00011517          	auipc	a0,0x11
    80006a8e:	87650513          	addi	a0,a0,-1930 # 80017300 <tickslock>
    80006a92:	ffffa097          	auipc	ra,0xffffa
    80006a96:	144080e7          	jalr	324(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006a9a:	00002917          	auipc	s2,0x2
    80006a9e:	7c690913          	addi	s2,s2,1990 # 80009260 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    80006aa2:	00011497          	auipc	s1,0x11
    80006aa6:	85e48493          	addi	s1,s1,-1954 # 80017300 <tickslock>
    80006aaa:	a839                	j	80006ac8 <display_daemon+0x5c>

        release(&tickslock);
    80006aac:	8526                	mv	a0,s1
    80006aae:	ffffa097          	auipc	ra,0xffffa
    80006ab2:	1dc080e7          	jalr	476(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006ab6:	00000097          	auipc	ra,0x0
    80006aba:	a98080e7          	jalr	-1384(ra) # 8000654e <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    80006abe:	8526                	mv	a0,s1
    80006ac0:	ffffa097          	auipc	ra,0xffffa
    80006ac4:	116080e7          	jalr	278(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006ac8:	00092783          	lw	a5,0(s2)
    80006acc:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    80006ad0:	fd37fee3          	bgeu	a5,s3,80006aac <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006ad4:	85a6                	mv	a1,s1
    80006ad6:	854a                	mv	a0,s2
    80006ad8:	ffffb097          	auipc	ra,0xffffb
    80006adc:	618080e7          	jalr	1560(ra) # 800020f0 <sleep>
        while (ticks < deadline)
    80006ae0:	00092783          	lw	a5,0(s2)
    80006ae4:	ff37e8e3          	bltu	a5,s3,80006ad4 <display_daemon+0x68>
    80006ae8:	b7d1                	j	80006aac <display_daemon+0x40>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
