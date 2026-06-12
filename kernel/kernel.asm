
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
    80000068:	bec78793          	addi	a5,a5,-1044 # 80005c50 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9107>
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
    8000047c:	0d078793          	addi	a5,a5,208 # 80021548 <devsw>
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
    80000a02:	cfa78793          	addi	a5,a5,-774 # 800256f8 <end>
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
    80000ad2:	c2a50513          	addi	a0,a0,-982 # 800256f8 <end>
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
    80000eca:	dca080e7          	jalr	-566(ra) # 80005c90 <plicinithart>
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
    80000f4a:	d34080e7          	jalr	-716(ra) # 80005c7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d42080e7          	jalr	-702(ra) # 80005c90 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	ee6080e7          	jalr	-282(ra) # 80002e3c <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	58a080e7          	jalr	1418(ra) # 800034e8 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	528080e7          	jalr	1320(ra) # 8000448e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	e2a080e7          	jalr	-470(ra) # 80005d98 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	530080e7          	jalr	1328(ra) # 800064a6 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d3c080e7          	jalr	-708(ra) # 80001cba <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	96a50513          	addi	a0,a0,-1686 # 800068f8 <display_daemon>
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
    80001a5a:	a12080e7          	jalr	-1518(ra) # 80003468 <fsinit>
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
    80001d1c:	172080e7          	jalr	370(ra) # 80003e8a <namei>
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
    80001eb2:	672080e7          	jalr	1650(ra) # 80004520 <filedup>
    80001eb6:	00a93023          	sd	a0,0(s2)
    80001eba:	b7e5                	j	80001ea2 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ebc:	150ab503          	ld	a0,336(s5)
    80001ec0:	00001097          	auipc	ra,0x1
    80001ec4:	7e6080e7          	jalr	2022(ra) # 800036a6 <idup>
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
    80002268:	30e080e7          	jalr	782(ra) # 80004572 <fileclose>
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
    80002280:	e2a080e7          	jalr	-470(ra) # 800040a6 <begin_op>
  iput(p->cwd);
    80002284:	1509b503          	ld	a0,336(s3)
    80002288:	00001097          	auipc	ra,0x1
    8000228c:	616080e7          	jalr	1558(ra) # 8000389e <iput>
  end_op();
    80002290:	00002097          	auipc	ra,0x2
    80002294:	e96080e7          	jalr	-362(ra) # 80004126 <end_op>
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
    800025d6:	e8690913          	addi	s2,s2,-378 # 80017458 <bcache+0x140>
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
    800026ee:	4d678793          	addi	a5,a5,1238 # 80005bc0 <kernelvec>
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
    8000280e:	4be080e7          	jalr	1214(ra) # 80005cc8 <plic_claim>
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
    8000283c:	4b4080e7          	jalr	1204(ra) # 80005cec <plic_complete>
    return 1;
    80002840:	4505                	li	a0,1
    80002842:	bf55                	j	800027f6 <devintr+0x1e>
      uartintr();
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	156080e7          	jalr	342(ra) # 8000099a <uartintr>
    8000284c:	b7ed                	j	80002836 <devintr+0x5e>
      virtio_disk_intr();
    8000284e:	00004097          	auipc	ra,0x4
    80002852:	96a080e7          	jalr	-1686(ra) # 800061b8 <virtio_disk_intr>
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
    80002894:	33078793          	addi	a5,a5,816 # 80005bc0 <kernelvec>
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
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c48:	fec40593          	addi	a1,s0,-20
    80002c4c:	4501                	li	a0,0
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	f0e080e7          	jalr	-242(ra) # 80002b5c <argint>
  exit(n);
    80002c56:	fec42503          	lw	a0,-20(s0)
    80002c5a:	fffff097          	auipc	ra,0xfffff
    80002c5e:	5ca080e7          	jalr	1482(ra) # 80002224 <exit>
  return 0;  // not reached
}
    80002c62:	4501                	li	a0,0
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	6105                	addi	sp,sp,32
    80002c6a:	8082                	ret

0000000080002c6c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c6c:	1141                	addi	sp,sp,-16
    80002c6e:	e406                	sd	ra,8(sp)
    80002c70:	e022                	sd	s0,0(sp)
    80002c72:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d6e080e7          	jalr	-658(ra) # 800019e2 <myproc>
}
    80002c7c:	5908                	lw	a0,48(a0)
    80002c7e:	60a2                	ld	ra,8(sp)
    80002c80:	6402                	ld	s0,0(sp)
    80002c82:	0141                	addi	sp,sp,16
    80002c84:	8082                	ret

0000000080002c86 <sys_fork>:

uint64
sys_fork(void)
{
    80002c86:	1141                	addi	sp,sp,-16
    80002c88:	e406                	sd	ra,8(sp)
    80002c8a:	e022                	sd	s0,0(sp)
    80002c8c:	0800                	addi	s0,sp,16
  return fork();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	170080e7          	jalr	368(ra) # 80001dfe <fork>
}
    80002c96:	60a2                	ld	ra,8(sp)
    80002c98:	6402                	ld	s0,0(sp)
    80002c9a:	0141                	addi	sp,sp,16
    80002c9c:	8082                	ret

0000000080002c9e <sys_wait>:

uint64
sys_wait(void)
{
    80002c9e:	1101                	addi	sp,sp,-32
    80002ca0:	ec06                	sd	ra,24(sp)
    80002ca2:	e822                	sd	s0,16(sp)
    80002ca4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ca6:	fe840593          	addi	a1,s0,-24
    80002caa:	4501                	li	a0,0
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	ed0080e7          	jalr	-304(ra) # 80002b7c <argaddr>
  return wait(p);
    80002cb4:	fe843503          	ld	a0,-24(s0)
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	712080e7          	jalr	1810(ra) # 800023ca <wait>
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret

0000000080002cc8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cc8:	7179                	addi	sp,sp,-48
    80002cca:	f406                	sd	ra,40(sp)
    80002ccc:	f022                	sd	s0,32(sp)
    80002cce:	ec26                	sd	s1,24(sp)
    80002cd0:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cd2:	fdc40593          	addi	a1,s0,-36
    80002cd6:	4501                	li	a0,0
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	e84080e7          	jalr	-380(ra) # 80002b5c <argint>
  addr = myproc()->sz;
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	d02080e7          	jalr	-766(ra) # 800019e2 <myproc>
    80002ce8:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002cea:	fdc42503          	lw	a0,-36(s0)
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	0b4080e7          	jalr	180(ra) # 80001da2 <growproc>
    80002cf6:	00054863          	bltz	a0,80002d06 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	70a2                	ld	ra,40(sp)
    80002cfe:	7402                	ld	s0,32(sp)
    80002d00:	64e2                	ld	s1,24(sp)
    80002d02:	6145                	addi	sp,sp,48
    80002d04:	8082                	ret
    return -1;
    80002d06:	54fd                	li	s1,-1
    80002d08:	bfcd                	j	80002cfa <sys_sbrk+0x32>

0000000080002d0a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d0a:	7139                	addi	sp,sp,-64
    80002d0c:	fc06                	sd	ra,56(sp)
    80002d0e:	f822                	sd	s0,48(sp)
    80002d10:	f426                	sd	s1,40(sp)
    80002d12:	f04a                	sd	s2,32(sp)
    80002d14:	ec4e                	sd	s3,24(sp)
    80002d16:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d18:	fcc40593          	addi	a1,s0,-52
    80002d1c:	4501                	li	a0,0
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	e3e080e7          	jalr	-450(ra) # 80002b5c <argint>
  acquire(&tickslock);
    80002d26:	00014517          	auipc	a0,0x14
    80002d2a:	5da50513          	addi	a0,a0,1498 # 80017300 <tickslock>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	ea8080e7          	jalr	-344(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d36:	00006917          	auipc	s2,0x6
    80002d3a:	52a92903          	lw	s2,1322(s2) # 80009260 <ticks>
  while(ticks - ticks0 < n){
    80002d3e:	fcc42783          	lw	a5,-52(s0)
    80002d42:	cf9d                	beqz	a5,80002d80 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d44:	00014997          	auipc	s3,0x14
    80002d48:	5bc98993          	addi	s3,s3,1468 # 80017300 <tickslock>
    80002d4c:	00006497          	auipc	s1,0x6
    80002d50:	51448493          	addi	s1,s1,1300 # 80009260 <ticks>
    if(killed(myproc())){
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	c8e080e7          	jalr	-882(ra) # 800019e2 <myproc>
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	63c080e7          	jalr	1596(ra) # 80002398 <killed>
    80002d64:	ed15                	bnez	a0,80002da0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d66:	85ce                	mv	a1,s3
    80002d68:	8526                	mv	a0,s1
    80002d6a:	fffff097          	auipc	ra,0xfffff
    80002d6e:	386080e7          	jalr	902(ra) # 800020f0 <sleep>
  while(ticks - ticks0 < n){
    80002d72:	409c                	lw	a5,0(s1)
    80002d74:	412787bb          	subw	a5,a5,s2
    80002d78:	fcc42703          	lw	a4,-52(s0)
    80002d7c:	fce7ece3          	bltu	a5,a4,80002d54 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d80:	00014517          	auipc	a0,0x14
    80002d84:	58050513          	addi	a0,a0,1408 # 80017300 <tickslock>
    80002d88:	ffffe097          	auipc	ra,0xffffe
    80002d8c:	f02080e7          	jalr	-254(ra) # 80000c8a <release>
  return 0;
    80002d90:	4501                	li	a0,0
}
    80002d92:	70e2                	ld	ra,56(sp)
    80002d94:	7442                	ld	s0,48(sp)
    80002d96:	74a2                	ld	s1,40(sp)
    80002d98:	7902                	ld	s2,32(sp)
    80002d9a:	69e2                	ld	s3,24(sp)
    80002d9c:	6121                	addi	sp,sp,64
    80002d9e:	8082                	ret
      release(&tickslock);
    80002da0:	00014517          	auipc	a0,0x14
    80002da4:	56050513          	addi	a0,a0,1376 # 80017300 <tickslock>
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	ee2080e7          	jalr	-286(ra) # 80000c8a <release>
      return -1;
    80002db0:	557d                	li	a0,-1
    80002db2:	b7c5                	j	80002d92 <sys_sleep+0x88>

0000000080002db4 <sys_kill>:

uint64
sys_kill(void)
{
    80002db4:	1101                	addi	sp,sp,-32
    80002db6:	ec06                	sd	ra,24(sp)
    80002db8:	e822                	sd	s0,16(sp)
    80002dba:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002dbc:	fec40593          	addi	a1,s0,-20
    80002dc0:	4501                	li	a0,0
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	d9a080e7          	jalr	-614(ra) # 80002b5c <argint>
  return kill(pid);
    80002dca:	fec42503          	lw	a0,-20(s0)
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	52c080e7          	jalr	1324(ra) # 800022fa <kill>
}
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret

0000000080002dde <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dde:	1101                	addi	sp,sp,-32
    80002de0:	ec06                	sd	ra,24(sp)
    80002de2:	e822                	sd	s0,16(sp)
    80002de4:	e426                	sd	s1,8(sp)
    80002de6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002de8:	00014517          	auipc	a0,0x14
    80002dec:	51850513          	addi	a0,a0,1304 # 80017300 <tickslock>
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	de6080e7          	jalr	-538(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002df8:	00006497          	auipc	s1,0x6
    80002dfc:	4684a483          	lw	s1,1128(s1) # 80009260 <ticks>
  release(&tickslock);
    80002e00:	00014517          	auipc	a0,0x14
    80002e04:	50050513          	addi	a0,a0,1280 # 80017300 <tickslock>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	e82080e7          	jalr	-382(ra) # 80000c8a <release>
  return xticks;
}
    80002e10:	02049513          	slli	a0,s1,0x20
    80002e14:	9101                	srli	a0,a0,0x20
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret

0000000080002e20 <sys_flip_display>:
// calling process's address space.
//
// TODO: Students implement this syscall.
uint64
sys_flip_display(void)
{
    80002e20:	1141                	addi	sp,sp,-16
    80002e22:	e422                	sd	s0,8(sp)
    80002e24:	0800                	addi	s0,sp,16
  return -1;
}
    80002e26:	557d                	li	a0,-1
    80002e28:	6422                	ld	s0,8(sp)
    80002e2a:	0141                	addi	sp,sp,16
    80002e2c:	8082                	ret

0000000080002e2e <sys_map_display>:
// Returns the mapped virtual address on success, (uint64)-1 on failure.
//
// TODO: Students implement this syscall.
uint64
sys_map_display(void)
{
    80002e2e:	1141                	addi	sp,sp,-16
    80002e30:	e422                	sd	s0,8(sp)
    80002e32:	0800                	addi	s0,sp,16
  return -1;
}
    80002e34:	557d                	li	a0,-1
    80002e36:	6422                	ld	s0,8(sp)
    80002e38:	0141                	addi	sp,sp,16
    80002e3a:	8082                	ret

0000000080002e3c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e3c:	7179                	addi	sp,sp,-48
    80002e3e:	f406                	sd	ra,40(sp)
    80002e40:	f022                	sd	s0,32(sp)
    80002e42:	ec26                	sd	s1,24(sp)
    80002e44:	e84a                	sd	s2,16(sp)
    80002e46:	e44e                	sd	s3,8(sp)
    80002e48:	e052                	sd	s4,0(sp)
    80002e4a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e4c:	00005597          	auipc	a1,0x5
    80002e50:	6e458593          	addi	a1,a1,1764 # 80008530 <syscalls+0xc0>
    80002e54:	00014517          	auipc	a0,0x14
    80002e58:	4c450513          	addi	a0,a0,1220 # 80017318 <bcache>
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	cea080e7          	jalr	-790(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e64:	0001c797          	auipc	a5,0x1c
    80002e68:	4b478793          	addi	a5,a5,1204 # 8001f318 <bcache+0x8000>
    80002e6c:	0001c717          	auipc	a4,0x1c
    80002e70:	71470713          	addi	a4,a4,1812 # 8001f580 <bcache+0x8268>
    80002e74:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e78:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e7c:	00014497          	auipc	s1,0x14
    80002e80:	4b448493          	addi	s1,s1,1204 # 80017330 <bcache+0x18>
    b->next = bcache.head.next;
    80002e84:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e86:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e88:	00005a17          	auipc	s4,0x5
    80002e8c:	6b0a0a13          	addi	s4,s4,1712 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002e90:	2b893783          	ld	a5,696(s2)
    80002e94:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e96:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e9a:	85d2                	mv	a1,s4
    80002e9c:	01048513          	addi	a0,s1,16
    80002ea0:	00001097          	auipc	ra,0x1
    80002ea4:	4c4080e7          	jalr	1220(ra) # 80004364 <initsleeplock>
    bcache.head.next->prev = b;
    80002ea8:	2b893783          	ld	a5,696(s2)
    80002eac:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eae:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eb2:	45848493          	addi	s1,s1,1112
    80002eb6:	fd349de3          	bne	s1,s3,80002e90 <binit+0x54>
  }
}
    80002eba:	70a2                	ld	ra,40(sp)
    80002ebc:	7402                	ld	s0,32(sp)
    80002ebe:	64e2                	ld	s1,24(sp)
    80002ec0:	6942                	ld	s2,16(sp)
    80002ec2:	69a2                	ld	s3,8(sp)
    80002ec4:	6a02                	ld	s4,0(sp)
    80002ec6:	6145                	addi	sp,sp,48
    80002ec8:	8082                	ret

0000000080002eca <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002eca:	7179                	addi	sp,sp,-48
    80002ecc:	f406                	sd	ra,40(sp)
    80002ece:	f022                	sd	s0,32(sp)
    80002ed0:	ec26                	sd	s1,24(sp)
    80002ed2:	e84a                	sd	s2,16(sp)
    80002ed4:	e44e                	sd	s3,8(sp)
    80002ed6:	1800                	addi	s0,sp,48
    80002ed8:	892a                	mv	s2,a0
    80002eda:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002edc:	00014517          	auipc	a0,0x14
    80002ee0:	43c50513          	addi	a0,a0,1084 # 80017318 <bcache>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	cf2080e7          	jalr	-782(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eec:	0001c497          	auipc	s1,0x1c
    80002ef0:	6e44b483          	ld	s1,1764(s1) # 8001f5d0 <bcache+0x82b8>
    80002ef4:	0001c797          	auipc	a5,0x1c
    80002ef8:	68c78793          	addi	a5,a5,1676 # 8001f580 <bcache+0x8268>
    80002efc:	02f48f63          	beq	s1,a5,80002f3a <bread+0x70>
    80002f00:	873e                	mv	a4,a5
    80002f02:	a021                	j	80002f0a <bread+0x40>
    80002f04:	68a4                	ld	s1,80(s1)
    80002f06:	02e48a63          	beq	s1,a4,80002f3a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f0a:	449c                	lw	a5,8(s1)
    80002f0c:	ff279ce3          	bne	a5,s2,80002f04 <bread+0x3a>
    80002f10:	44dc                	lw	a5,12(s1)
    80002f12:	ff3799e3          	bne	a5,s3,80002f04 <bread+0x3a>
      b->refcnt++;
    80002f16:	40bc                	lw	a5,64(s1)
    80002f18:	2785                	addiw	a5,a5,1
    80002f1a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f1c:	00014517          	auipc	a0,0x14
    80002f20:	3fc50513          	addi	a0,a0,1020 # 80017318 <bcache>
    80002f24:	ffffe097          	auipc	ra,0xffffe
    80002f28:	d66080e7          	jalr	-666(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f2c:	01048513          	addi	a0,s1,16
    80002f30:	00001097          	auipc	ra,0x1
    80002f34:	46e080e7          	jalr	1134(ra) # 8000439e <acquiresleep>
      return b;
    80002f38:	a8b9                	j	80002f96 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f3a:	0001c497          	auipc	s1,0x1c
    80002f3e:	68e4b483          	ld	s1,1678(s1) # 8001f5c8 <bcache+0x82b0>
    80002f42:	0001c797          	auipc	a5,0x1c
    80002f46:	63e78793          	addi	a5,a5,1598 # 8001f580 <bcache+0x8268>
    80002f4a:	00f48863          	beq	s1,a5,80002f5a <bread+0x90>
    80002f4e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f50:	40bc                	lw	a5,64(s1)
    80002f52:	cf81                	beqz	a5,80002f6a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f54:	64a4                	ld	s1,72(s1)
    80002f56:	fee49de3          	bne	s1,a4,80002f50 <bread+0x86>
  panic("bget: no buffers");
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	5e650513          	addi	a0,a0,1510 # 80008540 <syscalls+0xd0>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	5dc080e7          	jalr	1500(ra) # 8000053e <panic>
      b->dev = dev;
    80002f6a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f6e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f72:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f76:	4785                	li	a5,1
    80002f78:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f7a:	00014517          	auipc	a0,0x14
    80002f7e:	39e50513          	addi	a0,a0,926 # 80017318 <bcache>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	d08080e7          	jalr	-760(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f8a:	01048513          	addi	a0,s1,16
    80002f8e:	00001097          	auipc	ra,0x1
    80002f92:	410080e7          	jalr	1040(ra) # 8000439e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f96:	409c                	lw	a5,0(s1)
    80002f98:	cb89                	beqz	a5,80002faa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f9a:	8526                	mv	a0,s1
    80002f9c:	70a2                	ld	ra,40(sp)
    80002f9e:	7402                	ld	s0,32(sp)
    80002fa0:	64e2                	ld	s1,24(sp)
    80002fa2:	6942                	ld	s2,16(sp)
    80002fa4:	69a2                	ld	s3,8(sp)
    80002fa6:	6145                	addi	sp,sp,48
    80002fa8:	8082                	ret
    virtio_disk_rw(b, 0);
    80002faa:	4581                	li	a1,0
    80002fac:	8526                	mv	a0,s1
    80002fae:	00003097          	auipc	ra,0x3
    80002fb2:	fd6080e7          	jalr	-42(ra) # 80005f84 <virtio_disk_rw>
    b->valid = 1;
    80002fb6:	4785                	li	a5,1
    80002fb8:	c09c                	sw	a5,0(s1)
  return b;
    80002fba:	b7c5                	j	80002f9a <bread+0xd0>

0000000080002fbc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	e426                	sd	s1,8(sp)
    80002fc4:	1000                	addi	s0,sp,32
    80002fc6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fc8:	0541                	addi	a0,a0,16
    80002fca:	00001097          	auipc	ra,0x1
    80002fce:	46e080e7          	jalr	1134(ra) # 80004438 <holdingsleep>
    80002fd2:	cd01                	beqz	a0,80002fea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fd4:	4585                	li	a1,1
    80002fd6:	8526                	mv	a0,s1
    80002fd8:	00003097          	auipc	ra,0x3
    80002fdc:	fac080e7          	jalr	-84(ra) # 80005f84 <virtio_disk_rw>
}
    80002fe0:	60e2                	ld	ra,24(sp)
    80002fe2:	6442                	ld	s0,16(sp)
    80002fe4:	64a2                	ld	s1,8(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret
    panic("bwrite");
    80002fea:	00005517          	auipc	a0,0x5
    80002fee:	56e50513          	addi	a0,a0,1390 # 80008558 <syscalls+0xe8>
    80002ff2:	ffffd097          	auipc	ra,0xffffd
    80002ff6:	54c080e7          	jalr	1356(ra) # 8000053e <panic>

0000000080002ffa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	e426                	sd	s1,8(sp)
    80003002:	e04a                	sd	s2,0(sp)
    80003004:	1000                	addi	s0,sp,32
    80003006:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003008:	01050913          	addi	s2,a0,16
    8000300c:	854a                	mv	a0,s2
    8000300e:	00001097          	auipc	ra,0x1
    80003012:	42a080e7          	jalr	1066(ra) # 80004438 <holdingsleep>
    80003016:	c92d                	beqz	a0,80003088 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003018:	854a                	mv	a0,s2
    8000301a:	00001097          	auipc	ra,0x1
    8000301e:	3da080e7          	jalr	986(ra) # 800043f4 <releasesleep>

  acquire(&bcache.lock);
    80003022:	00014517          	auipc	a0,0x14
    80003026:	2f650513          	addi	a0,a0,758 # 80017318 <bcache>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	bac080e7          	jalr	-1108(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003032:	40bc                	lw	a5,64(s1)
    80003034:	37fd                	addiw	a5,a5,-1
    80003036:	0007871b          	sext.w	a4,a5
    8000303a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000303c:	eb05                	bnez	a4,8000306c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000303e:	68bc                	ld	a5,80(s1)
    80003040:	64b8                	ld	a4,72(s1)
    80003042:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003044:	64bc                	ld	a5,72(s1)
    80003046:	68b8                	ld	a4,80(s1)
    80003048:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000304a:	0001c797          	auipc	a5,0x1c
    8000304e:	2ce78793          	addi	a5,a5,718 # 8001f318 <bcache+0x8000>
    80003052:	2b87b703          	ld	a4,696(a5)
    80003056:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003058:	0001c717          	auipc	a4,0x1c
    8000305c:	52870713          	addi	a4,a4,1320 # 8001f580 <bcache+0x8268>
    80003060:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003062:	2b87b703          	ld	a4,696(a5)
    80003066:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003068:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	2ac50513          	addi	a0,a0,684 # 80017318 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	c16080e7          	jalr	-1002(ra) # 80000c8a <release>
}
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6902                	ld	s2,0(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret
    panic("brelse");
    80003088:	00005517          	auipc	a0,0x5
    8000308c:	4d850513          	addi	a0,a0,1240 # 80008560 <syscalls+0xf0>
    80003090:	ffffd097          	auipc	ra,0xffffd
    80003094:	4ae080e7          	jalr	1198(ra) # 8000053e <panic>

0000000080003098 <bpin>:

void
bpin(struct buf *b) {
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	1000                	addi	s0,sp,32
    800030a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a4:	00014517          	auipc	a0,0x14
    800030a8:	27450513          	addi	a0,a0,628 # 80017318 <bcache>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	b2a080e7          	jalr	-1238(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800030b4:	40bc                	lw	a5,64(s1)
    800030b6:	2785                	addiw	a5,a5,1
    800030b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ba:	00014517          	auipc	a0,0x14
    800030be:	25e50513          	addi	a0,a0,606 # 80017318 <bcache>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	bc8080e7          	jalr	-1080(ra) # 80000c8a <release>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret

00000000800030d4 <bunpin>:

void
bunpin(struct buf *b) {
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	e426                	sd	s1,8(sp)
    800030dc:	1000                	addi	s0,sp,32
    800030de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030e0:	00014517          	auipc	a0,0x14
    800030e4:	23850513          	addi	a0,a0,568 # 80017318 <bcache>
    800030e8:	ffffe097          	auipc	ra,0xffffe
    800030ec:	aee080e7          	jalr	-1298(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030f0:	40bc                	lw	a5,64(s1)
    800030f2:	37fd                	addiw	a5,a5,-1
    800030f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f6:	00014517          	auipc	a0,0x14
    800030fa:	22250513          	addi	a0,a0,546 # 80017318 <bcache>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b8c080e7          	jalr	-1140(ra) # 80000c8a <release>
}
    80003106:	60e2                	ld	ra,24(sp)
    80003108:	6442                	ld	s0,16(sp)
    8000310a:	64a2                	ld	s1,8(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret

0000000080003110 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	e04a                	sd	s2,0(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000311e:	00d5d59b          	srliw	a1,a1,0xd
    80003122:	0001d797          	auipc	a5,0x1d
    80003126:	8d27a783          	lw	a5,-1838(a5) # 8001f9f4 <sb+0x1c>
    8000312a:	9dbd                	addw	a1,a1,a5
    8000312c:	00000097          	auipc	ra,0x0
    80003130:	d9e080e7          	jalr	-610(ra) # 80002eca <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003134:	0074f713          	andi	a4,s1,7
    80003138:	4785                	li	a5,1
    8000313a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000313e:	14ce                	slli	s1,s1,0x33
    80003140:	90d9                	srli	s1,s1,0x36
    80003142:	00950733          	add	a4,a0,s1
    80003146:	05874703          	lbu	a4,88(a4)
    8000314a:	00e7f6b3          	and	a3,a5,a4
    8000314e:	c69d                	beqz	a3,8000317c <bfree+0x6c>
    80003150:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003152:	94aa                	add	s1,s1,a0
    80003154:	fff7c793          	not	a5,a5
    80003158:	8ff9                	and	a5,a5,a4
    8000315a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000315e:	00001097          	auipc	ra,0x1
    80003162:	120080e7          	jalr	288(ra) # 8000427e <log_write>
  brelse(bp);
    80003166:	854a                	mv	a0,s2
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	e92080e7          	jalr	-366(ra) # 80002ffa <brelse>
}
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	64a2                	ld	s1,8(sp)
    80003176:	6902                	ld	s2,0(sp)
    80003178:	6105                	addi	sp,sp,32
    8000317a:	8082                	ret
    panic("freeing free block");
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	3ec50513          	addi	a0,a0,1004 # 80008568 <syscalls+0xf8>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	3ba080e7          	jalr	954(ra) # 8000053e <panic>

000000008000318c <balloc>:
{
    8000318c:	711d                	addi	sp,sp,-96
    8000318e:	ec86                	sd	ra,88(sp)
    80003190:	e8a2                	sd	s0,80(sp)
    80003192:	e4a6                	sd	s1,72(sp)
    80003194:	e0ca                	sd	s2,64(sp)
    80003196:	fc4e                	sd	s3,56(sp)
    80003198:	f852                	sd	s4,48(sp)
    8000319a:	f456                	sd	s5,40(sp)
    8000319c:	f05a                	sd	s6,32(sp)
    8000319e:	ec5e                	sd	s7,24(sp)
    800031a0:	e862                	sd	s8,16(sp)
    800031a2:	e466                	sd	s9,8(sp)
    800031a4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031a6:	0001d797          	auipc	a5,0x1d
    800031aa:	8367a783          	lw	a5,-1994(a5) # 8001f9dc <sb+0x4>
    800031ae:	10078163          	beqz	a5,800032b0 <balloc+0x124>
    800031b2:	8baa                	mv	s7,a0
    800031b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031b6:	0001db17          	auipc	s6,0x1d
    800031ba:	822b0b13          	addi	s6,s6,-2014 # 8001f9d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031c4:	6c89                	lui	s9,0x2
    800031c6:	a061                	j	8000324e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031c8:	974a                	add	a4,a4,s2
    800031ca:	8fd5                	or	a5,a5,a3
    800031cc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031d0:	854a                	mv	a0,s2
    800031d2:	00001097          	auipc	ra,0x1
    800031d6:	0ac080e7          	jalr	172(ra) # 8000427e <log_write>
        brelse(bp);
    800031da:	854a                	mv	a0,s2
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	e1e080e7          	jalr	-482(ra) # 80002ffa <brelse>
  bp = bread(dev, bno);
    800031e4:	85a6                	mv	a1,s1
    800031e6:	855e                	mv	a0,s7
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	ce2080e7          	jalr	-798(ra) # 80002eca <bread>
    800031f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031f2:	40000613          	li	a2,1024
    800031f6:	4581                	li	a1,0
    800031f8:	05850513          	addi	a0,a0,88
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	ad6080e7          	jalr	-1322(ra) # 80000cd2 <memset>
  log_write(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00001097          	auipc	ra,0x1
    8000320a:	078080e7          	jalr	120(ra) # 8000427e <log_write>
  brelse(bp);
    8000320e:	854a                	mv	a0,s2
    80003210:	00000097          	auipc	ra,0x0
    80003214:	dea080e7          	jalr	-534(ra) # 80002ffa <brelse>
}
    80003218:	8526                	mv	a0,s1
    8000321a:	60e6                	ld	ra,88(sp)
    8000321c:	6446                	ld	s0,80(sp)
    8000321e:	64a6                	ld	s1,72(sp)
    80003220:	6906                	ld	s2,64(sp)
    80003222:	79e2                	ld	s3,56(sp)
    80003224:	7a42                	ld	s4,48(sp)
    80003226:	7aa2                	ld	s5,40(sp)
    80003228:	7b02                	ld	s6,32(sp)
    8000322a:	6be2                	ld	s7,24(sp)
    8000322c:	6c42                	ld	s8,16(sp)
    8000322e:	6ca2                	ld	s9,8(sp)
    80003230:	6125                	addi	sp,sp,96
    80003232:	8082                	ret
    brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	dc4080e7          	jalr	-572(ra) # 80002ffa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000323e:	015c87bb          	addw	a5,s9,s5
    80003242:	00078a9b          	sext.w	s5,a5
    80003246:	004b2703          	lw	a4,4(s6)
    8000324a:	06eaf363          	bgeu	s5,a4,800032b0 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000324e:	41fad79b          	sraiw	a5,s5,0x1f
    80003252:	0137d79b          	srliw	a5,a5,0x13
    80003256:	015787bb          	addw	a5,a5,s5
    8000325a:	40d7d79b          	sraiw	a5,a5,0xd
    8000325e:	01cb2583          	lw	a1,28(s6)
    80003262:	9dbd                	addw	a1,a1,a5
    80003264:	855e                	mv	a0,s7
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	c64080e7          	jalr	-924(ra) # 80002eca <bread>
    8000326e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	004b2503          	lw	a0,4(s6)
    80003274:	000a849b          	sext.w	s1,s5
    80003278:	8662                	mv	a2,s8
    8000327a:	faa4fde3          	bgeu	s1,a0,80003234 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000327e:	41f6579b          	sraiw	a5,a2,0x1f
    80003282:	01d7d69b          	srliw	a3,a5,0x1d
    80003286:	00c6873b          	addw	a4,a3,a2
    8000328a:	00777793          	andi	a5,a4,7
    8000328e:	9f95                	subw	a5,a5,a3
    80003290:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003294:	4037571b          	sraiw	a4,a4,0x3
    80003298:	00e906b3          	add	a3,s2,a4
    8000329c:	0586c683          	lbu	a3,88(a3)
    800032a0:	00d7f5b3          	and	a1,a5,a3
    800032a4:	d195                	beqz	a1,800031c8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	2605                	addiw	a2,a2,1
    800032a8:	2485                	addiw	s1,s1,1
    800032aa:	fd4618e3          	bne	a2,s4,8000327a <balloc+0xee>
    800032ae:	b759                	j	80003234 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800032b0:	00005517          	auipc	a0,0x5
    800032b4:	2d050513          	addi	a0,a0,720 # 80008580 <syscalls+0x110>
    800032b8:	ffffd097          	auipc	ra,0xffffd
    800032bc:	2d0080e7          	jalr	720(ra) # 80000588 <printf>
  return 0;
    800032c0:	4481                	li	s1,0
    800032c2:	bf99                	j	80003218 <balloc+0x8c>

00000000800032c4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800032c4:	7179                	addi	sp,sp,-48
    800032c6:	f406                	sd	ra,40(sp)
    800032c8:	f022                	sd	s0,32(sp)
    800032ca:	ec26                	sd	s1,24(sp)
    800032cc:	e84a                	sd	s2,16(sp)
    800032ce:	e44e                	sd	s3,8(sp)
    800032d0:	e052                	sd	s4,0(sp)
    800032d2:	1800                	addi	s0,sp,48
    800032d4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032d6:	47ad                	li	a5,11
    800032d8:	02b7e763          	bltu	a5,a1,80003306 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800032dc:	02059493          	slli	s1,a1,0x20
    800032e0:	9081                	srli	s1,s1,0x20
    800032e2:	048a                	slli	s1,s1,0x2
    800032e4:	94aa                	add	s1,s1,a0
    800032e6:	0504a903          	lw	s2,80(s1)
    800032ea:	06091e63          	bnez	s2,80003366 <bmap+0xa2>
      addr = balloc(ip->dev);
    800032ee:	4108                	lw	a0,0(a0)
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	e9c080e7          	jalr	-356(ra) # 8000318c <balloc>
    800032f8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032fc:	06090563          	beqz	s2,80003366 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003300:	0524a823          	sw	s2,80(s1)
    80003304:	a08d                	j	80003366 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003306:	ff45849b          	addiw	s1,a1,-12
    8000330a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000330e:	0ff00793          	li	a5,255
    80003312:	08e7e563          	bltu	a5,a4,8000339c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003316:	08052903          	lw	s2,128(a0)
    8000331a:	00091d63          	bnez	s2,80003334 <bmap+0x70>
      addr = balloc(ip->dev);
    8000331e:	4108                	lw	a0,0(a0)
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e6c080e7          	jalr	-404(ra) # 8000318c <balloc>
    80003328:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000332c:	02090d63          	beqz	s2,80003366 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003330:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003334:	85ca                	mv	a1,s2
    80003336:	0009a503          	lw	a0,0(s3)
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	b90080e7          	jalr	-1136(ra) # 80002eca <bread>
    80003342:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003344:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003348:	02049593          	slli	a1,s1,0x20
    8000334c:	9181                	srli	a1,a1,0x20
    8000334e:	058a                	slli	a1,a1,0x2
    80003350:	00b784b3          	add	s1,a5,a1
    80003354:	0004a903          	lw	s2,0(s1)
    80003358:	02090063          	beqz	s2,80003378 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000335c:	8552                	mv	a0,s4
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	c9c080e7          	jalr	-868(ra) # 80002ffa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003366:	854a                	mv	a0,s2
    80003368:	70a2                	ld	ra,40(sp)
    8000336a:	7402                	ld	s0,32(sp)
    8000336c:	64e2                	ld	s1,24(sp)
    8000336e:	6942                	ld	s2,16(sp)
    80003370:	69a2                	ld	s3,8(sp)
    80003372:	6a02                	ld	s4,0(sp)
    80003374:	6145                	addi	sp,sp,48
    80003376:	8082                	ret
      addr = balloc(ip->dev);
    80003378:	0009a503          	lw	a0,0(s3)
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	e10080e7          	jalr	-496(ra) # 8000318c <balloc>
    80003384:	0005091b          	sext.w	s2,a0
      if(addr){
    80003388:	fc090ae3          	beqz	s2,8000335c <bmap+0x98>
        a[bn] = addr;
    8000338c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003390:	8552                	mv	a0,s4
    80003392:	00001097          	auipc	ra,0x1
    80003396:	eec080e7          	jalr	-276(ra) # 8000427e <log_write>
    8000339a:	b7c9                	j	8000335c <bmap+0x98>
  panic("bmap: out of range");
    8000339c:	00005517          	auipc	a0,0x5
    800033a0:	1fc50513          	addi	a0,a0,508 # 80008598 <syscalls+0x128>
    800033a4:	ffffd097          	auipc	ra,0xffffd
    800033a8:	19a080e7          	jalr	410(ra) # 8000053e <panic>

00000000800033ac <iget>:
{
    800033ac:	7179                	addi	sp,sp,-48
    800033ae:	f406                	sd	ra,40(sp)
    800033b0:	f022                	sd	s0,32(sp)
    800033b2:	ec26                	sd	s1,24(sp)
    800033b4:	e84a                	sd	s2,16(sp)
    800033b6:	e44e                	sd	s3,8(sp)
    800033b8:	e052                	sd	s4,0(sp)
    800033ba:	1800                	addi	s0,sp,48
    800033bc:	89aa                	mv	s3,a0
    800033be:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033c0:	0001c517          	auipc	a0,0x1c
    800033c4:	63850513          	addi	a0,a0,1592 # 8001f9f8 <itable>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	80e080e7          	jalr	-2034(ra) # 80000bd6 <acquire>
  empty = 0;
    800033d0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033d2:	0001c497          	auipc	s1,0x1c
    800033d6:	63e48493          	addi	s1,s1,1598 # 8001fa10 <itable+0x18>
    800033da:	0001e697          	auipc	a3,0x1e
    800033de:	0c668693          	addi	a3,a3,198 # 800214a0 <log>
    800033e2:	a039                	j	800033f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e4:	02090b63          	beqz	s2,8000341a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033e8:	08848493          	addi	s1,s1,136
    800033ec:	02d48a63          	beq	s1,a3,80003420 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033f0:	449c                	lw	a5,8(s1)
    800033f2:	fef059e3          	blez	a5,800033e4 <iget+0x38>
    800033f6:	4098                	lw	a4,0(s1)
    800033f8:	ff3716e3          	bne	a4,s3,800033e4 <iget+0x38>
    800033fc:	40d8                	lw	a4,4(s1)
    800033fe:	ff4713e3          	bne	a4,s4,800033e4 <iget+0x38>
      ip->ref++;
    80003402:	2785                	addiw	a5,a5,1
    80003404:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003406:	0001c517          	auipc	a0,0x1c
    8000340a:	5f250513          	addi	a0,a0,1522 # 8001f9f8 <itable>
    8000340e:	ffffe097          	auipc	ra,0xffffe
    80003412:	87c080e7          	jalr	-1924(ra) # 80000c8a <release>
      return ip;
    80003416:	8926                	mv	s2,s1
    80003418:	a03d                	j	80003446 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000341a:	f7f9                	bnez	a5,800033e8 <iget+0x3c>
    8000341c:	8926                	mv	s2,s1
    8000341e:	b7e9                	j	800033e8 <iget+0x3c>
  if(empty == 0)
    80003420:	02090c63          	beqz	s2,80003458 <iget+0xac>
  ip->dev = dev;
    80003424:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003428:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000342c:	4785                	li	a5,1
    8000342e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003432:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003436:	0001c517          	auipc	a0,0x1c
    8000343a:	5c250513          	addi	a0,a0,1474 # 8001f9f8 <itable>
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	84c080e7          	jalr	-1972(ra) # 80000c8a <release>
}
    80003446:	854a                	mv	a0,s2
    80003448:	70a2                	ld	ra,40(sp)
    8000344a:	7402                	ld	s0,32(sp)
    8000344c:	64e2                	ld	s1,24(sp)
    8000344e:	6942                	ld	s2,16(sp)
    80003450:	69a2                	ld	s3,8(sp)
    80003452:	6a02                	ld	s4,0(sp)
    80003454:	6145                	addi	sp,sp,48
    80003456:	8082                	ret
    panic("iget: no inodes");
    80003458:	00005517          	auipc	a0,0x5
    8000345c:	15850513          	addi	a0,a0,344 # 800085b0 <syscalls+0x140>
    80003460:	ffffd097          	auipc	ra,0xffffd
    80003464:	0de080e7          	jalr	222(ra) # 8000053e <panic>

0000000080003468 <fsinit>:
fsinit(int dev) {
    80003468:	7179                	addi	sp,sp,-48
    8000346a:	f406                	sd	ra,40(sp)
    8000346c:	f022                	sd	s0,32(sp)
    8000346e:	ec26                	sd	s1,24(sp)
    80003470:	e84a                	sd	s2,16(sp)
    80003472:	e44e                	sd	s3,8(sp)
    80003474:	1800                	addi	s0,sp,48
    80003476:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003478:	4585                	li	a1,1
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	a50080e7          	jalr	-1456(ra) # 80002eca <bread>
    80003482:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003484:	0001c997          	auipc	s3,0x1c
    80003488:	55498993          	addi	s3,s3,1364 # 8001f9d8 <sb>
    8000348c:	02000613          	li	a2,32
    80003490:	05850593          	addi	a1,a0,88
    80003494:	854e                	mv	a0,s3
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	898080e7          	jalr	-1896(ra) # 80000d2e <memmove>
  brelse(bp);
    8000349e:	8526                	mv	a0,s1
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	b5a080e7          	jalr	-1190(ra) # 80002ffa <brelse>
  if(sb.magic != FSMAGIC)
    800034a8:	0009a703          	lw	a4,0(s3)
    800034ac:	102037b7          	lui	a5,0x10203
    800034b0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034b4:	02f71263          	bne	a4,a5,800034d8 <fsinit+0x70>
  initlog(dev, &sb);
    800034b8:	0001c597          	auipc	a1,0x1c
    800034bc:	52058593          	addi	a1,a1,1312 # 8001f9d8 <sb>
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	b40080e7          	jalr	-1216(ra) # 80004002 <initlog>
}
    800034ca:	70a2                	ld	ra,40(sp)
    800034cc:	7402                	ld	s0,32(sp)
    800034ce:	64e2                	ld	s1,24(sp)
    800034d0:	6942                	ld	s2,16(sp)
    800034d2:	69a2                	ld	s3,8(sp)
    800034d4:	6145                	addi	sp,sp,48
    800034d6:	8082                	ret
    panic("invalid file system");
    800034d8:	00005517          	auipc	a0,0x5
    800034dc:	0e850513          	addi	a0,a0,232 # 800085c0 <syscalls+0x150>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	05e080e7          	jalr	94(ra) # 8000053e <panic>

00000000800034e8 <iinit>:
{
    800034e8:	7179                	addi	sp,sp,-48
    800034ea:	f406                	sd	ra,40(sp)
    800034ec:	f022                	sd	s0,32(sp)
    800034ee:	ec26                	sd	s1,24(sp)
    800034f0:	e84a                	sd	s2,16(sp)
    800034f2:	e44e                	sd	s3,8(sp)
    800034f4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034f6:	00005597          	auipc	a1,0x5
    800034fa:	0e258593          	addi	a1,a1,226 # 800085d8 <syscalls+0x168>
    800034fe:	0001c517          	auipc	a0,0x1c
    80003502:	4fa50513          	addi	a0,a0,1274 # 8001f9f8 <itable>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	640080e7          	jalr	1600(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000350e:	0001c497          	auipc	s1,0x1c
    80003512:	51248493          	addi	s1,s1,1298 # 8001fa20 <itable+0x28>
    80003516:	0001e997          	auipc	s3,0x1e
    8000351a:	f9a98993          	addi	s3,s3,-102 # 800214b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000351e:	00005917          	auipc	s2,0x5
    80003522:	0c290913          	addi	s2,s2,194 # 800085e0 <syscalls+0x170>
    80003526:	85ca                	mv	a1,s2
    80003528:	8526                	mv	a0,s1
    8000352a:	00001097          	auipc	ra,0x1
    8000352e:	e3a080e7          	jalr	-454(ra) # 80004364 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003532:	08848493          	addi	s1,s1,136
    80003536:	ff3498e3          	bne	s1,s3,80003526 <iinit+0x3e>
}
    8000353a:	70a2                	ld	ra,40(sp)
    8000353c:	7402                	ld	s0,32(sp)
    8000353e:	64e2                	ld	s1,24(sp)
    80003540:	6942                	ld	s2,16(sp)
    80003542:	69a2                	ld	s3,8(sp)
    80003544:	6145                	addi	sp,sp,48
    80003546:	8082                	ret

0000000080003548 <ialloc>:
{
    80003548:	715d                	addi	sp,sp,-80
    8000354a:	e486                	sd	ra,72(sp)
    8000354c:	e0a2                	sd	s0,64(sp)
    8000354e:	fc26                	sd	s1,56(sp)
    80003550:	f84a                	sd	s2,48(sp)
    80003552:	f44e                	sd	s3,40(sp)
    80003554:	f052                	sd	s4,32(sp)
    80003556:	ec56                	sd	s5,24(sp)
    80003558:	e85a                	sd	s6,16(sp)
    8000355a:	e45e                	sd	s7,8(sp)
    8000355c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000355e:	0001c717          	auipc	a4,0x1c
    80003562:	48672703          	lw	a4,1158(a4) # 8001f9e4 <sb+0xc>
    80003566:	4785                	li	a5,1
    80003568:	04e7fa63          	bgeu	a5,a4,800035bc <ialloc+0x74>
    8000356c:	8aaa                	mv	s5,a0
    8000356e:	8bae                	mv	s7,a1
    80003570:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003572:	0001ca17          	auipc	s4,0x1c
    80003576:	466a0a13          	addi	s4,s4,1126 # 8001f9d8 <sb>
    8000357a:	00048b1b          	sext.w	s6,s1
    8000357e:	0044d793          	srli	a5,s1,0x4
    80003582:	018a2583          	lw	a1,24(s4)
    80003586:	9dbd                	addw	a1,a1,a5
    80003588:	8556                	mv	a0,s5
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	940080e7          	jalr	-1728(ra) # 80002eca <bread>
    80003592:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003594:	05850993          	addi	s3,a0,88
    80003598:	00f4f793          	andi	a5,s1,15
    8000359c:	079a                	slli	a5,a5,0x6
    8000359e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035a0:	00099783          	lh	a5,0(s3)
    800035a4:	c3a1                	beqz	a5,800035e4 <ialloc+0x9c>
    brelse(bp);
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	a54080e7          	jalr	-1452(ra) # 80002ffa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ae:	0485                	addi	s1,s1,1
    800035b0:	00ca2703          	lw	a4,12(s4)
    800035b4:	0004879b          	sext.w	a5,s1
    800035b8:	fce7e1e3          	bltu	a5,a4,8000357a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800035bc:	00005517          	auipc	a0,0x5
    800035c0:	02c50513          	addi	a0,a0,44 # 800085e8 <syscalls+0x178>
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	fc4080e7          	jalr	-60(ra) # 80000588 <printf>
  return 0;
    800035cc:	4501                	li	a0,0
}
    800035ce:	60a6                	ld	ra,72(sp)
    800035d0:	6406                	ld	s0,64(sp)
    800035d2:	74e2                	ld	s1,56(sp)
    800035d4:	7942                	ld	s2,48(sp)
    800035d6:	79a2                	ld	s3,40(sp)
    800035d8:	7a02                	ld	s4,32(sp)
    800035da:	6ae2                	ld	s5,24(sp)
    800035dc:	6b42                	ld	s6,16(sp)
    800035de:	6ba2                	ld	s7,8(sp)
    800035e0:	6161                	addi	sp,sp,80
    800035e2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035e4:	04000613          	li	a2,64
    800035e8:	4581                	li	a1,0
    800035ea:	854e                	mv	a0,s3
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	6e6080e7          	jalr	1766(ra) # 80000cd2 <memset>
      dip->type = type;
    800035f4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035f8:	854a                	mv	a0,s2
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	c84080e7          	jalr	-892(ra) # 8000427e <log_write>
      brelse(bp);
    80003602:	854a                	mv	a0,s2
    80003604:	00000097          	auipc	ra,0x0
    80003608:	9f6080e7          	jalr	-1546(ra) # 80002ffa <brelse>
      return iget(dev, inum);
    8000360c:	85da                	mv	a1,s6
    8000360e:	8556                	mv	a0,s5
    80003610:	00000097          	auipc	ra,0x0
    80003614:	d9c080e7          	jalr	-612(ra) # 800033ac <iget>
    80003618:	bf5d                	j	800035ce <ialloc+0x86>

000000008000361a <iupdate>:
{
    8000361a:	1101                	addi	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	e426                	sd	s1,8(sp)
    80003622:	e04a                	sd	s2,0(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003628:	415c                	lw	a5,4(a0)
    8000362a:	0047d79b          	srliw	a5,a5,0x4
    8000362e:	0001c597          	auipc	a1,0x1c
    80003632:	3c25a583          	lw	a1,962(a1) # 8001f9f0 <sb+0x18>
    80003636:	9dbd                	addw	a1,a1,a5
    80003638:	4108                	lw	a0,0(a0)
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	890080e7          	jalr	-1904(ra) # 80002eca <bread>
    80003642:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003644:	05850793          	addi	a5,a0,88
    80003648:	40c8                	lw	a0,4(s1)
    8000364a:	893d                	andi	a0,a0,15
    8000364c:	051a                	slli	a0,a0,0x6
    8000364e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003650:	04449703          	lh	a4,68(s1)
    80003654:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003658:	04649703          	lh	a4,70(s1)
    8000365c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003660:	04849703          	lh	a4,72(s1)
    80003664:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003668:	04a49703          	lh	a4,74(s1)
    8000366c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003670:	44f8                	lw	a4,76(s1)
    80003672:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003674:	03400613          	li	a2,52
    80003678:	05048593          	addi	a1,s1,80
    8000367c:	0531                	addi	a0,a0,12
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	6b0080e7          	jalr	1712(ra) # 80000d2e <memmove>
  log_write(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00001097          	auipc	ra,0x1
    8000368c:	bf6080e7          	jalr	-1034(ra) # 8000427e <log_write>
  brelse(bp);
    80003690:	854a                	mv	a0,s2
    80003692:	00000097          	auipc	ra,0x0
    80003696:	968080e7          	jalr	-1688(ra) # 80002ffa <brelse>
}
    8000369a:	60e2                	ld	ra,24(sp)
    8000369c:	6442                	ld	s0,16(sp)
    8000369e:	64a2                	ld	s1,8(sp)
    800036a0:	6902                	ld	s2,0(sp)
    800036a2:	6105                	addi	sp,sp,32
    800036a4:	8082                	ret

00000000800036a6 <idup>:
{
    800036a6:	1101                	addi	sp,sp,-32
    800036a8:	ec06                	sd	ra,24(sp)
    800036aa:	e822                	sd	s0,16(sp)
    800036ac:	e426                	sd	s1,8(sp)
    800036ae:	1000                	addi	s0,sp,32
    800036b0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036b2:	0001c517          	auipc	a0,0x1c
    800036b6:	34650513          	addi	a0,a0,838 # 8001f9f8 <itable>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	51c080e7          	jalr	1308(ra) # 80000bd6 <acquire>
  ip->ref++;
    800036c2:	449c                	lw	a5,8(s1)
    800036c4:	2785                	addiw	a5,a5,1
    800036c6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036c8:	0001c517          	auipc	a0,0x1c
    800036cc:	33050513          	addi	a0,a0,816 # 8001f9f8 <itable>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	5ba080e7          	jalr	1466(ra) # 80000c8a <release>
}
    800036d8:	8526                	mv	a0,s1
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	64a2                	ld	s1,8(sp)
    800036e0:	6105                	addi	sp,sp,32
    800036e2:	8082                	ret

00000000800036e4 <ilock>:
{
    800036e4:	1101                	addi	sp,sp,-32
    800036e6:	ec06                	sd	ra,24(sp)
    800036e8:	e822                	sd	s0,16(sp)
    800036ea:	e426                	sd	s1,8(sp)
    800036ec:	e04a                	sd	s2,0(sp)
    800036ee:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036f0:	c115                	beqz	a0,80003714 <ilock+0x30>
    800036f2:	84aa                	mv	s1,a0
    800036f4:	451c                	lw	a5,8(a0)
    800036f6:	00f05f63          	blez	a5,80003714 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036fa:	0541                	addi	a0,a0,16
    800036fc:	00001097          	auipc	ra,0x1
    80003700:	ca2080e7          	jalr	-862(ra) # 8000439e <acquiresleep>
  if(ip->valid == 0){
    80003704:	40bc                	lw	a5,64(s1)
    80003706:	cf99                	beqz	a5,80003724 <ilock+0x40>
}
    80003708:	60e2                	ld	ra,24(sp)
    8000370a:	6442                	ld	s0,16(sp)
    8000370c:	64a2                	ld	s1,8(sp)
    8000370e:	6902                	ld	s2,0(sp)
    80003710:	6105                	addi	sp,sp,32
    80003712:	8082                	ret
    panic("ilock");
    80003714:	00005517          	auipc	a0,0x5
    80003718:	eec50513          	addi	a0,a0,-276 # 80008600 <syscalls+0x190>
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	e22080e7          	jalr	-478(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003724:	40dc                	lw	a5,4(s1)
    80003726:	0047d79b          	srliw	a5,a5,0x4
    8000372a:	0001c597          	auipc	a1,0x1c
    8000372e:	2c65a583          	lw	a1,710(a1) # 8001f9f0 <sb+0x18>
    80003732:	9dbd                	addw	a1,a1,a5
    80003734:	4088                	lw	a0,0(s1)
    80003736:	fffff097          	auipc	ra,0xfffff
    8000373a:	794080e7          	jalr	1940(ra) # 80002eca <bread>
    8000373e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003740:	05850593          	addi	a1,a0,88
    80003744:	40dc                	lw	a5,4(s1)
    80003746:	8bbd                	andi	a5,a5,15
    80003748:	079a                	slli	a5,a5,0x6
    8000374a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000374c:	00059783          	lh	a5,0(a1)
    80003750:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003754:	00259783          	lh	a5,2(a1)
    80003758:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000375c:	00459783          	lh	a5,4(a1)
    80003760:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003764:	00659783          	lh	a5,6(a1)
    80003768:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000376c:	459c                	lw	a5,8(a1)
    8000376e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003770:	03400613          	li	a2,52
    80003774:	05b1                	addi	a1,a1,12
    80003776:	05048513          	addi	a0,s1,80
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	5b4080e7          	jalr	1460(ra) # 80000d2e <memmove>
    brelse(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00000097          	auipc	ra,0x0
    80003788:	876080e7          	jalr	-1930(ra) # 80002ffa <brelse>
    ip->valid = 1;
    8000378c:	4785                	li	a5,1
    8000378e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003790:	04449783          	lh	a5,68(s1)
    80003794:	fbb5                	bnez	a5,80003708 <ilock+0x24>
      panic("ilock: no type");
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	e7250513          	addi	a0,a0,-398 # 80008608 <syscalls+0x198>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>

00000000800037a6 <iunlock>:
{
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	e04a                	sd	s2,0(sp)
    800037b0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037b2:	c905                	beqz	a0,800037e2 <iunlock+0x3c>
    800037b4:	84aa                	mv	s1,a0
    800037b6:	01050913          	addi	s2,a0,16
    800037ba:	854a                	mv	a0,s2
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	c7c080e7          	jalr	-900(ra) # 80004438 <holdingsleep>
    800037c4:	cd19                	beqz	a0,800037e2 <iunlock+0x3c>
    800037c6:	449c                	lw	a5,8(s1)
    800037c8:	00f05d63          	blez	a5,800037e2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	c26080e7          	jalr	-986(ra) # 800043f4 <releasesleep>
}
    800037d6:	60e2                	ld	ra,24(sp)
    800037d8:	6442                	ld	s0,16(sp)
    800037da:	64a2                	ld	s1,8(sp)
    800037dc:	6902                	ld	s2,0(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret
    panic("iunlock");
    800037e2:	00005517          	auipc	a0,0x5
    800037e6:	e3650513          	addi	a0,a0,-458 # 80008618 <syscalls+0x1a8>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	d54080e7          	jalr	-684(ra) # 8000053e <panic>

00000000800037f2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037f2:	7179                	addi	sp,sp,-48
    800037f4:	f406                	sd	ra,40(sp)
    800037f6:	f022                	sd	s0,32(sp)
    800037f8:	ec26                	sd	s1,24(sp)
    800037fa:	e84a                	sd	s2,16(sp)
    800037fc:	e44e                	sd	s3,8(sp)
    800037fe:	e052                	sd	s4,0(sp)
    80003800:	1800                	addi	s0,sp,48
    80003802:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003804:	05050493          	addi	s1,a0,80
    80003808:	08050913          	addi	s2,a0,128
    8000380c:	a021                	j	80003814 <itrunc+0x22>
    8000380e:	0491                	addi	s1,s1,4
    80003810:	01248d63          	beq	s1,s2,8000382a <itrunc+0x38>
    if(ip->addrs[i]){
    80003814:	408c                	lw	a1,0(s1)
    80003816:	dde5                	beqz	a1,8000380e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003818:	0009a503          	lw	a0,0(s3)
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	8f4080e7          	jalr	-1804(ra) # 80003110 <bfree>
      ip->addrs[i] = 0;
    80003824:	0004a023          	sw	zero,0(s1)
    80003828:	b7dd                	j	8000380e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000382a:	0809a583          	lw	a1,128(s3)
    8000382e:	e185                	bnez	a1,8000384e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003830:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003834:	854e                	mv	a0,s3
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	de4080e7          	jalr	-540(ra) # 8000361a <iupdate>
}
    8000383e:	70a2                	ld	ra,40(sp)
    80003840:	7402                	ld	s0,32(sp)
    80003842:	64e2                	ld	s1,24(sp)
    80003844:	6942                	ld	s2,16(sp)
    80003846:	69a2                	ld	s3,8(sp)
    80003848:	6a02                	ld	s4,0(sp)
    8000384a:	6145                	addi	sp,sp,48
    8000384c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000384e:	0009a503          	lw	a0,0(s3)
    80003852:	fffff097          	auipc	ra,0xfffff
    80003856:	678080e7          	jalr	1656(ra) # 80002eca <bread>
    8000385a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000385c:	05850493          	addi	s1,a0,88
    80003860:	45850913          	addi	s2,a0,1112
    80003864:	a021                	j	8000386c <itrunc+0x7a>
    80003866:	0491                	addi	s1,s1,4
    80003868:	01248b63          	beq	s1,s2,8000387e <itrunc+0x8c>
      if(a[j])
    8000386c:	408c                	lw	a1,0(s1)
    8000386e:	dde5                	beqz	a1,80003866 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003870:	0009a503          	lw	a0,0(s3)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	89c080e7          	jalr	-1892(ra) # 80003110 <bfree>
    8000387c:	b7ed                	j	80003866 <itrunc+0x74>
    brelse(bp);
    8000387e:	8552                	mv	a0,s4
    80003880:	fffff097          	auipc	ra,0xfffff
    80003884:	77a080e7          	jalr	1914(ra) # 80002ffa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003888:	0809a583          	lw	a1,128(s3)
    8000388c:	0009a503          	lw	a0,0(s3)
    80003890:	00000097          	auipc	ra,0x0
    80003894:	880080e7          	jalr	-1920(ra) # 80003110 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003898:	0809a023          	sw	zero,128(s3)
    8000389c:	bf51                	j	80003830 <itrunc+0x3e>

000000008000389e <iput>:
{
    8000389e:	1101                	addi	sp,sp,-32
    800038a0:	ec06                	sd	ra,24(sp)
    800038a2:	e822                	sd	s0,16(sp)
    800038a4:	e426                	sd	s1,8(sp)
    800038a6:	e04a                	sd	s2,0(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038ac:	0001c517          	auipc	a0,0x1c
    800038b0:	14c50513          	addi	a0,a0,332 # 8001f9f8 <itable>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	322080e7          	jalr	802(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038bc:	4498                	lw	a4,8(s1)
    800038be:	4785                	li	a5,1
    800038c0:	02f70363          	beq	a4,a5,800038e6 <iput+0x48>
  ip->ref--;
    800038c4:	449c                	lw	a5,8(s1)
    800038c6:	37fd                	addiw	a5,a5,-1
    800038c8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038ca:	0001c517          	auipc	a0,0x1c
    800038ce:	12e50513          	addi	a0,a0,302 # 8001f9f8 <itable>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	3b8080e7          	jalr	952(ra) # 80000c8a <release>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6902                	ld	s2,0(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e6:	40bc                	lw	a5,64(s1)
    800038e8:	dff1                	beqz	a5,800038c4 <iput+0x26>
    800038ea:	04a49783          	lh	a5,74(s1)
    800038ee:	fbf9                	bnez	a5,800038c4 <iput+0x26>
    acquiresleep(&ip->lock);
    800038f0:	01048913          	addi	s2,s1,16
    800038f4:	854a                	mv	a0,s2
    800038f6:	00001097          	auipc	ra,0x1
    800038fa:	aa8080e7          	jalr	-1368(ra) # 8000439e <acquiresleep>
    release(&itable.lock);
    800038fe:	0001c517          	auipc	a0,0x1c
    80003902:	0fa50513          	addi	a0,a0,250 # 8001f9f8 <itable>
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	384080e7          	jalr	900(ra) # 80000c8a <release>
    itrunc(ip);
    8000390e:	8526                	mv	a0,s1
    80003910:	00000097          	auipc	ra,0x0
    80003914:	ee2080e7          	jalr	-286(ra) # 800037f2 <itrunc>
    ip->type = 0;
    80003918:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000391c:	8526                	mv	a0,s1
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	cfc080e7          	jalr	-772(ra) # 8000361a <iupdate>
    ip->valid = 0;
    80003926:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	ac8080e7          	jalr	-1336(ra) # 800043f4 <releasesleep>
    acquire(&itable.lock);
    80003934:	0001c517          	auipc	a0,0x1c
    80003938:	0c450513          	addi	a0,a0,196 # 8001f9f8 <itable>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	29a080e7          	jalr	666(ra) # 80000bd6 <acquire>
    80003944:	b741                	j	800038c4 <iput+0x26>

0000000080003946 <iunlockput>:
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	1000                	addi	s0,sp,32
    80003950:	84aa                	mv	s1,a0
  iunlock(ip);
    80003952:	00000097          	auipc	ra,0x0
    80003956:	e54080e7          	jalr	-428(ra) # 800037a6 <iunlock>
  iput(ip);
    8000395a:	8526                	mv	a0,s1
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	f42080e7          	jalr	-190(ra) # 8000389e <iput>
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6105                	addi	sp,sp,32
    8000396c:	8082                	ret

000000008000396e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000396e:	1141                	addi	sp,sp,-16
    80003970:	e422                	sd	s0,8(sp)
    80003972:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003974:	411c                	lw	a5,0(a0)
    80003976:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003978:	415c                	lw	a5,4(a0)
    8000397a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000397c:	04451783          	lh	a5,68(a0)
    80003980:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003984:	04a51783          	lh	a5,74(a0)
    80003988:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000398c:	04c56783          	lwu	a5,76(a0)
    80003990:	e99c                	sd	a5,16(a1)
}
    80003992:	6422                	ld	s0,8(sp)
    80003994:	0141                	addi	sp,sp,16
    80003996:	8082                	ret

0000000080003998 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003998:	457c                	lw	a5,76(a0)
    8000399a:	0ed7e963          	bltu	a5,a3,80003a8c <readi+0xf4>
{
    8000399e:	7159                	addi	sp,sp,-112
    800039a0:	f486                	sd	ra,104(sp)
    800039a2:	f0a2                	sd	s0,96(sp)
    800039a4:	eca6                	sd	s1,88(sp)
    800039a6:	e8ca                	sd	s2,80(sp)
    800039a8:	e4ce                	sd	s3,72(sp)
    800039aa:	e0d2                	sd	s4,64(sp)
    800039ac:	fc56                	sd	s5,56(sp)
    800039ae:	f85a                	sd	s6,48(sp)
    800039b0:	f45e                	sd	s7,40(sp)
    800039b2:	f062                	sd	s8,32(sp)
    800039b4:	ec66                	sd	s9,24(sp)
    800039b6:	e86a                	sd	s10,16(sp)
    800039b8:	e46e                	sd	s11,8(sp)
    800039ba:	1880                	addi	s0,sp,112
    800039bc:	8b2a                	mv	s6,a0
    800039be:	8bae                	mv	s7,a1
    800039c0:	8a32                	mv	s4,a2
    800039c2:	84b6                	mv	s1,a3
    800039c4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800039c6:	9f35                	addw	a4,a4,a3
    return 0;
    800039c8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039ca:	0ad76063          	bltu	a4,a3,80003a6a <readi+0xd2>
  if(off + n > ip->size)
    800039ce:	00e7f463          	bgeu	a5,a4,800039d6 <readi+0x3e>
    n = ip->size - off;
    800039d2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d6:	0a0a8963          	beqz	s5,80003a88 <readi+0xf0>
    800039da:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039dc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039e0:	5c7d                	li	s8,-1
    800039e2:	a82d                	j	80003a1c <readi+0x84>
    800039e4:	020d1d93          	slli	s11,s10,0x20
    800039e8:	020ddd93          	srli	s11,s11,0x20
    800039ec:	05890793          	addi	a5,s2,88
    800039f0:	86ee                	mv	a3,s11
    800039f2:	963e                	add	a2,a2,a5
    800039f4:	85d2                	mv	a1,s4
    800039f6:	855e                	mv	a0,s7
    800039f8:	fffff097          	auipc	ra,0xfffff
    800039fc:	b00080e7          	jalr	-1280(ra) # 800024f8 <either_copyout>
    80003a00:	05850d63          	beq	a0,s8,80003a5a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a04:	854a                	mv	a0,s2
    80003a06:	fffff097          	auipc	ra,0xfffff
    80003a0a:	5f4080e7          	jalr	1524(ra) # 80002ffa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a0e:	013d09bb          	addw	s3,s10,s3
    80003a12:	009d04bb          	addw	s1,s10,s1
    80003a16:	9a6e                	add	s4,s4,s11
    80003a18:	0559f763          	bgeu	s3,s5,80003a66 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a1c:	00a4d59b          	srliw	a1,s1,0xa
    80003a20:	855a                	mv	a0,s6
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	8a2080e7          	jalr	-1886(ra) # 800032c4 <bmap>
    80003a2a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a2e:	cd85                	beqz	a1,80003a66 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a30:	000b2503          	lw	a0,0(s6)
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	496080e7          	jalr	1174(ra) # 80002eca <bread>
    80003a3c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3e:	3ff4f613          	andi	a2,s1,1023
    80003a42:	40cc87bb          	subw	a5,s9,a2
    80003a46:	413a873b          	subw	a4,s5,s3
    80003a4a:	8d3e                	mv	s10,a5
    80003a4c:	2781                	sext.w	a5,a5
    80003a4e:	0007069b          	sext.w	a3,a4
    80003a52:	f8f6f9e3          	bgeu	a3,a5,800039e4 <readi+0x4c>
    80003a56:	8d3a                	mv	s10,a4
    80003a58:	b771                	j	800039e4 <readi+0x4c>
      brelse(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	59e080e7          	jalr	1438(ra) # 80002ffa <brelse>
      tot = -1;
    80003a64:	59fd                	li	s3,-1
  }
  return tot;
    80003a66:	0009851b          	sext.w	a0,s3
}
    80003a6a:	70a6                	ld	ra,104(sp)
    80003a6c:	7406                	ld	s0,96(sp)
    80003a6e:	64e6                	ld	s1,88(sp)
    80003a70:	6946                	ld	s2,80(sp)
    80003a72:	69a6                	ld	s3,72(sp)
    80003a74:	6a06                	ld	s4,64(sp)
    80003a76:	7ae2                	ld	s5,56(sp)
    80003a78:	7b42                	ld	s6,48(sp)
    80003a7a:	7ba2                	ld	s7,40(sp)
    80003a7c:	7c02                	ld	s8,32(sp)
    80003a7e:	6ce2                	ld	s9,24(sp)
    80003a80:	6d42                	ld	s10,16(sp)
    80003a82:	6da2                	ld	s11,8(sp)
    80003a84:	6165                	addi	sp,sp,112
    80003a86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a88:	89d6                	mv	s3,s5
    80003a8a:	bff1                	j	80003a66 <readi+0xce>
    return 0;
    80003a8c:	4501                	li	a0,0
}
    80003a8e:	8082                	ret

0000000080003a90 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a90:	457c                	lw	a5,76(a0)
    80003a92:	10d7e863          	bltu	a5,a3,80003ba2 <writei+0x112>
{
    80003a96:	7159                	addi	sp,sp,-112
    80003a98:	f486                	sd	ra,104(sp)
    80003a9a:	f0a2                	sd	s0,96(sp)
    80003a9c:	eca6                	sd	s1,88(sp)
    80003a9e:	e8ca                	sd	s2,80(sp)
    80003aa0:	e4ce                	sd	s3,72(sp)
    80003aa2:	e0d2                	sd	s4,64(sp)
    80003aa4:	fc56                	sd	s5,56(sp)
    80003aa6:	f85a                	sd	s6,48(sp)
    80003aa8:	f45e                	sd	s7,40(sp)
    80003aaa:	f062                	sd	s8,32(sp)
    80003aac:	ec66                	sd	s9,24(sp)
    80003aae:	e86a                	sd	s10,16(sp)
    80003ab0:	e46e                	sd	s11,8(sp)
    80003ab2:	1880                	addi	s0,sp,112
    80003ab4:	8aaa                	mv	s5,a0
    80003ab6:	8bae                	mv	s7,a1
    80003ab8:	8a32                	mv	s4,a2
    80003aba:	8936                	mv	s2,a3
    80003abc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003abe:	00e687bb          	addw	a5,a3,a4
    80003ac2:	0ed7e263          	bltu	a5,a3,80003ba6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ac6:	00043737          	lui	a4,0x43
    80003aca:	0ef76063          	bltu	a4,a5,80003baa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ace:	0c0b0863          	beqz	s6,80003b9e <writei+0x10e>
    80003ad2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ad8:	5c7d                	li	s8,-1
    80003ada:	a091                	j	80003b1e <writei+0x8e>
    80003adc:	020d1d93          	slli	s11,s10,0x20
    80003ae0:	020ddd93          	srli	s11,s11,0x20
    80003ae4:	05848793          	addi	a5,s1,88
    80003ae8:	86ee                	mv	a3,s11
    80003aea:	8652                	mv	a2,s4
    80003aec:	85de                	mv	a1,s7
    80003aee:	953e                	add	a0,a0,a5
    80003af0:	fffff097          	auipc	ra,0xfffff
    80003af4:	a5e080e7          	jalr	-1442(ra) # 8000254e <either_copyin>
    80003af8:	07850263          	beq	a0,s8,80003b5c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003afc:	8526                	mv	a0,s1
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	780080e7          	jalr	1920(ra) # 8000427e <log_write>
    brelse(bp);
    80003b06:	8526                	mv	a0,s1
    80003b08:	fffff097          	auipc	ra,0xfffff
    80003b0c:	4f2080e7          	jalr	1266(ra) # 80002ffa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b10:	013d09bb          	addw	s3,s10,s3
    80003b14:	012d093b          	addw	s2,s10,s2
    80003b18:	9a6e                	add	s4,s4,s11
    80003b1a:	0569f663          	bgeu	s3,s6,80003b66 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b1e:	00a9559b          	srliw	a1,s2,0xa
    80003b22:	8556                	mv	a0,s5
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	7a0080e7          	jalr	1952(ra) # 800032c4 <bmap>
    80003b2c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b30:	c99d                	beqz	a1,80003b66 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b32:	000aa503          	lw	a0,0(s5)
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	394080e7          	jalr	916(ra) # 80002eca <bread>
    80003b3e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b40:	3ff97513          	andi	a0,s2,1023
    80003b44:	40ac87bb          	subw	a5,s9,a0
    80003b48:	413b073b          	subw	a4,s6,s3
    80003b4c:	8d3e                	mv	s10,a5
    80003b4e:	2781                	sext.w	a5,a5
    80003b50:	0007069b          	sext.w	a3,a4
    80003b54:	f8f6f4e3          	bgeu	a3,a5,80003adc <writei+0x4c>
    80003b58:	8d3a                	mv	s10,a4
    80003b5a:	b749                	j	80003adc <writei+0x4c>
      brelse(bp);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	fffff097          	auipc	ra,0xfffff
    80003b62:	49c080e7          	jalr	1180(ra) # 80002ffa <brelse>
  }

  if(off > ip->size)
    80003b66:	04caa783          	lw	a5,76(s5)
    80003b6a:	0127f463          	bgeu	a5,s2,80003b72 <writei+0xe2>
    ip->size = off;
    80003b6e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b72:	8556                	mv	a0,s5
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	aa6080e7          	jalr	-1370(ra) # 8000361a <iupdate>

  return tot;
    80003b7c:	0009851b          	sext.w	a0,s3
}
    80003b80:	70a6                	ld	ra,104(sp)
    80003b82:	7406                	ld	s0,96(sp)
    80003b84:	64e6                	ld	s1,88(sp)
    80003b86:	6946                	ld	s2,80(sp)
    80003b88:	69a6                	ld	s3,72(sp)
    80003b8a:	6a06                	ld	s4,64(sp)
    80003b8c:	7ae2                	ld	s5,56(sp)
    80003b8e:	7b42                	ld	s6,48(sp)
    80003b90:	7ba2                	ld	s7,40(sp)
    80003b92:	7c02                	ld	s8,32(sp)
    80003b94:	6ce2                	ld	s9,24(sp)
    80003b96:	6d42                	ld	s10,16(sp)
    80003b98:	6da2                	ld	s11,8(sp)
    80003b9a:	6165                	addi	sp,sp,112
    80003b9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b9e:	89da                	mv	s3,s6
    80003ba0:	bfc9                	j	80003b72 <writei+0xe2>
    return -1;
    80003ba2:	557d                	li	a0,-1
}
    80003ba4:	8082                	ret
    return -1;
    80003ba6:	557d                	li	a0,-1
    80003ba8:	bfe1                	j	80003b80 <writei+0xf0>
    return -1;
    80003baa:	557d                	li	a0,-1
    80003bac:	bfd1                	j	80003b80 <writei+0xf0>

0000000080003bae <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bae:	1141                	addi	sp,sp,-16
    80003bb0:	e406                	sd	ra,8(sp)
    80003bb2:	e022                	sd	s0,0(sp)
    80003bb4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bb6:	4639                	li	a2,14
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	1ea080e7          	jalr	490(ra) # 80000da2 <strncmp>
}
    80003bc0:	60a2                	ld	ra,8(sp)
    80003bc2:	6402                	ld	s0,0(sp)
    80003bc4:	0141                	addi	sp,sp,16
    80003bc6:	8082                	ret

0000000080003bc8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bc8:	7139                	addi	sp,sp,-64
    80003bca:	fc06                	sd	ra,56(sp)
    80003bcc:	f822                	sd	s0,48(sp)
    80003bce:	f426                	sd	s1,40(sp)
    80003bd0:	f04a                	sd	s2,32(sp)
    80003bd2:	ec4e                	sd	s3,24(sp)
    80003bd4:	e852                	sd	s4,16(sp)
    80003bd6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bd8:	04451703          	lh	a4,68(a0)
    80003bdc:	4785                	li	a5,1
    80003bde:	00f71a63          	bne	a4,a5,80003bf2 <dirlookup+0x2a>
    80003be2:	892a                	mv	s2,a0
    80003be4:	89ae                	mv	s3,a1
    80003be6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003be8:	457c                	lw	a5,76(a0)
    80003bea:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bec:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bee:	e79d                	bnez	a5,80003c1c <dirlookup+0x54>
    80003bf0:	a8a5                	j	80003c68 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bf2:	00005517          	auipc	a0,0x5
    80003bf6:	a2e50513          	addi	a0,a0,-1490 # 80008620 <syscalls+0x1b0>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	944080e7          	jalr	-1724(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c02:	00005517          	auipc	a0,0x5
    80003c06:	a3650513          	addi	a0,a0,-1482 # 80008638 <syscalls+0x1c8>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	934080e7          	jalr	-1740(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c12:	24c1                	addiw	s1,s1,16
    80003c14:	04c92783          	lw	a5,76(s2)
    80003c18:	04f4f763          	bgeu	s1,a5,80003c66 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c1c:	4741                	li	a4,16
    80003c1e:	86a6                	mv	a3,s1
    80003c20:	fc040613          	addi	a2,s0,-64
    80003c24:	4581                	li	a1,0
    80003c26:	854a                	mv	a0,s2
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	d70080e7          	jalr	-656(ra) # 80003998 <readi>
    80003c30:	47c1                	li	a5,16
    80003c32:	fcf518e3          	bne	a0,a5,80003c02 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c36:	fc045783          	lhu	a5,-64(s0)
    80003c3a:	dfe1                	beqz	a5,80003c12 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c3c:	fc240593          	addi	a1,s0,-62
    80003c40:	854e                	mv	a0,s3
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	f6c080e7          	jalr	-148(ra) # 80003bae <namecmp>
    80003c4a:	f561                	bnez	a0,80003c12 <dirlookup+0x4a>
      if(poff)
    80003c4c:	000a0463          	beqz	s4,80003c54 <dirlookup+0x8c>
        *poff = off;
    80003c50:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c54:	fc045583          	lhu	a1,-64(s0)
    80003c58:	00092503          	lw	a0,0(s2)
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	750080e7          	jalr	1872(ra) # 800033ac <iget>
    80003c64:	a011                	j	80003c68 <dirlookup+0xa0>
  return 0;
    80003c66:	4501                	li	a0,0
}
    80003c68:	70e2                	ld	ra,56(sp)
    80003c6a:	7442                	ld	s0,48(sp)
    80003c6c:	74a2                	ld	s1,40(sp)
    80003c6e:	7902                	ld	s2,32(sp)
    80003c70:	69e2                	ld	s3,24(sp)
    80003c72:	6a42                	ld	s4,16(sp)
    80003c74:	6121                	addi	sp,sp,64
    80003c76:	8082                	ret

0000000080003c78 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c78:	711d                	addi	sp,sp,-96
    80003c7a:	ec86                	sd	ra,88(sp)
    80003c7c:	e8a2                	sd	s0,80(sp)
    80003c7e:	e4a6                	sd	s1,72(sp)
    80003c80:	e0ca                	sd	s2,64(sp)
    80003c82:	fc4e                	sd	s3,56(sp)
    80003c84:	f852                	sd	s4,48(sp)
    80003c86:	f456                	sd	s5,40(sp)
    80003c88:	f05a                	sd	s6,32(sp)
    80003c8a:	ec5e                	sd	s7,24(sp)
    80003c8c:	e862                	sd	s8,16(sp)
    80003c8e:	e466                	sd	s9,8(sp)
    80003c90:	1080                	addi	s0,sp,96
    80003c92:	84aa                	mv	s1,a0
    80003c94:	8aae                	mv	s5,a1
    80003c96:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c98:	00054703          	lbu	a4,0(a0)
    80003c9c:	02f00793          	li	a5,47
    80003ca0:	02f70363          	beq	a4,a5,80003cc6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ca4:	ffffe097          	auipc	ra,0xffffe
    80003ca8:	d3e080e7          	jalr	-706(ra) # 800019e2 <myproc>
    80003cac:	15053503          	ld	a0,336(a0)
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	9f6080e7          	jalr	-1546(ra) # 800036a6 <idup>
    80003cb8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cba:	02f00913          	li	s2,47
  len = path - s;
    80003cbe:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003cc0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cc2:	4b85                	li	s7,1
    80003cc4:	a865                	j	80003d7c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cc6:	4585                	li	a1,1
    80003cc8:	4505                	li	a0,1
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	6e2080e7          	jalr	1762(ra) # 800033ac <iget>
    80003cd2:	89aa                	mv	s3,a0
    80003cd4:	b7dd                	j	80003cba <namex+0x42>
      iunlockput(ip);
    80003cd6:	854e                	mv	a0,s3
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	c6e080e7          	jalr	-914(ra) # 80003946 <iunlockput>
      return 0;
    80003ce0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	60e6                	ld	ra,88(sp)
    80003ce6:	6446                	ld	s0,80(sp)
    80003ce8:	64a6                	ld	s1,72(sp)
    80003cea:	6906                	ld	s2,64(sp)
    80003cec:	79e2                	ld	s3,56(sp)
    80003cee:	7a42                	ld	s4,48(sp)
    80003cf0:	7aa2                	ld	s5,40(sp)
    80003cf2:	7b02                	ld	s6,32(sp)
    80003cf4:	6be2                	ld	s7,24(sp)
    80003cf6:	6c42                	ld	s8,16(sp)
    80003cf8:	6ca2                	ld	s9,8(sp)
    80003cfa:	6125                	addi	sp,sp,96
    80003cfc:	8082                	ret
      iunlock(ip);
    80003cfe:	854e                	mv	a0,s3
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	aa6080e7          	jalr	-1370(ra) # 800037a6 <iunlock>
      return ip;
    80003d08:	bfe9                	j	80003ce2 <namex+0x6a>
      iunlockput(ip);
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	c3a080e7          	jalr	-966(ra) # 80003946 <iunlockput>
      return 0;
    80003d14:	89e6                	mv	s3,s9
    80003d16:	b7f1                	j	80003ce2 <namex+0x6a>
  len = path - s;
    80003d18:	40b48633          	sub	a2,s1,a1
    80003d1c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d20:	099c5463          	bge	s8,s9,80003da8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d24:	4639                	li	a2,14
    80003d26:	8552                	mv	a0,s4
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	006080e7          	jalr	6(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003d30:	0004c783          	lbu	a5,0(s1)
    80003d34:	01279763          	bne	a5,s2,80003d42 <namex+0xca>
    path++;
    80003d38:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d3a:	0004c783          	lbu	a5,0(s1)
    80003d3e:	ff278de3          	beq	a5,s2,80003d38 <namex+0xc0>
    ilock(ip);
    80003d42:	854e                	mv	a0,s3
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	9a0080e7          	jalr	-1632(ra) # 800036e4 <ilock>
    if(ip->type != T_DIR){
    80003d4c:	04499783          	lh	a5,68(s3)
    80003d50:	f97793e3          	bne	a5,s7,80003cd6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d54:	000a8563          	beqz	s5,80003d5e <namex+0xe6>
    80003d58:	0004c783          	lbu	a5,0(s1)
    80003d5c:	d3cd                	beqz	a5,80003cfe <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d5e:	865a                	mv	a2,s6
    80003d60:	85d2                	mv	a1,s4
    80003d62:	854e                	mv	a0,s3
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	e64080e7          	jalr	-412(ra) # 80003bc8 <dirlookup>
    80003d6c:	8caa                	mv	s9,a0
    80003d6e:	dd51                	beqz	a0,80003d0a <namex+0x92>
    iunlockput(ip);
    80003d70:	854e                	mv	a0,s3
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	bd4080e7          	jalr	-1068(ra) # 80003946 <iunlockput>
    ip = next;
    80003d7a:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d7c:	0004c783          	lbu	a5,0(s1)
    80003d80:	05279763          	bne	a5,s2,80003dce <namex+0x156>
    path++;
    80003d84:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	ff278de3          	beq	a5,s2,80003d84 <namex+0x10c>
  if(*path == 0)
    80003d8e:	c79d                	beqz	a5,80003dbc <namex+0x144>
    path++;
    80003d90:	85a6                	mv	a1,s1
  len = path - s;
    80003d92:	8cda                	mv	s9,s6
    80003d94:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d96:	01278963          	beq	a5,s2,80003da8 <namex+0x130>
    80003d9a:	dfbd                	beqz	a5,80003d18 <namex+0xa0>
    path++;
    80003d9c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d9e:	0004c783          	lbu	a5,0(s1)
    80003da2:	ff279ce3          	bne	a5,s2,80003d9a <namex+0x122>
    80003da6:	bf8d                	j	80003d18 <namex+0xa0>
    memmove(name, s, len);
    80003da8:	2601                	sext.w	a2,a2
    80003daa:	8552                	mv	a0,s4
    80003dac:	ffffd097          	auipc	ra,0xffffd
    80003db0:	f82080e7          	jalr	-126(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003db4:	9cd2                	add	s9,s9,s4
    80003db6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003dba:	bf9d                	j	80003d30 <namex+0xb8>
  if(nameiparent){
    80003dbc:	f20a83e3          	beqz	s5,80003ce2 <namex+0x6a>
    iput(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	adc080e7          	jalr	-1316(ra) # 8000389e <iput>
    return 0;
    80003dca:	4981                	li	s3,0
    80003dcc:	bf19                	j	80003ce2 <namex+0x6a>
  if(*path == 0)
    80003dce:	d7fd                	beqz	a5,80003dbc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dd0:	0004c783          	lbu	a5,0(s1)
    80003dd4:	85a6                	mv	a1,s1
    80003dd6:	b7d1                	j	80003d9a <namex+0x122>

0000000080003dd8 <dirlink>:
{
    80003dd8:	7139                	addi	sp,sp,-64
    80003dda:	fc06                	sd	ra,56(sp)
    80003ddc:	f822                	sd	s0,48(sp)
    80003dde:	f426                	sd	s1,40(sp)
    80003de0:	f04a                	sd	s2,32(sp)
    80003de2:	ec4e                	sd	s3,24(sp)
    80003de4:	e852                	sd	s4,16(sp)
    80003de6:	0080                	addi	s0,sp,64
    80003de8:	892a                	mv	s2,a0
    80003dea:	8a2e                	mv	s4,a1
    80003dec:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dee:	4601                	li	a2,0
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	dd8080e7          	jalr	-552(ra) # 80003bc8 <dirlookup>
    80003df8:	e93d                	bnez	a0,80003e6e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfa:	04c92483          	lw	s1,76(s2)
    80003dfe:	c49d                	beqz	s1,80003e2c <dirlink+0x54>
    80003e00:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e02:	4741                	li	a4,16
    80003e04:	86a6                	mv	a3,s1
    80003e06:	fc040613          	addi	a2,s0,-64
    80003e0a:	4581                	li	a1,0
    80003e0c:	854a                	mv	a0,s2
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	b8a080e7          	jalr	-1142(ra) # 80003998 <readi>
    80003e16:	47c1                	li	a5,16
    80003e18:	06f51163          	bne	a0,a5,80003e7a <dirlink+0xa2>
    if(de.inum == 0)
    80003e1c:	fc045783          	lhu	a5,-64(s0)
    80003e20:	c791                	beqz	a5,80003e2c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e22:	24c1                	addiw	s1,s1,16
    80003e24:	04c92783          	lw	a5,76(s2)
    80003e28:	fcf4ede3          	bltu	s1,a5,80003e02 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e2c:	4639                	li	a2,14
    80003e2e:	85d2                	mv	a1,s4
    80003e30:	fc240513          	addi	a0,s0,-62
    80003e34:	ffffd097          	auipc	ra,0xffffd
    80003e38:	faa080e7          	jalr	-86(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e3c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e40:	4741                	li	a4,16
    80003e42:	86a6                	mv	a3,s1
    80003e44:	fc040613          	addi	a2,s0,-64
    80003e48:	4581                	li	a1,0
    80003e4a:	854a                	mv	a0,s2
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	c44080e7          	jalr	-956(ra) # 80003a90 <writei>
    80003e54:	1541                	addi	a0,a0,-16
    80003e56:	00a03533          	snez	a0,a0
    80003e5a:	40a00533          	neg	a0,a0
}
    80003e5e:	70e2                	ld	ra,56(sp)
    80003e60:	7442                	ld	s0,48(sp)
    80003e62:	74a2                	ld	s1,40(sp)
    80003e64:	7902                	ld	s2,32(sp)
    80003e66:	69e2                	ld	s3,24(sp)
    80003e68:	6a42                	ld	s4,16(sp)
    80003e6a:	6121                	addi	sp,sp,64
    80003e6c:	8082                	ret
    iput(ip);
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	a30080e7          	jalr	-1488(ra) # 8000389e <iput>
    return -1;
    80003e76:	557d                	li	a0,-1
    80003e78:	b7dd                	j	80003e5e <dirlink+0x86>
      panic("dirlink read");
    80003e7a:	00004517          	auipc	a0,0x4
    80003e7e:	7ce50513          	addi	a0,a0,1998 # 80008648 <syscalls+0x1d8>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6bc080e7          	jalr	1724(ra) # 8000053e <panic>

0000000080003e8a <namei>:

struct inode*
namei(char *path)
{
    80003e8a:	1101                	addi	sp,sp,-32
    80003e8c:	ec06                	sd	ra,24(sp)
    80003e8e:	e822                	sd	s0,16(sp)
    80003e90:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e92:	fe040613          	addi	a2,s0,-32
    80003e96:	4581                	li	a1,0
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	de0080e7          	jalr	-544(ra) # 80003c78 <namex>
}
    80003ea0:	60e2                	ld	ra,24(sp)
    80003ea2:	6442                	ld	s0,16(sp)
    80003ea4:	6105                	addi	sp,sp,32
    80003ea6:	8082                	ret

0000000080003ea8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ea8:	1141                	addi	sp,sp,-16
    80003eaa:	e406                	sd	ra,8(sp)
    80003eac:	e022                	sd	s0,0(sp)
    80003eae:	0800                	addi	s0,sp,16
    80003eb0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eb2:	4585                	li	a1,1
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	dc4080e7          	jalr	-572(ra) # 80003c78 <namex>
}
    80003ebc:	60a2                	ld	ra,8(sp)
    80003ebe:	6402                	ld	s0,0(sp)
    80003ec0:	0141                	addi	sp,sp,16
    80003ec2:	8082                	ret

0000000080003ec4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ec4:	1101                	addi	sp,sp,-32
    80003ec6:	ec06                	sd	ra,24(sp)
    80003ec8:	e822                	sd	s0,16(sp)
    80003eca:	e426                	sd	s1,8(sp)
    80003ecc:	e04a                	sd	s2,0(sp)
    80003ece:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ed0:	0001d917          	auipc	s2,0x1d
    80003ed4:	5d090913          	addi	s2,s2,1488 # 800214a0 <log>
    80003ed8:	01892583          	lw	a1,24(s2)
    80003edc:	02892503          	lw	a0,40(s2)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	fea080e7          	jalr	-22(ra) # 80002eca <bread>
    80003ee8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003eea:	02c92683          	lw	a3,44(s2)
    80003eee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ef0:	02d05763          	blez	a3,80003f1e <write_head+0x5a>
    80003ef4:	0001d797          	auipc	a5,0x1d
    80003ef8:	5dc78793          	addi	a5,a5,1500 # 800214d0 <log+0x30>
    80003efc:	05c50713          	addi	a4,a0,92
    80003f00:	36fd                	addiw	a3,a3,-1
    80003f02:	1682                	slli	a3,a3,0x20
    80003f04:	9281                	srli	a3,a3,0x20
    80003f06:	068a                	slli	a3,a3,0x2
    80003f08:	0001d617          	auipc	a2,0x1d
    80003f0c:	5cc60613          	addi	a2,a2,1484 # 800214d4 <log+0x34>
    80003f10:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f12:	4390                	lw	a2,0(a5)
    80003f14:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f16:	0791                	addi	a5,a5,4
    80003f18:	0711                	addi	a4,a4,4
    80003f1a:	fed79ce3          	bne	a5,a3,80003f12 <write_head+0x4e>
  }
  bwrite(buf);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	09c080e7          	jalr	156(ra) # 80002fbc <bwrite>
  brelse(buf);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	0d0080e7          	jalr	208(ra) # 80002ffa <brelse>
}
    80003f32:	60e2                	ld	ra,24(sp)
    80003f34:	6442                	ld	s0,16(sp)
    80003f36:	64a2                	ld	s1,8(sp)
    80003f38:	6902                	ld	s2,0(sp)
    80003f3a:	6105                	addi	sp,sp,32
    80003f3c:	8082                	ret

0000000080003f3e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f3e:	0001d797          	auipc	a5,0x1d
    80003f42:	58e7a783          	lw	a5,1422(a5) # 800214cc <log+0x2c>
    80003f46:	0af05d63          	blez	a5,80004000 <install_trans+0xc2>
{
    80003f4a:	7139                	addi	sp,sp,-64
    80003f4c:	fc06                	sd	ra,56(sp)
    80003f4e:	f822                	sd	s0,48(sp)
    80003f50:	f426                	sd	s1,40(sp)
    80003f52:	f04a                	sd	s2,32(sp)
    80003f54:	ec4e                	sd	s3,24(sp)
    80003f56:	e852                	sd	s4,16(sp)
    80003f58:	e456                	sd	s5,8(sp)
    80003f5a:	e05a                	sd	s6,0(sp)
    80003f5c:	0080                	addi	s0,sp,64
    80003f5e:	8b2a                	mv	s6,a0
    80003f60:	0001da97          	auipc	s5,0x1d
    80003f64:	570a8a93          	addi	s5,s5,1392 # 800214d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f68:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f6a:	0001d997          	auipc	s3,0x1d
    80003f6e:	53698993          	addi	s3,s3,1334 # 800214a0 <log>
    80003f72:	a00d                	j	80003f94 <install_trans+0x56>
    brelse(lbuf);
    80003f74:	854a                	mv	a0,s2
    80003f76:	fffff097          	auipc	ra,0xfffff
    80003f7a:	084080e7          	jalr	132(ra) # 80002ffa <brelse>
    brelse(dbuf);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	07a080e7          	jalr	122(ra) # 80002ffa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f88:	2a05                	addiw	s4,s4,1
    80003f8a:	0a91                	addi	s5,s5,4
    80003f8c:	02c9a783          	lw	a5,44(s3)
    80003f90:	04fa5e63          	bge	s4,a5,80003fec <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f94:	0189a583          	lw	a1,24(s3)
    80003f98:	014585bb          	addw	a1,a1,s4
    80003f9c:	2585                	addiw	a1,a1,1
    80003f9e:	0289a503          	lw	a0,40(s3)
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	f28080e7          	jalr	-216(ra) # 80002eca <bread>
    80003faa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fac:	000aa583          	lw	a1,0(s5)
    80003fb0:	0289a503          	lw	a0,40(s3)
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	f16080e7          	jalr	-234(ra) # 80002eca <bread>
    80003fbc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fbe:	40000613          	li	a2,1024
    80003fc2:	05890593          	addi	a1,s2,88
    80003fc6:	05850513          	addi	a0,a0,88
    80003fca:	ffffd097          	auipc	ra,0xffffd
    80003fce:	d64080e7          	jalr	-668(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fd2:	8526                	mv	a0,s1
    80003fd4:	fffff097          	auipc	ra,0xfffff
    80003fd8:	fe8080e7          	jalr	-24(ra) # 80002fbc <bwrite>
    if(recovering == 0)
    80003fdc:	f80b1ce3          	bnez	s6,80003f74 <install_trans+0x36>
      bunpin(dbuf);
    80003fe0:	8526                	mv	a0,s1
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	0f2080e7          	jalr	242(ra) # 800030d4 <bunpin>
    80003fea:	b769                	j	80003f74 <install_trans+0x36>
}
    80003fec:	70e2                	ld	ra,56(sp)
    80003fee:	7442                	ld	s0,48(sp)
    80003ff0:	74a2                	ld	s1,40(sp)
    80003ff2:	7902                	ld	s2,32(sp)
    80003ff4:	69e2                	ld	s3,24(sp)
    80003ff6:	6a42                	ld	s4,16(sp)
    80003ff8:	6aa2                	ld	s5,8(sp)
    80003ffa:	6b02                	ld	s6,0(sp)
    80003ffc:	6121                	addi	sp,sp,64
    80003ffe:	8082                	ret
    80004000:	8082                	ret

0000000080004002 <initlog>:
{
    80004002:	7179                	addi	sp,sp,-48
    80004004:	f406                	sd	ra,40(sp)
    80004006:	f022                	sd	s0,32(sp)
    80004008:	ec26                	sd	s1,24(sp)
    8000400a:	e84a                	sd	s2,16(sp)
    8000400c:	e44e                	sd	s3,8(sp)
    8000400e:	1800                	addi	s0,sp,48
    80004010:	892a                	mv	s2,a0
    80004012:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004014:	0001d497          	auipc	s1,0x1d
    80004018:	48c48493          	addi	s1,s1,1164 # 800214a0 <log>
    8000401c:	00004597          	auipc	a1,0x4
    80004020:	63c58593          	addi	a1,a1,1596 # 80008658 <syscalls+0x1e8>
    80004024:	8526                	mv	a0,s1
    80004026:	ffffd097          	auipc	ra,0xffffd
    8000402a:	b20080e7          	jalr	-1248(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000402e:	0149a583          	lw	a1,20(s3)
    80004032:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004034:	0109a783          	lw	a5,16(s3)
    80004038:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000403a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000403e:	854a                	mv	a0,s2
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	e8a080e7          	jalr	-374(ra) # 80002eca <bread>
  log.lh.n = lh->n;
    80004048:	4d34                	lw	a3,88(a0)
    8000404a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000404c:	02d05563          	blez	a3,80004076 <initlog+0x74>
    80004050:	05c50793          	addi	a5,a0,92
    80004054:	0001d717          	auipc	a4,0x1d
    80004058:	47c70713          	addi	a4,a4,1148 # 800214d0 <log+0x30>
    8000405c:	36fd                	addiw	a3,a3,-1
    8000405e:	1682                	slli	a3,a3,0x20
    80004060:	9281                	srli	a3,a3,0x20
    80004062:	068a                	slli	a3,a3,0x2
    80004064:	06050613          	addi	a2,a0,96
    80004068:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000406a:	4390                	lw	a2,0(a5)
    8000406c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000406e:	0791                	addi	a5,a5,4
    80004070:	0711                	addi	a4,a4,4
    80004072:	fed79ce3          	bne	a5,a3,8000406a <initlog+0x68>
  brelse(buf);
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	f84080e7          	jalr	-124(ra) # 80002ffa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000407e:	4505                	li	a0,1
    80004080:	00000097          	auipc	ra,0x0
    80004084:	ebe080e7          	jalr	-322(ra) # 80003f3e <install_trans>
  log.lh.n = 0;
    80004088:	0001d797          	auipc	a5,0x1d
    8000408c:	4407a223          	sw	zero,1092(a5) # 800214cc <log+0x2c>
  write_head(); // clear the log
    80004090:	00000097          	auipc	ra,0x0
    80004094:	e34080e7          	jalr	-460(ra) # 80003ec4 <write_head>
}
    80004098:	70a2                	ld	ra,40(sp)
    8000409a:	7402                	ld	s0,32(sp)
    8000409c:	64e2                	ld	s1,24(sp)
    8000409e:	6942                	ld	s2,16(sp)
    800040a0:	69a2                	ld	s3,8(sp)
    800040a2:	6145                	addi	sp,sp,48
    800040a4:	8082                	ret

00000000800040a6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040a6:	1101                	addi	sp,sp,-32
    800040a8:	ec06                	sd	ra,24(sp)
    800040aa:	e822                	sd	s0,16(sp)
    800040ac:	e426                	sd	s1,8(sp)
    800040ae:	e04a                	sd	s2,0(sp)
    800040b0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040b2:	0001d517          	auipc	a0,0x1d
    800040b6:	3ee50513          	addi	a0,a0,1006 # 800214a0 <log>
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	b1c080e7          	jalr	-1252(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800040c2:	0001d497          	auipc	s1,0x1d
    800040c6:	3de48493          	addi	s1,s1,990 # 800214a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ca:	4979                	li	s2,30
    800040cc:	a039                	j	800040da <begin_op+0x34>
      sleep(&log, &log.lock);
    800040ce:	85a6                	mv	a1,s1
    800040d0:	8526                	mv	a0,s1
    800040d2:	ffffe097          	auipc	ra,0xffffe
    800040d6:	01e080e7          	jalr	30(ra) # 800020f0 <sleep>
    if(log.committing){
    800040da:	50dc                	lw	a5,36(s1)
    800040dc:	fbed                	bnez	a5,800040ce <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040de:	509c                	lw	a5,32(s1)
    800040e0:	0017871b          	addiw	a4,a5,1
    800040e4:	0007069b          	sext.w	a3,a4
    800040e8:	0027179b          	slliw	a5,a4,0x2
    800040ec:	9fb9                	addw	a5,a5,a4
    800040ee:	0017979b          	slliw	a5,a5,0x1
    800040f2:	54d8                	lw	a4,44(s1)
    800040f4:	9fb9                	addw	a5,a5,a4
    800040f6:	00f95963          	bge	s2,a5,80004108 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040fa:	85a6                	mv	a1,s1
    800040fc:	8526                	mv	a0,s1
    800040fe:	ffffe097          	auipc	ra,0xffffe
    80004102:	ff2080e7          	jalr	-14(ra) # 800020f0 <sleep>
    80004106:	bfd1                	j	800040da <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004108:	0001d517          	auipc	a0,0x1d
    8000410c:	39850513          	addi	a0,a0,920 # 800214a0 <log>
    80004110:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004112:	ffffd097          	auipc	ra,0xffffd
    80004116:	b78080e7          	jalr	-1160(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000411a:	60e2                	ld	ra,24(sp)
    8000411c:	6442                	ld	s0,16(sp)
    8000411e:	64a2                	ld	s1,8(sp)
    80004120:	6902                	ld	s2,0(sp)
    80004122:	6105                	addi	sp,sp,32
    80004124:	8082                	ret

0000000080004126 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004126:	7139                	addi	sp,sp,-64
    80004128:	fc06                	sd	ra,56(sp)
    8000412a:	f822                	sd	s0,48(sp)
    8000412c:	f426                	sd	s1,40(sp)
    8000412e:	f04a                	sd	s2,32(sp)
    80004130:	ec4e                	sd	s3,24(sp)
    80004132:	e852                	sd	s4,16(sp)
    80004134:	e456                	sd	s5,8(sp)
    80004136:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004138:	0001d497          	auipc	s1,0x1d
    8000413c:	36848493          	addi	s1,s1,872 # 800214a0 <log>
    80004140:	8526                	mv	a0,s1
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	a94080e7          	jalr	-1388(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000414a:	509c                	lw	a5,32(s1)
    8000414c:	37fd                	addiw	a5,a5,-1
    8000414e:	0007891b          	sext.w	s2,a5
    80004152:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004154:	50dc                	lw	a5,36(s1)
    80004156:	e7b9                	bnez	a5,800041a4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004158:	04091e63          	bnez	s2,800041b4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000415c:	0001d497          	auipc	s1,0x1d
    80004160:	34448493          	addi	s1,s1,836 # 800214a0 <log>
    80004164:	4785                	li	a5,1
    80004166:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004168:	8526                	mv	a0,s1
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	b20080e7          	jalr	-1248(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004172:	54dc                	lw	a5,44(s1)
    80004174:	06f04763          	bgtz	a5,800041e2 <end_op+0xbc>
    acquire(&log.lock);
    80004178:	0001d497          	auipc	s1,0x1d
    8000417c:	32848493          	addi	s1,s1,808 # 800214a0 <log>
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	a54080e7          	jalr	-1452(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000418a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000418e:	8526                	mv	a0,s1
    80004190:	ffffe097          	auipc	ra,0xffffe
    80004194:	fc4080e7          	jalr	-60(ra) # 80002154 <wakeup>
    release(&log.lock);
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffd097          	auipc	ra,0xffffd
    8000419e:	af0080e7          	jalr	-1296(ra) # 80000c8a <release>
}
    800041a2:	a03d                	j	800041d0 <end_op+0xaa>
    panic("log.committing");
    800041a4:	00004517          	auipc	a0,0x4
    800041a8:	4bc50513          	addi	a0,a0,1212 # 80008660 <syscalls+0x1f0>
    800041ac:	ffffc097          	auipc	ra,0xffffc
    800041b0:	392080e7          	jalr	914(ra) # 8000053e <panic>
    wakeup(&log);
    800041b4:	0001d497          	auipc	s1,0x1d
    800041b8:	2ec48493          	addi	s1,s1,748 # 800214a0 <log>
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	f96080e7          	jalr	-106(ra) # 80002154 <wakeup>
  release(&log.lock);
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	ac2080e7          	jalr	-1342(ra) # 80000c8a <release>
}
    800041d0:	70e2                	ld	ra,56(sp)
    800041d2:	7442                	ld	s0,48(sp)
    800041d4:	74a2                	ld	s1,40(sp)
    800041d6:	7902                	ld	s2,32(sp)
    800041d8:	69e2                	ld	s3,24(sp)
    800041da:	6a42                	ld	s4,16(sp)
    800041dc:	6aa2                	ld	s5,8(sp)
    800041de:	6121                	addi	sp,sp,64
    800041e0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e2:	0001da97          	auipc	s5,0x1d
    800041e6:	2eea8a93          	addi	s5,s5,750 # 800214d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041ea:	0001da17          	auipc	s4,0x1d
    800041ee:	2b6a0a13          	addi	s4,s4,694 # 800214a0 <log>
    800041f2:	018a2583          	lw	a1,24(s4)
    800041f6:	012585bb          	addw	a1,a1,s2
    800041fa:	2585                	addiw	a1,a1,1
    800041fc:	028a2503          	lw	a0,40(s4)
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	cca080e7          	jalr	-822(ra) # 80002eca <bread>
    80004208:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000420a:	000aa583          	lw	a1,0(s5)
    8000420e:	028a2503          	lw	a0,40(s4)
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	cb8080e7          	jalr	-840(ra) # 80002eca <bread>
    8000421a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000421c:	40000613          	li	a2,1024
    80004220:	05850593          	addi	a1,a0,88
    80004224:	05848513          	addi	a0,s1,88
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	b06080e7          	jalr	-1274(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	d8a080e7          	jalr	-630(ra) # 80002fbc <bwrite>
    brelse(from);
    8000423a:	854e                	mv	a0,s3
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	dbe080e7          	jalr	-578(ra) # 80002ffa <brelse>
    brelse(to);
    80004244:	8526                	mv	a0,s1
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	db4080e7          	jalr	-588(ra) # 80002ffa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424e:	2905                	addiw	s2,s2,1
    80004250:	0a91                	addi	s5,s5,4
    80004252:	02ca2783          	lw	a5,44(s4)
    80004256:	f8f94ee3          	blt	s2,a5,800041f2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000425a:	00000097          	auipc	ra,0x0
    8000425e:	c6a080e7          	jalr	-918(ra) # 80003ec4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004262:	4501                	li	a0,0
    80004264:	00000097          	auipc	ra,0x0
    80004268:	cda080e7          	jalr	-806(ra) # 80003f3e <install_trans>
    log.lh.n = 0;
    8000426c:	0001d797          	auipc	a5,0x1d
    80004270:	2607a023          	sw	zero,608(a5) # 800214cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004274:	00000097          	auipc	ra,0x0
    80004278:	c50080e7          	jalr	-944(ra) # 80003ec4 <write_head>
    8000427c:	bdf5                	j	80004178 <end_op+0x52>

000000008000427e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000427e:	1101                	addi	sp,sp,-32
    80004280:	ec06                	sd	ra,24(sp)
    80004282:	e822                	sd	s0,16(sp)
    80004284:	e426                	sd	s1,8(sp)
    80004286:	e04a                	sd	s2,0(sp)
    80004288:	1000                	addi	s0,sp,32
    8000428a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000428c:	0001d917          	auipc	s2,0x1d
    80004290:	21490913          	addi	s2,s2,532 # 800214a0 <log>
    80004294:	854a                	mv	a0,s2
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	940080e7          	jalr	-1728(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000429e:	02c92603          	lw	a2,44(s2)
    800042a2:	47f5                	li	a5,29
    800042a4:	06c7c563          	blt	a5,a2,8000430e <log_write+0x90>
    800042a8:	0001d797          	auipc	a5,0x1d
    800042ac:	2147a783          	lw	a5,532(a5) # 800214bc <log+0x1c>
    800042b0:	37fd                	addiw	a5,a5,-1
    800042b2:	04f65e63          	bge	a2,a5,8000430e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042b6:	0001d797          	auipc	a5,0x1d
    800042ba:	20a7a783          	lw	a5,522(a5) # 800214c0 <log+0x20>
    800042be:	06f05063          	blez	a5,8000431e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042c2:	4781                	li	a5,0
    800042c4:	06c05563          	blez	a2,8000432e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042c8:	44cc                	lw	a1,12(s1)
    800042ca:	0001d717          	auipc	a4,0x1d
    800042ce:	20670713          	addi	a4,a4,518 # 800214d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042d2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042d4:	4314                	lw	a3,0(a4)
    800042d6:	04b68c63          	beq	a3,a1,8000432e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042da:	2785                	addiw	a5,a5,1
    800042dc:	0711                	addi	a4,a4,4
    800042de:	fef61be3          	bne	a2,a5,800042d4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042e2:	0621                	addi	a2,a2,8
    800042e4:	060a                	slli	a2,a2,0x2
    800042e6:	0001d797          	auipc	a5,0x1d
    800042ea:	1ba78793          	addi	a5,a5,442 # 800214a0 <log>
    800042ee:	963e                	add	a2,a2,a5
    800042f0:	44dc                	lw	a5,12(s1)
    800042f2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042f4:	8526                	mv	a0,s1
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	da2080e7          	jalr	-606(ra) # 80003098 <bpin>
    log.lh.n++;
    800042fe:	0001d717          	auipc	a4,0x1d
    80004302:	1a270713          	addi	a4,a4,418 # 800214a0 <log>
    80004306:	575c                	lw	a5,44(a4)
    80004308:	2785                	addiw	a5,a5,1
    8000430a:	d75c                	sw	a5,44(a4)
    8000430c:	a835                	j	80004348 <log_write+0xca>
    panic("too big a transaction");
    8000430e:	00004517          	auipc	a0,0x4
    80004312:	36250513          	addi	a0,a0,866 # 80008670 <syscalls+0x200>
    80004316:	ffffc097          	auipc	ra,0xffffc
    8000431a:	228080e7          	jalr	552(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000431e:	00004517          	auipc	a0,0x4
    80004322:	36a50513          	addi	a0,a0,874 # 80008688 <syscalls+0x218>
    80004326:	ffffc097          	auipc	ra,0xffffc
    8000432a:	218080e7          	jalr	536(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000432e:	00878713          	addi	a4,a5,8
    80004332:	00271693          	slli	a3,a4,0x2
    80004336:	0001d717          	auipc	a4,0x1d
    8000433a:	16a70713          	addi	a4,a4,362 # 800214a0 <log>
    8000433e:	9736                	add	a4,a4,a3
    80004340:	44d4                	lw	a3,12(s1)
    80004342:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004344:	faf608e3          	beq	a2,a5,800042f4 <log_write+0x76>
  }
  release(&log.lock);
    80004348:	0001d517          	auipc	a0,0x1d
    8000434c:	15850513          	addi	a0,a0,344 # 800214a0 <log>
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	93a080e7          	jalr	-1734(ra) # 80000c8a <release>
}
    80004358:	60e2                	ld	ra,24(sp)
    8000435a:	6442                	ld	s0,16(sp)
    8000435c:	64a2                	ld	s1,8(sp)
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004364:	1101                	addi	sp,sp,-32
    80004366:	ec06                	sd	ra,24(sp)
    80004368:	e822                	sd	s0,16(sp)
    8000436a:	e426                	sd	s1,8(sp)
    8000436c:	e04a                	sd	s2,0(sp)
    8000436e:	1000                	addi	s0,sp,32
    80004370:	84aa                	mv	s1,a0
    80004372:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004374:	00004597          	auipc	a1,0x4
    80004378:	33458593          	addi	a1,a1,820 # 800086a8 <syscalls+0x238>
    8000437c:	0521                	addi	a0,a0,8
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	7c8080e7          	jalr	1992(ra) # 80000b46 <initlock>
  lk->name = name;
    80004386:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000438a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000438e:	0204a423          	sw	zero,40(s1)
}
    80004392:	60e2                	ld	ra,24(sp)
    80004394:	6442                	ld	s0,16(sp)
    80004396:	64a2                	ld	s1,8(sp)
    80004398:	6902                	ld	s2,0(sp)
    8000439a:	6105                	addi	sp,sp,32
    8000439c:	8082                	ret

000000008000439e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000439e:	1101                	addi	sp,sp,-32
    800043a0:	ec06                	sd	ra,24(sp)
    800043a2:	e822                	sd	s0,16(sp)
    800043a4:	e426                	sd	s1,8(sp)
    800043a6:	e04a                	sd	s2,0(sp)
    800043a8:	1000                	addi	s0,sp,32
    800043aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ac:	00850913          	addi	s2,a0,8
    800043b0:	854a                	mv	a0,s2
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	824080e7          	jalr	-2012(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800043ba:	409c                	lw	a5,0(s1)
    800043bc:	cb89                	beqz	a5,800043ce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043be:	85ca                	mv	a1,s2
    800043c0:	8526                	mv	a0,s1
    800043c2:	ffffe097          	auipc	ra,0xffffe
    800043c6:	d2e080e7          	jalr	-722(ra) # 800020f0 <sleep>
  while (lk->locked) {
    800043ca:	409c                	lw	a5,0(s1)
    800043cc:	fbed                	bnez	a5,800043be <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043ce:	4785                	li	a5,1
    800043d0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043d2:	ffffd097          	auipc	ra,0xffffd
    800043d6:	610080e7          	jalr	1552(ra) # 800019e2 <myproc>
    800043da:	591c                	lw	a5,48(a0)
    800043dc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043de:	854a                	mv	a0,s2
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	8aa080e7          	jalr	-1878(ra) # 80000c8a <release>
}
    800043e8:	60e2                	ld	ra,24(sp)
    800043ea:	6442                	ld	s0,16(sp)
    800043ec:	64a2                	ld	s1,8(sp)
    800043ee:	6902                	ld	s2,0(sp)
    800043f0:	6105                	addi	sp,sp,32
    800043f2:	8082                	ret

00000000800043f4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043f4:	1101                	addi	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	e426                	sd	s1,8(sp)
    800043fc:	e04a                	sd	s2,0(sp)
    800043fe:	1000                	addi	s0,sp,32
    80004400:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004402:	00850913          	addi	s2,a0,8
    80004406:	854a                	mv	a0,s2
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	7ce080e7          	jalr	1998(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004410:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004414:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffe097          	auipc	ra,0xffffe
    8000441e:	d3a080e7          	jalr	-710(ra) # 80002154 <wakeup>
  release(&lk->lk);
    80004422:	854a                	mv	a0,s2
    80004424:	ffffd097          	auipc	ra,0xffffd
    80004428:	866080e7          	jalr	-1946(ra) # 80000c8a <release>
}
    8000442c:	60e2                	ld	ra,24(sp)
    8000442e:	6442                	ld	s0,16(sp)
    80004430:	64a2                	ld	s1,8(sp)
    80004432:	6902                	ld	s2,0(sp)
    80004434:	6105                	addi	sp,sp,32
    80004436:	8082                	ret

0000000080004438 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004438:	7179                	addi	sp,sp,-48
    8000443a:	f406                	sd	ra,40(sp)
    8000443c:	f022                	sd	s0,32(sp)
    8000443e:	ec26                	sd	s1,24(sp)
    80004440:	e84a                	sd	s2,16(sp)
    80004442:	e44e                	sd	s3,8(sp)
    80004444:	1800                	addi	s0,sp,48
    80004446:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004448:	00850913          	addi	s2,a0,8
    8000444c:	854a                	mv	a0,s2
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	788080e7          	jalr	1928(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004456:	409c                	lw	a5,0(s1)
    80004458:	ef99                	bnez	a5,80004476 <holdingsleep+0x3e>
    8000445a:	4481                	li	s1,0
  release(&lk->lk);
    8000445c:	854a                	mv	a0,s2
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	82c080e7          	jalr	-2004(ra) # 80000c8a <release>
  return r;
}
    80004466:	8526                	mv	a0,s1
    80004468:	70a2                	ld	ra,40(sp)
    8000446a:	7402                	ld	s0,32(sp)
    8000446c:	64e2                	ld	s1,24(sp)
    8000446e:	6942                	ld	s2,16(sp)
    80004470:	69a2                	ld	s3,8(sp)
    80004472:	6145                	addi	sp,sp,48
    80004474:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004476:	0284a983          	lw	s3,40(s1)
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	568080e7          	jalr	1384(ra) # 800019e2 <myproc>
    80004482:	5904                	lw	s1,48(a0)
    80004484:	413484b3          	sub	s1,s1,s3
    80004488:	0014b493          	seqz	s1,s1
    8000448c:	bfc1                	j	8000445c <holdingsleep+0x24>

000000008000448e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000448e:	1141                	addi	sp,sp,-16
    80004490:	e406                	sd	ra,8(sp)
    80004492:	e022                	sd	s0,0(sp)
    80004494:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004496:	00004597          	auipc	a1,0x4
    8000449a:	22258593          	addi	a1,a1,546 # 800086b8 <syscalls+0x248>
    8000449e:	0001d517          	auipc	a0,0x1d
    800044a2:	14a50513          	addi	a0,a0,330 # 800215e8 <ftable>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	6a0080e7          	jalr	1696(ra) # 80000b46 <initlock>
}
    800044ae:	60a2                	ld	ra,8(sp)
    800044b0:	6402                	ld	s0,0(sp)
    800044b2:	0141                	addi	sp,sp,16
    800044b4:	8082                	ret

00000000800044b6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044b6:	1101                	addi	sp,sp,-32
    800044b8:	ec06                	sd	ra,24(sp)
    800044ba:	e822                	sd	s0,16(sp)
    800044bc:	e426                	sd	s1,8(sp)
    800044be:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044c0:	0001d517          	auipc	a0,0x1d
    800044c4:	12850513          	addi	a0,a0,296 # 800215e8 <ftable>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	70e080e7          	jalr	1806(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044d0:	0001d497          	auipc	s1,0x1d
    800044d4:	13048493          	addi	s1,s1,304 # 80021600 <ftable+0x18>
    800044d8:	0001e717          	auipc	a4,0x1e
    800044dc:	0c870713          	addi	a4,a4,200 # 800225a0 <disk>
    if(f->ref == 0){
    800044e0:	40dc                	lw	a5,4(s1)
    800044e2:	cf99                	beqz	a5,80004500 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044e4:	02848493          	addi	s1,s1,40
    800044e8:	fee49ce3          	bne	s1,a4,800044e0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044ec:	0001d517          	auipc	a0,0x1d
    800044f0:	0fc50513          	addi	a0,a0,252 # 800215e8 <ftable>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	796080e7          	jalr	1942(ra) # 80000c8a <release>
  return 0;
    800044fc:	4481                	li	s1,0
    800044fe:	a819                	j	80004514 <filealloc+0x5e>
      f->ref = 1;
    80004500:	4785                	li	a5,1
    80004502:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004504:	0001d517          	auipc	a0,0x1d
    80004508:	0e450513          	addi	a0,a0,228 # 800215e8 <ftable>
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	77e080e7          	jalr	1918(ra) # 80000c8a <release>
}
    80004514:	8526                	mv	a0,s1
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004520:	1101                	addi	sp,sp,-32
    80004522:	ec06                	sd	ra,24(sp)
    80004524:	e822                	sd	s0,16(sp)
    80004526:	e426                	sd	s1,8(sp)
    80004528:	1000                	addi	s0,sp,32
    8000452a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000452c:	0001d517          	auipc	a0,0x1d
    80004530:	0bc50513          	addi	a0,a0,188 # 800215e8 <ftable>
    80004534:	ffffc097          	auipc	ra,0xffffc
    80004538:	6a2080e7          	jalr	1698(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000453c:	40dc                	lw	a5,4(s1)
    8000453e:	02f05263          	blez	a5,80004562 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004542:	2785                	addiw	a5,a5,1
    80004544:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004546:	0001d517          	auipc	a0,0x1d
    8000454a:	0a250513          	addi	a0,a0,162 # 800215e8 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	73c080e7          	jalr	1852(ra) # 80000c8a <release>
  return f;
}
    80004556:	8526                	mv	a0,s1
    80004558:	60e2                	ld	ra,24(sp)
    8000455a:	6442                	ld	s0,16(sp)
    8000455c:	64a2                	ld	s1,8(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret
    panic("filedup");
    80004562:	00004517          	auipc	a0,0x4
    80004566:	15e50513          	addi	a0,a0,350 # 800086c0 <syscalls+0x250>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>

0000000080004572 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004572:	7139                	addi	sp,sp,-64
    80004574:	fc06                	sd	ra,56(sp)
    80004576:	f822                	sd	s0,48(sp)
    80004578:	f426                	sd	s1,40(sp)
    8000457a:	f04a                	sd	s2,32(sp)
    8000457c:	ec4e                	sd	s3,24(sp)
    8000457e:	e852                	sd	s4,16(sp)
    80004580:	e456                	sd	s5,8(sp)
    80004582:	0080                	addi	s0,sp,64
    80004584:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	06250513          	addi	a0,a0,98 # 800215e8 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	648080e7          	jalr	1608(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004596:	40dc                	lw	a5,4(s1)
    80004598:	06f05163          	blez	a5,800045fa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000459c:	37fd                	addiw	a5,a5,-1
    8000459e:	0007871b          	sext.w	a4,a5
    800045a2:	c0dc                	sw	a5,4(s1)
    800045a4:	06e04363          	bgtz	a4,8000460a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045a8:	0004a903          	lw	s2,0(s1)
    800045ac:	0094ca83          	lbu	s5,9(s1)
    800045b0:	0104ba03          	ld	s4,16(s1)
    800045b4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045b8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045bc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045c0:	0001d517          	auipc	a0,0x1d
    800045c4:	02850513          	addi	a0,a0,40 # 800215e8 <ftable>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	6c2080e7          	jalr	1730(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800045d0:	4785                	li	a5,1
    800045d2:	04f90d63          	beq	s2,a5,8000462c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045d6:	3979                	addiw	s2,s2,-2
    800045d8:	4785                	li	a5,1
    800045da:	0527e063          	bltu	a5,s2,8000461a <fileclose+0xa8>
    begin_op();
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	ac8080e7          	jalr	-1336(ra) # 800040a6 <begin_op>
    iput(ff.ip);
    800045e6:	854e                	mv	a0,s3
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	2b6080e7          	jalr	694(ra) # 8000389e <iput>
    end_op();
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	b36080e7          	jalr	-1226(ra) # 80004126 <end_op>
    800045f8:	a00d                	j	8000461a <fileclose+0xa8>
    panic("fileclose");
    800045fa:	00004517          	auipc	a0,0x4
    800045fe:	0ce50513          	addi	a0,a0,206 # 800086c8 <syscalls+0x258>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	f3c080e7          	jalr	-196(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	fde50513          	addi	a0,a0,-34 # 800215e8 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	678080e7          	jalr	1656(ra) # 80000c8a <release>
  }
}
    8000461a:	70e2                	ld	ra,56(sp)
    8000461c:	7442                	ld	s0,48(sp)
    8000461e:	74a2                	ld	s1,40(sp)
    80004620:	7902                	ld	s2,32(sp)
    80004622:	69e2                	ld	s3,24(sp)
    80004624:	6a42                	ld	s4,16(sp)
    80004626:	6aa2                	ld	s5,8(sp)
    80004628:	6121                	addi	sp,sp,64
    8000462a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000462c:	85d6                	mv	a1,s5
    8000462e:	8552                	mv	a0,s4
    80004630:	00000097          	auipc	ra,0x0
    80004634:	34c080e7          	jalr	844(ra) # 8000497c <pipeclose>
    80004638:	b7cd                	j	8000461a <fileclose+0xa8>

000000008000463a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000463a:	715d                	addi	sp,sp,-80
    8000463c:	e486                	sd	ra,72(sp)
    8000463e:	e0a2                	sd	s0,64(sp)
    80004640:	fc26                	sd	s1,56(sp)
    80004642:	f84a                	sd	s2,48(sp)
    80004644:	f44e                	sd	s3,40(sp)
    80004646:	0880                	addi	s0,sp,80
    80004648:	84aa                	mv	s1,a0
    8000464a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000464c:	ffffd097          	auipc	ra,0xffffd
    80004650:	396080e7          	jalr	918(ra) # 800019e2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004654:	409c                	lw	a5,0(s1)
    80004656:	37f9                	addiw	a5,a5,-2
    80004658:	4705                	li	a4,1
    8000465a:	04f76763          	bltu	a4,a5,800046a8 <filestat+0x6e>
    8000465e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004660:	6c88                	ld	a0,24(s1)
    80004662:	fffff097          	auipc	ra,0xfffff
    80004666:	082080e7          	jalr	130(ra) # 800036e4 <ilock>
    stati(f->ip, &st);
    8000466a:	fb840593          	addi	a1,s0,-72
    8000466e:	6c88                	ld	a0,24(s1)
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	2fe080e7          	jalr	766(ra) # 8000396e <stati>
    iunlock(f->ip);
    80004678:	6c88                	ld	a0,24(s1)
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	12c080e7          	jalr	300(ra) # 800037a6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004682:	46e1                	li	a3,24
    80004684:	fb840613          	addi	a2,s0,-72
    80004688:	85ce                	mv	a1,s3
    8000468a:	05093503          	ld	a0,80(s2)
    8000468e:	ffffd097          	auipc	ra,0xffffd
    80004692:	010080e7          	jalr	16(ra) # 8000169e <copyout>
    80004696:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000469a:	60a6                	ld	ra,72(sp)
    8000469c:	6406                	ld	s0,64(sp)
    8000469e:	74e2                	ld	s1,56(sp)
    800046a0:	7942                	ld	s2,48(sp)
    800046a2:	79a2                	ld	s3,40(sp)
    800046a4:	6161                	addi	sp,sp,80
    800046a6:	8082                	ret
  return -1;
    800046a8:	557d                	li	a0,-1
    800046aa:	bfc5                	j	8000469a <filestat+0x60>

00000000800046ac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046ac:	7179                	addi	sp,sp,-48
    800046ae:	f406                	sd	ra,40(sp)
    800046b0:	f022                	sd	s0,32(sp)
    800046b2:	ec26                	sd	s1,24(sp)
    800046b4:	e84a                	sd	s2,16(sp)
    800046b6:	e44e                	sd	s3,8(sp)
    800046b8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046ba:	00854783          	lbu	a5,8(a0)
    800046be:	c3d5                	beqz	a5,80004762 <fileread+0xb6>
    800046c0:	84aa                	mv	s1,a0
    800046c2:	89ae                	mv	s3,a1
    800046c4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046c6:	411c                	lw	a5,0(a0)
    800046c8:	4705                	li	a4,1
    800046ca:	04e78963          	beq	a5,a4,8000471c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046ce:	470d                	li	a4,3
    800046d0:	04e78d63          	beq	a5,a4,8000472a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046d4:	4709                	li	a4,2
    800046d6:	06e79e63          	bne	a5,a4,80004752 <fileread+0xa6>
    ilock(f->ip);
    800046da:	6d08                	ld	a0,24(a0)
    800046dc:	fffff097          	auipc	ra,0xfffff
    800046e0:	008080e7          	jalr	8(ra) # 800036e4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046e4:	874a                	mv	a4,s2
    800046e6:	5094                	lw	a3,32(s1)
    800046e8:	864e                	mv	a2,s3
    800046ea:	4585                	li	a1,1
    800046ec:	6c88                	ld	a0,24(s1)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	2aa080e7          	jalr	682(ra) # 80003998 <readi>
    800046f6:	892a                	mv	s2,a0
    800046f8:	00a05563          	blez	a0,80004702 <fileread+0x56>
      f->off += r;
    800046fc:	509c                	lw	a5,32(s1)
    800046fe:	9fa9                	addw	a5,a5,a0
    80004700:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004702:	6c88                	ld	a0,24(s1)
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	0a2080e7          	jalr	162(ra) # 800037a6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000470c:	854a                	mv	a0,s2
    8000470e:	70a2                	ld	ra,40(sp)
    80004710:	7402                	ld	s0,32(sp)
    80004712:	64e2                	ld	s1,24(sp)
    80004714:	6942                	ld	s2,16(sp)
    80004716:	69a2                	ld	s3,8(sp)
    80004718:	6145                	addi	sp,sp,48
    8000471a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000471c:	6908                	ld	a0,16(a0)
    8000471e:	00000097          	auipc	ra,0x0
    80004722:	3c6080e7          	jalr	966(ra) # 80004ae4 <piperead>
    80004726:	892a                	mv	s2,a0
    80004728:	b7d5                	j	8000470c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000472a:	02451783          	lh	a5,36(a0)
    8000472e:	03079693          	slli	a3,a5,0x30
    80004732:	92c1                	srli	a3,a3,0x30
    80004734:	4725                	li	a4,9
    80004736:	02d76863          	bltu	a4,a3,80004766 <fileread+0xba>
    8000473a:	0792                	slli	a5,a5,0x4
    8000473c:	0001d717          	auipc	a4,0x1d
    80004740:	e0c70713          	addi	a4,a4,-500 # 80021548 <devsw>
    80004744:	97ba                	add	a5,a5,a4
    80004746:	639c                	ld	a5,0(a5)
    80004748:	c38d                	beqz	a5,8000476a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000474a:	4505                	li	a0,1
    8000474c:	9782                	jalr	a5
    8000474e:	892a                	mv	s2,a0
    80004750:	bf75                	j	8000470c <fileread+0x60>
    panic("fileread");
    80004752:	00004517          	auipc	a0,0x4
    80004756:	f8650513          	addi	a0,a0,-122 # 800086d8 <syscalls+0x268>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	de4080e7          	jalr	-540(ra) # 8000053e <panic>
    return -1;
    80004762:	597d                	li	s2,-1
    80004764:	b765                	j	8000470c <fileread+0x60>
      return -1;
    80004766:	597d                	li	s2,-1
    80004768:	b755                	j	8000470c <fileread+0x60>
    8000476a:	597d                	li	s2,-1
    8000476c:	b745                	j	8000470c <fileread+0x60>

000000008000476e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000476e:	715d                	addi	sp,sp,-80
    80004770:	e486                	sd	ra,72(sp)
    80004772:	e0a2                	sd	s0,64(sp)
    80004774:	fc26                	sd	s1,56(sp)
    80004776:	f84a                	sd	s2,48(sp)
    80004778:	f44e                	sd	s3,40(sp)
    8000477a:	f052                	sd	s4,32(sp)
    8000477c:	ec56                	sd	s5,24(sp)
    8000477e:	e85a                	sd	s6,16(sp)
    80004780:	e45e                	sd	s7,8(sp)
    80004782:	e062                	sd	s8,0(sp)
    80004784:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004786:	00954783          	lbu	a5,9(a0)
    8000478a:	10078663          	beqz	a5,80004896 <filewrite+0x128>
    8000478e:	892a                	mv	s2,a0
    80004790:	8aae                	mv	s5,a1
    80004792:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004794:	411c                	lw	a5,0(a0)
    80004796:	4705                	li	a4,1
    80004798:	02e78263          	beq	a5,a4,800047bc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000479c:	470d                	li	a4,3
    8000479e:	02e78663          	beq	a5,a4,800047ca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a2:	4709                	li	a4,2
    800047a4:	0ee79163          	bne	a5,a4,80004886 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047a8:	0ac05d63          	blez	a2,80004862 <filewrite+0xf4>
    int i = 0;
    800047ac:	4981                	li	s3,0
    800047ae:	6b05                	lui	s6,0x1
    800047b0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047b4:	6b85                	lui	s7,0x1
    800047b6:	c00b8b9b          	addiw	s7,s7,-1024
    800047ba:	a861                	j	80004852 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047bc:	6908                	ld	a0,16(a0)
    800047be:	00000097          	auipc	ra,0x0
    800047c2:	22e080e7          	jalr	558(ra) # 800049ec <pipewrite>
    800047c6:	8a2a                	mv	s4,a0
    800047c8:	a045                	j	80004868 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047ca:	02451783          	lh	a5,36(a0)
    800047ce:	03079693          	slli	a3,a5,0x30
    800047d2:	92c1                	srli	a3,a3,0x30
    800047d4:	4725                	li	a4,9
    800047d6:	0cd76263          	bltu	a4,a3,8000489a <filewrite+0x12c>
    800047da:	0792                	slli	a5,a5,0x4
    800047dc:	0001d717          	auipc	a4,0x1d
    800047e0:	d6c70713          	addi	a4,a4,-660 # 80021548 <devsw>
    800047e4:	97ba                	add	a5,a5,a4
    800047e6:	679c                	ld	a5,8(a5)
    800047e8:	cbdd                	beqz	a5,8000489e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047ea:	4505                	li	a0,1
    800047ec:	9782                	jalr	a5
    800047ee:	8a2a                	mv	s4,a0
    800047f0:	a8a5                	j	80004868 <filewrite+0xfa>
    800047f2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	8b0080e7          	jalr	-1872(ra) # 800040a6 <begin_op>
      ilock(f->ip);
    800047fe:	01893503          	ld	a0,24(s2)
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	ee2080e7          	jalr	-286(ra) # 800036e4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000480a:	8762                	mv	a4,s8
    8000480c:	02092683          	lw	a3,32(s2)
    80004810:	01598633          	add	a2,s3,s5
    80004814:	4585                	li	a1,1
    80004816:	01893503          	ld	a0,24(s2)
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	276080e7          	jalr	630(ra) # 80003a90 <writei>
    80004822:	84aa                	mv	s1,a0
    80004824:	00a05763          	blez	a0,80004832 <filewrite+0xc4>
        f->off += r;
    80004828:	02092783          	lw	a5,32(s2)
    8000482c:	9fa9                	addw	a5,a5,a0
    8000482e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004832:	01893503          	ld	a0,24(s2)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	f70080e7          	jalr	-144(ra) # 800037a6 <iunlock>
      end_op();
    8000483e:	00000097          	auipc	ra,0x0
    80004842:	8e8080e7          	jalr	-1816(ra) # 80004126 <end_op>

      if(r != n1){
    80004846:	009c1f63          	bne	s8,s1,80004864 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000484a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000484e:	0149db63          	bge	s3,s4,80004864 <filewrite+0xf6>
      int n1 = n - i;
    80004852:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004856:	84be                	mv	s1,a5
    80004858:	2781                	sext.w	a5,a5
    8000485a:	f8fb5ce3          	bge	s6,a5,800047f2 <filewrite+0x84>
    8000485e:	84de                	mv	s1,s7
    80004860:	bf49                	j	800047f2 <filewrite+0x84>
    int i = 0;
    80004862:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004864:	013a1f63          	bne	s4,s3,80004882 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004868:	8552                	mv	a0,s4
    8000486a:	60a6                	ld	ra,72(sp)
    8000486c:	6406                	ld	s0,64(sp)
    8000486e:	74e2                	ld	s1,56(sp)
    80004870:	7942                	ld	s2,48(sp)
    80004872:	79a2                	ld	s3,40(sp)
    80004874:	7a02                	ld	s4,32(sp)
    80004876:	6ae2                	ld	s5,24(sp)
    80004878:	6b42                	ld	s6,16(sp)
    8000487a:	6ba2                	ld	s7,8(sp)
    8000487c:	6c02                	ld	s8,0(sp)
    8000487e:	6161                	addi	sp,sp,80
    80004880:	8082                	ret
    ret = (i == n ? n : -1);
    80004882:	5a7d                	li	s4,-1
    80004884:	b7d5                	j	80004868 <filewrite+0xfa>
    panic("filewrite");
    80004886:	00004517          	auipc	a0,0x4
    8000488a:	e6250513          	addi	a0,a0,-414 # 800086e8 <syscalls+0x278>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	cb0080e7          	jalr	-848(ra) # 8000053e <panic>
    return -1;
    80004896:	5a7d                	li	s4,-1
    80004898:	bfc1                	j	80004868 <filewrite+0xfa>
      return -1;
    8000489a:	5a7d                	li	s4,-1
    8000489c:	b7f1                	j	80004868 <filewrite+0xfa>
    8000489e:	5a7d                	li	s4,-1
    800048a0:	b7e1                	j	80004868 <filewrite+0xfa>

00000000800048a2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048a2:	7179                	addi	sp,sp,-48
    800048a4:	f406                	sd	ra,40(sp)
    800048a6:	f022                	sd	s0,32(sp)
    800048a8:	ec26                	sd	s1,24(sp)
    800048aa:	e84a                	sd	s2,16(sp)
    800048ac:	e44e                	sd	s3,8(sp)
    800048ae:	e052                	sd	s4,0(sp)
    800048b0:	1800                	addi	s0,sp,48
    800048b2:	84aa                	mv	s1,a0
    800048b4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048b6:	0005b023          	sd	zero,0(a1)
    800048ba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	bf8080e7          	jalr	-1032(ra) # 800044b6 <filealloc>
    800048c6:	e088                	sd	a0,0(s1)
    800048c8:	c551                	beqz	a0,80004954 <pipealloc+0xb2>
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	bec080e7          	jalr	-1044(ra) # 800044b6 <filealloc>
    800048d2:	00aa3023          	sd	a0,0(s4)
    800048d6:	c92d                	beqz	a0,80004948 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048d8:	ffffc097          	auipc	ra,0xffffc
    800048dc:	20e080e7          	jalr	526(ra) # 80000ae6 <kalloc>
    800048e0:	892a                	mv	s2,a0
    800048e2:	c125                	beqz	a0,80004942 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048e4:	4985                	li	s3,1
    800048e6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048ea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048ee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048f2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048f6:	00004597          	auipc	a1,0x4
    800048fa:	e0258593          	addi	a1,a1,-510 # 800086f8 <syscalls+0x288>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	248080e7          	jalr	584(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004906:	609c                	ld	a5,0(s1)
    80004908:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000490c:	609c                	ld	a5,0(s1)
    8000490e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004912:	609c                	ld	a5,0(s1)
    80004914:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004918:	609c                	ld	a5,0(s1)
    8000491a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000491e:	000a3783          	ld	a5,0(s4)
    80004922:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004926:	000a3783          	ld	a5,0(s4)
    8000492a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000492e:	000a3783          	ld	a5,0(s4)
    80004932:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004936:	000a3783          	ld	a5,0(s4)
    8000493a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000493e:	4501                	li	a0,0
    80004940:	a025                	j	80004968 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004942:	6088                	ld	a0,0(s1)
    80004944:	e501                	bnez	a0,8000494c <pipealloc+0xaa>
    80004946:	a039                	j	80004954 <pipealloc+0xb2>
    80004948:	6088                	ld	a0,0(s1)
    8000494a:	c51d                	beqz	a0,80004978 <pipealloc+0xd6>
    fileclose(*f0);
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	c26080e7          	jalr	-986(ra) # 80004572 <fileclose>
  if(*f1)
    80004954:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004958:	557d                	li	a0,-1
  if(*f1)
    8000495a:	c799                	beqz	a5,80004968 <pipealloc+0xc6>
    fileclose(*f1);
    8000495c:	853e                	mv	a0,a5
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	c14080e7          	jalr	-1004(ra) # 80004572 <fileclose>
  return -1;
    80004966:	557d                	li	a0,-1
}
    80004968:	70a2                	ld	ra,40(sp)
    8000496a:	7402                	ld	s0,32(sp)
    8000496c:	64e2                	ld	s1,24(sp)
    8000496e:	6942                	ld	s2,16(sp)
    80004970:	69a2                	ld	s3,8(sp)
    80004972:	6a02                	ld	s4,0(sp)
    80004974:	6145                	addi	sp,sp,48
    80004976:	8082                	ret
  return -1;
    80004978:	557d                	li	a0,-1
    8000497a:	b7fd                	j	80004968 <pipealloc+0xc6>

000000008000497c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000497c:	1101                	addi	sp,sp,-32
    8000497e:	ec06                	sd	ra,24(sp)
    80004980:	e822                	sd	s0,16(sp)
    80004982:	e426                	sd	s1,8(sp)
    80004984:	e04a                	sd	s2,0(sp)
    80004986:	1000                	addi	s0,sp,32
    80004988:	84aa                	mv	s1,a0
    8000498a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	24a080e7          	jalr	586(ra) # 80000bd6 <acquire>
  if(writable){
    80004994:	02090d63          	beqz	s2,800049ce <pipeclose+0x52>
    pi->writeopen = 0;
    80004998:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000499c:	21848513          	addi	a0,s1,536
    800049a0:	ffffd097          	auipc	ra,0xffffd
    800049a4:	7b4080e7          	jalr	1972(ra) # 80002154 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049a8:	2204b783          	ld	a5,544(s1)
    800049ac:	eb95                	bnez	a5,800049e0 <pipeclose+0x64>
    release(&pi->lock);
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	2da080e7          	jalr	730(ra) # 80000c8a <release>
    kfree((char*)pi);
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	030080e7          	jalr	48(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800049c2:	60e2                	ld	ra,24(sp)
    800049c4:	6442                	ld	s0,16(sp)
    800049c6:	64a2                	ld	s1,8(sp)
    800049c8:	6902                	ld	s2,0(sp)
    800049ca:	6105                	addi	sp,sp,32
    800049cc:	8082                	ret
    pi->readopen = 0;
    800049ce:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049d2:	21c48513          	addi	a0,s1,540
    800049d6:	ffffd097          	auipc	ra,0xffffd
    800049da:	77e080e7          	jalr	1918(ra) # 80002154 <wakeup>
    800049de:	b7e9                	j	800049a8 <pipeclose+0x2c>
    release(&pi->lock);
    800049e0:	8526                	mv	a0,s1
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	2a8080e7          	jalr	680(ra) # 80000c8a <release>
}
    800049ea:	bfe1                	j	800049c2 <pipeclose+0x46>

00000000800049ec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049ec:	711d                	addi	sp,sp,-96
    800049ee:	ec86                	sd	ra,88(sp)
    800049f0:	e8a2                	sd	s0,80(sp)
    800049f2:	e4a6                	sd	s1,72(sp)
    800049f4:	e0ca                	sd	s2,64(sp)
    800049f6:	fc4e                	sd	s3,56(sp)
    800049f8:	f852                	sd	s4,48(sp)
    800049fa:	f456                	sd	s5,40(sp)
    800049fc:	f05a                	sd	s6,32(sp)
    800049fe:	ec5e                	sd	s7,24(sp)
    80004a00:	e862                	sd	s8,16(sp)
    80004a02:	1080                	addi	s0,sp,96
    80004a04:	84aa                	mv	s1,a0
    80004a06:	8aae                	mv	s5,a1
    80004a08:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a0a:	ffffd097          	auipc	ra,0xffffd
    80004a0e:	fd8080e7          	jalr	-40(ra) # 800019e2 <myproc>
    80004a12:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	1c0080e7          	jalr	448(ra) # 80000bd6 <acquire>
  while(i < n){
    80004a1e:	0b405663          	blez	s4,80004aca <pipewrite+0xde>
  int i = 0;
    80004a22:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a24:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a26:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a2a:	21c48b93          	addi	s7,s1,540
    80004a2e:	a089                	j	80004a70 <pipewrite+0x84>
      release(&pi->lock);
    80004a30:	8526                	mv	a0,s1
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	258080e7          	jalr	600(ra) # 80000c8a <release>
      return -1;
    80004a3a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a3c:	854a                	mv	a0,s2
    80004a3e:	60e6                	ld	ra,88(sp)
    80004a40:	6446                	ld	s0,80(sp)
    80004a42:	64a6                	ld	s1,72(sp)
    80004a44:	6906                	ld	s2,64(sp)
    80004a46:	79e2                	ld	s3,56(sp)
    80004a48:	7a42                	ld	s4,48(sp)
    80004a4a:	7aa2                	ld	s5,40(sp)
    80004a4c:	7b02                	ld	s6,32(sp)
    80004a4e:	6be2                	ld	s7,24(sp)
    80004a50:	6c42                	ld	s8,16(sp)
    80004a52:	6125                	addi	sp,sp,96
    80004a54:	8082                	ret
      wakeup(&pi->nread);
    80004a56:	8562                	mv	a0,s8
    80004a58:	ffffd097          	auipc	ra,0xffffd
    80004a5c:	6fc080e7          	jalr	1788(ra) # 80002154 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a60:	85a6                	mv	a1,s1
    80004a62:	855e                	mv	a0,s7
    80004a64:	ffffd097          	auipc	ra,0xffffd
    80004a68:	68c080e7          	jalr	1676(ra) # 800020f0 <sleep>
  while(i < n){
    80004a6c:	07495063          	bge	s2,s4,80004acc <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a70:	2204a783          	lw	a5,544(s1)
    80004a74:	dfd5                	beqz	a5,80004a30 <pipewrite+0x44>
    80004a76:	854e                	mv	a0,s3
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	920080e7          	jalr	-1760(ra) # 80002398 <killed>
    80004a80:	f945                	bnez	a0,80004a30 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a82:	2184a783          	lw	a5,536(s1)
    80004a86:	21c4a703          	lw	a4,540(s1)
    80004a8a:	2007879b          	addiw	a5,a5,512
    80004a8e:	fcf704e3          	beq	a4,a5,80004a56 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a92:	4685                	li	a3,1
    80004a94:	01590633          	add	a2,s2,s5
    80004a98:	faf40593          	addi	a1,s0,-81
    80004a9c:	0509b503          	ld	a0,80(s3)
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	c8a080e7          	jalr	-886(ra) # 8000172a <copyin>
    80004aa8:	03650263          	beq	a0,s6,80004acc <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aac:	21c4a783          	lw	a5,540(s1)
    80004ab0:	0017871b          	addiw	a4,a5,1
    80004ab4:	20e4ae23          	sw	a4,540(s1)
    80004ab8:	1ff7f793          	andi	a5,a5,511
    80004abc:	97a6                	add	a5,a5,s1
    80004abe:	faf44703          	lbu	a4,-81(s0)
    80004ac2:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ac6:	2905                	addiw	s2,s2,1
    80004ac8:	b755                	j	80004a6c <pipewrite+0x80>
  int i = 0;
    80004aca:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004acc:	21848513          	addi	a0,s1,536
    80004ad0:	ffffd097          	auipc	ra,0xffffd
    80004ad4:	684080e7          	jalr	1668(ra) # 80002154 <wakeup>
  release(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1b0080e7          	jalr	432(ra) # 80000c8a <release>
  return i;
    80004ae2:	bfa9                	j	80004a3c <pipewrite+0x50>

0000000080004ae4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ae4:	715d                	addi	sp,sp,-80
    80004ae6:	e486                	sd	ra,72(sp)
    80004ae8:	e0a2                	sd	s0,64(sp)
    80004aea:	fc26                	sd	s1,56(sp)
    80004aec:	f84a                	sd	s2,48(sp)
    80004aee:	f44e                	sd	s3,40(sp)
    80004af0:	f052                	sd	s4,32(sp)
    80004af2:	ec56                	sd	s5,24(sp)
    80004af4:	e85a                	sd	s6,16(sp)
    80004af6:	0880                	addi	s0,sp,80
    80004af8:	84aa                	mv	s1,a0
    80004afa:	892e                	mv	s2,a1
    80004afc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004afe:	ffffd097          	auipc	ra,0xffffd
    80004b02:	ee4080e7          	jalr	-284(ra) # 800019e2 <myproc>
    80004b06:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b08:	8526                	mv	a0,s1
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	0cc080e7          	jalr	204(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b12:	2184a703          	lw	a4,536(s1)
    80004b16:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1e:	02f71763          	bne	a4,a5,80004b4c <piperead+0x68>
    80004b22:	2244a783          	lw	a5,548(s1)
    80004b26:	c39d                	beqz	a5,80004b4c <piperead+0x68>
    if(killed(pr)){
    80004b28:	8552                	mv	a0,s4
    80004b2a:	ffffe097          	auipc	ra,0xffffe
    80004b2e:	86e080e7          	jalr	-1938(ra) # 80002398 <killed>
    80004b32:	e941                	bnez	a0,80004bc2 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b34:	85a6                	mv	a1,s1
    80004b36:	854e                	mv	a0,s3
    80004b38:	ffffd097          	auipc	ra,0xffffd
    80004b3c:	5b8080e7          	jalr	1464(ra) # 800020f0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b40:	2184a703          	lw	a4,536(s1)
    80004b44:	21c4a783          	lw	a5,540(s1)
    80004b48:	fcf70de3          	beq	a4,a5,80004b22 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b4c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b4e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b50:	05505363          	blez	s5,80004b96 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004b54:	2184a783          	lw	a5,536(s1)
    80004b58:	21c4a703          	lw	a4,540(s1)
    80004b5c:	02f70d63          	beq	a4,a5,80004b96 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b60:	0017871b          	addiw	a4,a5,1
    80004b64:	20e4ac23          	sw	a4,536(s1)
    80004b68:	1ff7f793          	andi	a5,a5,511
    80004b6c:	97a6                	add	a5,a5,s1
    80004b6e:	0187c783          	lbu	a5,24(a5)
    80004b72:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b76:	4685                	li	a3,1
    80004b78:	fbf40613          	addi	a2,s0,-65
    80004b7c:	85ca                	mv	a1,s2
    80004b7e:	050a3503          	ld	a0,80(s4)
    80004b82:	ffffd097          	auipc	ra,0xffffd
    80004b86:	b1c080e7          	jalr	-1252(ra) # 8000169e <copyout>
    80004b8a:	01650663          	beq	a0,s6,80004b96 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b8e:	2985                	addiw	s3,s3,1
    80004b90:	0905                	addi	s2,s2,1
    80004b92:	fd3a91e3          	bne	s5,s3,80004b54 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b96:	21c48513          	addi	a0,s1,540
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	5ba080e7          	jalr	1466(ra) # 80002154 <wakeup>
  release(&pi->lock);
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	0e6080e7          	jalr	230(ra) # 80000c8a <release>
  return i;
}
    80004bac:	854e                	mv	a0,s3
    80004bae:	60a6                	ld	ra,72(sp)
    80004bb0:	6406                	ld	s0,64(sp)
    80004bb2:	74e2                	ld	s1,56(sp)
    80004bb4:	7942                	ld	s2,48(sp)
    80004bb6:	79a2                	ld	s3,40(sp)
    80004bb8:	7a02                	ld	s4,32(sp)
    80004bba:	6ae2                	ld	s5,24(sp)
    80004bbc:	6b42                	ld	s6,16(sp)
    80004bbe:	6161                	addi	sp,sp,80
    80004bc0:	8082                	ret
      release(&pi->lock);
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	0c6080e7          	jalr	198(ra) # 80000c8a <release>
      return -1;
    80004bcc:	59fd                	li	s3,-1
    80004bce:	bff9                	j	80004bac <piperead+0xc8>

0000000080004bd0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bd0:	1141                	addi	sp,sp,-16
    80004bd2:	e422                	sd	s0,8(sp)
    80004bd4:	0800                	addi	s0,sp,16
    80004bd6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bd8:	8905                	andi	a0,a0,1
    80004bda:	c111                	beqz	a0,80004bde <flags2perm+0xe>
      perm = PTE_X;
    80004bdc:	4521                	li	a0,8
    if(flags & 0x2)
    80004bde:	8b89                	andi	a5,a5,2
    80004be0:	c399                	beqz	a5,80004be6 <flags2perm+0x16>
      perm |= PTE_W;
    80004be2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004be6:	6422                	ld	s0,8(sp)
    80004be8:	0141                	addi	sp,sp,16
    80004bea:	8082                	ret

0000000080004bec <exec>:

int
exec(char *path, char **argv)
{
    80004bec:	de010113          	addi	sp,sp,-544
    80004bf0:	20113c23          	sd	ra,536(sp)
    80004bf4:	20813823          	sd	s0,528(sp)
    80004bf8:	20913423          	sd	s1,520(sp)
    80004bfc:	21213023          	sd	s2,512(sp)
    80004c00:	ffce                	sd	s3,504(sp)
    80004c02:	fbd2                	sd	s4,496(sp)
    80004c04:	f7d6                	sd	s5,488(sp)
    80004c06:	f3da                	sd	s6,480(sp)
    80004c08:	efde                	sd	s7,472(sp)
    80004c0a:	ebe2                	sd	s8,464(sp)
    80004c0c:	e7e6                	sd	s9,456(sp)
    80004c0e:	e3ea                	sd	s10,448(sp)
    80004c10:	ff6e                	sd	s11,440(sp)
    80004c12:	1400                	addi	s0,sp,544
    80004c14:	892a                	mv	s2,a0
    80004c16:	dea43423          	sd	a0,-536(s0)
    80004c1a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	dc4080e7          	jalr	-572(ra) # 800019e2 <myproc>
    80004c26:	84aa                	mv	s1,a0

  begin_op();
    80004c28:	fffff097          	auipc	ra,0xfffff
    80004c2c:	47e080e7          	jalr	1150(ra) # 800040a6 <begin_op>

  if((ip = namei(path)) == 0){
    80004c30:	854a                	mv	a0,s2
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	258080e7          	jalr	600(ra) # 80003e8a <namei>
    80004c3a:	c93d                	beqz	a0,80004cb0 <exec+0xc4>
    80004c3c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	aa6080e7          	jalr	-1370(ra) # 800036e4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c46:	04000713          	li	a4,64
    80004c4a:	4681                	li	a3,0
    80004c4c:	e5040613          	addi	a2,s0,-432
    80004c50:	4581                	li	a1,0
    80004c52:	8556                	mv	a0,s5
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	d44080e7          	jalr	-700(ra) # 80003998 <readi>
    80004c5c:	04000793          	li	a5,64
    80004c60:	00f51a63          	bne	a0,a5,80004c74 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c64:	e5042703          	lw	a4,-432(s0)
    80004c68:	464c47b7          	lui	a5,0x464c4
    80004c6c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c70:	04f70663          	beq	a4,a5,80004cbc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c74:	8556                	mv	a0,s5
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	cd0080e7          	jalr	-816(ra) # 80003946 <iunlockput>
    end_op();
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	4a8080e7          	jalr	1192(ra) # 80004126 <end_op>
  }
  return -1;
    80004c86:	557d                	li	a0,-1
}
    80004c88:	21813083          	ld	ra,536(sp)
    80004c8c:	21013403          	ld	s0,528(sp)
    80004c90:	20813483          	ld	s1,520(sp)
    80004c94:	20013903          	ld	s2,512(sp)
    80004c98:	79fe                	ld	s3,504(sp)
    80004c9a:	7a5e                	ld	s4,496(sp)
    80004c9c:	7abe                	ld	s5,488(sp)
    80004c9e:	7b1e                	ld	s6,480(sp)
    80004ca0:	6bfe                	ld	s7,472(sp)
    80004ca2:	6c5e                	ld	s8,464(sp)
    80004ca4:	6cbe                	ld	s9,456(sp)
    80004ca6:	6d1e                	ld	s10,448(sp)
    80004ca8:	7dfa                	ld	s11,440(sp)
    80004caa:	22010113          	addi	sp,sp,544
    80004cae:	8082                	ret
    end_op();
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	476080e7          	jalr	1142(ra) # 80004126 <end_op>
    return -1;
    80004cb8:	557d                	li	a0,-1
    80004cba:	b7f9                	j	80004c88 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	de8080e7          	jalr	-536(ra) # 80001aa6 <proc_pagetable>
    80004cc6:	8b2a                	mv	s6,a0
    80004cc8:	d555                	beqz	a0,80004c74 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cca:	e7042783          	lw	a5,-400(s0)
    80004cce:	e8845703          	lhu	a4,-376(s0)
    80004cd2:	c735                	beqz	a4,80004d3e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cd4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cda:	6a05                	lui	s4,0x1
    80004cdc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ce0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004ce4:	6d85                	lui	s11,0x1
    80004ce6:	7d7d                	lui	s10,0xfffff
    80004ce8:	a481                	j	80004f28 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cea:	00004517          	auipc	a0,0x4
    80004cee:	a1650513          	addi	a0,a0,-1514 # 80008700 <syscalls+0x290>
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	84c080e7          	jalr	-1972(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cfa:	874a                	mv	a4,s2
    80004cfc:	009c86bb          	addw	a3,s9,s1
    80004d00:	4581                	li	a1,0
    80004d02:	8556                	mv	a0,s5
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	c94080e7          	jalr	-876(ra) # 80003998 <readi>
    80004d0c:	2501                	sext.w	a0,a0
    80004d0e:	1aa91a63          	bne	s2,a0,80004ec2 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d12:	009d84bb          	addw	s1,s11,s1
    80004d16:	013d09bb          	addw	s3,s10,s3
    80004d1a:	1f74f763          	bgeu	s1,s7,80004f08 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    80004d1e:	02049593          	slli	a1,s1,0x20
    80004d22:	9181                	srli	a1,a1,0x20
    80004d24:	95e2                	add	a1,a1,s8
    80004d26:	855a                	mv	a0,s6
    80004d28:	ffffc097          	auipc	ra,0xffffc
    80004d2c:	354080e7          	jalr	852(ra) # 8000107c <walkaddr>
    80004d30:	862a                	mv	a2,a0
    if(pa == 0)
    80004d32:	dd45                	beqz	a0,80004cea <exec+0xfe>
      n = PGSIZE;
    80004d34:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d36:	fd49f2e3          	bgeu	s3,s4,80004cfa <exec+0x10e>
      n = sz - i;
    80004d3a:	894e                	mv	s2,s3
    80004d3c:	bf7d                	j	80004cfa <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d3e:	4901                	li	s2,0
  iunlockput(ip);
    80004d40:	8556                	mv	a0,s5
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	c04080e7          	jalr	-1020(ra) # 80003946 <iunlockput>
  end_op();
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	3dc080e7          	jalr	988(ra) # 80004126 <end_op>
  p = myproc();
    80004d52:	ffffd097          	auipc	ra,0xffffd
    80004d56:	c90080e7          	jalr	-880(ra) # 800019e2 <myproc>
    80004d5a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d5c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d60:	6785                	lui	a5,0x1
    80004d62:	17fd                	addi	a5,a5,-1
    80004d64:	993e                	add	s2,s2,a5
    80004d66:	77fd                	lui	a5,0xfffff
    80004d68:	00f977b3          	and	a5,s2,a5
    80004d6c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d70:	4691                	li	a3,4
    80004d72:	6609                	lui	a2,0x2
    80004d74:	963e                	add	a2,a2,a5
    80004d76:	85be                	mv	a1,a5
    80004d78:	855a                	mv	a0,s6
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	6cc080e7          	jalr	1740(ra) # 80001446 <uvmalloc>
    80004d82:	8c2a                	mv	s8,a0
  ip = 0;
    80004d84:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d86:	12050e63          	beqz	a0,80004ec2 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d8a:	75f9                	lui	a1,0xffffe
    80004d8c:	95aa                	add	a1,a1,a0
    80004d8e:	855a                	mv	a0,s6
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	8dc080e7          	jalr	-1828(ra) # 8000166c <uvmclear>
  stackbase = sp - PGSIZE;
    80004d98:	7afd                	lui	s5,0xfffff
    80004d9a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d9c:	df043783          	ld	a5,-528(s0)
    80004da0:	6388                	ld	a0,0(a5)
    80004da2:	c925                	beqz	a0,80004e12 <exec+0x226>
    80004da4:	e9040993          	addi	s3,s0,-368
    80004da8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dac:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dae:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	09e080e7          	jalr	158(ra) # 80000e4e <strlen>
    80004db8:	0015079b          	addiw	a5,a0,1
    80004dbc:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dc0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dc4:	13596663          	bltu	s2,s5,80004ef0 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dc8:	df043d83          	ld	s11,-528(s0)
    80004dcc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dd0:	8552                	mv	a0,s4
    80004dd2:	ffffc097          	auipc	ra,0xffffc
    80004dd6:	07c080e7          	jalr	124(ra) # 80000e4e <strlen>
    80004dda:	0015069b          	addiw	a3,a0,1
    80004dde:	8652                	mv	a2,s4
    80004de0:	85ca                	mv	a1,s2
    80004de2:	855a                	mv	a0,s6
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	8ba080e7          	jalr	-1862(ra) # 8000169e <copyout>
    80004dec:	10054663          	bltz	a0,80004ef8 <exec+0x30c>
    ustack[argc] = sp;
    80004df0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004df4:	0485                	addi	s1,s1,1
    80004df6:	008d8793          	addi	a5,s11,8
    80004dfa:	def43823          	sd	a5,-528(s0)
    80004dfe:	008db503          	ld	a0,8(s11)
    80004e02:	c911                	beqz	a0,80004e16 <exec+0x22a>
    if(argc >= MAXARG)
    80004e04:	09a1                	addi	s3,s3,8
    80004e06:	fb3c95e3          	bne	s9,s3,80004db0 <exec+0x1c4>
  sz = sz1;
    80004e0a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e0e:	4a81                	li	s5,0
    80004e10:	a84d                	j	80004ec2 <exec+0x2d6>
  sp = sz;
    80004e12:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e14:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e16:	00349793          	slli	a5,s1,0x3
    80004e1a:	f9040713          	addi	a4,s0,-112
    80004e1e:	97ba                	add	a5,a5,a4
    80004e20:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd9808>
  sp -= (argc+1) * sizeof(uint64);
    80004e24:	00148693          	addi	a3,s1,1
    80004e28:	068e                	slli	a3,a3,0x3
    80004e2a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e2e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e32:	01597663          	bgeu	s2,s5,80004e3e <exec+0x252>
  sz = sz1;
    80004e36:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e3a:	4a81                	li	s5,0
    80004e3c:	a059                	j	80004ec2 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e3e:	e9040613          	addi	a2,s0,-368
    80004e42:	85ca                	mv	a1,s2
    80004e44:	855a                	mv	a0,s6
    80004e46:	ffffd097          	auipc	ra,0xffffd
    80004e4a:	858080e7          	jalr	-1960(ra) # 8000169e <copyout>
    80004e4e:	0a054963          	bltz	a0,80004f00 <exec+0x314>
  p->trapframe->a1 = sp;
    80004e52:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e56:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e5a:	de843783          	ld	a5,-536(s0)
    80004e5e:	0007c703          	lbu	a4,0(a5)
    80004e62:	cf11                	beqz	a4,80004e7e <exec+0x292>
    80004e64:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e66:	02f00693          	li	a3,47
    80004e6a:	a039                	j	80004e78 <exec+0x28c>
      last = s+1;
    80004e6c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e70:	0785                	addi	a5,a5,1
    80004e72:	fff7c703          	lbu	a4,-1(a5)
    80004e76:	c701                	beqz	a4,80004e7e <exec+0x292>
    if(*s == '/')
    80004e78:	fed71ce3          	bne	a4,a3,80004e70 <exec+0x284>
    80004e7c:	bfc5                	j	80004e6c <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e7e:	4641                	li	a2,16
    80004e80:	de843583          	ld	a1,-536(s0)
    80004e84:	158b8513          	addi	a0,s7,344
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	f94080e7          	jalr	-108(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e90:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e94:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e98:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e9c:	058bb783          	ld	a5,88(s7)
    80004ea0:	e6843703          	ld	a4,-408(s0)
    80004ea4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ea6:	058bb783          	ld	a5,88(s7)
    80004eaa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004eae:	85ea                	mv	a1,s10
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	c92080e7          	jalr	-878(ra) # 80001b42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004eb8:	0004851b          	sext.w	a0,s1
    80004ebc:	b3f1                	j	80004c88 <exec+0x9c>
    80004ebe:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004ec2:	df843583          	ld	a1,-520(s0)
    80004ec6:	855a                	mv	a0,s6
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	c7a080e7          	jalr	-902(ra) # 80001b42 <proc_freepagetable>
  if(ip){
    80004ed0:	da0a92e3          	bnez	s5,80004c74 <exec+0x88>
  return -1;
    80004ed4:	557d                	li	a0,-1
    80004ed6:	bb4d                	j	80004c88 <exec+0x9c>
    80004ed8:	df243c23          	sd	s2,-520(s0)
    80004edc:	b7dd                	j	80004ec2 <exec+0x2d6>
    80004ede:	df243c23          	sd	s2,-520(s0)
    80004ee2:	b7c5                	j	80004ec2 <exec+0x2d6>
    80004ee4:	df243c23          	sd	s2,-520(s0)
    80004ee8:	bfe9                	j	80004ec2 <exec+0x2d6>
    80004eea:	df243c23          	sd	s2,-520(s0)
    80004eee:	bfd1                	j	80004ec2 <exec+0x2d6>
  sz = sz1;
    80004ef0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef4:	4a81                	li	s5,0
    80004ef6:	b7f1                	j	80004ec2 <exec+0x2d6>
  sz = sz1;
    80004ef8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004efc:	4a81                	li	s5,0
    80004efe:	b7d1                	j	80004ec2 <exec+0x2d6>
  sz = sz1;
    80004f00:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f04:	4a81                	li	s5,0
    80004f06:	bf75                	j	80004ec2 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f08:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f0c:	e0843783          	ld	a5,-504(s0)
    80004f10:	0017869b          	addiw	a3,a5,1
    80004f14:	e0d43423          	sd	a3,-504(s0)
    80004f18:	e0043783          	ld	a5,-512(s0)
    80004f1c:	0387879b          	addiw	a5,a5,56
    80004f20:	e8845703          	lhu	a4,-376(s0)
    80004f24:	e0e6dee3          	bge	a3,a4,80004d40 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f28:	2781                	sext.w	a5,a5
    80004f2a:	e0f43023          	sd	a5,-512(s0)
    80004f2e:	03800713          	li	a4,56
    80004f32:	86be                	mv	a3,a5
    80004f34:	e1840613          	addi	a2,s0,-488
    80004f38:	4581                	li	a1,0
    80004f3a:	8556                	mv	a0,s5
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	a5c080e7          	jalr	-1444(ra) # 80003998 <readi>
    80004f44:	03800793          	li	a5,56
    80004f48:	f6f51be3          	bne	a0,a5,80004ebe <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80004f4c:	e1842783          	lw	a5,-488(s0)
    80004f50:	4705                	li	a4,1
    80004f52:	fae79de3          	bne	a5,a4,80004f0c <exec+0x320>
    if(ph.memsz < ph.filesz)
    80004f56:	e4043483          	ld	s1,-448(s0)
    80004f5a:	e3843783          	ld	a5,-456(s0)
    80004f5e:	f6f4ede3          	bltu	s1,a5,80004ed8 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f62:	e2843783          	ld	a5,-472(s0)
    80004f66:	94be                	add	s1,s1,a5
    80004f68:	f6f4ebe3          	bltu	s1,a5,80004ede <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80004f6c:	de043703          	ld	a4,-544(s0)
    80004f70:	8ff9                	and	a5,a5,a4
    80004f72:	fbad                	bnez	a5,80004ee4 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f74:	e1c42503          	lw	a0,-484(s0)
    80004f78:	00000097          	auipc	ra,0x0
    80004f7c:	c58080e7          	jalr	-936(ra) # 80004bd0 <flags2perm>
    80004f80:	86aa                	mv	a3,a0
    80004f82:	8626                	mv	a2,s1
    80004f84:	85ca                	mv	a1,s2
    80004f86:	855a                	mv	a0,s6
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	4be080e7          	jalr	1214(ra) # 80001446 <uvmalloc>
    80004f90:	dea43c23          	sd	a0,-520(s0)
    80004f94:	d939                	beqz	a0,80004eea <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f96:	e2843c03          	ld	s8,-472(s0)
    80004f9a:	e2042c83          	lw	s9,-480(s0)
    80004f9e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fa2:	f60b83e3          	beqz	s7,80004f08 <exec+0x31c>
    80004fa6:	89de                	mv	s3,s7
    80004fa8:	4481                	li	s1,0
    80004faa:	bb95                	j	80004d1e <exec+0x132>

0000000080004fac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fac:	7179                	addi	sp,sp,-48
    80004fae:	f406                	sd	ra,40(sp)
    80004fb0:	f022                	sd	s0,32(sp)
    80004fb2:	ec26                	sd	s1,24(sp)
    80004fb4:	e84a                	sd	s2,16(sp)
    80004fb6:	1800                	addi	s0,sp,48
    80004fb8:	892e                	mv	s2,a1
    80004fba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004fbc:	fdc40593          	addi	a1,s0,-36
    80004fc0:	ffffe097          	auipc	ra,0xffffe
    80004fc4:	b9c080e7          	jalr	-1124(ra) # 80002b5c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fc8:	fdc42703          	lw	a4,-36(s0)
    80004fcc:	47bd                	li	a5,15
    80004fce:	02e7eb63          	bltu	a5,a4,80005004 <argfd+0x58>
    80004fd2:	ffffd097          	auipc	ra,0xffffd
    80004fd6:	a10080e7          	jalr	-1520(ra) # 800019e2 <myproc>
    80004fda:	fdc42703          	lw	a4,-36(s0)
    80004fde:	01a70793          	addi	a5,a4,26
    80004fe2:	078e                	slli	a5,a5,0x3
    80004fe4:	953e                	add	a0,a0,a5
    80004fe6:	611c                	ld	a5,0(a0)
    80004fe8:	c385                	beqz	a5,80005008 <argfd+0x5c>
    return -1;
  if(pfd)
    80004fea:	00090463          	beqz	s2,80004ff2 <argfd+0x46>
    *pfd = fd;
    80004fee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ff2:	4501                	li	a0,0
  if(pf)
    80004ff4:	c091                	beqz	s1,80004ff8 <argfd+0x4c>
    *pf = f;
    80004ff6:	e09c                	sd	a5,0(s1)
}
    80004ff8:	70a2                	ld	ra,40(sp)
    80004ffa:	7402                	ld	s0,32(sp)
    80004ffc:	64e2                	ld	s1,24(sp)
    80004ffe:	6942                	ld	s2,16(sp)
    80005000:	6145                	addi	sp,sp,48
    80005002:	8082                	ret
    return -1;
    80005004:	557d                	li	a0,-1
    80005006:	bfcd                	j	80004ff8 <argfd+0x4c>
    80005008:	557d                	li	a0,-1
    8000500a:	b7fd                	j	80004ff8 <argfd+0x4c>

000000008000500c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000500c:	1101                	addi	sp,sp,-32
    8000500e:	ec06                	sd	ra,24(sp)
    80005010:	e822                	sd	s0,16(sp)
    80005012:	e426                	sd	s1,8(sp)
    80005014:	1000                	addi	s0,sp,32
    80005016:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	9ca080e7          	jalr	-1590(ra) # 800019e2 <myproc>
    80005020:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005022:	0d050793          	addi	a5,a0,208
    80005026:	4501                	li	a0,0
    80005028:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000502a:	6398                	ld	a4,0(a5)
    8000502c:	cb19                	beqz	a4,80005042 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000502e:	2505                	addiw	a0,a0,1
    80005030:	07a1                	addi	a5,a5,8
    80005032:	fed51ce3          	bne	a0,a3,8000502a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005036:	557d                	li	a0,-1
}
    80005038:	60e2                	ld	ra,24(sp)
    8000503a:	6442                	ld	s0,16(sp)
    8000503c:	64a2                	ld	s1,8(sp)
    8000503e:	6105                	addi	sp,sp,32
    80005040:	8082                	ret
      p->ofile[fd] = f;
    80005042:	01a50793          	addi	a5,a0,26
    80005046:	078e                	slli	a5,a5,0x3
    80005048:	963e                	add	a2,a2,a5
    8000504a:	e204                	sd	s1,0(a2)
      return fd;
    8000504c:	b7f5                	j	80005038 <fdalloc+0x2c>

000000008000504e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000504e:	715d                	addi	sp,sp,-80
    80005050:	e486                	sd	ra,72(sp)
    80005052:	e0a2                	sd	s0,64(sp)
    80005054:	fc26                	sd	s1,56(sp)
    80005056:	f84a                	sd	s2,48(sp)
    80005058:	f44e                	sd	s3,40(sp)
    8000505a:	f052                	sd	s4,32(sp)
    8000505c:	ec56                	sd	s5,24(sp)
    8000505e:	e85a                	sd	s6,16(sp)
    80005060:	0880                	addi	s0,sp,80
    80005062:	8b2e                	mv	s6,a1
    80005064:	89b2                	mv	s3,a2
    80005066:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005068:	fb040593          	addi	a1,s0,-80
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	e3c080e7          	jalr	-452(ra) # 80003ea8 <nameiparent>
    80005074:	84aa                	mv	s1,a0
    80005076:	14050f63          	beqz	a0,800051d4 <create+0x186>
    return 0;

  ilock(dp);
    8000507a:	ffffe097          	auipc	ra,0xffffe
    8000507e:	66a080e7          	jalr	1642(ra) # 800036e4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005082:	4601                	li	a2,0
    80005084:	fb040593          	addi	a1,s0,-80
    80005088:	8526                	mv	a0,s1
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	b3e080e7          	jalr	-1218(ra) # 80003bc8 <dirlookup>
    80005092:	8aaa                	mv	s5,a0
    80005094:	c931                	beqz	a0,800050e8 <create+0x9a>
    iunlockput(dp);
    80005096:	8526                	mv	a0,s1
    80005098:	fffff097          	auipc	ra,0xfffff
    8000509c:	8ae080e7          	jalr	-1874(ra) # 80003946 <iunlockput>
    ilock(ip);
    800050a0:	8556                	mv	a0,s5
    800050a2:	ffffe097          	auipc	ra,0xffffe
    800050a6:	642080e7          	jalr	1602(ra) # 800036e4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050aa:	000b059b          	sext.w	a1,s6
    800050ae:	4789                	li	a5,2
    800050b0:	02f59563          	bne	a1,a5,800050da <create+0x8c>
    800050b4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd994c>
    800050b8:	37f9                	addiw	a5,a5,-2
    800050ba:	17c2                	slli	a5,a5,0x30
    800050bc:	93c1                	srli	a5,a5,0x30
    800050be:	4705                	li	a4,1
    800050c0:	00f76d63          	bltu	a4,a5,800050da <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800050c4:	8556                	mv	a0,s5
    800050c6:	60a6                	ld	ra,72(sp)
    800050c8:	6406                	ld	s0,64(sp)
    800050ca:	74e2                	ld	s1,56(sp)
    800050cc:	7942                	ld	s2,48(sp)
    800050ce:	79a2                	ld	s3,40(sp)
    800050d0:	7a02                	ld	s4,32(sp)
    800050d2:	6ae2                	ld	s5,24(sp)
    800050d4:	6b42                	ld	s6,16(sp)
    800050d6:	6161                	addi	sp,sp,80
    800050d8:	8082                	ret
    iunlockput(ip);
    800050da:	8556                	mv	a0,s5
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	86a080e7          	jalr	-1942(ra) # 80003946 <iunlockput>
    return 0;
    800050e4:	4a81                	li	s5,0
    800050e6:	bff9                	j	800050c4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050e8:	85da                	mv	a1,s6
    800050ea:	4088                	lw	a0,0(s1)
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	45c080e7          	jalr	1116(ra) # 80003548 <ialloc>
    800050f4:	8a2a                	mv	s4,a0
    800050f6:	c539                	beqz	a0,80005144 <create+0xf6>
  ilock(ip);
    800050f8:	ffffe097          	auipc	ra,0xffffe
    800050fc:	5ec080e7          	jalr	1516(ra) # 800036e4 <ilock>
  ip->major = major;
    80005100:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005104:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005108:	4905                	li	s2,1
    8000510a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000510e:	8552                	mv	a0,s4
    80005110:	ffffe097          	auipc	ra,0xffffe
    80005114:	50a080e7          	jalr	1290(ra) # 8000361a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005118:	000b059b          	sext.w	a1,s6
    8000511c:	03258b63          	beq	a1,s2,80005152 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005120:	004a2603          	lw	a2,4(s4)
    80005124:	fb040593          	addi	a1,s0,-80
    80005128:	8526                	mv	a0,s1
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	cae080e7          	jalr	-850(ra) # 80003dd8 <dirlink>
    80005132:	06054f63          	bltz	a0,800051b0 <create+0x162>
  iunlockput(dp);
    80005136:	8526                	mv	a0,s1
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	80e080e7          	jalr	-2034(ra) # 80003946 <iunlockput>
  return ip;
    80005140:	8ad2                	mv	s5,s4
    80005142:	b749                	j	800050c4 <create+0x76>
    iunlockput(dp);
    80005144:	8526                	mv	a0,s1
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	800080e7          	jalr	-2048(ra) # 80003946 <iunlockput>
    return 0;
    8000514e:	8ad2                	mv	s5,s4
    80005150:	bf95                	j	800050c4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005152:	004a2603          	lw	a2,4(s4)
    80005156:	00003597          	auipc	a1,0x3
    8000515a:	5ca58593          	addi	a1,a1,1482 # 80008720 <syscalls+0x2b0>
    8000515e:	8552                	mv	a0,s4
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	c78080e7          	jalr	-904(ra) # 80003dd8 <dirlink>
    80005168:	04054463          	bltz	a0,800051b0 <create+0x162>
    8000516c:	40d0                	lw	a2,4(s1)
    8000516e:	00003597          	auipc	a1,0x3
    80005172:	5ba58593          	addi	a1,a1,1466 # 80008728 <syscalls+0x2b8>
    80005176:	8552                	mv	a0,s4
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	c60080e7          	jalr	-928(ra) # 80003dd8 <dirlink>
    80005180:	02054863          	bltz	a0,800051b0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005184:	004a2603          	lw	a2,4(s4)
    80005188:	fb040593          	addi	a1,s0,-80
    8000518c:	8526                	mv	a0,s1
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	c4a080e7          	jalr	-950(ra) # 80003dd8 <dirlink>
    80005196:	00054d63          	bltz	a0,800051b0 <create+0x162>
    dp->nlink++;  // for ".."
    8000519a:	04a4d783          	lhu	a5,74(s1)
    8000519e:	2785                	addiw	a5,a5,1
    800051a0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800051a4:	8526                	mv	a0,s1
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	474080e7          	jalr	1140(ra) # 8000361a <iupdate>
    800051ae:	b761                	j	80005136 <create+0xe8>
  ip->nlink = 0;
    800051b0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800051b4:	8552                	mv	a0,s4
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	464080e7          	jalr	1124(ra) # 8000361a <iupdate>
  iunlockput(ip);
    800051be:	8552                	mv	a0,s4
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	786080e7          	jalr	1926(ra) # 80003946 <iunlockput>
  iunlockput(dp);
    800051c8:	8526                	mv	a0,s1
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	77c080e7          	jalr	1916(ra) # 80003946 <iunlockput>
  return 0;
    800051d2:	bdcd                	j	800050c4 <create+0x76>
    return 0;
    800051d4:	8aaa                	mv	s5,a0
    800051d6:	b5fd                	j	800050c4 <create+0x76>

00000000800051d8 <sys_dup>:
{
    800051d8:	7179                	addi	sp,sp,-48
    800051da:	f406                	sd	ra,40(sp)
    800051dc:	f022                	sd	s0,32(sp)
    800051de:	ec26                	sd	s1,24(sp)
    800051e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051e2:	fd840613          	addi	a2,s0,-40
    800051e6:	4581                	li	a1,0
    800051e8:	4501                	li	a0,0
    800051ea:	00000097          	auipc	ra,0x0
    800051ee:	dc2080e7          	jalr	-574(ra) # 80004fac <argfd>
    return -1;
    800051f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051f4:	02054363          	bltz	a0,8000521a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051f8:	fd843503          	ld	a0,-40(s0)
    800051fc:	00000097          	auipc	ra,0x0
    80005200:	e10080e7          	jalr	-496(ra) # 8000500c <fdalloc>
    80005204:	84aa                	mv	s1,a0
    return -1;
    80005206:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005208:	00054963          	bltz	a0,8000521a <sys_dup+0x42>
  filedup(f);
    8000520c:	fd843503          	ld	a0,-40(s0)
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	310080e7          	jalr	784(ra) # 80004520 <filedup>
  return fd;
    80005218:	87a6                	mv	a5,s1
}
    8000521a:	853e                	mv	a0,a5
    8000521c:	70a2                	ld	ra,40(sp)
    8000521e:	7402                	ld	s0,32(sp)
    80005220:	64e2                	ld	s1,24(sp)
    80005222:	6145                	addi	sp,sp,48
    80005224:	8082                	ret

0000000080005226 <sys_read>:
{
    80005226:	7179                	addi	sp,sp,-48
    80005228:	f406                	sd	ra,40(sp)
    8000522a:	f022                	sd	s0,32(sp)
    8000522c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000522e:	fd840593          	addi	a1,s0,-40
    80005232:	4505                	li	a0,1
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	948080e7          	jalr	-1720(ra) # 80002b7c <argaddr>
  argint(2, &n);
    8000523c:	fe440593          	addi	a1,s0,-28
    80005240:	4509                	li	a0,2
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	91a080e7          	jalr	-1766(ra) # 80002b5c <argint>
  if(argfd(0, 0, &f) < 0)
    8000524a:	fe840613          	addi	a2,s0,-24
    8000524e:	4581                	li	a1,0
    80005250:	4501                	li	a0,0
    80005252:	00000097          	auipc	ra,0x0
    80005256:	d5a080e7          	jalr	-678(ra) # 80004fac <argfd>
    8000525a:	87aa                	mv	a5,a0
    return -1;
    8000525c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000525e:	0007cc63          	bltz	a5,80005276 <sys_read+0x50>
  return fileread(f, p, n);
    80005262:	fe442603          	lw	a2,-28(s0)
    80005266:	fd843583          	ld	a1,-40(s0)
    8000526a:	fe843503          	ld	a0,-24(s0)
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	43e080e7          	jalr	1086(ra) # 800046ac <fileread>
}
    80005276:	70a2                	ld	ra,40(sp)
    80005278:	7402                	ld	s0,32(sp)
    8000527a:	6145                	addi	sp,sp,48
    8000527c:	8082                	ret

000000008000527e <sys_write>:
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005286:	fd840593          	addi	a1,s0,-40
    8000528a:	4505                	li	a0,1
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	8f0080e7          	jalr	-1808(ra) # 80002b7c <argaddr>
  argint(2, &n);
    80005294:	fe440593          	addi	a1,s0,-28
    80005298:	4509                	li	a0,2
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	8c2080e7          	jalr	-1854(ra) # 80002b5c <argint>
  if(argfd(0, 0, &f) < 0)
    800052a2:	fe840613          	addi	a2,s0,-24
    800052a6:	4581                	li	a1,0
    800052a8:	4501                	li	a0,0
    800052aa:	00000097          	auipc	ra,0x0
    800052ae:	d02080e7          	jalr	-766(ra) # 80004fac <argfd>
    800052b2:	87aa                	mv	a5,a0
    return -1;
    800052b4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052b6:	0007cc63          	bltz	a5,800052ce <sys_write+0x50>
  return filewrite(f, p, n);
    800052ba:	fe442603          	lw	a2,-28(s0)
    800052be:	fd843583          	ld	a1,-40(s0)
    800052c2:	fe843503          	ld	a0,-24(s0)
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	4a8080e7          	jalr	1192(ra) # 8000476e <filewrite>
}
    800052ce:	70a2                	ld	ra,40(sp)
    800052d0:	7402                	ld	s0,32(sp)
    800052d2:	6145                	addi	sp,sp,48
    800052d4:	8082                	ret

00000000800052d6 <sys_close>:
{
    800052d6:	1101                	addi	sp,sp,-32
    800052d8:	ec06                	sd	ra,24(sp)
    800052da:	e822                	sd	s0,16(sp)
    800052dc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052de:	fe040613          	addi	a2,s0,-32
    800052e2:	fec40593          	addi	a1,s0,-20
    800052e6:	4501                	li	a0,0
    800052e8:	00000097          	auipc	ra,0x0
    800052ec:	cc4080e7          	jalr	-828(ra) # 80004fac <argfd>
    return -1;
    800052f0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052f2:	02054463          	bltz	a0,8000531a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	6ec080e7          	jalr	1772(ra) # 800019e2 <myproc>
    800052fe:	fec42783          	lw	a5,-20(s0)
    80005302:	07e9                	addi	a5,a5,26
    80005304:	078e                	slli	a5,a5,0x3
    80005306:	97aa                	add	a5,a5,a0
    80005308:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000530c:	fe043503          	ld	a0,-32(s0)
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	262080e7          	jalr	610(ra) # 80004572 <fileclose>
  return 0;
    80005318:	4781                	li	a5,0
}
    8000531a:	853e                	mv	a0,a5
    8000531c:	60e2                	ld	ra,24(sp)
    8000531e:	6442                	ld	s0,16(sp)
    80005320:	6105                	addi	sp,sp,32
    80005322:	8082                	ret

0000000080005324 <sys_fstat>:
{
    80005324:	1101                	addi	sp,sp,-32
    80005326:	ec06                	sd	ra,24(sp)
    80005328:	e822                	sd	s0,16(sp)
    8000532a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000532c:	fe040593          	addi	a1,s0,-32
    80005330:	4505                	li	a0,1
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	84a080e7          	jalr	-1974(ra) # 80002b7c <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000533a:	fe840613          	addi	a2,s0,-24
    8000533e:	4581                	li	a1,0
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	c6a080e7          	jalr	-918(ra) # 80004fac <argfd>
    8000534a:	87aa                	mv	a5,a0
    return -1;
    8000534c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000534e:	0007ca63          	bltz	a5,80005362 <sys_fstat+0x3e>
  return filestat(f, st);
    80005352:	fe043583          	ld	a1,-32(s0)
    80005356:	fe843503          	ld	a0,-24(s0)
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	2e0080e7          	jalr	736(ra) # 8000463a <filestat>
}
    80005362:	60e2                	ld	ra,24(sp)
    80005364:	6442                	ld	s0,16(sp)
    80005366:	6105                	addi	sp,sp,32
    80005368:	8082                	ret

000000008000536a <sys_link>:
{
    8000536a:	7169                	addi	sp,sp,-304
    8000536c:	f606                	sd	ra,296(sp)
    8000536e:	f222                	sd	s0,288(sp)
    80005370:	ee26                	sd	s1,280(sp)
    80005372:	ea4a                	sd	s2,272(sp)
    80005374:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005376:	08000613          	li	a2,128
    8000537a:	ed040593          	addi	a1,s0,-304
    8000537e:	4501                	li	a0,0
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	81c080e7          	jalr	-2020(ra) # 80002b9c <argstr>
    return -1;
    80005388:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000538a:	10054e63          	bltz	a0,800054a6 <sys_link+0x13c>
    8000538e:	08000613          	li	a2,128
    80005392:	f5040593          	addi	a1,s0,-176
    80005396:	4505                	li	a0,1
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	804080e7          	jalr	-2044(ra) # 80002b9c <argstr>
    return -1;
    800053a0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053a2:	10054263          	bltz	a0,800054a6 <sys_link+0x13c>
  begin_op();
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	d00080e7          	jalr	-768(ra) # 800040a6 <begin_op>
  if((ip = namei(old)) == 0){
    800053ae:	ed040513          	addi	a0,s0,-304
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	ad8080e7          	jalr	-1320(ra) # 80003e8a <namei>
    800053ba:	84aa                	mv	s1,a0
    800053bc:	c551                	beqz	a0,80005448 <sys_link+0xde>
  ilock(ip);
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	326080e7          	jalr	806(ra) # 800036e4 <ilock>
  if(ip->type == T_DIR){
    800053c6:	04449703          	lh	a4,68(s1)
    800053ca:	4785                	li	a5,1
    800053cc:	08f70463          	beq	a4,a5,80005454 <sys_link+0xea>
  ip->nlink++;
    800053d0:	04a4d783          	lhu	a5,74(s1)
    800053d4:	2785                	addiw	a5,a5,1
    800053d6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053da:	8526                	mv	a0,s1
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	23e080e7          	jalr	574(ra) # 8000361a <iupdate>
  iunlock(ip);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	3c0080e7          	jalr	960(ra) # 800037a6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053ee:	fd040593          	addi	a1,s0,-48
    800053f2:	f5040513          	addi	a0,s0,-176
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	ab2080e7          	jalr	-1358(ra) # 80003ea8 <nameiparent>
    800053fe:	892a                	mv	s2,a0
    80005400:	c935                	beqz	a0,80005474 <sys_link+0x10a>
  ilock(dp);
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	2e2080e7          	jalr	738(ra) # 800036e4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000540a:	00092703          	lw	a4,0(s2)
    8000540e:	409c                	lw	a5,0(s1)
    80005410:	04f71d63          	bne	a4,a5,8000546a <sys_link+0x100>
    80005414:	40d0                	lw	a2,4(s1)
    80005416:	fd040593          	addi	a1,s0,-48
    8000541a:	854a                	mv	a0,s2
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	9bc080e7          	jalr	-1604(ra) # 80003dd8 <dirlink>
    80005424:	04054363          	bltz	a0,8000546a <sys_link+0x100>
  iunlockput(dp);
    80005428:	854a                	mv	a0,s2
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	51c080e7          	jalr	1308(ra) # 80003946 <iunlockput>
  iput(ip);
    80005432:	8526                	mv	a0,s1
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	46a080e7          	jalr	1130(ra) # 8000389e <iput>
  end_op();
    8000543c:	fffff097          	auipc	ra,0xfffff
    80005440:	cea080e7          	jalr	-790(ra) # 80004126 <end_op>
  return 0;
    80005444:	4781                	li	a5,0
    80005446:	a085                	j	800054a6 <sys_link+0x13c>
    end_op();
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	cde080e7          	jalr	-802(ra) # 80004126 <end_op>
    return -1;
    80005450:	57fd                	li	a5,-1
    80005452:	a891                	j	800054a6 <sys_link+0x13c>
    iunlockput(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	4f0080e7          	jalr	1264(ra) # 80003946 <iunlockput>
    end_op();
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	cc8080e7          	jalr	-824(ra) # 80004126 <end_op>
    return -1;
    80005466:	57fd                	li	a5,-1
    80005468:	a83d                	j	800054a6 <sys_link+0x13c>
    iunlockput(dp);
    8000546a:	854a                	mv	a0,s2
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	4da080e7          	jalr	1242(ra) # 80003946 <iunlockput>
  ilock(ip);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	26e080e7          	jalr	622(ra) # 800036e4 <ilock>
  ip->nlink--;
    8000547e:	04a4d783          	lhu	a5,74(s1)
    80005482:	37fd                	addiw	a5,a5,-1
    80005484:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	190080e7          	jalr	400(ra) # 8000361a <iupdate>
  iunlockput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	4b2080e7          	jalr	1202(ra) # 80003946 <iunlockput>
  end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	c8a080e7          	jalr	-886(ra) # 80004126 <end_op>
  return -1;
    800054a4:	57fd                	li	a5,-1
}
    800054a6:	853e                	mv	a0,a5
    800054a8:	70b2                	ld	ra,296(sp)
    800054aa:	7412                	ld	s0,288(sp)
    800054ac:	64f2                	ld	s1,280(sp)
    800054ae:	6952                	ld	s2,272(sp)
    800054b0:	6155                	addi	sp,sp,304
    800054b2:	8082                	ret

00000000800054b4 <sys_unlink>:
{
    800054b4:	7151                	addi	sp,sp,-240
    800054b6:	f586                	sd	ra,232(sp)
    800054b8:	f1a2                	sd	s0,224(sp)
    800054ba:	eda6                	sd	s1,216(sp)
    800054bc:	e9ca                	sd	s2,208(sp)
    800054be:	e5ce                	sd	s3,200(sp)
    800054c0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054c2:	08000613          	li	a2,128
    800054c6:	f3040593          	addi	a1,s0,-208
    800054ca:	4501                	li	a0,0
    800054cc:	ffffd097          	auipc	ra,0xffffd
    800054d0:	6d0080e7          	jalr	1744(ra) # 80002b9c <argstr>
    800054d4:	18054163          	bltz	a0,80005656 <sys_unlink+0x1a2>
  begin_op();
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	bce080e7          	jalr	-1074(ra) # 800040a6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054e0:	fb040593          	addi	a1,s0,-80
    800054e4:	f3040513          	addi	a0,s0,-208
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	9c0080e7          	jalr	-1600(ra) # 80003ea8 <nameiparent>
    800054f0:	84aa                	mv	s1,a0
    800054f2:	c979                	beqz	a0,800055c8 <sys_unlink+0x114>
  ilock(dp);
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	1f0080e7          	jalr	496(ra) # 800036e4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054fc:	00003597          	auipc	a1,0x3
    80005500:	22458593          	addi	a1,a1,548 # 80008720 <syscalls+0x2b0>
    80005504:	fb040513          	addi	a0,s0,-80
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	6a6080e7          	jalr	1702(ra) # 80003bae <namecmp>
    80005510:	14050a63          	beqz	a0,80005664 <sys_unlink+0x1b0>
    80005514:	00003597          	auipc	a1,0x3
    80005518:	21458593          	addi	a1,a1,532 # 80008728 <syscalls+0x2b8>
    8000551c:	fb040513          	addi	a0,s0,-80
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	68e080e7          	jalr	1678(ra) # 80003bae <namecmp>
    80005528:	12050e63          	beqz	a0,80005664 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000552c:	f2c40613          	addi	a2,s0,-212
    80005530:	fb040593          	addi	a1,s0,-80
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	692080e7          	jalr	1682(ra) # 80003bc8 <dirlookup>
    8000553e:	892a                	mv	s2,a0
    80005540:	12050263          	beqz	a0,80005664 <sys_unlink+0x1b0>
  ilock(ip);
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	1a0080e7          	jalr	416(ra) # 800036e4 <ilock>
  if(ip->nlink < 1)
    8000554c:	04a91783          	lh	a5,74(s2)
    80005550:	08f05263          	blez	a5,800055d4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005554:	04491703          	lh	a4,68(s2)
    80005558:	4785                	li	a5,1
    8000555a:	08f70563          	beq	a4,a5,800055e4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000555e:	4641                	li	a2,16
    80005560:	4581                	li	a1,0
    80005562:	fc040513          	addi	a0,s0,-64
    80005566:	ffffb097          	auipc	ra,0xffffb
    8000556a:	76c080e7          	jalr	1900(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000556e:	4741                	li	a4,16
    80005570:	f2c42683          	lw	a3,-212(s0)
    80005574:	fc040613          	addi	a2,s0,-64
    80005578:	4581                	li	a1,0
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	514080e7          	jalr	1300(ra) # 80003a90 <writei>
    80005584:	47c1                	li	a5,16
    80005586:	0af51563          	bne	a0,a5,80005630 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000558a:	04491703          	lh	a4,68(s2)
    8000558e:	4785                	li	a5,1
    80005590:	0af70863          	beq	a4,a5,80005640 <sys_unlink+0x18c>
  iunlockput(dp);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	3b0080e7          	jalr	944(ra) # 80003946 <iunlockput>
  ip->nlink--;
    8000559e:	04a95783          	lhu	a5,74(s2)
    800055a2:	37fd                	addiw	a5,a5,-1
    800055a4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055a8:	854a                	mv	a0,s2
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	070080e7          	jalr	112(ra) # 8000361a <iupdate>
  iunlockput(ip);
    800055b2:	854a                	mv	a0,s2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	392080e7          	jalr	914(ra) # 80003946 <iunlockput>
  end_op();
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	b6a080e7          	jalr	-1174(ra) # 80004126 <end_op>
  return 0;
    800055c4:	4501                	li	a0,0
    800055c6:	a84d                	j	80005678 <sys_unlink+0x1c4>
    end_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	b5e080e7          	jalr	-1186(ra) # 80004126 <end_op>
    return -1;
    800055d0:	557d                	li	a0,-1
    800055d2:	a05d                	j	80005678 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055d4:	00003517          	auipc	a0,0x3
    800055d8:	15c50513          	addi	a0,a0,348 # 80008730 <syscalls+0x2c0>
    800055dc:	ffffb097          	auipc	ra,0xffffb
    800055e0:	f62080e7          	jalr	-158(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055e4:	04c92703          	lw	a4,76(s2)
    800055e8:	02000793          	li	a5,32
    800055ec:	f6e7f9e3          	bgeu	a5,a4,8000555e <sys_unlink+0xaa>
    800055f0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055f4:	4741                	li	a4,16
    800055f6:	86ce                	mv	a3,s3
    800055f8:	f1840613          	addi	a2,s0,-232
    800055fc:	4581                	li	a1,0
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	398080e7          	jalr	920(ra) # 80003998 <readi>
    80005608:	47c1                	li	a5,16
    8000560a:	00f51b63          	bne	a0,a5,80005620 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000560e:	f1845783          	lhu	a5,-232(s0)
    80005612:	e7a1                	bnez	a5,8000565a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005614:	29c1                	addiw	s3,s3,16
    80005616:	04c92783          	lw	a5,76(s2)
    8000561a:	fcf9ede3          	bltu	s3,a5,800055f4 <sys_unlink+0x140>
    8000561e:	b781                	j	8000555e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005620:	00003517          	auipc	a0,0x3
    80005624:	12850513          	addi	a0,a0,296 # 80008748 <syscalls+0x2d8>
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005630:	00003517          	auipc	a0,0x3
    80005634:	13050513          	addi	a0,a0,304 # 80008760 <syscalls+0x2f0>
    80005638:	ffffb097          	auipc	ra,0xffffb
    8000563c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>
    dp->nlink--;
    80005640:	04a4d783          	lhu	a5,74(s1)
    80005644:	37fd                	addiw	a5,a5,-1
    80005646:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	fce080e7          	jalr	-50(ra) # 8000361a <iupdate>
    80005654:	b781                	j	80005594 <sys_unlink+0xe0>
    return -1;
    80005656:	557d                	li	a0,-1
    80005658:	a005                	j	80005678 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000565a:	854a                	mv	a0,s2
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	2ea080e7          	jalr	746(ra) # 80003946 <iunlockput>
  iunlockput(dp);
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	2e0080e7          	jalr	736(ra) # 80003946 <iunlockput>
  end_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	ab8080e7          	jalr	-1352(ra) # 80004126 <end_op>
  return -1;
    80005676:	557d                	li	a0,-1
}
    80005678:	70ae                	ld	ra,232(sp)
    8000567a:	740e                	ld	s0,224(sp)
    8000567c:	64ee                	ld	s1,216(sp)
    8000567e:	694e                	ld	s2,208(sp)
    80005680:	69ae                	ld	s3,200(sp)
    80005682:	616d                	addi	sp,sp,240
    80005684:	8082                	ret

0000000080005686 <sys_open>:

uint64
sys_open(void)
{
    80005686:	7131                	addi	sp,sp,-192
    80005688:	fd06                	sd	ra,184(sp)
    8000568a:	f922                	sd	s0,176(sp)
    8000568c:	f526                	sd	s1,168(sp)
    8000568e:	f14a                	sd	s2,160(sp)
    80005690:	ed4e                	sd	s3,152(sp)
    80005692:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005694:	f4c40593          	addi	a1,s0,-180
    80005698:	4505                	li	a0,1
    8000569a:	ffffd097          	auipc	ra,0xffffd
    8000569e:	4c2080e7          	jalr	1218(ra) # 80002b5c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056a2:	08000613          	li	a2,128
    800056a6:	f5040593          	addi	a1,s0,-176
    800056aa:	4501                	li	a0,0
    800056ac:	ffffd097          	auipc	ra,0xffffd
    800056b0:	4f0080e7          	jalr	1264(ra) # 80002b9c <argstr>
    800056b4:	87aa                	mv	a5,a0
    return -1;
    800056b6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800056b8:	0a07c963          	bltz	a5,8000576a <sys_open+0xe4>

  begin_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	9ea080e7          	jalr	-1558(ra) # 800040a6 <begin_op>

  if(omode & O_CREATE){
    800056c4:	f4c42783          	lw	a5,-180(s0)
    800056c8:	2007f793          	andi	a5,a5,512
    800056cc:	cfc5                	beqz	a5,80005784 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056ce:	4681                	li	a3,0
    800056d0:	4601                	li	a2,0
    800056d2:	4589                	li	a1,2
    800056d4:	f5040513          	addi	a0,s0,-176
    800056d8:	00000097          	auipc	ra,0x0
    800056dc:	976080e7          	jalr	-1674(ra) # 8000504e <create>
    800056e0:	84aa                	mv	s1,a0
    if(ip == 0){
    800056e2:	c959                	beqz	a0,80005778 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056e4:	04449703          	lh	a4,68(s1)
    800056e8:	478d                	li	a5,3
    800056ea:	00f71763          	bne	a4,a5,800056f8 <sys_open+0x72>
    800056ee:	0464d703          	lhu	a4,70(s1)
    800056f2:	47a5                	li	a5,9
    800056f4:	0ce7ed63          	bltu	a5,a4,800057ce <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	dbe080e7          	jalr	-578(ra) # 800044b6 <filealloc>
    80005700:	89aa                	mv	s3,a0
    80005702:	10050363          	beqz	a0,80005808 <sys_open+0x182>
    80005706:	00000097          	auipc	ra,0x0
    8000570a:	906080e7          	jalr	-1786(ra) # 8000500c <fdalloc>
    8000570e:	892a                	mv	s2,a0
    80005710:	0e054763          	bltz	a0,800057fe <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005714:	04449703          	lh	a4,68(s1)
    80005718:	478d                	li	a5,3
    8000571a:	0cf70563          	beq	a4,a5,800057e4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000571e:	4789                	li	a5,2
    80005720:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005724:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005728:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000572c:	f4c42783          	lw	a5,-180(s0)
    80005730:	0017c713          	xori	a4,a5,1
    80005734:	8b05                	andi	a4,a4,1
    80005736:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000573a:	0037f713          	andi	a4,a5,3
    8000573e:	00e03733          	snez	a4,a4
    80005742:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005746:	4007f793          	andi	a5,a5,1024
    8000574a:	c791                	beqz	a5,80005756 <sys_open+0xd0>
    8000574c:	04449703          	lh	a4,68(s1)
    80005750:	4789                	li	a5,2
    80005752:	0af70063          	beq	a4,a5,800057f2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005756:	8526                	mv	a0,s1
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	04e080e7          	jalr	78(ra) # 800037a6 <iunlock>
  end_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	9c6080e7          	jalr	-1594(ra) # 80004126 <end_op>

  return fd;
    80005768:	854a                	mv	a0,s2
}
    8000576a:	70ea                	ld	ra,184(sp)
    8000576c:	744a                	ld	s0,176(sp)
    8000576e:	74aa                	ld	s1,168(sp)
    80005770:	790a                	ld	s2,160(sp)
    80005772:	69ea                	ld	s3,152(sp)
    80005774:	6129                	addi	sp,sp,192
    80005776:	8082                	ret
      end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	9ae080e7          	jalr	-1618(ra) # 80004126 <end_op>
      return -1;
    80005780:	557d                	li	a0,-1
    80005782:	b7e5                	j	8000576a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005784:	f5040513          	addi	a0,s0,-176
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	702080e7          	jalr	1794(ra) # 80003e8a <namei>
    80005790:	84aa                	mv	s1,a0
    80005792:	c905                	beqz	a0,800057c2 <sys_open+0x13c>
    ilock(ip);
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	f50080e7          	jalr	-176(ra) # 800036e4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000579c:	04449703          	lh	a4,68(s1)
    800057a0:	4785                	li	a5,1
    800057a2:	f4f711e3          	bne	a4,a5,800056e4 <sys_open+0x5e>
    800057a6:	f4c42783          	lw	a5,-180(s0)
    800057aa:	d7b9                	beqz	a5,800056f8 <sys_open+0x72>
      iunlockput(ip);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	198080e7          	jalr	408(ra) # 80003946 <iunlockput>
      end_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	970080e7          	jalr	-1680(ra) # 80004126 <end_op>
      return -1;
    800057be:	557d                	li	a0,-1
    800057c0:	b76d                	j	8000576a <sys_open+0xe4>
      end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	964080e7          	jalr	-1692(ra) # 80004126 <end_op>
      return -1;
    800057ca:	557d                	li	a0,-1
    800057cc:	bf79                	j	8000576a <sys_open+0xe4>
    iunlockput(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	176080e7          	jalr	374(ra) # 80003946 <iunlockput>
    end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	94e080e7          	jalr	-1714(ra) # 80004126 <end_op>
    return -1;
    800057e0:	557d                	li	a0,-1
    800057e2:	b761                	j	8000576a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057e4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057e8:	04649783          	lh	a5,70(s1)
    800057ec:	02f99223          	sh	a5,36(s3)
    800057f0:	bf25                	j	80005728 <sys_open+0xa2>
    itrunc(ip);
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	ffe080e7          	jalr	-2(ra) # 800037f2 <itrunc>
    800057fc:	bfa9                	j	80005756 <sys_open+0xd0>
      fileclose(f);
    800057fe:	854e                	mv	a0,s3
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	d72080e7          	jalr	-654(ra) # 80004572 <fileclose>
    iunlockput(ip);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	13c080e7          	jalr	316(ra) # 80003946 <iunlockput>
    end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	914080e7          	jalr	-1772(ra) # 80004126 <end_op>
    return -1;
    8000581a:	557d                	li	a0,-1
    8000581c:	b7b9                	j	8000576a <sys_open+0xe4>

000000008000581e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000581e:	7175                	addi	sp,sp,-144
    80005820:	e506                	sd	ra,136(sp)
    80005822:	e122                	sd	s0,128(sp)
    80005824:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	880080e7          	jalr	-1920(ra) # 800040a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000582e:	08000613          	li	a2,128
    80005832:	f7040593          	addi	a1,s0,-144
    80005836:	4501                	li	a0,0
    80005838:	ffffd097          	auipc	ra,0xffffd
    8000583c:	364080e7          	jalr	868(ra) # 80002b9c <argstr>
    80005840:	02054963          	bltz	a0,80005872 <sys_mkdir+0x54>
    80005844:	4681                	li	a3,0
    80005846:	4601                	li	a2,0
    80005848:	4585                	li	a1,1
    8000584a:	f7040513          	addi	a0,s0,-144
    8000584e:	00000097          	auipc	ra,0x0
    80005852:	800080e7          	jalr	-2048(ra) # 8000504e <create>
    80005856:	cd11                	beqz	a0,80005872 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	0ee080e7          	jalr	238(ra) # 80003946 <iunlockput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	8c6080e7          	jalr	-1850(ra) # 80004126 <end_op>
  return 0;
    80005868:	4501                	li	a0,0
}
    8000586a:	60aa                	ld	ra,136(sp)
    8000586c:	640a                	ld	s0,128(sp)
    8000586e:	6149                	addi	sp,sp,144
    80005870:	8082                	ret
    end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	8b4080e7          	jalr	-1868(ra) # 80004126 <end_op>
    return -1;
    8000587a:	557d                	li	a0,-1
    8000587c:	b7fd                	j	8000586a <sys_mkdir+0x4c>

000000008000587e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000587e:	7135                	addi	sp,sp,-160
    80005880:	ed06                	sd	ra,152(sp)
    80005882:	e922                	sd	s0,144(sp)
    80005884:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	820080e7          	jalr	-2016(ra) # 800040a6 <begin_op>
  argint(1, &major);
    8000588e:	f6c40593          	addi	a1,s0,-148
    80005892:	4505                	li	a0,1
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	2c8080e7          	jalr	712(ra) # 80002b5c <argint>
  argint(2, &minor);
    8000589c:	f6840593          	addi	a1,s0,-152
    800058a0:	4509                	li	a0,2
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	2ba080e7          	jalr	698(ra) # 80002b5c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058aa:	08000613          	li	a2,128
    800058ae:	f7040593          	addi	a1,s0,-144
    800058b2:	4501                	li	a0,0
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	2e8080e7          	jalr	744(ra) # 80002b9c <argstr>
    800058bc:	02054b63          	bltz	a0,800058f2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058c0:	f6841683          	lh	a3,-152(s0)
    800058c4:	f6c41603          	lh	a2,-148(s0)
    800058c8:	458d                	li	a1,3
    800058ca:	f7040513          	addi	a0,s0,-144
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	780080e7          	jalr	1920(ra) # 8000504e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058d6:	cd11                	beqz	a0,800058f2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	06e080e7          	jalr	110(ra) # 80003946 <iunlockput>
  end_op();
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	846080e7          	jalr	-1978(ra) # 80004126 <end_op>
  return 0;
    800058e8:	4501                	li	a0,0
}
    800058ea:	60ea                	ld	ra,152(sp)
    800058ec:	644a                	ld	s0,144(sp)
    800058ee:	610d                	addi	sp,sp,160
    800058f0:	8082                	ret
    end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	834080e7          	jalr	-1996(ra) # 80004126 <end_op>
    return -1;
    800058fa:	557d                	li	a0,-1
    800058fc:	b7fd                	j	800058ea <sys_mknod+0x6c>

00000000800058fe <sys_chdir>:

uint64
sys_chdir(void)
{
    800058fe:	7135                	addi	sp,sp,-160
    80005900:	ed06                	sd	ra,152(sp)
    80005902:	e922                	sd	s0,144(sp)
    80005904:	e526                	sd	s1,136(sp)
    80005906:	e14a                	sd	s2,128(sp)
    80005908:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000590a:	ffffc097          	auipc	ra,0xffffc
    8000590e:	0d8080e7          	jalr	216(ra) # 800019e2 <myproc>
    80005912:	892a                	mv	s2,a0
  
  begin_op();
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	792080e7          	jalr	1938(ra) # 800040a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000591c:	08000613          	li	a2,128
    80005920:	f6040593          	addi	a1,s0,-160
    80005924:	4501                	li	a0,0
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	276080e7          	jalr	630(ra) # 80002b9c <argstr>
    8000592e:	04054b63          	bltz	a0,80005984 <sys_chdir+0x86>
    80005932:	f6040513          	addi	a0,s0,-160
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	554080e7          	jalr	1364(ra) # 80003e8a <namei>
    8000593e:	84aa                	mv	s1,a0
    80005940:	c131                	beqz	a0,80005984 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	da2080e7          	jalr	-606(ra) # 800036e4 <ilock>
  if(ip->type != T_DIR){
    8000594a:	04449703          	lh	a4,68(s1)
    8000594e:	4785                	li	a5,1
    80005950:	04f71063          	bne	a4,a5,80005990 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	e50080e7          	jalr	-432(ra) # 800037a6 <iunlock>
  iput(p->cwd);
    8000595e:	15093503          	ld	a0,336(s2)
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	f3c080e7          	jalr	-196(ra) # 8000389e <iput>
  end_op();
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	7bc080e7          	jalr	1980(ra) # 80004126 <end_op>
  p->cwd = ip;
    80005972:	14993823          	sd	s1,336(s2)
  return 0;
    80005976:	4501                	li	a0,0
}
    80005978:	60ea                	ld	ra,152(sp)
    8000597a:	644a                	ld	s0,144(sp)
    8000597c:	64aa                	ld	s1,136(sp)
    8000597e:	690a                	ld	s2,128(sp)
    80005980:	610d                	addi	sp,sp,160
    80005982:	8082                	ret
    end_op();
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	7a2080e7          	jalr	1954(ra) # 80004126 <end_op>
    return -1;
    8000598c:	557d                	li	a0,-1
    8000598e:	b7ed                	j	80005978 <sys_chdir+0x7a>
    iunlockput(ip);
    80005990:	8526                	mv	a0,s1
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	fb4080e7          	jalr	-76(ra) # 80003946 <iunlockput>
    end_op();
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	78c080e7          	jalr	1932(ra) # 80004126 <end_op>
    return -1;
    800059a2:	557d                	li	a0,-1
    800059a4:	bfd1                	j	80005978 <sys_chdir+0x7a>

00000000800059a6 <sys_exec>:

uint64
sys_exec(void)
{
    800059a6:	7145                	addi	sp,sp,-464
    800059a8:	e786                	sd	ra,456(sp)
    800059aa:	e3a2                	sd	s0,448(sp)
    800059ac:	ff26                	sd	s1,440(sp)
    800059ae:	fb4a                	sd	s2,432(sp)
    800059b0:	f74e                	sd	s3,424(sp)
    800059b2:	f352                	sd	s4,416(sp)
    800059b4:	ef56                	sd	s5,408(sp)
    800059b6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800059b8:	e3840593          	addi	a1,s0,-456
    800059bc:	4505                	li	a0,1
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	1be080e7          	jalr	446(ra) # 80002b7c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800059c6:	08000613          	li	a2,128
    800059ca:	f4040593          	addi	a1,s0,-192
    800059ce:	4501                	li	a0,0
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	1cc080e7          	jalr	460(ra) # 80002b9c <argstr>
    800059d8:	87aa                	mv	a5,a0
    return -1;
    800059da:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800059dc:	0c07c263          	bltz	a5,80005aa0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059e0:	10000613          	li	a2,256
    800059e4:	4581                	li	a1,0
    800059e6:	e4040513          	addi	a0,s0,-448
    800059ea:	ffffb097          	auipc	ra,0xffffb
    800059ee:	2e8080e7          	jalr	744(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059f2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059f6:	89a6                	mv	s3,s1
    800059f8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059fa:	02000a13          	li	s4,32
    800059fe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a02:	00391793          	slli	a5,s2,0x3
    80005a06:	e3040593          	addi	a1,s0,-464
    80005a0a:	e3843503          	ld	a0,-456(s0)
    80005a0e:	953e                	add	a0,a0,a5
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	0ae080e7          	jalr	174(ra) # 80002abe <fetchaddr>
    80005a18:	02054a63          	bltz	a0,80005a4c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005a1c:	e3043783          	ld	a5,-464(s0)
    80005a20:	c3b9                	beqz	a5,80005a66 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a22:	ffffb097          	auipc	ra,0xffffb
    80005a26:	0c4080e7          	jalr	196(ra) # 80000ae6 <kalloc>
    80005a2a:	85aa                	mv	a1,a0
    80005a2c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a30:	cd11                	beqz	a0,80005a4c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a32:	6605                	lui	a2,0x1
    80005a34:	e3043503          	ld	a0,-464(s0)
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	0d8080e7          	jalr	216(ra) # 80002b10 <fetchstr>
    80005a40:	00054663          	bltz	a0,80005a4c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a44:	0905                	addi	s2,s2,1
    80005a46:	09a1                	addi	s3,s3,8
    80005a48:	fb491be3          	bne	s2,s4,800059fe <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a4c:	10048913          	addi	s2,s1,256
    80005a50:	6088                	ld	a0,0(s1)
    80005a52:	c531                	beqz	a0,80005a9e <sys_exec+0xf8>
    kfree(argv[i]);
    80005a54:	ffffb097          	auipc	ra,0xffffb
    80005a58:	f96080e7          	jalr	-106(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a5c:	04a1                	addi	s1,s1,8
    80005a5e:	ff2499e3          	bne	s1,s2,80005a50 <sys_exec+0xaa>
  return -1;
    80005a62:	557d                	li	a0,-1
    80005a64:	a835                	j	80005aa0 <sys_exec+0xfa>
      argv[i] = 0;
    80005a66:	0a8e                	slli	s5,s5,0x3
    80005a68:	fc040793          	addi	a5,s0,-64
    80005a6c:	9abe                	add	s5,s5,a5
    80005a6e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a72:	e4040593          	addi	a1,s0,-448
    80005a76:	f4040513          	addi	a0,s0,-192
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	172080e7          	jalr	370(ra) # 80004bec <exec>
    80005a82:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a84:	10048993          	addi	s3,s1,256
    80005a88:	6088                	ld	a0,0(s1)
    80005a8a:	c901                	beqz	a0,80005a9a <sys_exec+0xf4>
    kfree(argv[i]);
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a94:	04a1                	addi	s1,s1,8
    80005a96:	ff3499e3          	bne	s1,s3,80005a88 <sys_exec+0xe2>
  return ret;
    80005a9a:	854a                	mv	a0,s2
    80005a9c:	a011                	j	80005aa0 <sys_exec+0xfa>
  return -1;
    80005a9e:	557d                	li	a0,-1
}
    80005aa0:	60be                	ld	ra,456(sp)
    80005aa2:	641e                	ld	s0,448(sp)
    80005aa4:	74fa                	ld	s1,440(sp)
    80005aa6:	795a                	ld	s2,432(sp)
    80005aa8:	79ba                	ld	s3,424(sp)
    80005aaa:	7a1a                	ld	s4,416(sp)
    80005aac:	6afa                	ld	s5,408(sp)
    80005aae:	6179                	addi	sp,sp,464
    80005ab0:	8082                	ret

0000000080005ab2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ab2:	7139                	addi	sp,sp,-64
    80005ab4:	fc06                	sd	ra,56(sp)
    80005ab6:	f822                	sd	s0,48(sp)
    80005ab8:	f426                	sd	s1,40(sp)
    80005aba:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005abc:	ffffc097          	auipc	ra,0xffffc
    80005ac0:	f26080e7          	jalr	-218(ra) # 800019e2 <myproc>
    80005ac4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005ac6:	fd840593          	addi	a1,s0,-40
    80005aca:	4501                	li	a0,0
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	0b0080e7          	jalr	176(ra) # 80002b7c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ad4:	fc840593          	addi	a1,s0,-56
    80005ad8:	fd040513          	addi	a0,s0,-48
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	dc6080e7          	jalr	-570(ra) # 800048a2 <pipealloc>
    return -1;
    80005ae4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ae6:	0c054463          	bltz	a0,80005bae <sys_pipe+0xfc>
  fd0 = -1;
    80005aea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005aee:	fd043503          	ld	a0,-48(s0)
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	51a080e7          	jalr	1306(ra) # 8000500c <fdalloc>
    80005afa:	fca42223          	sw	a0,-60(s0)
    80005afe:	08054b63          	bltz	a0,80005b94 <sys_pipe+0xe2>
    80005b02:	fc843503          	ld	a0,-56(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	506080e7          	jalr	1286(ra) # 8000500c <fdalloc>
    80005b0e:	fca42023          	sw	a0,-64(s0)
    80005b12:	06054863          	bltz	a0,80005b82 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b16:	4691                	li	a3,4
    80005b18:	fc440613          	addi	a2,s0,-60
    80005b1c:	fd843583          	ld	a1,-40(s0)
    80005b20:	68a8                	ld	a0,80(s1)
    80005b22:	ffffc097          	auipc	ra,0xffffc
    80005b26:	b7c080e7          	jalr	-1156(ra) # 8000169e <copyout>
    80005b2a:	02054063          	bltz	a0,80005b4a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b2e:	4691                	li	a3,4
    80005b30:	fc040613          	addi	a2,s0,-64
    80005b34:	fd843583          	ld	a1,-40(s0)
    80005b38:	0591                	addi	a1,a1,4
    80005b3a:	68a8                	ld	a0,80(s1)
    80005b3c:	ffffc097          	auipc	ra,0xffffc
    80005b40:	b62080e7          	jalr	-1182(ra) # 8000169e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b46:	06055463          	bgez	a0,80005bae <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b4a:	fc442783          	lw	a5,-60(s0)
    80005b4e:	07e9                	addi	a5,a5,26
    80005b50:	078e                	slli	a5,a5,0x3
    80005b52:	97a6                	add	a5,a5,s1
    80005b54:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b58:	fc042503          	lw	a0,-64(s0)
    80005b5c:	0569                	addi	a0,a0,26
    80005b5e:	050e                	slli	a0,a0,0x3
    80005b60:	94aa                	add	s1,s1,a0
    80005b62:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b66:	fd043503          	ld	a0,-48(s0)
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	a08080e7          	jalr	-1528(ra) # 80004572 <fileclose>
    fileclose(wf);
    80005b72:	fc843503          	ld	a0,-56(s0)
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	9fc080e7          	jalr	-1540(ra) # 80004572 <fileclose>
    return -1;
    80005b7e:	57fd                	li	a5,-1
    80005b80:	a03d                	j	80005bae <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b82:	fc442783          	lw	a5,-60(s0)
    80005b86:	0007c763          	bltz	a5,80005b94 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b8a:	07e9                	addi	a5,a5,26
    80005b8c:	078e                	slli	a5,a5,0x3
    80005b8e:	94be                	add	s1,s1,a5
    80005b90:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b94:	fd043503          	ld	a0,-48(s0)
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	9da080e7          	jalr	-1574(ra) # 80004572 <fileclose>
    fileclose(wf);
    80005ba0:	fc843503          	ld	a0,-56(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	9ce080e7          	jalr	-1586(ra) # 80004572 <fileclose>
    return -1;
    80005bac:	57fd                	li	a5,-1
}
    80005bae:	853e                	mv	a0,a5
    80005bb0:	70e2                	ld	ra,56(sp)
    80005bb2:	7442                	ld	s0,48(sp)
    80005bb4:	74a2                	ld	s1,40(sp)
    80005bb6:	6121                	addi	sp,sp,64
    80005bb8:	8082                	ret
    80005bba:	0000                	unimp
    80005bbc:	0000                	unimp
	...

0000000080005bc0 <kernelvec>:
    80005bc0:	7111                	addi	sp,sp,-256
    80005bc2:	e006                	sd	ra,0(sp)
    80005bc4:	e40a                	sd	sp,8(sp)
    80005bc6:	e80e                	sd	gp,16(sp)
    80005bc8:	ec12                	sd	tp,24(sp)
    80005bca:	f016                	sd	t0,32(sp)
    80005bcc:	f41a                	sd	t1,40(sp)
    80005bce:	f81e                	sd	t2,48(sp)
    80005bd0:	fc22                	sd	s0,56(sp)
    80005bd2:	e0a6                	sd	s1,64(sp)
    80005bd4:	e4aa                	sd	a0,72(sp)
    80005bd6:	e8ae                	sd	a1,80(sp)
    80005bd8:	ecb2                	sd	a2,88(sp)
    80005bda:	f0b6                	sd	a3,96(sp)
    80005bdc:	f4ba                	sd	a4,104(sp)
    80005bde:	f8be                	sd	a5,112(sp)
    80005be0:	fcc2                	sd	a6,120(sp)
    80005be2:	e146                	sd	a7,128(sp)
    80005be4:	e54a                	sd	s2,136(sp)
    80005be6:	e94e                	sd	s3,144(sp)
    80005be8:	ed52                	sd	s4,152(sp)
    80005bea:	f156                	sd	s5,160(sp)
    80005bec:	f55a                	sd	s6,168(sp)
    80005bee:	f95e                	sd	s7,176(sp)
    80005bf0:	fd62                	sd	s8,184(sp)
    80005bf2:	e1e6                	sd	s9,192(sp)
    80005bf4:	e5ea                	sd	s10,200(sp)
    80005bf6:	e9ee                	sd	s11,208(sp)
    80005bf8:	edf2                	sd	t3,216(sp)
    80005bfa:	f1f6                	sd	t4,224(sp)
    80005bfc:	f5fa                	sd	t5,232(sp)
    80005bfe:	f9fe                	sd	t6,240(sp)
    80005c00:	d8bfc0ef          	jal	ra,8000298a <kerneltrap>
    80005c04:	6082                	ld	ra,0(sp)
    80005c06:	6122                	ld	sp,8(sp)
    80005c08:	61c2                	ld	gp,16(sp)
    80005c0a:	7282                	ld	t0,32(sp)
    80005c0c:	7322                	ld	t1,40(sp)
    80005c0e:	73c2                	ld	t2,48(sp)
    80005c10:	7462                	ld	s0,56(sp)
    80005c12:	6486                	ld	s1,64(sp)
    80005c14:	6526                	ld	a0,72(sp)
    80005c16:	65c6                	ld	a1,80(sp)
    80005c18:	6666                	ld	a2,88(sp)
    80005c1a:	7686                	ld	a3,96(sp)
    80005c1c:	7726                	ld	a4,104(sp)
    80005c1e:	77c6                	ld	a5,112(sp)
    80005c20:	7866                	ld	a6,120(sp)
    80005c22:	688a                	ld	a7,128(sp)
    80005c24:	692a                	ld	s2,136(sp)
    80005c26:	69ca                	ld	s3,144(sp)
    80005c28:	6a6a                	ld	s4,152(sp)
    80005c2a:	7a8a                	ld	s5,160(sp)
    80005c2c:	7b2a                	ld	s6,168(sp)
    80005c2e:	7bca                	ld	s7,176(sp)
    80005c30:	7c6a                	ld	s8,184(sp)
    80005c32:	6c8e                	ld	s9,192(sp)
    80005c34:	6d2e                	ld	s10,200(sp)
    80005c36:	6dce                	ld	s11,208(sp)
    80005c38:	6e6e                	ld	t3,216(sp)
    80005c3a:	7e8e                	ld	t4,224(sp)
    80005c3c:	7f2e                	ld	t5,232(sp)
    80005c3e:	7fce                	ld	t6,240(sp)
    80005c40:	6111                	addi	sp,sp,256
    80005c42:	10200073          	sret
    80005c46:	00000013          	nop
    80005c4a:	00000013          	nop
    80005c4e:	0001                	nop

0000000080005c50 <timervec>:
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	e10c                	sd	a1,0(a0)
    80005c56:	e510                	sd	a2,8(a0)
    80005c58:	e914                	sd	a3,16(a0)
    80005c5a:	6d0c                	ld	a1,24(a0)
    80005c5c:	7110                	ld	a2,32(a0)
    80005c5e:	6194                	ld	a3,0(a1)
    80005c60:	96b2                	add	a3,a3,a2
    80005c62:	e194                	sd	a3,0(a1)
    80005c64:	4589                	li	a1,2
    80005c66:	14459073          	csrw	sip,a1
    80005c6a:	6914                	ld	a3,16(a0)
    80005c6c:	6510                	ld	a2,8(a0)
    80005c6e:	610c                	ld	a1,0(a0)
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	30200073          	mret
	...

0000000080005c7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c7a:	1141                	addi	sp,sp,-16
    80005c7c:	e422                	sd	s0,8(sp)
    80005c7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c80:	0c0007b7          	lui	a5,0xc000
    80005c84:	4705                	li	a4,1
    80005c86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c88:	c3d8                	sw	a4,4(a5)
}
    80005c8a:	6422                	ld	s0,8(sp)
    80005c8c:	0141                	addi	sp,sp,16
    80005c8e:	8082                	ret

0000000080005c90 <plicinithart>:

void
plicinithart(void)
{
    80005c90:	1141                	addi	sp,sp,-16
    80005c92:	e406                	sd	ra,8(sp)
    80005c94:	e022                	sd	s0,0(sp)
    80005c96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	d1e080e7          	jalr	-738(ra) # 800019b6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ca0:	0085171b          	slliw	a4,a0,0x8
    80005ca4:	0c0027b7          	lui	a5,0xc002
    80005ca8:	97ba                	add	a5,a5,a4
    80005caa:	40200713          	li	a4,1026
    80005cae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cb2:	00d5151b          	slliw	a0,a0,0xd
    80005cb6:	0c2017b7          	lui	a5,0xc201
    80005cba:	953e                	add	a0,a0,a5
    80005cbc:	00052023          	sw	zero,0(a0)
}
    80005cc0:	60a2                	ld	ra,8(sp)
    80005cc2:	6402                	ld	s0,0(sp)
    80005cc4:	0141                	addi	sp,sp,16
    80005cc6:	8082                	ret

0000000080005cc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cc8:	1141                	addi	sp,sp,-16
    80005cca:	e406                	sd	ra,8(sp)
    80005ccc:	e022                	sd	s0,0(sp)
    80005cce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	ce6080e7          	jalr	-794(ra) # 800019b6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cd8:	00d5179b          	slliw	a5,a0,0xd
    80005cdc:	0c201537          	lui	a0,0xc201
    80005ce0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ce2:	4148                	lw	a0,4(a0)
    80005ce4:	60a2                	ld	ra,8(sp)
    80005ce6:	6402                	ld	s0,0(sp)
    80005ce8:	0141                	addi	sp,sp,16
    80005cea:	8082                	ret

0000000080005cec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cec:	1101                	addi	sp,sp,-32
    80005cee:	ec06                	sd	ra,24(sp)
    80005cf0:	e822                	sd	s0,16(sp)
    80005cf2:	e426                	sd	s1,8(sp)
    80005cf4:	1000                	addi	s0,sp,32
    80005cf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	cbe080e7          	jalr	-834(ra) # 800019b6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d00:	00d5151b          	slliw	a0,a0,0xd
    80005d04:	0c2017b7          	lui	a5,0xc201
    80005d08:	97aa                	add	a5,a5,a0
    80005d0a:	c3c4                	sw	s1,4(a5)
}
    80005d0c:	60e2                	ld	ra,24(sp)
    80005d0e:	6442                	ld	s0,16(sp)
    80005d10:	64a2                	ld	s1,8(sp)
    80005d12:	6105                	addi	sp,sp,32
    80005d14:	8082                	ret

0000000080005d16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d16:	1141                	addi	sp,sp,-16
    80005d18:	e406                	sd	ra,8(sp)
    80005d1a:	e022                	sd	s0,0(sp)
    80005d1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d1e:	479d                	li	a5,7
    80005d20:	04a7cc63          	blt	a5,a0,80005d78 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d24:	0001d797          	auipc	a5,0x1d
    80005d28:	87c78793          	addi	a5,a5,-1924 # 800225a0 <disk>
    80005d2c:	97aa                	add	a5,a5,a0
    80005d2e:	0187c783          	lbu	a5,24(a5)
    80005d32:	ebb9                	bnez	a5,80005d88 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d34:	00451613          	slli	a2,a0,0x4
    80005d38:	0001d797          	auipc	a5,0x1d
    80005d3c:	86878793          	addi	a5,a5,-1944 # 800225a0 <disk>
    80005d40:	6394                	ld	a3,0(a5)
    80005d42:	96b2                	add	a3,a3,a2
    80005d44:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d48:	6398                	ld	a4,0(a5)
    80005d4a:	9732                	add	a4,a4,a2
    80005d4c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d50:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d54:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d58:	953e                	add	a0,a0,a5
    80005d5a:	4785                	li	a5,1
    80005d5c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005d60:	0001d517          	auipc	a0,0x1d
    80005d64:	85850513          	addi	a0,a0,-1960 # 800225b8 <disk+0x18>
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	3ec080e7          	jalr	1004(ra) # 80002154 <wakeup>
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret
    panic("free_desc 1");
    80005d78:	00003517          	auipc	a0,0x3
    80005d7c:	9f850513          	addi	a0,a0,-1544 # 80008770 <syscalls+0x300>
    80005d80:	ffffa097          	auipc	ra,0xffffa
    80005d84:	7be080e7          	jalr	1982(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d88:	00003517          	auipc	a0,0x3
    80005d8c:	9f850513          	addi	a0,a0,-1544 # 80008780 <syscalls+0x310>
    80005d90:	ffffa097          	auipc	ra,0xffffa
    80005d94:	7ae080e7          	jalr	1966(ra) # 8000053e <panic>

0000000080005d98 <virtio_disk_init>:
{
    80005d98:	1101                	addi	sp,sp,-32
    80005d9a:	ec06                	sd	ra,24(sp)
    80005d9c:	e822                	sd	s0,16(sp)
    80005d9e:	e426                	sd	s1,8(sp)
    80005da0:	e04a                	sd	s2,0(sp)
    80005da2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005da4:	00003597          	auipc	a1,0x3
    80005da8:	9ec58593          	addi	a1,a1,-1556 # 80008790 <syscalls+0x320>
    80005dac:	0001d517          	auipc	a0,0x1d
    80005db0:	91c50513          	addi	a0,a0,-1764 # 800226c8 <disk+0x128>
    80005db4:	ffffb097          	auipc	ra,0xffffb
    80005db8:	d92080e7          	jalr	-622(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dbc:	100017b7          	lui	a5,0x10001
    80005dc0:	4398                	lw	a4,0(a5)
    80005dc2:	2701                	sext.w	a4,a4
    80005dc4:	747277b7          	lui	a5,0x74727
    80005dc8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dcc:	14f71c63          	bne	a4,a5,80005f24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005dd0:	100017b7          	lui	a5,0x10001
    80005dd4:	43dc                	lw	a5,4(a5)
    80005dd6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd8:	4709                	li	a4,2
    80005dda:	14e79563          	bne	a5,a4,80005f24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dde:	100017b7          	lui	a5,0x10001
    80005de2:	479c                	lw	a5,8(a5)
    80005de4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005de6:	12e79f63          	bne	a5,a4,80005f24 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dea:	100017b7          	lui	a5,0x10001
    80005dee:	47d8                	lw	a4,12(a5)
    80005df0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005df2:	554d47b7          	lui	a5,0x554d4
    80005df6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dfa:	12f71563          	bne	a4,a5,80005f24 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dfe:	100017b7          	lui	a5,0x10001
    80005e02:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e06:	4705                	li	a4,1
    80005e08:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e0a:	470d                	li	a4,3
    80005e0c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e0e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e10:	c7ffe737          	lui	a4,0xc7ffe
    80005e14:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9067>
    80005e18:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e1a:	2701                	sext.w	a4,a4
    80005e1c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e1e:	472d                	li	a4,11
    80005e20:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e22:	5bbc                	lw	a5,112(a5)
    80005e24:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e28:	8ba1                	andi	a5,a5,8
    80005e2a:	10078563          	beqz	a5,80005f34 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e36:	43fc                	lw	a5,68(a5)
    80005e38:	2781                	sext.w	a5,a5
    80005e3a:	10079563          	bnez	a5,80005f44 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	5bdc                	lw	a5,52(a5)
    80005e44:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e46:	10078763          	beqz	a5,80005f54 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005e4a:	471d                	li	a4,7
    80005e4c:	10f77c63          	bgeu	a4,a5,80005f64 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005e50:	ffffb097          	auipc	ra,0xffffb
    80005e54:	c96080e7          	jalr	-874(ra) # 80000ae6 <kalloc>
    80005e58:	0001c497          	auipc	s1,0x1c
    80005e5c:	74848493          	addi	s1,s1,1864 # 800225a0 <disk>
    80005e60:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	c84080e7          	jalr	-892(ra) # 80000ae6 <kalloc>
    80005e6a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	c7a080e7          	jalr	-902(ra) # 80000ae6 <kalloc>
    80005e74:	87aa                	mv	a5,a0
    80005e76:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e78:	6088                	ld	a0,0(s1)
    80005e7a:	cd6d                	beqz	a0,80005f74 <virtio_disk_init+0x1dc>
    80005e7c:	0001c717          	auipc	a4,0x1c
    80005e80:	72c73703          	ld	a4,1836(a4) # 800225a8 <disk+0x8>
    80005e84:	cb65                	beqz	a4,80005f74 <virtio_disk_init+0x1dc>
    80005e86:	c7fd                	beqz	a5,80005f74 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80005e88:	6605                	lui	a2,0x1
    80005e8a:	4581                	li	a1,0
    80005e8c:	ffffb097          	auipc	ra,0xffffb
    80005e90:	e46080e7          	jalr	-442(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e94:	0001c497          	auipc	s1,0x1c
    80005e98:	70c48493          	addi	s1,s1,1804 # 800225a0 <disk>
    80005e9c:	6605                	lui	a2,0x1
    80005e9e:	4581                	li	a1,0
    80005ea0:	6488                	ld	a0,8(s1)
    80005ea2:	ffffb097          	auipc	ra,0xffffb
    80005ea6:	e30080e7          	jalr	-464(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005eaa:	6605                	lui	a2,0x1
    80005eac:	4581                	li	a1,0
    80005eae:	6888                	ld	a0,16(s1)
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	e22080e7          	jalr	-478(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005eb8:	100017b7          	lui	a5,0x10001
    80005ebc:	4721                	li	a4,8
    80005ebe:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005ec0:	4098                	lw	a4,0(s1)
    80005ec2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005ec6:	40d8                	lw	a4,4(s1)
    80005ec8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005ecc:	6498                	ld	a4,8(s1)
    80005ece:	0007069b          	sext.w	a3,a4
    80005ed2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005ed6:	9701                	srai	a4,a4,0x20
    80005ed8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005edc:	6898                	ld	a4,16(s1)
    80005ede:	0007069b          	sext.w	a3,a4
    80005ee2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005ee6:	9701                	srai	a4,a4,0x20
    80005ee8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005eec:	4705                	li	a4,1
    80005eee:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005ef0:	00e48c23          	sb	a4,24(s1)
    80005ef4:	00e48ca3          	sb	a4,25(s1)
    80005ef8:	00e48d23          	sb	a4,26(s1)
    80005efc:	00e48da3          	sb	a4,27(s1)
    80005f00:	00e48e23          	sb	a4,28(s1)
    80005f04:	00e48ea3          	sb	a4,29(s1)
    80005f08:	00e48f23          	sb	a4,30(s1)
    80005f0c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f10:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f14:	0727a823          	sw	s2,112(a5)
}
    80005f18:	60e2                	ld	ra,24(sp)
    80005f1a:	6442                	ld	s0,16(sp)
    80005f1c:	64a2                	ld	s1,8(sp)
    80005f1e:	6902                	ld	s2,0(sp)
    80005f20:	6105                	addi	sp,sp,32
    80005f22:	8082                	ret
    panic("could not find virtio disk");
    80005f24:	00003517          	auipc	a0,0x3
    80005f28:	87c50513          	addi	a0,a0,-1924 # 800087a0 <syscalls+0x330>
    80005f2c:	ffffa097          	auipc	ra,0xffffa
    80005f30:	612080e7          	jalr	1554(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f34:	00003517          	auipc	a0,0x3
    80005f38:	88c50513          	addi	a0,a0,-1908 # 800087c0 <syscalls+0x350>
    80005f3c:	ffffa097          	auipc	ra,0xffffa
    80005f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80005f44:	00003517          	auipc	a0,0x3
    80005f48:	89c50513          	addi	a0,a0,-1892 # 800087e0 <syscalls+0x370>
    80005f4c:	ffffa097          	auipc	ra,0xffffa
    80005f50:	5f2080e7          	jalr	1522(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f54:	00003517          	auipc	a0,0x3
    80005f58:	8ac50513          	addi	a0,a0,-1876 # 80008800 <syscalls+0x390>
    80005f5c:	ffffa097          	auipc	ra,0xffffa
    80005f60:	5e2080e7          	jalr	1506(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f64:	00003517          	auipc	a0,0x3
    80005f68:	8bc50513          	addi	a0,a0,-1860 # 80008820 <syscalls+0x3b0>
    80005f6c:	ffffa097          	auipc	ra,0xffffa
    80005f70:	5d2080e7          	jalr	1490(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80005f74:	00003517          	auipc	a0,0x3
    80005f78:	8cc50513          	addi	a0,a0,-1844 # 80008840 <syscalls+0x3d0>
    80005f7c:	ffffa097          	auipc	ra,0xffffa
    80005f80:	5c2080e7          	jalr	1474(ra) # 8000053e <panic>

0000000080005f84 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f84:	7119                	addi	sp,sp,-128
    80005f86:	fc86                	sd	ra,120(sp)
    80005f88:	f8a2                	sd	s0,112(sp)
    80005f8a:	f4a6                	sd	s1,104(sp)
    80005f8c:	f0ca                	sd	s2,96(sp)
    80005f8e:	ecce                	sd	s3,88(sp)
    80005f90:	e8d2                	sd	s4,80(sp)
    80005f92:	e4d6                	sd	s5,72(sp)
    80005f94:	e0da                	sd	s6,64(sp)
    80005f96:	fc5e                	sd	s7,56(sp)
    80005f98:	f862                	sd	s8,48(sp)
    80005f9a:	f466                	sd	s9,40(sp)
    80005f9c:	f06a                	sd	s10,32(sp)
    80005f9e:	ec6e                	sd	s11,24(sp)
    80005fa0:	0100                	addi	s0,sp,128
    80005fa2:	8aaa                	mv	s5,a0
    80005fa4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fa6:	00c52d03          	lw	s10,12(a0)
    80005faa:	001d1d1b          	slliw	s10,s10,0x1
    80005fae:	1d02                	slli	s10,s10,0x20
    80005fb0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005fb4:	0001c517          	auipc	a0,0x1c
    80005fb8:	71450513          	addi	a0,a0,1812 # 800226c8 <disk+0x128>
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	c1a080e7          	jalr	-998(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005fc4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fc6:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fc8:	0001cb97          	auipc	s7,0x1c
    80005fcc:	5d8b8b93          	addi	s7,s7,1496 # 800225a0 <disk>
  for(int i = 0; i < 3; i++){
    80005fd0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fd2:	0001cc97          	auipc	s9,0x1c
    80005fd6:	6f6c8c93          	addi	s9,s9,1782 # 800226c8 <disk+0x128>
    80005fda:	a08d                	j	8000603c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005fdc:	00fb8733          	add	a4,s7,a5
    80005fe0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fe4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fe6:	0207c563          	bltz	a5,80006010 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005fea:	2905                	addiw	s2,s2,1
    80005fec:	0611                	addi	a2,a2,4
    80005fee:	05690c63          	beq	s2,s6,80006046 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005ff2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005ff4:	0001c717          	auipc	a4,0x1c
    80005ff8:	5ac70713          	addi	a4,a4,1452 # 800225a0 <disk>
    80005ffc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ffe:	01874683          	lbu	a3,24(a4)
    80006002:	fee9                	bnez	a3,80005fdc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006004:	2785                	addiw	a5,a5,1
    80006006:	0705                	addi	a4,a4,1
    80006008:	fe979be3          	bne	a5,s1,80005ffe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000600c:	57fd                	li	a5,-1
    8000600e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006010:	01205d63          	blez	s2,8000602a <virtio_disk_rw+0xa6>
    80006014:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006016:	000a2503          	lw	a0,0(s4)
    8000601a:	00000097          	auipc	ra,0x0
    8000601e:	cfc080e7          	jalr	-772(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80006022:	2d85                	addiw	s11,s11,1
    80006024:	0a11                	addi	s4,s4,4
    80006026:	ffb918e3          	bne	s2,s11,80006016 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000602a:	85e6                	mv	a1,s9
    8000602c:	0001c517          	auipc	a0,0x1c
    80006030:	58c50513          	addi	a0,a0,1420 # 800225b8 <disk+0x18>
    80006034:	ffffc097          	auipc	ra,0xffffc
    80006038:	0bc080e7          	jalr	188(ra) # 800020f0 <sleep>
  for(int i = 0; i < 3; i++){
    8000603c:	f8040a13          	addi	s4,s0,-128
{
    80006040:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006042:	894e                	mv	s2,s3
    80006044:	b77d                	j	80005ff2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006046:	f8042583          	lw	a1,-128(s0)
    8000604a:	00a58793          	addi	a5,a1,10
    8000604e:	0792                	slli	a5,a5,0x4

  if(write)
    80006050:	0001c617          	auipc	a2,0x1c
    80006054:	55060613          	addi	a2,a2,1360 # 800225a0 <disk>
    80006058:	00f60733          	add	a4,a2,a5
    8000605c:	018036b3          	snez	a3,s8
    80006060:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006062:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006066:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000606a:	f6078693          	addi	a3,a5,-160
    8000606e:	6218                	ld	a4,0(a2)
    80006070:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006072:	00878513          	addi	a0,a5,8
    80006076:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006078:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000607a:	6208                	ld	a0,0(a2)
    8000607c:	96aa                	add	a3,a3,a0
    8000607e:	4741                	li	a4,16
    80006080:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006082:	4705                	li	a4,1
    80006084:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006088:	f8442703          	lw	a4,-124(s0)
    8000608c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006090:	0712                	slli	a4,a4,0x4
    80006092:	953a                	add	a0,a0,a4
    80006094:	058a8693          	addi	a3,s5,88
    80006098:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000609a:	6208                	ld	a0,0(a2)
    8000609c:	972a                	add	a4,a4,a0
    8000609e:	40000693          	li	a3,1024
    800060a2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060a4:	001c3c13          	seqz	s8,s8
    800060a8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060aa:	001c6c13          	ori	s8,s8,1
    800060ae:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800060b2:	f8842603          	lw	a2,-120(s0)
    800060b6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060ba:	0001c697          	auipc	a3,0x1c
    800060be:	4e668693          	addi	a3,a3,1254 # 800225a0 <disk>
    800060c2:	00258713          	addi	a4,a1,2
    800060c6:	0712                	slli	a4,a4,0x4
    800060c8:	9736                	add	a4,a4,a3
    800060ca:	587d                	li	a6,-1
    800060cc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060d0:	0612                	slli	a2,a2,0x4
    800060d2:	9532                	add	a0,a0,a2
    800060d4:	f9078793          	addi	a5,a5,-112
    800060d8:	97b6                	add	a5,a5,a3
    800060da:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800060dc:	629c                	ld	a5,0(a3)
    800060de:	97b2                	add	a5,a5,a2
    800060e0:	4605                	li	a2,1
    800060e2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060e4:	4509                	li	a0,2
    800060e6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800060ea:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060ee:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800060f2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060f6:	6698                	ld	a4,8(a3)
    800060f8:	00275783          	lhu	a5,2(a4)
    800060fc:	8b9d                	andi	a5,a5,7
    800060fe:	0786                	slli	a5,a5,0x1
    80006100:	97ba                	add	a5,a5,a4
    80006102:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006106:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000610a:	6698                	ld	a4,8(a3)
    8000610c:	00275783          	lhu	a5,2(a4)
    80006110:	2785                	addiw	a5,a5,1
    80006112:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006116:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000611a:	100017b7          	lui	a5,0x10001
    8000611e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006122:	004aa783          	lw	a5,4(s5)
    80006126:	02c79163          	bne	a5,a2,80006148 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000612a:	0001c917          	auipc	s2,0x1c
    8000612e:	59e90913          	addi	s2,s2,1438 # 800226c8 <disk+0x128>
  while(b->disk == 1) {
    80006132:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006134:	85ca                	mv	a1,s2
    80006136:	8556                	mv	a0,s5
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	fb8080e7          	jalr	-72(ra) # 800020f0 <sleep>
  while(b->disk == 1) {
    80006140:	004aa783          	lw	a5,4(s5)
    80006144:	fe9788e3          	beq	a5,s1,80006134 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006148:	f8042903          	lw	s2,-128(s0)
    8000614c:	00290793          	addi	a5,s2,2
    80006150:	00479713          	slli	a4,a5,0x4
    80006154:	0001c797          	auipc	a5,0x1c
    80006158:	44c78793          	addi	a5,a5,1100 # 800225a0 <disk>
    8000615c:	97ba                	add	a5,a5,a4
    8000615e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006162:	0001c997          	auipc	s3,0x1c
    80006166:	43e98993          	addi	s3,s3,1086 # 800225a0 <disk>
    8000616a:	00491713          	slli	a4,s2,0x4
    8000616e:	0009b783          	ld	a5,0(s3)
    80006172:	97ba                	add	a5,a5,a4
    80006174:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006178:	854a                	mv	a0,s2
    8000617a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000617e:	00000097          	auipc	ra,0x0
    80006182:	b98080e7          	jalr	-1128(ra) # 80005d16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006186:	8885                	andi	s1,s1,1
    80006188:	f0ed                	bnez	s1,8000616a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000618a:	0001c517          	auipc	a0,0x1c
    8000618e:	53e50513          	addi	a0,a0,1342 # 800226c8 <disk+0x128>
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	af8080e7          	jalr	-1288(ra) # 80000c8a <release>
}
    8000619a:	70e6                	ld	ra,120(sp)
    8000619c:	7446                	ld	s0,112(sp)
    8000619e:	74a6                	ld	s1,104(sp)
    800061a0:	7906                	ld	s2,96(sp)
    800061a2:	69e6                	ld	s3,88(sp)
    800061a4:	6a46                	ld	s4,80(sp)
    800061a6:	6aa6                	ld	s5,72(sp)
    800061a8:	6b06                	ld	s6,64(sp)
    800061aa:	7be2                	ld	s7,56(sp)
    800061ac:	7c42                	ld	s8,48(sp)
    800061ae:	7ca2                	ld	s9,40(sp)
    800061b0:	7d02                	ld	s10,32(sp)
    800061b2:	6de2                	ld	s11,24(sp)
    800061b4:	6109                	addi	sp,sp,128
    800061b6:	8082                	ret

00000000800061b8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061b8:	1101                	addi	sp,sp,-32
    800061ba:	ec06                	sd	ra,24(sp)
    800061bc:	e822                	sd	s0,16(sp)
    800061be:	e426                	sd	s1,8(sp)
    800061c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061c2:	0001c497          	auipc	s1,0x1c
    800061c6:	3de48493          	addi	s1,s1,990 # 800225a0 <disk>
    800061ca:	0001c517          	auipc	a0,0x1c
    800061ce:	4fe50513          	addi	a0,a0,1278 # 800226c8 <disk+0x128>
    800061d2:	ffffb097          	auipc	ra,0xffffb
    800061d6:	a04080e7          	jalr	-1532(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061da:	10001737          	lui	a4,0x10001
    800061de:	533c                	lw	a5,96(a4)
    800061e0:	8b8d                	andi	a5,a5,3
    800061e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061e8:	689c                	ld	a5,16(s1)
    800061ea:	0204d703          	lhu	a4,32(s1)
    800061ee:	0027d783          	lhu	a5,2(a5)
    800061f2:	04f70863          	beq	a4,a5,80006242 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800061f6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061fa:	6898                	ld	a4,16(s1)
    800061fc:	0204d783          	lhu	a5,32(s1)
    80006200:	8b9d                	andi	a5,a5,7
    80006202:	078e                	slli	a5,a5,0x3
    80006204:	97ba                	add	a5,a5,a4
    80006206:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006208:	00278713          	addi	a4,a5,2
    8000620c:	0712                	slli	a4,a4,0x4
    8000620e:	9726                	add	a4,a4,s1
    80006210:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006214:	e721                	bnez	a4,8000625c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006216:	0789                	addi	a5,a5,2
    80006218:	0792                	slli	a5,a5,0x4
    8000621a:	97a6                	add	a5,a5,s1
    8000621c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000621e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006222:	ffffc097          	auipc	ra,0xffffc
    80006226:	f32080e7          	jalr	-206(ra) # 80002154 <wakeup>

    disk.used_idx += 1;
    8000622a:	0204d783          	lhu	a5,32(s1)
    8000622e:	2785                	addiw	a5,a5,1
    80006230:	17c2                	slli	a5,a5,0x30
    80006232:	93c1                	srli	a5,a5,0x30
    80006234:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006238:	6898                	ld	a4,16(s1)
    8000623a:	00275703          	lhu	a4,2(a4)
    8000623e:	faf71ce3          	bne	a4,a5,800061f6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006242:	0001c517          	auipc	a0,0x1c
    80006246:	48650513          	addi	a0,a0,1158 # 800226c8 <disk+0x128>
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	a40080e7          	jalr	-1472(ra) # 80000c8a <release>
}
    80006252:	60e2                	ld	ra,24(sp)
    80006254:	6442                	ld	s0,16(sp)
    80006256:	64a2                	ld	s1,8(sp)
    80006258:	6105                	addi	sp,sp,32
    8000625a:	8082                	ret
      panic("virtio_disk_intr status");
    8000625c:	00002517          	auipc	a0,0x2
    80006260:	5fc50513          	addi	a0,a0,1532 # 80008858 <syscalls+0x3e8>
    80006264:	ffffa097          	auipc	ra,0xffffa
    80006268:	2da080e7          	jalr	730(ra) # 8000053e <panic>

000000008000626c <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    8000626c:	1141                	addi	sp,sp,-16
    8000626e:	e422                	sd	s0,8(sp)
    80006270:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    80006272:	0001c717          	auipc	a4,0x1c
    80006276:	46e70713          	addi	a4,a4,1134 # 800226e0 <gq>
    8000627a:	00451693          	slli	a3,a0,0x4
    8000627e:	631c                	ld	a5,0(a4)
    80006280:	97b6                	add	a5,a5,a3
    80006282:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    80006286:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    8000628a:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    8000628e:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    80006292:	972a                	add	a4,a4,a0
    80006294:	4785                	li	a5,1
    80006296:	00f70c23          	sb	a5,24(a4)
}
    8000629a:	6422                	ld	s0,8(sp)
    8000629c:	0141                	addi	sp,sp,16
    8000629e:	8082                	ret

00000000800062a0 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    800062a0:	0001c797          	auipc	a5,0x1c
    800062a4:	44078793          	addi	a5,a5,1088 # 800226e0 <gq>
    800062a8:	4501                	li	a0,0
    800062aa:	46a1                	li	a3,8
        if (gq.free[i])
    800062ac:	0187c703          	lbu	a4,24(a5)
    800062b0:	e30d                	bnez	a4,800062d2 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    800062b2:	2505                	addiw	a0,a0,1
    800062b4:	0785                	addi	a5,a5,1
    800062b6:	fed51be3          	bne	a0,a3,800062ac <alloc_desc+0xc>
{
    800062ba:	1141                	addi	sp,sp,-16
    800062bc:	e406                	sd	ra,8(sp)
    800062be:	e022                	sd	s0,0(sp)
    800062c0:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	5ae50513          	addi	a0,a0,1454 # 80008870 <syscalls+0x400>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	274080e7          	jalr	628(ra) # 8000053e <panic>
            gq.free[i] = 0;
    800062d2:	0001c797          	auipc	a5,0x1c
    800062d6:	40e78793          	addi	a5,a5,1038 # 800226e0 <gq>
    800062da:	97aa                	add	a5,a5,a0
    800062dc:	00078c23          	sb	zero,24(a5)
}
    800062e0:	8082                	ret

00000000800062e2 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    800062e2:	7139                	addi	sp,sp,-64
    800062e4:	fc06                	sd	ra,56(sp)
    800062e6:	f822                	sd	s0,48(sp)
    800062e8:	f426                	sd	s1,40(sp)
    800062ea:	f04a                	sd	s2,32(sp)
    800062ec:	ec4e                	sd	s3,24(sp)
    800062ee:	e852                	sd	s4,16(sp)
    800062f0:	e456                	sd	s5,8(sp)
    800062f2:	0080                	addi	s0,sp,64
    800062f4:	8aaa                	mv	s5,a0
    800062f6:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    800062f8:	0001c997          	auipc	s3,0x1c
    800062fc:	3e898993          	addi	s3,s3,1000 # 800226e0 <gq>
    80006300:	0001c517          	auipc	a0,0x1c
    80006304:	40850513          	addi	a0,a0,1032 # 80022708 <gpu_lock>
    80006308:	ffffb097          	auipc	ra,0xffffb
    8000630c:	8ce080e7          	jalr	-1842(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    80006310:	00000097          	auipc	ra,0x0
    80006314:	f90080e7          	jalr	-112(ra) # 800062a0 <alloc_desc>
    80006318:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    8000631a:	00000097          	auipc	ra,0x0
    8000631e:	f86080e7          	jalr	-122(ra) # 800062a0 <alloc_desc>
    80006322:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    80006324:	00491793          	slli	a5,s2,0x4
    80006328:	0009b703          	ld	a4,0(s3)
    8000632c:	973e                	add	a4,a4,a5
    8000632e:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    80006332:	0009b703          	ld	a4,0(s3)
    80006336:	97ba                	add	a5,a5,a4
    80006338:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    8000633c:	4685                	li	a3,1
    8000633e:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    80006342:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    80006346:	00451693          	slli	a3,a0,0x4
    8000634a:	9736                	add	a4,a4,a3
    8000634c:	0001c797          	auipc	a5,0x1c
    80006350:	3d478793          	addi	a5,a5,980 # 80022720 <cmd_resp>
    80006354:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    80006356:	0009b783          	ld	a5,0(s3)
    8000635a:	97b6                	add	a5,a5,a3
    8000635c:	4761                	li	a4,24
    8000635e:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    80006360:	4709                	li	a4,2
    80006362:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    80006366:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    8000636a:	0089b703          	ld	a4,8(s3)
    8000636e:	00275783          	lhu	a5,2(a4)
    80006372:	8b9d                	andi	a5,a5,7
    80006374:	0786                	slli	a5,a5,0x1
    80006376:	97ba                	add	a5,a5,a4
    80006378:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    8000637c:	0ff0000f          	fence
    gq.avail->idx++;
    80006380:	0089b703          	ld	a4,8(s3)
    80006384:	00275783          	lhu	a5,2(a4)
    80006388:	2785                	addiw	a5,a5,1
    8000638a:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    8000638e:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006392:	100027b7          	lui	a5,0x10002
    80006396:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    8000639a:	874e                	mv	a4,s3
        __sync_synchronize();
    8000639c:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    800063a0:	02075783          	lhu	a5,32(a4)
    800063a4:	6b14                	ld	a3,16(a4)
    800063a6:	0026d683          	lhu	a3,2(a3)
    800063aa:	fef689e3          	beq	a3,a5,8000639c <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    800063ae:	2785                	addiw	a5,a5,1
    800063b0:	0001c717          	auipc	a4,0x1c
    800063b4:	34f71823          	sh	a5,848(a4) # 80022700 <gq+0x20>

    free_desc(d0);
    800063b8:	854a                	mv	a0,s2
    800063ba:	00000097          	auipc	ra,0x0
    800063be:	eb2080e7          	jalr	-334(ra) # 8000626c <free_desc>
    free_desc(d1);
    800063c2:	8526                	mv	a0,s1
    800063c4:	00000097          	auipc	ra,0x0
    800063c8:	ea8080e7          	jalr	-344(ra) # 8000626c <free_desc>
    release(&gpu_lock);
    800063cc:	0001c517          	auipc	a0,0x1c
    800063d0:	33c50513          	addi	a0,a0,828 # 80022708 <gpu_lock>
    800063d4:	ffffb097          	auipc	ra,0xffffb
    800063d8:	8b6080e7          	jalr	-1866(ra) # 80000c8a <release>
}
    800063dc:	70e2                	ld	ra,56(sp)
    800063de:	7442                	ld	s0,48(sp)
    800063e0:	74a2                	ld	s1,40(sp)
    800063e2:	7902                	ld	s2,32(sp)
    800063e4:	69e2                	ld	s3,24(sp)
    800063e6:	6a42                	ld	s4,16(sp)
    800063e8:	6aa2                	ld	s5,8(sp)
    800063ea:	6121                	addi	sp,sp,64
    800063ec:	8082                	ret

00000000800063ee <gpu_transfer_flush>:
{
    800063ee:	7139                	addi	sp,sp,-64
    800063f0:	fc06                	sd	ra,56(sp)
    800063f2:	f822                	sd	s0,48(sp)
    800063f4:	f426                	sd	s1,40(sp)
    800063f6:	f04a                	sd	s2,32(sp)
    800063f8:	ec4e                	sd	s3,24(sp)
    800063fa:	e852                	sd	s4,16(sp)
    800063fc:	e456                	sd	s5,8(sp)
    800063fe:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    80006400:	0001c497          	auipc	s1,0x1c
    80006404:	2e048493          	addi	s1,s1,736 # 800226e0 <gq>
    80006408:	0001c917          	auipc	s2,0x1c
    8000640c:	33090913          	addi	s2,s2,816 # 80022738 <xfer.1>
    80006410:	03800613          	li	a2,56
    80006414:	4581                	li	a1,0
    80006416:	854a                	mv	a0,s2
    80006418:	ffffb097          	auipc	ra,0xffffb
    8000641c:	8ba080e7          	jalr	-1862(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    80006420:	10500793          	li	a5,261
    80006424:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    80006426:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    8000642a:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    8000642e:	28000a93          	li	s5,640
    80006432:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006436:	1e000a13          	li	s4,480
    8000643a:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    8000643e:	4985                	li	s3,1
    80006440:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    80006444:	03800593          	li	a1,56
    80006448:	854a                	mv	a0,s2
    8000644a:	00000097          	auipc	ra,0x0
    8000644e:	e98080e7          	jalr	-360(ra) # 800062e2 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    80006452:	0001c917          	auipc	s2,0x1c
    80006456:	31e90913          	addi	s2,s2,798 # 80022770 <flush.0>
    8000645a:	03000613          	li	a2,48
    8000645e:	4581                	li	a1,0
    80006460:	854a                	mv	a0,s2
    80006462:	ffffb097          	auipc	ra,0xffffb
    80006466:	870080e7          	jalr	-1936(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    8000646a:	10400793          	li	a5,260
    8000646e:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    80006472:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    80006476:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    8000647a:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    8000647e:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    80006482:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    80006486:	03000593          	li	a1,48
    8000648a:	854a                	mv	a0,s2
    8000648c:	00000097          	auipc	ra,0x0
    80006490:	e56080e7          	jalr	-426(ra) # 800062e2 <gpu_send>
}
    80006494:	70e2                	ld	ra,56(sp)
    80006496:	7442                	ld	s0,48(sp)
    80006498:	74a2                	ld	s1,40(sp)
    8000649a:	7902                	ld	s2,32(sp)
    8000649c:	69e2                	ld	s3,24(sp)
    8000649e:	6a42                	ld	s4,16(sp)
    800064a0:	6aa2                	ld	s5,8(sp)
    800064a2:	6121                	addi	sp,sp,64
    800064a4:	8082                	ret

00000000800064a6 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    800064a6:	7159                	addi	sp,sp,-112
    800064a8:	f486                	sd	ra,104(sp)
    800064aa:	f0a2                	sd	s0,96(sp)
    800064ac:	eca6                	sd	s1,88(sp)
    800064ae:	e8ca                	sd	s2,80(sp)
    800064b0:	e4ce                	sd	s3,72(sp)
    800064b2:	e0d2                	sd	s4,64(sp)
    800064b4:	fc56                	sd	s5,56(sp)
    800064b6:	f85a                	sd	s6,48(sp)
    800064b8:	f45e                	sd	s7,40(sp)
    800064ba:	f062                	sd	s8,32(sp)
    800064bc:	ec66                	sd	s9,24(sp)
    800064be:	e86a                	sd	s10,16(sp)
    800064c0:	e46e                	sd	s11,8(sp)
    800064c2:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    800064c4:	00002597          	auipc	a1,0x2
    800064c8:	3cc58593          	addi	a1,a1,972 # 80008890 <syscalls+0x420>
    800064cc:	0001c517          	auipc	a0,0x1c
    800064d0:	23c50513          	addi	a0,a0,572 # 80022708 <gpu_lock>
    800064d4:	ffffa097          	auipc	ra,0xffffa
    800064d8:	672080e7          	jalr	1650(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064dc:	100027b7          	lui	a5,0x10002
    800064e0:	4398                	lw	a4,0(a5)
    800064e2:	2701                	sext.w	a4,a4
    800064e4:	747277b7          	lui	a5,0x74727
    800064e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064ec:	02f71a63          	bne	a4,a5,80006520 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    800064f0:	100027b7          	lui	a5,0x10002
    800064f4:	43dc                	lw	a5,4(a5)
    800064f6:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064f8:	4709                	li	a4,2
    800064fa:	02e79363          	bne	a5,a4,80006520 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    800064fe:	100027b7          	lui	a5,0x10002
    80006502:	479c                	lw	a5,8(a5)
    80006504:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    80006506:	4741                	li	a4,16
    80006508:	00e79c63          	bne	a5,a4,80006520 <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    8000650c:	100027b7          	lui	a5,0x10002
    80006510:	47d8                	lw	a4,12(a5)
    80006512:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    80006514:	554d47b7          	lui	a5,0x554d4
    80006518:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000651c:	02f70963          	beq	a4,a5,8000654e <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    80006520:	00002517          	auipc	a0,0x2
    80006524:	37850513          	addi	a0,a0,888 # 80008898 <syscalls+0x428>
    80006528:	ffffa097          	auipc	ra,0xffffa
    8000652c:	060080e7          	jalr	96(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    80006530:	70a6                	ld	ra,104(sp)
    80006532:	7406                	ld	s0,96(sp)
    80006534:	64e6                	ld	s1,88(sp)
    80006536:	6946                	ld	s2,80(sp)
    80006538:	69a6                	ld	s3,72(sp)
    8000653a:	6a06                	ld	s4,64(sp)
    8000653c:	7ae2                	ld	s5,56(sp)
    8000653e:	7b42                	ld	s6,48(sp)
    80006540:	7ba2                	ld	s7,40(sp)
    80006542:	7c02                	ld	s8,32(sp)
    80006544:	6ce2                	ld	s9,24(sp)
    80006546:	6d42                	ld	s10,16(sp)
    80006548:	6da2                	ld	s11,8(sp)
    8000654a:	6165                	addi	sp,sp,112
    8000654c:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000654e:	100027b7          	lui	a5,0x10002
    80006552:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006556:	4705                	li	a4,1
    80006558:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000655a:	470d                	li	a4,3
    8000655c:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    8000655e:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006562:	472d                	li	a4,11
    80006564:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    80006566:	5bbc                	lw	a5,112(a5)
    80006568:	8ba1                	andi	a5,a5,8
    8000656a:	22078363          	beqz	a5,80006790 <virtio_gpu_init+0x2ea>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000656e:	100027b7          	lui	a5,0x10002
    80006572:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    80006576:	43fc                	lw	a5,68(a5)
    80006578:	2781                	sext.w	a5,a5
    8000657a:	22079363          	bnez	a5,800067a0 <virtio_gpu_init+0x2fa>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    8000657e:	100027b7          	lui	a5,0x10002
    80006582:	5bdc                	lw	a5,52(a5)
    80006584:	2781                	sext.w	a5,a5
    80006586:	471d                	li	a4,7
    80006588:	22f77463          	bgeu	a4,a5,800067b0 <virtio_gpu_init+0x30a>
    gq.desc = kalloc();
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	55a080e7          	jalr	1370(ra) # 80000ae6 <kalloc>
    80006594:	0001c497          	auipc	s1,0x1c
    80006598:	14c48493          	addi	s1,s1,332 # 800226e0 <gq>
    8000659c:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	548080e7          	jalr	1352(ra) # 80000ae6 <kalloc>
    800065a6:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    800065a8:	ffffa097          	auipc	ra,0xffffa
    800065ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800065b0:	87aa                	mv	a5,a0
    800065b2:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    800065b4:	6088                	ld	a0,0(s1)
    800065b6:	20050563          	beqz	a0,800067c0 <virtio_gpu_init+0x31a>
    800065ba:	0001c717          	auipc	a4,0x1c
    800065be:	12e73703          	ld	a4,302(a4) # 800226e8 <gq+0x8>
    800065c2:	1e070f63          	beqz	a4,800067c0 <virtio_gpu_init+0x31a>
    800065c6:	1e078d63          	beqz	a5,800067c0 <virtio_gpu_init+0x31a>
    memset(gq.desc, 0, PGSIZE);
    800065ca:	6605                	lui	a2,0x1
    800065cc:	4581                	li	a1,0
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	704080e7          	jalr	1796(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    800065d6:	0001c497          	auipc	s1,0x1c
    800065da:	10a48493          	addi	s1,s1,266 # 800226e0 <gq>
    800065de:	6605                	lui	a2,0x1
    800065e0:	4581                	li	a1,0
    800065e2:	6488                	ld	a0,8(s1)
    800065e4:	ffffa097          	auipc	ra,0xffffa
    800065e8:	6ee080e7          	jalr	1774(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    800065ec:	6605                	lui	a2,0x1
    800065ee:	4581                	li	a1,0
    800065f0:	6888                	ld	a0,16(s1)
    800065f2:	ffffa097          	auipc	ra,0xffffa
    800065f6:	6e0080e7          	jalr	1760(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    800065fa:	100027b7          	lui	a5,0x10002
    800065fe:	4721                	li	a4,8
    80006600:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    80006602:	4098                	lw	a4,0(s1)
    80006604:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    80006608:	40d8                	lw	a4,4(s1)
    8000660a:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    8000660e:	6498                	ld	a4,8(s1)
    80006610:	0007069b          	sext.w	a3,a4
    80006614:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    80006618:	9701                	srai	a4,a4,0x20
    8000661a:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    8000661e:	6898                	ld	a4,16(s1)
    80006620:	0007069b          	sext.w	a3,a4
    80006624:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    80006628:	9701                	srai	a4,a4,0x20
    8000662a:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    8000662e:	4705                	li	a4,1
    80006630:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    80006632:	00e48c23          	sb	a4,24(s1)
    80006636:	00e48ca3          	sb	a4,25(s1)
    8000663a:	00e48d23          	sb	a4,26(s1)
    8000663e:	00e48da3          	sb	a4,27(s1)
    80006642:	00e48e23          	sb	a4,28(s1)
    80006646:	00e48ea3          	sb	a4,29(s1)
    8000664a:	00e48f23          	sb	a4,30(s1)
    8000664e:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006652:	473d                	li	a4,15
    80006654:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    80006656:	0001e917          	auipc	s2,0x1e
    8000665a:	74290913          	addi	s2,s2,1858 # 80024d98 <fb>
    8000665e:	0001f997          	auipc	s3,0x1f
    80006662:	09a98993          	addi	s3,s3,154 # 800256f8 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    80006666:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    80006668:	ffffa097          	auipc	ra,0xffffa
    8000666c:	47e080e7          	jalr	1150(ra) # 80000ae6 <kalloc>
    80006670:	e088                	sd	a0,0(s1)
        if (!fb[i])
    80006672:	14050f63          	beqz	a0,800067d0 <virtio_gpu_init+0x32a>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    80006676:	6605                	lui	a2,0x1
    80006678:	4581                	li	a1,0
    8000667a:	ffffa097          	auipc	ra,0xffffa
    8000667e:	658080e7          	jalr	1624(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    80006682:	04a1                	addi	s1,s1,8
    80006684:	ff3492e3          	bne	s1,s3,80006668 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    80006688:	0001c497          	auipc	s1,0x1c
    8000668c:	05848493          	addi	s1,s1,88 # 800226e0 <gq>
    80006690:	0001c997          	auipc	s3,0x1c
    80006694:	11098993          	addi	s3,s3,272 # 800227a0 <create_req.4>
    80006698:	02800613          	li	a2,40
    8000669c:	4581                	li	a1,0
    8000669e:	854e                	mv	a0,s3
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	632080e7          	jalr	1586(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    800066a8:	10100793          	li	a5,257
    800066ac:	0cf4a023          	sw	a5,192(s1)
    create_req.resource_id = RESOURCE_ID;
    800066b0:	4785                	li	a5,1
    800066b2:	0cf4ac23          	sw	a5,216(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    800066b6:	4789                	li	a5,2
    800066b8:	0cf4ae23          	sw	a5,220(s1)
    create_req.width = SCREEN_W;
    800066bc:	28000793          	li	a5,640
    800066c0:	0ef4a023          	sw	a5,224(s1)
    create_req.height = SCREEN_H;
    800066c4:	1e000793          	li	a5,480
    800066c8:	0ef4a223          	sw	a5,228(s1)
    gpu_send(&create_req, sizeof(create_req));
    800066cc:	02800593          	li	a1,40
    800066d0:	854e                	mv	a0,s3
    800066d2:	00000097          	auipc	ra,0x0
    800066d6:	c10080e7          	jalr	-1008(ra) # 800062e2 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    800066da:	0001c597          	auipc	a1,0x1c
    800066de:	11e58593          	addi	a1,a1,286 # 800227f8 <fb_entries.3>
    800066e2:	0001d697          	auipc	a3,0x1d
    800066e6:	3d668693          	addi	a3,a3,982 # 80023ab8 <attach_buf>
    gpu_send(&create_req, sizeof(create_req));
    800066ea:	87ae                	mv	a5,a1
        fb_entries[i].length = PGSIZE;
    800066ec:	6605                	lui	a2,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    800066ee:	00093703          	ld	a4,0(s2)
    800066f2:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    800066f4:	c790                	sw	a2,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    800066f6:	0921                	addi	s2,s2,8
    800066f8:	07c1                	addi	a5,a5,16
    800066fa:	fed79ae3          	bne	a5,a3,800066ee <virtio_gpu_init+0x248>
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    800066fe:	0001d797          	auipc	a5,0x1d
    80006702:	3ba78793          	addi	a5,a5,954 # 80023ab8 <attach_buf>
    80006706:	10600713          	li	a4,262
    8000670a:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    8000670c:	4705                	li	a4,1
    8000670e:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    80006710:	12c00713          	li	a4,300
    80006714:	cfd8                	sw	a4,28(a5)
    for (int i = 0; i < n; i++)
    80006716:	0001d797          	auipc	a5,0x1d
    8000671a:	3c278793          	addi	a5,a5,962 # 80023ad8 <attach_buf+0x20>
        attach_buf.entries[i] = entries[i];
    8000671e:	6198                	ld	a4,0(a1)
    80006720:	e398                	sd	a4,0(a5)
    80006722:	6598                	ld	a4,8(a1)
    80006724:	e798                	sd	a4,8(a5)
    for (int i = 0; i < n; i++)
    80006726:	05c1                	addi	a1,a1,16
    80006728:	07c1                	addi	a5,a5,16
    8000672a:	fed59ae3          	bne	a1,a3,8000671e <virtio_gpu_init+0x278>
    gpu_send(&attach_buf, sizeof(attach_buf));
    8000672e:	6585                	lui	a1,0x1
    80006730:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    80006734:	0001d517          	auipc	a0,0x1d
    80006738:	38450513          	addi	a0,a0,900 # 80023ab8 <attach_buf>
    8000673c:	00000097          	auipc	ra,0x0
    80006740:	ba6080e7          	jalr	-1114(ra) # 800062e2 <gpu_send>
        for (int i = 0; msg[i]; i++)
    80006744:	00002c17          	auipc	s8,0x2
    80006748:	22cc0c13          	addi	s8,s8,556 # 80008970 <syscalls+0x500>
    gpu_send(&attach_buf, sizeof(attach_buf));
    8000674c:	0008cbb7          	lui	s7,0x8c
    80006750:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    80006754:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    80006758:	00002c97          	auipc	s9,0x2
    8000675c:	260c8c93          	addi	s9,s9,608 # 800089b8 <font8x8>
    80006760:	00024737          	lui	a4,0x24
    80006764:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    80006768:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    8000676a:	010004b7          	lui	s1,0x1000
    8000676e:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006770:	0001e897          	auipc	a7,0x1e
    80006774:	62888893          	addi	a7,a7,1576 # 80024d98 <fb>
    int off = byte_off % PGSIZE;
    80006778:	6805                	lui	a6,0x1
    8000677a:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    8000677c:	6e05                	lui	t3,0x1
    8000677e:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    80006782:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    80006784:	6a8d                	lui	s5,0x3
    80006786:	800a8a9b          	addiw	s5,s5,-2048
    8000678a:	10000b13          	li	s6,256
    8000678e:	a0f1                	j	8000685a <virtio_gpu_init+0x3b4>
        panic("virtio_gpu: FEATURES_OK not set");
    80006790:	00002517          	auipc	a0,0x2
    80006794:	12850513          	addi	a0,a0,296 # 800088b8 <syscalls+0x448>
    80006798:	ffffa097          	auipc	ra,0xffffa
    8000679c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    800067a0:	00002517          	auipc	a0,0x2
    800067a4:	13850513          	addi	a0,a0,312 # 800088d8 <syscalls+0x468>
    800067a8:	ffffa097          	auipc	ra,0xffffa
    800067ac:	d96080e7          	jalr	-618(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    800067b0:	00002517          	auipc	a0,0x2
    800067b4:	14850513          	addi	a0,a0,328 # 800088f8 <syscalls+0x488>
    800067b8:	ffffa097          	auipc	ra,0xffffa
    800067bc:	d86080e7          	jalr	-634(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    800067c0:	00002517          	auipc	a0,0x2
    800067c4:	15850513          	addi	a0,a0,344 # 80008918 <syscalls+0x4a8>
    800067c8:	ffffa097          	auipc	ra,0xffffa
    800067cc:	d76080e7          	jalr	-650(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    800067d0:	00002517          	auipc	a0,0x2
    800067d4:	17050513          	addi	a0,a0,368 # 80008940 <syscalls+0x4d0>
    800067d8:	ffffa097          	auipc	ra,0xffffa
    800067dc:	d66080e7          	jalr	-666(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800067e0:	85fe                	mv	a1,t6
    800067e2:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    800067e4:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    800067e8:	43f6d613          	srai	a2,a3,0x3f
    800067ec:	0146561b          	srliw	a2,a2,0x14
    800067f0:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    800067f4:	40c7d71b          	sraiw	a4,a5,0xc
    800067f8:	070e                	slli	a4,a4,0x3
    800067fa:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    800067fc:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006800:	9f91                	subw	a5,a5,a2
    *p = color;
    80006802:	6310                	ld	a2,0(a4)
    80006804:	97b2                	add	a5,a5,a2
    80006806:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    80006808:	2691                	addiw	a3,a3,4
    8000680a:	fcd59fe3          	bne	a1,a3,800067e8 <virtio_gpu_init+0x342>
            for (int dy = 0; dy < SCALE; dy++)
    8000680e:	2803031b          	addiw	t1,t1,640
    80006812:	00be05bb          	addw	a1,t3,a1
    80006816:	fdd317e3          	bne	t1,t4,800067e4 <virtio_gpu_init+0x33e>
        for (int col = 0; col < 8; col++)
    8000681a:	2f05                	addiw	t5,t5,1
    8000681c:	2fc1                	addiw	t6,t6,16
    8000681e:	001f0a63          	beq	t5,ra,80006832 <virtio_gpu_init+0x38c>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006822:	0002c503          	lbu	a0,0(t0)
    80006826:	01e5553b          	srlw	a0,a0,t5
    8000682a:	8905                	andi	a0,a0,1
    8000682c:	d955                	beqz	a0,800067e0 <virtio_gpu_init+0x33a>
    8000682e:	8526                	mv	a0,s1
    80006830:	bf45                	j	800067e0 <virtio_gpu_init+0x33a>
    for (int row = 0; row < 8; row++)
    80006832:	01de0ebb          	addw	t4,t3,t4
    80006836:	012e093b          	addw	s2,t3,s2
    8000683a:	2991                	addiw	s3,s3,4
    8000683c:	014a8a3b          	addw	s4,s5,s4
    80006840:	0285                	addi	t0,t0,1
    80006842:	01698663          	beq	s3,s6,8000684e <virtio_gpu_init+0x3a8>
        for (int i = 0; msg[i]; i++)
    80006846:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    80006848:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    8000684a:	83ca                	mv	t2,s2
    8000684c:	bfd9                	j	80006822 <virtio_gpu_init+0x37c>
        for (int i = 0; msg[i]; i++)
    8000684e:	001c4783          	lbu	a5,1(s8)
    80006852:	0c05                	addi	s8,s8,1
    80006854:	080b8b9b          	addiw	s7,s7,128
    80006858:	cb99                	beqz	a5,8000686e <virtio_gpu_init+0x3c8>
    const uint8 *rows = font8x8[ch];
    8000685a:	078e                	slli	a5,a5,0x3
    8000685c:	019782b3          	add	t0,a5,s9
    80006860:	8a5e                	mv	s4,s7
    80006862:	0e000993          	li	s3,224
    80006866:	00023937          	lui	s2,0x23
    8000686a:	8eee                	mv	t4,s11
    8000686c:	bfe9                	j	80006846 <virtio_gpu_init+0x3a0>
    memset(&scanout_req, 0, sizeof(scanout_req));
    8000686e:	0001c497          	auipc	s1,0x1c
    80006872:	e7248493          	addi	s1,s1,-398 # 800226e0 <gq>
    80006876:	0001c917          	auipc	s2,0x1c
    8000687a:	f5290913          	addi	s2,s2,-174 # 800227c8 <scanout_req.2>
    8000687e:	03000613          	li	a2,48
    80006882:	4581                	li	a1,0
    80006884:	854a                	mv	a0,s2
    80006886:	ffffa097          	auipc	ra,0xffffa
    8000688a:	44c080e7          	jalr	1100(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    8000688e:	10300793          	li	a5,259
    80006892:	0ef4a423          	sw	a5,232(s1)
    scanout_req.r.x = 0;
    80006896:	1004a023          	sw	zero,256(s1)
    scanout_req.r.y = 0;
    8000689a:	1004a223          	sw	zero,260(s1)
    scanout_req.r.width = SCREEN_W;
    8000689e:	28000793          	li	a5,640
    800068a2:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.height = SCREEN_H;
    800068a6:	1e000793          	li	a5,480
    800068aa:	10f4a623          	sw	a5,268(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    800068ae:	1004a823          	sw	zero,272(s1)
    scanout_req.resource_id = RESOURCE_ID;
    800068b2:	4785                	li	a5,1
    800068b4:	10f4aa23          	sw	a5,276(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    800068b8:	03000593          	li	a1,48
    800068bc:	854a                	mv	a0,s2
    800068be:	00000097          	auipc	ra,0x0
    800068c2:	a24080e7          	jalr	-1500(ra) # 800062e2 <gpu_send>
    gpu_transfer_flush();
    800068c6:	00000097          	auipc	ra,0x0
    800068ca:	b28080e7          	jalr	-1240(ra) # 800063ee <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    800068ce:	00002517          	auipc	a0,0x2
    800068d2:	0b250513          	addi	a0,a0,178 # 80008980 <syscalls+0x510>
    800068d6:	ffffa097          	auipc	ra,0xffffa
    800068da:	cb2080e7          	jalr	-846(ra) # 80000588 <printf>
    800068de:	b989                	j	80006530 <virtio_gpu_init+0x8a>

00000000800068e0 <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    800068e0:	1141                	addi	sp,sp,-16
    800068e2:	e406                	sd	ra,8(sp)
    800068e4:	e022                	sd	s0,0(sp)
    800068e6:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    800068e8:	00000097          	auipc	ra,0x0
    800068ec:	b06080e7          	jalr	-1274(ra) # 800063ee <gpu_transfer_flush>
}
    800068f0:	60a2                	ld	ra,8(sp)
    800068f2:	6402                	ld	s0,0(sp)
    800068f4:	0141                	addi	sp,sp,16
    800068f6:	8082                	ret

00000000800068f8 <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    800068f8:	7179                	addi	sp,sp,-48
    800068fa:	f406                	sd	ra,40(sp)
    800068fc:	f022                	sd	s0,32(sp)
    800068fe:	ec26                	sd	s1,24(sp)
    80006900:	e84a                	sd	s2,16(sp)
    80006902:	e44e                	sd	s3,8(sp)
    80006904:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    80006906:	ffffb097          	auipc	ra,0xffffb
    8000690a:	0dc080e7          	jalr	220(ra) # 800019e2 <myproc>
    release(&p->lock);
    8000690e:	ffffa097          	auipc	ra,0xffffa
    80006912:	37c080e7          	jalr	892(ra) # 80000c8a <release>

    acquire(&tickslock);
    80006916:	00011517          	auipc	a0,0x11
    8000691a:	9ea50513          	addi	a0,a0,-1558 # 80017300 <tickslock>
    8000691e:	ffffa097          	auipc	ra,0xffffa
    80006922:	2b8080e7          	jalr	696(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006926:	00003917          	auipc	s2,0x3
    8000692a:	93a90913          	addi	s2,s2,-1734 # 80009260 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    8000692e:	00011497          	auipc	s1,0x11
    80006932:	9d248493          	addi	s1,s1,-1582 # 80017300 <tickslock>
    80006936:	a839                	j	80006954 <display_daemon+0x5c>

        release(&tickslock);
    80006938:	8526                	mv	a0,s1
    8000693a:	ffffa097          	auipc	ra,0xffffa
    8000693e:	350080e7          	jalr	848(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006942:	00000097          	auipc	ra,0x0
    80006946:	aac080e7          	jalr	-1364(ra) # 800063ee <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    8000694a:	8526                	mv	a0,s1
    8000694c:	ffffa097          	auipc	ra,0xffffa
    80006950:	28a080e7          	jalr	650(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006954:	00092783          	lw	a5,0(s2)
    80006958:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    8000695c:	fd37fee3          	bgeu	a5,s3,80006938 <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006960:	85a6                	mv	a1,s1
    80006962:	854a                	mv	a0,s2
    80006964:	ffffb097          	auipc	ra,0xffffb
    80006968:	78c080e7          	jalr	1932(ra) # 800020f0 <sleep>
        while (ticks < deadline)
    8000696c:	00092783          	lw	a5,0(s2)
    80006970:	ff37e8e3          	bltu	a5,s3,80006960 <display_daemon+0x68>
    80006974:	b7d1                	j	80006938 <display_daemon+0x40>
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
