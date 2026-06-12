
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
    80000068:	d7c78793          	addi	a5,a5,-644 # 80005de0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd6967>
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
    80000130:	448080e7          	jalr	1096(ra) # 80002574 <either_copyin>
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
    800001cc:	1f6080e7          	jalr	502(ra) # 800023be <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f40080e7          	jalr	-192(ra) # 80002116 <sleep>
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
    80000216:	30c080e7          	jalr	780(ra) # 8000251e <either_copyout>
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
    800002f6:	2d8080e7          	jalr	728(ra) # 800025ca <procdump>
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
    8000044a:	d34080e7          	jalr	-716(ra) # 8000217a <wakeup>
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
    80000896:	8e8080e7          	jalr	-1816(ra) # 8000217a <wakeup>
    
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
    80000920:	7fa080e7          	jalr	2042(ra) # 80002116 <sleep>
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
    800009fe:	00027797          	auipc	a5,0x27
    80000a02:	49a78793          	addi	a5,a5,1178 # 80027e98 <end>
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
    80000ace:	00027517          	auipc	a0,0x27
    80000ad2:	3ca50513          	addi	a0,a0,970 # 80027e98 <end>
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
    80000ec2:	84c080e7          	jalr	-1972(ra) # 8000270a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	f5a080e7          	jalr	-166(ra) # 80005e20 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	096080e7          	jalr	150(ra) # 80001f64 <scheduler>
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
    80000f3a:	7ac080e7          	jalr	1964(ra) # 800026e2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7cc080e7          	jalr	1996(ra) # 8000270a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	ec4080e7          	jalr	-316(ra) # 80005e0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	ed2080e7          	jalr	-302(ra) # 80005e20 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	056080e7          	jalr	86(ra) # 80002fac <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	6fa080e7          	jalr	1786(ra) # 80003658 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	698080e7          	jalr	1688(ra) # 800045fe <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	fba080e7          	jalr	-70(ra) # 80005f28 <virtio_disk_init>
    virtio_gpu_init();  // virtio GPU display window
    80000f76:	00005097          	auipc	ra,0x5
    80000f7a:	77e080e7          	jalr	1918(ra) # 800066f4 <virtio_gpu_init>
    userinit();      // first user process
    80000f7e:	00001097          	auipc	ra,0x1
    80000f82:	d62080e7          	jalr	-670(ra) # 80001ce0 <userinit>
    kproc_create(display_daemon, "displaydaemon"); // GPU auto-commit daemon
    80000f86:	00007597          	auipc	a1,0x7
    80000f8a:	13258593          	addi	a1,a1,306 # 800080b8 <digits+0x78>
    80000f8e:	00006517          	auipc	a0,0x6
    80000f92:	ce850513          	addi	a0,a0,-792 # 80006c76 <display_daemon>
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	dcc080e7          	jalr	-564(ra) # 80001d62 <kproc_create>
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
    800018a0:	c64a0a13          	addi	s4,s4,-924 # 80017500 <tickslock>
    char *pa = kalloc();
    800018a4:	fffff097          	auipc	ra,0xfffff
    800018a8:	242080e7          	jalr	578(ra) # 80000ae6 <kalloc>
    800018ac:	862a                	mv	a2,a0
    if(pa == 0)
    800018ae:	c131                	beqz	a0,800018f2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018b0:	416485b3          	sub	a1,s1,s6
    800018b4:	8591                	srai	a1,a1,0x4
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
    800018d6:	17048493          	addi	s1,s1,368
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
    8000196c:	b9898993          	addi	s3,s3,-1128 # 80017500 <tickslock>
      initlock(&p->lock, "proc");
    80001970:	85da                	mv	a1,s6
    80001972:	8526                	mv	a0,s1
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	1d2080e7          	jalr	466(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    8000197c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001980:	415487b3          	sub	a5,s1,s5
    80001984:	8791                	srai	a5,a5,0x4
    80001986:	000a3703          	ld	a4,0(s4)
    8000198a:	02e787b3          	mul	a5,a5,a4
    8000198e:	2785                	addiw	a5,a5,1
    80001990:	00d7979b          	slliw	a5,a5,0xd
    80001994:	40f907b3          	sub	a5,s2,a5
    80001998:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199a:	17048493          	addi	s1,s1,368
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
    80001a40:	ce6080e7          	jalr	-794(ra) # 80002722 <usertrapret>
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
    80001a5a:	b82080e7          	jalr	-1150(ra) # 800035d8 <fsinit>
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
  virtio_gpu_on_proc_exit(p);
    80001bb0:	8526                	mv	a0,s1
    80001bb2:	00005097          	auipc	ra,0x5
    80001bb6:	056080e7          	jalr	86(ra) # 80006c08 <virtio_gpu_on_proc_exit>
  if(p->fb_map_va && p->pagetable)
    80001bba:	1684b583          	ld	a1,360(s1)
    80001bbe:	c991                	beqz	a1,80001bd2 <freeproc+0x3e>
    80001bc0:	68a8                	ld	a0,80(s1)
    80001bc2:	c901                	beqz	a0,80001bd2 <freeproc+0x3e>
    uvmunmap(p->pagetable, p->fb_map_va, GPU_FB_PAGES, 0);
    80001bc4:	4681                	li	a3,0
    80001bc6:	12c00613          	li	a2,300
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	6d0080e7          	jalr	1744(ra) # 8000129a <uvmunmap>
  p->fb_map_va = 0;
    80001bd2:	1604b423          	sd	zero,360(s1)
  if(p->pagetable)
    80001bd6:	68a8                	ld	a0,80(s1)
    80001bd8:	c511                	beqz	a0,80001be4 <freeproc+0x50>
    proc_freepagetable(p->pagetable, p->sz);
    80001bda:	64ac                	ld	a1,72(s1)
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	f66080e7          	jalr	-154(ra) # 80001b42 <proc_freepagetable>
  p->pagetable = 0;
    80001be4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bec:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bf0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bf4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bfc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c00:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c04:	0004ac23          	sw	zero,24(s1)
}
    80001c08:	60e2                	ld	ra,24(sp)
    80001c0a:	6442                	ld	s0,16(sp)
    80001c0c:	64a2                	ld	s1,8(sp)
    80001c0e:	6105                	addi	sp,sp,32
    80001c10:	8082                	ret

0000000080001c12 <allocproc>:
{
    80001c12:	1101                	addi	sp,sp,-32
    80001c14:	ec06                	sd	ra,24(sp)
    80001c16:	e822                	sd	s0,16(sp)
    80001c18:	e426                	sd	s1,8(sp)
    80001c1a:	e04a                	sd	s2,0(sp)
    80001c1c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1e:	00010497          	auipc	s1,0x10
    80001c22:	ce248493          	addi	s1,s1,-798 # 80011900 <proc>
    80001c26:	00016917          	auipc	s2,0x16
    80001c2a:	8da90913          	addi	s2,s2,-1830 # 80017500 <tickslock>
    acquire(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	fa6080e7          	jalr	-90(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001c38:	4c9c                	lw	a5,24(s1)
    80001c3a:	cf81                	beqz	a5,80001c52 <allocproc+0x40>
      release(&p->lock);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	04c080e7          	jalr	76(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	17048493          	addi	s1,s1,368
    80001c4a:	ff2492e3          	bne	s1,s2,80001c2e <allocproc+0x1c>
  return 0;
    80001c4e:	4481                	li	s1,0
    80001c50:	a889                	j	80001ca2 <allocproc+0x90>
  p->pid = allocpid();
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	e0e080e7          	jalr	-498(ra) # 80001a60 <allocpid>
    80001c5a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c5c:	4785                	li	a5,1
    80001c5e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	e86080e7          	jalr	-378(ra) # 80000ae6 <kalloc>
    80001c68:	892a                	mv	s2,a0
    80001c6a:	eca8                	sd	a0,88(s1)
    80001c6c:	c131                	beqz	a0,80001cb0 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	e36080e7          	jalr	-458(ra) # 80001aa6 <proc_pagetable>
    80001c78:	892a                	mv	s2,a0
    80001c7a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c7c:	c531                	beqz	a0,80001cc8 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c7e:	07000613          	li	a2,112
    80001c82:	4581                	li	a1,0
    80001c84:	06048513          	addi	a0,s1,96
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	04a080e7          	jalr	74(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c90:	00000797          	auipc	a5,0x0
    80001c94:	d8a78793          	addi	a5,a5,-630 # 80001a1a <forkret>
    80001c98:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c9a:	60bc                	ld	a5,64(s1)
    80001c9c:	6705                	lui	a4,0x1
    80001c9e:	97ba                	add	a5,a5,a4
    80001ca0:	f4bc                	sd	a5,104(s1)
}
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	60e2                	ld	ra,24(sp)
    80001ca6:	6442                	ld	s0,16(sp)
    80001ca8:	64a2                	ld	s1,8(sp)
    80001caa:	6902                	ld	s2,0(sp)
    80001cac:	6105                	addi	sp,sp,32
    80001cae:	8082                	ret
    freeproc(p);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	ee2080e7          	jalr	-286(ra) # 80001b94 <freeproc>
    release(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	fce080e7          	jalr	-50(ra) # 80000c8a <release>
    return 0;
    80001cc4:	84ca                	mv	s1,s2
    80001cc6:	bff1                	j	80001ca2 <allocproc+0x90>
    freeproc(p);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	eca080e7          	jalr	-310(ra) # 80001b94 <freeproc>
    release(&p->lock);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	fb6080e7          	jalr	-74(ra) # 80000c8a <release>
    return 0;
    80001cdc:	84ca                	mv	s1,s2
    80001cde:	b7d1                	j	80001ca2 <allocproc+0x90>

0000000080001ce0 <userinit>:
{
    80001ce0:	1101                	addi	sp,sp,-32
    80001ce2:	ec06                	sd	ra,24(sp)
    80001ce4:	e822                	sd	s0,16(sp)
    80001ce6:	e426                	sd	s1,8(sp)
    80001ce8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cea:	00000097          	auipc	ra,0x0
    80001cee:	f28080e7          	jalr	-216(ra) # 80001c12 <allocproc>
    80001cf2:	84aa                	mv	s1,a0
  initproc = p;
    80001cf4:	00007797          	auipc	a5,0x7
    80001cf8:	56a7b223          	sd	a0,1380(a5) # 80009258 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cfc:	03400613          	li	a2,52
    80001d00:	00007597          	auipc	a1,0x7
    80001d04:	4d058593          	addi	a1,a1,1232 # 800091d0 <initcode>
    80001d08:	6928                	ld	a0,80(a0)
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	682080e7          	jalr	1666(ra) # 8000138c <uvmfirst>
  p->sz = PGSIZE;
    80001d12:	6785                	lui	a5,0x1
    80001d14:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d16:	6cb8                	ld	a4,88(s1)
    80001d18:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d1c:	6cb8                	ld	a4,88(s1)
    80001d1e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d20:	4641                	li	a2,16
    80001d22:	00006597          	auipc	a1,0x6
    80001d26:	4ee58593          	addi	a1,a1,1262 # 80008210 <digits+0x1d0>
    80001d2a:	15848513          	addi	a0,s1,344
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	0ee080e7          	jalr	238(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d36:	00006517          	auipc	a0,0x6
    80001d3a:	4ea50513          	addi	a0,a0,1258 # 80008220 <digits+0x1e0>
    80001d3e:	00002097          	auipc	ra,0x2
    80001d42:	2bc080e7          	jalr	700(ra) # 80003ffa <namei>
    80001d46:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d4a:	478d                	li	a5,3
    80001d4c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	f3a080e7          	jalr	-198(ra) # 80000c8a <release>
}
    80001d58:	60e2                	ld	ra,24(sp)
    80001d5a:	6442                	ld	s0,16(sp)
    80001d5c:	64a2                	ld	s1,8(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret

0000000080001d62 <kproc_create>:
{
    80001d62:	7179                	addi	sp,sp,-48
    80001d64:	f406                	sd	ra,40(sp)
    80001d66:	f022                	sd	s0,32(sp)
    80001d68:	ec26                	sd	s1,24(sp)
    80001d6a:	e84a                	sd	s2,16(sp)
    80001d6c:	e44e                	sd	s3,8(sp)
    80001d6e:	1800                	addi	s0,sp,48
    80001d70:	89aa                	mv	s3,a0
    80001d72:	892e                	mv	s2,a1
  struct proc *p = allocproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	e9e080e7          	jalr	-354(ra) # 80001c12 <allocproc>
  if(p == 0)
    80001d7c:	cd15                	beqz	a0,80001db8 <kproc_create+0x56>
    80001d7e:	84aa                	mv	s1,a0
  p->context.ra = (uint64)fn;
    80001d80:	07353023          	sd	s3,96(a0)
  p->context.sp = p->kstack + PGSIZE;
    80001d84:	613c                	ld	a5,64(a0)
    80001d86:	6705                	lui	a4,0x1
    80001d88:	97ba                	add	a5,a5,a4
    80001d8a:	f53c                	sd	a5,104(a0)
  safestrcpy(p->name, name, sizeof(p->name));
    80001d8c:	4641                	li	a2,16
    80001d8e:	85ca                	mv	a1,s2
    80001d90:	15850513          	addi	a0,a0,344
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	088080e7          	jalr	136(ra) # 80000e1c <safestrcpy>
  p->state = RUNNABLE;
    80001d9c:	478d                	li	a5,3
    80001d9e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001da0:	8526                	mv	a0,s1
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	ee8080e7          	jalr	-280(ra) # 80000c8a <release>
}
    80001daa:	70a2                	ld	ra,40(sp)
    80001dac:	7402                	ld	s0,32(sp)
    80001dae:	64e2                	ld	s1,24(sp)
    80001db0:	6942                	ld	s2,16(sp)
    80001db2:	69a2                	ld	s3,8(sp)
    80001db4:	6145                	addi	sp,sp,48
    80001db6:	8082                	ret
    panic("kproc_create");
    80001db8:	00006517          	auipc	a0,0x6
    80001dbc:	47050513          	addi	a0,a0,1136 # 80008228 <digits+0x1e8>
    80001dc0:	ffffe097          	auipc	ra,0xffffe
    80001dc4:	77e080e7          	jalr	1918(ra) # 8000053e <panic>

0000000080001dc8 <growproc>:
{
    80001dc8:	1101                	addi	sp,sp,-32
    80001dca:	ec06                	sd	ra,24(sp)
    80001dcc:	e822                	sd	s0,16(sp)
    80001dce:	e426                	sd	s1,8(sp)
    80001dd0:	e04a                	sd	s2,0(sp)
    80001dd2:	1000                	addi	s0,sp,32
    80001dd4:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	c0c080e7          	jalr	-1012(ra) # 800019e2 <myproc>
    80001dde:	84aa                	mv	s1,a0
  sz = p->sz;
    80001de0:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001de2:	01204c63          	bgtz	s2,80001dfa <growproc+0x32>
  } else if(n < 0){
    80001de6:	02094663          	bltz	s2,80001e12 <growproc+0x4a>
  p->sz = sz;
    80001dea:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dec:	4501                	li	a0,0
}
    80001dee:	60e2                	ld	ra,24(sp)
    80001df0:	6442                	ld	s0,16(sp)
    80001df2:	64a2                	ld	s1,8(sp)
    80001df4:	6902                	ld	s2,0(sp)
    80001df6:	6105                	addi	sp,sp,32
    80001df8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dfa:	4691                	li	a3,4
    80001dfc:	00b90633          	add	a2,s2,a1
    80001e00:	6928                	ld	a0,80(a0)
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	644080e7          	jalr	1604(ra) # 80001446 <uvmalloc>
    80001e0a:	85aa                	mv	a1,a0
    80001e0c:	fd79                	bnez	a0,80001dea <growproc+0x22>
      return -1;
    80001e0e:	557d                	li	a0,-1
    80001e10:	bff9                	j	80001dee <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e12:	00b90633          	add	a2,s2,a1
    80001e16:	6928                	ld	a0,80(a0)
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	5e6080e7          	jalr	1510(ra) # 800013fe <uvmdealloc>
    80001e20:	85aa                	mv	a1,a0
    80001e22:	b7e1                	j	80001dea <growproc+0x22>

0000000080001e24 <fork>:
{
    80001e24:	7139                	addi	sp,sp,-64
    80001e26:	fc06                	sd	ra,56(sp)
    80001e28:	f822                	sd	s0,48(sp)
    80001e2a:	f426                	sd	s1,40(sp)
    80001e2c:	f04a                	sd	s2,32(sp)
    80001e2e:	ec4e                	sd	s3,24(sp)
    80001e30:	e852                	sd	s4,16(sp)
    80001e32:	e456                	sd	s5,8(sp)
    80001e34:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e36:	00000097          	auipc	ra,0x0
    80001e3a:	bac080e7          	jalr	-1108(ra) # 800019e2 <myproc>
    80001e3e:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	dd2080e7          	jalr	-558(ra) # 80001c12 <allocproc>
    80001e48:	10050c63          	beqz	a0,80001f60 <fork+0x13c>
    80001e4c:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e4e:	048ab603          	ld	a2,72(s5)
    80001e52:	692c                	ld	a1,80(a0)
    80001e54:	050ab503          	ld	a0,80(s5)
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	742080e7          	jalr	1858(ra) # 8000159a <uvmcopy>
    80001e60:	04054863          	bltz	a0,80001eb0 <fork+0x8c>
  np->sz = p->sz;
    80001e64:	048ab783          	ld	a5,72(s5)
    80001e68:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e6c:	058ab683          	ld	a3,88(s5)
    80001e70:	87b6                	mv	a5,a3
    80001e72:	058a3703          	ld	a4,88(s4)
    80001e76:	12068693          	addi	a3,a3,288
    80001e7a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7e:	6788                	ld	a0,8(a5)
    80001e80:	6b8c                	ld	a1,16(a5)
    80001e82:	6f90                	ld	a2,24(a5)
    80001e84:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001e88:	e708                	sd	a0,8(a4)
    80001e8a:	eb0c                	sd	a1,16(a4)
    80001e8c:	ef10                	sd	a2,24(a4)
    80001e8e:	02078793          	addi	a5,a5,32
    80001e92:	02070713          	addi	a4,a4,32
    80001e96:	fed792e3          	bne	a5,a3,80001e7a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e9a:	058a3783          	ld	a5,88(s4)
    80001e9e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea2:	0d0a8493          	addi	s1,s5,208
    80001ea6:	0d0a0913          	addi	s2,s4,208
    80001eaa:	150a8993          	addi	s3,s5,336
    80001eae:	a00d                	j	80001ed0 <fork+0xac>
    freeproc(np);
    80001eb0:	8552                	mv	a0,s4
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	ce2080e7          	jalr	-798(ra) # 80001b94 <freeproc>
    release(&np->lock);
    80001eba:	8552                	mv	a0,s4
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	dce080e7          	jalr	-562(ra) # 80000c8a <release>
    return -1;
    80001ec4:	597d                	li	s2,-1
    80001ec6:	a059                	j	80001f4c <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001ec8:	04a1                	addi	s1,s1,8
    80001eca:	0921                	addi	s2,s2,8
    80001ecc:	01348b63          	beq	s1,s3,80001ee2 <fork+0xbe>
    if(p->ofile[i])
    80001ed0:	6088                	ld	a0,0(s1)
    80001ed2:	d97d                	beqz	a0,80001ec8 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed4:	00002097          	auipc	ra,0x2
    80001ed8:	7bc080e7          	jalr	1980(ra) # 80004690 <filedup>
    80001edc:	00a93023          	sd	a0,0(s2)
    80001ee0:	b7e5                	j	80001ec8 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ee2:	150ab503          	ld	a0,336(s5)
    80001ee6:	00002097          	auipc	ra,0x2
    80001eea:	930080e7          	jalr	-1744(ra) # 80003816 <idup>
    80001eee:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef2:	4641                	li	a2,16
    80001ef4:	158a8593          	addi	a1,s5,344
    80001ef8:	158a0513          	addi	a0,s4,344
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	f20080e7          	jalr	-224(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001f04:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f08:	8552                	mv	a0,s4
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	d80080e7          	jalr	-640(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001f12:	0000f497          	auipc	s1,0xf
    80001f16:	5d648493          	addi	s1,s1,1494 # 800114e8 <wait_lock>
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	cba080e7          	jalr	-838(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001f24:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	d60080e7          	jalr	-672(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f32:	8552                	mv	a0,s4
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	ca2080e7          	jalr	-862(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f3c:	478d                	li	a5,3
    80001f3e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f42:	8552                	mv	a0,s4
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	d46080e7          	jalr	-698(ra) # 80000c8a <release>
}
    80001f4c:	854a                	mv	a0,s2
    80001f4e:	70e2                	ld	ra,56(sp)
    80001f50:	7442                	ld	s0,48(sp)
    80001f52:	74a2                	ld	s1,40(sp)
    80001f54:	7902                	ld	s2,32(sp)
    80001f56:	69e2                	ld	s3,24(sp)
    80001f58:	6a42                	ld	s4,16(sp)
    80001f5a:	6aa2                	ld	s5,8(sp)
    80001f5c:	6121                	addi	sp,sp,64
    80001f5e:	8082                	ret
    return -1;
    80001f60:	597d                	li	s2,-1
    80001f62:	b7ed                	j	80001f4c <fork+0x128>

0000000080001f64 <scheduler>:
{
    80001f64:	7139                	addi	sp,sp,-64
    80001f66:	fc06                	sd	ra,56(sp)
    80001f68:	f822                	sd	s0,48(sp)
    80001f6a:	f426                	sd	s1,40(sp)
    80001f6c:	f04a                	sd	s2,32(sp)
    80001f6e:	ec4e                	sd	s3,24(sp)
    80001f70:	e852                	sd	s4,16(sp)
    80001f72:	e456                	sd	s5,8(sp)
    80001f74:	e05a                	sd	s6,0(sp)
    80001f76:	0080                	addi	s0,sp,64
    80001f78:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f7c:	00779a93          	slli	s5,a5,0x7
    80001f80:	0000f717          	auipc	a4,0xf
    80001f84:	55070713          	addi	a4,a4,1360 # 800114d0 <pid_lock>
    80001f88:	9756                	add	a4,a4,s5
    80001f8a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f8e:	0000f717          	auipc	a4,0xf
    80001f92:	57a70713          	addi	a4,a4,1402 # 80011508 <cpus+0x8>
    80001f96:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f98:	498d                	li	s3,3
        p->state = RUNNING;
    80001f9a:	4b11                	li	s6,4
        c->proc = p;
    80001f9c:	079e                	slli	a5,a5,0x7
    80001f9e:	0000fa17          	auipc	s4,0xf
    80001fa2:	532a0a13          	addi	s4,s4,1330 # 800114d0 <pid_lock>
    80001fa6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa8:	00015917          	auipc	s2,0x15
    80001fac:	55890913          	addi	s2,s2,1368 # 80017500 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb8:	10079073          	csrw	sstatus,a5
    80001fbc:	00010497          	auipc	s1,0x10
    80001fc0:	94448493          	addi	s1,s1,-1724 # 80011900 <proc>
    80001fc4:	a811                	j	80001fd8 <scheduler+0x74>
      release(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	cc2080e7          	jalr	-830(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd0:	17048493          	addi	s1,s1,368
    80001fd4:	fd248ee3          	beq	s1,s2,80001fb0 <scheduler+0x4c>
      acquire(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	bfc080e7          	jalr	-1028(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001fe2:	4c9c                	lw	a5,24(s1)
    80001fe4:	ff3791e3          	bne	a5,s3,80001fc6 <scheduler+0x62>
        p->state = RUNNING;
    80001fe8:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fec:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001ff0:	06048593          	addi	a1,s1,96
    80001ff4:	8556                	mv	a0,s5
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	682080e7          	jalr	1666(ra) # 80002678 <swtch>
        c->proc = 0;
    80001ffe:	020a3823          	sd	zero,48(s4)
    80002002:	b7d1                	j	80001fc6 <scheduler+0x62>

0000000080002004 <sched>:
{
    80002004:	7179                	addi	sp,sp,-48
    80002006:	f406                	sd	ra,40(sp)
    80002008:	f022                	sd	s0,32(sp)
    8000200a:	ec26                	sd	s1,24(sp)
    8000200c:	e84a                	sd	s2,16(sp)
    8000200e:	e44e                	sd	s3,8(sp)
    80002010:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002012:	00000097          	auipc	ra,0x0
    80002016:	9d0080e7          	jalr	-1584(ra) # 800019e2 <myproc>
    8000201a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	b40080e7          	jalr	-1216(ra) # 80000b5c <holding>
    80002024:	c93d                	beqz	a0,8000209a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002028:	2781                	sext.w	a5,a5
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	0000f717          	auipc	a4,0xf
    80002030:	4a470713          	addi	a4,a4,1188 # 800114d0 <pid_lock>
    80002034:	97ba                	add	a5,a5,a4
    80002036:	0a87a703          	lw	a4,168(a5)
    8000203a:	4785                	li	a5,1
    8000203c:	06f71763          	bne	a4,a5,800020aa <sched+0xa6>
  if(p->state == RUNNING)
    80002040:	4c98                	lw	a4,24(s1)
    80002042:	4791                	li	a5,4
    80002044:	06f70b63          	beq	a4,a5,800020ba <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002048:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000204c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000204e:	efb5                	bnez	a5,800020ca <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002050:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002052:	0000f917          	auipc	s2,0xf
    80002056:	47e90913          	addi	s2,s2,1150 # 800114d0 <pid_lock>
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	97ca                	add	a5,a5,s2
    80002060:	0ac7a983          	lw	s3,172(a5)
    80002064:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	0000f597          	auipc	a1,0xf
    8000206e:	49e58593          	addi	a1,a1,1182 # 80011508 <cpus+0x8>
    80002072:	95be                	add	a1,a1,a5
    80002074:	06048513          	addi	a0,s1,96
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	600080e7          	jalr	1536(ra) # 80002678 <swtch>
    80002080:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002082:	2781                	sext.w	a5,a5
    80002084:	079e                	slli	a5,a5,0x7
    80002086:	97ca                	add	a5,a5,s2
    80002088:	0b37a623          	sw	s3,172(a5)
}
    8000208c:	70a2                	ld	ra,40(sp)
    8000208e:	7402                	ld	s0,32(sp)
    80002090:	64e2                	ld	s1,24(sp)
    80002092:	6942                	ld	s2,16(sp)
    80002094:	69a2                	ld	s3,8(sp)
    80002096:	6145                	addi	sp,sp,48
    80002098:	8082                	ret
    panic("sched p->lock");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	19e50513          	addi	a0,a0,414 # 80008238 <digits+0x1f8>
    800020a2:	ffffe097          	auipc	ra,0xffffe
    800020a6:	49c080e7          	jalr	1180(ra) # 8000053e <panic>
    panic("sched locks");
    800020aa:	00006517          	auipc	a0,0x6
    800020ae:	19e50513          	addi	a0,a0,414 # 80008248 <digits+0x208>
    800020b2:	ffffe097          	auipc	ra,0xffffe
    800020b6:	48c080e7          	jalr	1164(ra) # 8000053e <panic>
    panic("sched running");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	19e50513          	addi	a0,a0,414 # 80008258 <digits+0x218>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	47c080e7          	jalr	1148(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020ca:	00006517          	auipc	a0,0x6
    800020ce:	19e50513          	addi	a0,a0,414 # 80008268 <digits+0x228>
    800020d2:	ffffe097          	auipc	ra,0xffffe
    800020d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>

00000000800020da <yield>:
{
    800020da:	1101                	addi	sp,sp,-32
    800020dc:	ec06                	sd	ra,24(sp)
    800020de:	e822                	sd	s0,16(sp)
    800020e0:	e426                	sd	s1,8(sp)
    800020e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	8fe080e7          	jalr	-1794(ra) # 800019e2 <myproc>
    800020ec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	ae8080e7          	jalr	-1304(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020f6:	478d                	li	a5,3
    800020f8:	cc9c                	sw	a5,24(s1)
  sched();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	f0a080e7          	jalr	-246(ra) # 80002004 <sched>
  release(&p->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b86080e7          	jalr	-1146(ra) # 80000c8a <release>
}
    8000210c:	60e2                	ld	ra,24(sp)
    8000210e:	6442                	ld	s0,16(sp)
    80002110:	64a2                	ld	s1,8(sp)
    80002112:	6105                	addi	sp,sp,32
    80002114:	8082                	ret

0000000080002116 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002116:	7179                	addi	sp,sp,-48
    80002118:	f406                	sd	ra,40(sp)
    8000211a:	f022                	sd	s0,32(sp)
    8000211c:	ec26                	sd	s1,24(sp)
    8000211e:	e84a                	sd	s2,16(sp)
    80002120:	e44e                	sd	s3,8(sp)
    80002122:	1800                	addi	s0,sp,48
    80002124:	89aa                	mv	s3,a0
    80002126:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	8ba080e7          	jalr	-1862(ra) # 800019e2 <myproc>
    80002130:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	aa4080e7          	jalr	-1372(ra) # 80000bd6 <acquire>
  release(lk);
    8000213a:	854a                	mv	a0,s2
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b4e080e7          	jalr	-1202(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002144:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002148:	4789                	li	a5,2
    8000214a:	cc9c                	sw	a5,24(s1)

  sched();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	eb8080e7          	jalr	-328(ra) # 80002004 <sched>

  // Tidy up.
  p->chan = 0;
    80002154:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b30080e7          	jalr	-1232(ra) # 80000c8a <release>
  acquire(lk);
    80002162:	854a                	mv	a0,s2
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	a72080e7          	jalr	-1422(ra) # 80000bd6 <acquire>
}
    8000216c:	70a2                	ld	ra,40(sp)
    8000216e:	7402                	ld	s0,32(sp)
    80002170:	64e2                	ld	s1,24(sp)
    80002172:	6942                	ld	s2,16(sp)
    80002174:	69a2                	ld	s3,8(sp)
    80002176:	6145                	addi	sp,sp,48
    80002178:	8082                	ret

000000008000217a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000217a:	7139                	addi	sp,sp,-64
    8000217c:	fc06                	sd	ra,56(sp)
    8000217e:	f822                	sd	s0,48(sp)
    80002180:	f426                	sd	s1,40(sp)
    80002182:	f04a                	sd	s2,32(sp)
    80002184:	ec4e                	sd	s3,24(sp)
    80002186:	e852                	sd	s4,16(sp)
    80002188:	e456                	sd	s5,8(sp)
    8000218a:	0080                	addi	s0,sp,64
    8000218c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	0000f497          	auipc	s1,0xf
    80002192:	77248493          	addi	s1,s1,1906 # 80011900 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002196:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002198:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000219a:	00015917          	auipc	s2,0x15
    8000219e:	36690913          	addi	s2,s2,870 # 80017500 <tickslock>
    800021a2:	a811                	j	800021b6 <wakeup+0x3c>
      }
      release(&p->lock);
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	ae4080e7          	jalr	-1308(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ae:	17048493          	addi	s1,s1,368
    800021b2:	03248663          	beq	s1,s2,800021de <wakeup+0x64>
    if(p != myproc()){
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	82c080e7          	jalr	-2004(ra) # 800019e2 <myproc>
    800021be:	fea488e3          	beq	s1,a0,800021ae <wakeup+0x34>
      acquire(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	a12080e7          	jalr	-1518(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021cc:	4c9c                	lw	a5,24(s1)
    800021ce:	fd379be3          	bne	a5,s3,800021a4 <wakeup+0x2a>
    800021d2:	709c                	ld	a5,32(s1)
    800021d4:	fd4798e3          	bne	a5,s4,800021a4 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021d8:	0154ac23          	sw	s5,24(s1)
    800021dc:	b7e1                	j	800021a4 <wakeup+0x2a>
    }
  }
}
    800021de:	70e2                	ld	ra,56(sp)
    800021e0:	7442                	ld	s0,48(sp)
    800021e2:	74a2                	ld	s1,40(sp)
    800021e4:	7902                	ld	s2,32(sp)
    800021e6:	69e2                	ld	s3,24(sp)
    800021e8:	6a42                	ld	s4,16(sp)
    800021ea:	6aa2                	ld	s5,8(sp)
    800021ec:	6121                	addi	sp,sp,64
    800021ee:	8082                	ret

00000000800021f0 <reparent>:
{
    800021f0:	7179                	addi	sp,sp,-48
    800021f2:	f406                	sd	ra,40(sp)
    800021f4:	f022                	sd	s0,32(sp)
    800021f6:	ec26                	sd	s1,24(sp)
    800021f8:	e84a                	sd	s2,16(sp)
    800021fa:	e44e                	sd	s3,8(sp)
    800021fc:	e052                	sd	s4,0(sp)
    800021fe:	1800                	addi	s0,sp,48
    80002200:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002202:	0000f497          	auipc	s1,0xf
    80002206:	6fe48493          	addi	s1,s1,1790 # 80011900 <proc>
      pp->parent = initproc;
    8000220a:	00007a17          	auipc	s4,0x7
    8000220e:	04ea0a13          	addi	s4,s4,78 # 80009258 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002212:	00015997          	auipc	s3,0x15
    80002216:	2ee98993          	addi	s3,s3,750 # 80017500 <tickslock>
    8000221a:	a029                	j	80002224 <reparent+0x34>
    8000221c:	17048493          	addi	s1,s1,368
    80002220:	01348d63          	beq	s1,s3,8000223a <reparent+0x4a>
    if(pp->parent == p){
    80002224:	7c9c                	ld	a5,56(s1)
    80002226:	ff279be3          	bne	a5,s2,8000221c <reparent+0x2c>
      pp->parent = initproc;
    8000222a:	000a3503          	ld	a0,0(s4)
    8000222e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002230:	00000097          	auipc	ra,0x0
    80002234:	f4a080e7          	jalr	-182(ra) # 8000217a <wakeup>
    80002238:	b7d5                	j	8000221c <reparent+0x2c>
}
    8000223a:	70a2                	ld	ra,40(sp)
    8000223c:	7402                	ld	s0,32(sp)
    8000223e:	64e2                	ld	s1,24(sp)
    80002240:	6942                	ld	s2,16(sp)
    80002242:	69a2                	ld	s3,8(sp)
    80002244:	6a02                	ld	s4,0(sp)
    80002246:	6145                	addi	sp,sp,48
    80002248:	8082                	ret

000000008000224a <exit>:
{
    8000224a:	7179                	addi	sp,sp,-48
    8000224c:	f406                	sd	ra,40(sp)
    8000224e:	f022                	sd	s0,32(sp)
    80002250:	ec26                	sd	s1,24(sp)
    80002252:	e84a                	sd	s2,16(sp)
    80002254:	e44e                	sd	s3,8(sp)
    80002256:	e052                	sd	s4,0(sp)
    80002258:	1800                	addi	s0,sp,48
    8000225a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	786080e7          	jalr	1926(ra) # 800019e2 <myproc>
    80002264:	89aa                	mv	s3,a0
  if(p == initproc)
    80002266:	00007797          	auipc	a5,0x7
    8000226a:	ff27b783          	ld	a5,-14(a5) # 80009258 <initproc>
    8000226e:	0d050493          	addi	s1,a0,208
    80002272:	15050913          	addi	s2,a0,336
    80002276:	02a79363          	bne	a5,a0,8000229c <exit+0x52>
    panic("init exiting");
    8000227a:	00006517          	auipc	a0,0x6
    8000227e:	00650513          	addi	a0,a0,6 # 80008280 <digits+0x240>
    80002282:	ffffe097          	auipc	ra,0xffffe
    80002286:	2bc080e7          	jalr	700(ra) # 8000053e <panic>
      fileclose(f);
    8000228a:	00002097          	auipc	ra,0x2
    8000228e:	458080e7          	jalr	1112(ra) # 800046e2 <fileclose>
      p->ofile[fd] = 0;
    80002292:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002296:	04a1                	addi	s1,s1,8
    80002298:	01248563          	beq	s1,s2,800022a2 <exit+0x58>
    if(p->ofile[fd]){
    8000229c:	6088                	ld	a0,0(s1)
    8000229e:	f575                	bnez	a0,8000228a <exit+0x40>
    800022a0:	bfdd                	j	80002296 <exit+0x4c>
  begin_op();
    800022a2:	00002097          	auipc	ra,0x2
    800022a6:	f74080e7          	jalr	-140(ra) # 80004216 <begin_op>
  iput(p->cwd);
    800022aa:	1509b503          	ld	a0,336(s3)
    800022ae:	00001097          	auipc	ra,0x1
    800022b2:	760080e7          	jalr	1888(ra) # 80003a0e <iput>
  end_op();
    800022b6:	00002097          	auipc	ra,0x2
    800022ba:	fe0080e7          	jalr	-32(ra) # 80004296 <end_op>
  p->cwd = 0;
    800022be:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022c2:	0000f497          	auipc	s1,0xf
    800022c6:	22648493          	addi	s1,s1,550 # 800114e8 <wait_lock>
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	90a080e7          	jalr	-1782(ra) # 80000bd6 <acquire>
  reparent(p);
    800022d4:	854e                	mv	a0,s3
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	f1a080e7          	jalr	-230(ra) # 800021f0 <reparent>
  wakeup(p->parent);
    800022de:	0389b503          	ld	a0,56(s3)
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	e98080e7          	jalr	-360(ra) # 8000217a <wakeup>
  acquire(&p->lock);
    800022ea:	854e                	mv	a0,s3
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	8ea080e7          	jalr	-1814(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022f4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022f8:	4795                	li	a5,5
    800022fa:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	98a080e7          	jalr	-1654(ra) # 80000c8a <release>
  sched();
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	cfc080e7          	jalr	-772(ra) # 80002004 <sched>
  panic("zombie exit");
    80002310:	00006517          	auipc	a0,0x6
    80002314:	f8050513          	addi	a0,a0,-128 # 80008290 <digits+0x250>
    80002318:	ffffe097          	auipc	ra,0xffffe
    8000231c:	226080e7          	jalr	550(ra) # 8000053e <panic>

0000000080002320 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002320:	7179                	addi	sp,sp,-48
    80002322:	f406                	sd	ra,40(sp)
    80002324:	f022                	sd	s0,32(sp)
    80002326:	ec26                	sd	s1,24(sp)
    80002328:	e84a                	sd	s2,16(sp)
    8000232a:	e44e                	sd	s3,8(sp)
    8000232c:	1800                	addi	s0,sp,48
    8000232e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002330:	0000f497          	auipc	s1,0xf
    80002334:	5d048493          	addi	s1,s1,1488 # 80011900 <proc>
    80002338:	00015997          	auipc	s3,0x15
    8000233c:	1c898993          	addi	s3,s3,456 # 80017500 <tickslock>
    acquire(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	894080e7          	jalr	-1900(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    8000234a:	589c                	lw	a5,48(s1)
    8000234c:	01278d63          	beq	a5,s2,80002366 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	938080e7          	jalr	-1736(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000235a:	17048493          	addi	s1,s1,368
    8000235e:	ff3491e3          	bne	s1,s3,80002340 <kill+0x20>
  }
  return -1;
    80002362:	557d                	li	a0,-1
    80002364:	a829                	j	8000237e <kill+0x5e>
      p->killed = 1;
    80002366:	4785                	li	a5,1
    80002368:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000236a:	4c98                	lw	a4,24(s1)
    8000236c:	4789                	li	a5,2
    8000236e:	00f70f63          	beq	a4,a5,8000238c <kill+0x6c>
      release(&p->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	916080e7          	jalr	-1770(ra) # 80000c8a <release>
      return 0;
    8000237c:	4501                	li	a0,0
}
    8000237e:	70a2                	ld	ra,40(sp)
    80002380:	7402                	ld	s0,32(sp)
    80002382:	64e2                	ld	s1,24(sp)
    80002384:	6942                	ld	s2,16(sp)
    80002386:	69a2                	ld	s3,8(sp)
    80002388:	6145                	addi	sp,sp,48
    8000238a:	8082                	ret
        p->state = RUNNABLE;
    8000238c:	478d                	li	a5,3
    8000238e:	cc9c                	sw	a5,24(s1)
    80002390:	b7cd                	j	80002372 <kill+0x52>

0000000080002392 <setkilled>:

void
setkilled(struct proc *p)
{
    80002392:	1101                	addi	sp,sp,-32
    80002394:	ec06                	sd	ra,24(sp)
    80002396:	e822                	sd	s0,16(sp)
    80002398:	e426                	sd	s1,8(sp)
    8000239a:	1000                	addi	s0,sp,32
    8000239c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	838080e7          	jalr	-1992(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800023a6:	4785                	li	a5,1
    800023a8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	8de080e7          	jalr	-1826(ra) # 80000c8a <release>
}
    800023b4:	60e2                	ld	ra,24(sp)
    800023b6:	6442                	ld	s0,16(sp)
    800023b8:	64a2                	ld	s1,8(sp)
    800023ba:	6105                	addi	sp,sp,32
    800023bc:	8082                	ret

00000000800023be <killed>:

int
killed(struct proc *p)
{
    800023be:	1101                	addi	sp,sp,-32
    800023c0:	ec06                	sd	ra,24(sp)
    800023c2:	e822                	sd	s0,16(sp)
    800023c4:	e426                	sd	s1,8(sp)
    800023c6:	e04a                	sd	s2,0(sp)
    800023c8:	1000                	addi	s0,sp,32
    800023ca:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	80a080e7          	jalr	-2038(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023d4:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	8b0080e7          	jalr	-1872(ra) # 80000c8a <release>
  return k;
}
    800023e2:	854a                	mv	a0,s2
    800023e4:	60e2                	ld	ra,24(sp)
    800023e6:	6442                	ld	s0,16(sp)
    800023e8:	64a2                	ld	s1,8(sp)
    800023ea:	6902                	ld	s2,0(sp)
    800023ec:	6105                	addi	sp,sp,32
    800023ee:	8082                	ret

00000000800023f0 <wait>:
{
    800023f0:	715d                	addi	sp,sp,-80
    800023f2:	e486                	sd	ra,72(sp)
    800023f4:	e0a2                	sd	s0,64(sp)
    800023f6:	fc26                	sd	s1,56(sp)
    800023f8:	f84a                	sd	s2,48(sp)
    800023fa:	f44e                	sd	s3,40(sp)
    800023fc:	f052                	sd	s4,32(sp)
    800023fe:	ec56                	sd	s5,24(sp)
    80002400:	e85a                	sd	s6,16(sp)
    80002402:	e45e                	sd	s7,8(sp)
    80002404:	e062                	sd	s8,0(sp)
    80002406:	0880                	addi	s0,sp,80
    80002408:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	5d8080e7          	jalr	1496(ra) # 800019e2 <myproc>
    80002412:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002414:	0000f517          	auipc	a0,0xf
    80002418:	0d450513          	addi	a0,a0,212 # 800114e8 <wait_lock>
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7ba080e7          	jalr	1978(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002424:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002426:	4a15                	li	s4,5
        havekids = 1;
    80002428:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242a:	00015997          	auipc	s3,0x15
    8000242e:	0d698993          	addi	s3,s3,214 # 80017500 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002432:	0000fc17          	auipc	s8,0xf
    80002436:	0b6c0c13          	addi	s8,s8,182 # 800114e8 <wait_lock>
    havekids = 0;
    8000243a:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000243c:	0000f497          	auipc	s1,0xf
    80002440:	4c448493          	addi	s1,s1,1220 # 80011900 <proc>
    80002444:	a0bd                	j	800024b2 <wait+0xc2>
          pid = pp->pid;
    80002446:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000244a:	000b0e63          	beqz	s6,80002466 <wait+0x76>
    8000244e:	4691                	li	a3,4
    80002450:	02c48613          	addi	a2,s1,44
    80002454:	85da                	mv	a1,s6
    80002456:	05093503          	ld	a0,80(s2)
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	244080e7          	jalr	580(ra) # 8000169e <copyout>
    80002462:	02054563          	bltz	a0,8000248c <wait+0x9c>
          freeproc(pp);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	72c080e7          	jalr	1836(ra) # 80001b94 <freeproc>
          release(&pp->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	818080e7          	jalr	-2024(ra) # 80000c8a <release>
          release(&wait_lock);
    8000247a:	0000f517          	auipc	a0,0xf
    8000247e:	06e50513          	addi	a0,a0,110 # 800114e8 <wait_lock>
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	808080e7          	jalr	-2040(ra) # 80000c8a <release>
          return pid;
    8000248a:	a0b5                	j	800024f6 <wait+0x106>
            release(&pp->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	7fc080e7          	jalr	2044(ra) # 80000c8a <release>
            release(&wait_lock);
    80002496:	0000f517          	auipc	a0,0xf
    8000249a:	05250513          	addi	a0,a0,82 # 800114e8 <wait_lock>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
            return -1;
    800024a6:	59fd                	li	s3,-1
    800024a8:	a0b9                	j	800024f6 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024aa:	17048493          	addi	s1,s1,368
    800024ae:	03348463          	beq	s1,s3,800024d6 <wait+0xe6>
      if(pp->parent == p){
    800024b2:	7c9c                	ld	a5,56(s1)
    800024b4:	ff279be3          	bne	a5,s2,800024aa <wait+0xba>
        acquire(&pp->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	71c080e7          	jalr	1820(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800024c2:	4c9c                	lw	a5,24(s1)
    800024c4:	f94781e3          	beq	a5,s4,80002446 <wait+0x56>
        release(&pp->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	7c0080e7          	jalr	1984(ra) # 80000c8a <release>
        havekids = 1;
    800024d2:	8756                	mv	a4,s5
    800024d4:	bfd9                	j	800024aa <wait+0xba>
    if(!havekids || killed(p)){
    800024d6:	c719                	beqz	a4,800024e4 <wait+0xf4>
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	ee4080e7          	jalr	-284(ra) # 800023be <killed>
    800024e2:	c51d                	beqz	a0,80002510 <wait+0x120>
      release(&wait_lock);
    800024e4:	0000f517          	auipc	a0,0xf
    800024e8:	00450513          	addi	a0,a0,4 # 800114e8 <wait_lock>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	79e080e7          	jalr	1950(ra) # 80000c8a <release>
      return -1;
    800024f4:	59fd                	li	s3,-1
}
    800024f6:	854e                	mv	a0,s3
    800024f8:	60a6                	ld	ra,72(sp)
    800024fa:	6406                	ld	s0,64(sp)
    800024fc:	74e2                	ld	s1,56(sp)
    800024fe:	7942                	ld	s2,48(sp)
    80002500:	79a2                	ld	s3,40(sp)
    80002502:	7a02                	ld	s4,32(sp)
    80002504:	6ae2                	ld	s5,24(sp)
    80002506:	6b42                	ld	s6,16(sp)
    80002508:	6ba2                	ld	s7,8(sp)
    8000250a:	6c02                	ld	s8,0(sp)
    8000250c:	6161                	addi	sp,sp,80
    8000250e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002510:	85e2                	mv	a1,s8
    80002512:	854a                	mv	a0,s2
    80002514:	00000097          	auipc	ra,0x0
    80002518:	c02080e7          	jalr	-1022(ra) # 80002116 <sleep>
    havekids = 0;
    8000251c:	bf39                	j	8000243a <wait+0x4a>

000000008000251e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000251e:	7179                	addi	sp,sp,-48
    80002520:	f406                	sd	ra,40(sp)
    80002522:	f022                	sd	s0,32(sp)
    80002524:	ec26                	sd	s1,24(sp)
    80002526:	e84a                	sd	s2,16(sp)
    80002528:	e44e                	sd	s3,8(sp)
    8000252a:	e052                	sd	s4,0(sp)
    8000252c:	1800                	addi	s0,sp,48
    8000252e:	84aa                	mv	s1,a0
    80002530:	892e                	mv	s2,a1
    80002532:	89b2                	mv	s3,a2
    80002534:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	4ac080e7          	jalr	1196(ra) # 800019e2 <myproc>
  if(user_dst){
    8000253e:	c08d                	beqz	s1,80002560 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002540:	86d2                	mv	a3,s4
    80002542:	864e                	mv	a2,s3
    80002544:	85ca                	mv	a1,s2
    80002546:	6928                	ld	a0,80(a0)
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	156080e7          	jalr	342(ra) # 8000169e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002550:	70a2                	ld	ra,40(sp)
    80002552:	7402                	ld	s0,32(sp)
    80002554:	64e2                	ld	s1,24(sp)
    80002556:	6942                	ld	s2,16(sp)
    80002558:	69a2                	ld	s3,8(sp)
    8000255a:	6a02                	ld	s4,0(sp)
    8000255c:	6145                	addi	sp,sp,48
    8000255e:	8082                	ret
    memmove((char *)dst, src, len);
    80002560:	000a061b          	sext.w	a2,s4
    80002564:	85ce                	mv	a1,s3
    80002566:	854a                	mv	a0,s2
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	7c6080e7          	jalr	1990(ra) # 80000d2e <memmove>
    return 0;
    80002570:	8526                	mv	a0,s1
    80002572:	bff9                	j	80002550 <either_copyout+0x32>

0000000080002574 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002574:	7179                	addi	sp,sp,-48
    80002576:	f406                	sd	ra,40(sp)
    80002578:	f022                	sd	s0,32(sp)
    8000257a:	ec26                	sd	s1,24(sp)
    8000257c:	e84a                	sd	s2,16(sp)
    8000257e:	e44e                	sd	s3,8(sp)
    80002580:	e052                	sd	s4,0(sp)
    80002582:	1800                	addi	s0,sp,48
    80002584:	892a                	mv	s2,a0
    80002586:	84ae                	mv	s1,a1
    80002588:	89b2                	mv	s3,a2
    8000258a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	456080e7          	jalr	1110(ra) # 800019e2 <myproc>
  if(user_src){
    80002594:	c08d                	beqz	s1,800025b6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002596:	86d2                	mv	a3,s4
    80002598:	864e                	mv	a2,s3
    8000259a:	85ca                	mv	a1,s2
    8000259c:	6928                	ld	a0,80(a0)
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	18c080e7          	jalr	396(ra) # 8000172a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025a6:	70a2                	ld	ra,40(sp)
    800025a8:	7402                	ld	s0,32(sp)
    800025aa:	64e2                	ld	s1,24(sp)
    800025ac:	6942                	ld	s2,16(sp)
    800025ae:	69a2                	ld	s3,8(sp)
    800025b0:	6a02                	ld	s4,0(sp)
    800025b2:	6145                	addi	sp,sp,48
    800025b4:	8082                	ret
    memmove(dst, (char*)src, len);
    800025b6:	000a061b          	sext.w	a2,s4
    800025ba:	85ce                	mv	a1,s3
    800025bc:	854a                	mv	a0,s2
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	770080e7          	jalr	1904(ra) # 80000d2e <memmove>
    return 0;
    800025c6:	8526                	mv	a0,s1
    800025c8:	bff9                	j	800025a6 <either_copyin+0x32>

00000000800025ca <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ca:	715d                	addi	sp,sp,-80
    800025cc:	e486                	sd	ra,72(sp)
    800025ce:	e0a2                	sd	s0,64(sp)
    800025d0:	fc26                	sd	s1,56(sp)
    800025d2:	f84a                	sd	s2,48(sp)
    800025d4:	f44e                	sd	s3,40(sp)
    800025d6:	f052                	sd	s4,32(sp)
    800025d8:	ec56                	sd	s5,24(sp)
    800025da:	e85a                	sd	s6,16(sp)
    800025dc:	e45e                	sd	s7,8(sp)
    800025de:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025e0:	00006517          	auipc	a0,0x6
    800025e4:	af850513          	addi	a0,a0,-1288 # 800080d8 <digits+0x98>
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	fa0080e7          	jalr	-96(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f0:	0000f497          	auipc	s1,0xf
    800025f4:	46848493          	addi	s1,s1,1128 # 80011a58 <proc+0x158>
    800025f8:	00015917          	auipc	s2,0x15
    800025fc:	06090913          	addi	s2,s2,96 # 80017658 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002600:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002602:	00006997          	auipc	s3,0x6
    80002606:	c9e98993          	addi	s3,s3,-866 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    8000260a:	00006a97          	auipc	s5,0x6
    8000260e:	c9ea8a93          	addi	s5,s5,-866 # 800082a8 <digits+0x268>
    printf("\n");
    80002612:	00006a17          	auipc	s4,0x6
    80002616:	ac6a0a13          	addi	s4,s4,-1338 # 800080d8 <digits+0x98>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261a:	00006b97          	auipc	s7,0x6
    8000261e:	cceb8b93          	addi	s7,s7,-818 # 800082e8 <states.0>
    80002622:	a00d                	j	80002644 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002624:	ed86a583          	lw	a1,-296(a3)
    80002628:	8556                	mv	a0,s5
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	f5e080e7          	jalr	-162(ra) # 80000588 <printf>
    printf("\n");
    80002632:	8552                	mv	a0,s4
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	f54080e7          	jalr	-172(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000263c:	17048493          	addi	s1,s1,368
    80002640:	03248163          	beq	s1,s2,80002662 <procdump+0x98>
    if(p->state == UNUSED)
    80002644:	86a6                	mv	a3,s1
    80002646:	ec04a783          	lw	a5,-320(s1)
    8000264a:	dbed                	beqz	a5,8000263c <procdump+0x72>
      state = "???";
    8000264c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000264e:	fcfb6be3          	bltu	s6,a5,80002624 <procdump+0x5a>
    80002652:	1782                	slli	a5,a5,0x20
    80002654:	9381                	srli	a5,a5,0x20
    80002656:	078e                	slli	a5,a5,0x3
    80002658:	97de                	add	a5,a5,s7
    8000265a:	6390                	ld	a2,0(a5)
    8000265c:	f661                	bnez	a2,80002624 <procdump+0x5a>
      state = "???";
    8000265e:	864e                	mv	a2,s3
    80002660:	b7d1                	j	80002624 <procdump+0x5a>
  }
}
    80002662:	60a6                	ld	ra,72(sp)
    80002664:	6406                	ld	s0,64(sp)
    80002666:	74e2                	ld	s1,56(sp)
    80002668:	7942                	ld	s2,48(sp)
    8000266a:	79a2                	ld	s3,40(sp)
    8000266c:	7a02                	ld	s4,32(sp)
    8000266e:	6ae2                	ld	s5,24(sp)
    80002670:	6b42                	ld	s6,16(sp)
    80002672:	6ba2                	ld	s7,8(sp)
    80002674:	6161                	addi	sp,sp,80
    80002676:	8082                	ret

0000000080002678 <swtch>:
    80002678:	00153023          	sd	ra,0(a0)
    8000267c:	00253423          	sd	sp,8(a0)
    80002680:	e900                	sd	s0,16(a0)
    80002682:	ed04                	sd	s1,24(a0)
    80002684:	03253023          	sd	s2,32(a0)
    80002688:	03353423          	sd	s3,40(a0)
    8000268c:	03453823          	sd	s4,48(a0)
    80002690:	03553c23          	sd	s5,56(a0)
    80002694:	05653023          	sd	s6,64(a0)
    80002698:	05753423          	sd	s7,72(a0)
    8000269c:	05853823          	sd	s8,80(a0)
    800026a0:	05953c23          	sd	s9,88(a0)
    800026a4:	07a53023          	sd	s10,96(a0)
    800026a8:	07b53423          	sd	s11,104(a0)
    800026ac:	0005b083          	ld	ra,0(a1)
    800026b0:	0085b103          	ld	sp,8(a1)
    800026b4:	6980                	ld	s0,16(a1)
    800026b6:	6d84                	ld	s1,24(a1)
    800026b8:	0205b903          	ld	s2,32(a1)
    800026bc:	0285b983          	ld	s3,40(a1)
    800026c0:	0305ba03          	ld	s4,48(a1)
    800026c4:	0385ba83          	ld	s5,56(a1)
    800026c8:	0405bb03          	ld	s6,64(a1)
    800026cc:	0485bb83          	ld	s7,72(a1)
    800026d0:	0505bc03          	ld	s8,80(a1)
    800026d4:	0585bc83          	ld	s9,88(a1)
    800026d8:	0605bd03          	ld	s10,96(a1)
    800026dc:	0685bd83          	ld	s11,104(a1)
    800026e0:	8082                	ret

00000000800026e2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026e2:	1141                	addi	sp,sp,-16
    800026e4:	e406                	sd	ra,8(sp)
    800026e6:	e022                	sd	s0,0(sp)
    800026e8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026ea:	00006597          	auipc	a1,0x6
    800026ee:	c2e58593          	addi	a1,a1,-978 # 80008318 <states.0+0x30>
    800026f2:	00015517          	auipc	a0,0x15
    800026f6:	e0e50513          	addi	a0,a0,-498 # 80017500 <tickslock>
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	44c080e7          	jalr	1100(ra) # 80000b46 <initlock>
}
    80002702:	60a2                	ld	ra,8(sp)
    80002704:	6402                	ld	s0,0(sp)
    80002706:	0141                	addi	sp,sp,16
    80002708:	8082                	ret

000000008000270a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000270a:	1141                	addi	sp,sp,-16
    8000270c:	e422                	sd	s0,8(sp)
    8000270e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002710:	00003797          	auipc	a5,0x3
    80002714:	64078793          	addi	a5,a5,1600 # 80005d50 <kernelvec>
    80002718:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000271c:	6422                	ld	s0,8(sp)
    8000271e:	0141                	addi	sp,sp,16
    80002720:	8082                	ret

0000000080002722 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002722:	1141                	addi	sp,sp,-16
    80002724:	e406                	sd	ra,8(sp)
    80002726:	e022                	sd	s0,0(sp)
    80002728:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	2b8080e7          	jalr	696(ra) # 800019e2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002732:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002736:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002738:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000273c:	00005617          	auipc	a2,0x5
    80002740:	8c460613          	addi	a2,a2,-1852 # 80007000 <_trampoline>
    80002744:	00005697          	auipc	a3,0x5
    80002748:	8bc68693          	addi	a3,a3,-1860 # 80007000 <_trampoline>
    8000274c:	8e91                	sub	a3,a3,a2
    8000274e:	040007b7          	lui	a5,0x4000
    80002752:	17fd                	addi	a5,a5,-1
    80002754:	07b2                	slli	a5,a5,0xc
    80002756:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002758:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000275c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000275e:	180026f3          	csrr	a3,satp
    80002762:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002764:	6d38                	ld	a4,88(a0)
    80002766:	6134                	ld	a3,64(a0)
    80002768:	6585                	lui	a1,0x1
    8000276a:	96ae                	add	a3,a3,a1
    8000276c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000276e:	6d38                	ld	a4,88(a0)
    80002770:	00000697          	auipc	a3,0x0
    80002774:	13068693          	addi	a3,a3,304 # 800028a0 <usertrap>
    80002778:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000277a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000277c:	8692                	mv	a3,tp
    8000277e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002780:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002784:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002788:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000278c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002790:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002792:	6f18                	ld	a4,24(a4)
    80002794:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002798:	6928                	ld	a0,80(a0)
    8000279a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000279c:	00005717          	auipc	a4,0x5
    800027a0:	90070713          	addi	a4,a4,-1792 # 8000709c <userret>
    800027a4:	8f11                	sub	a4,a4,a2
    800027a6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027a8:	577d                	li	a4,-1
    800027aa:	177e                	slli	a4,a4,0x3f
    800027ac:	8d59                	or	a0,a0,a4
    800027ae:	9782                	jalr	a5
}
    800027b0:	60a2                	ld	ra,8(sp)
    800027b2:	6402                	ld	s0,0(sp)
    800027b4:	0141                	addi	sp,sp,16
    800027b6:	8082                	ret

00000000800027b8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027b8:	1101                	addi	sp,sp,-32
    800027ba:	ec06                	sd	ra,24(sp)
    800027bc:	e822                	sd	s0,16(sp)
    800027be:	e426                	sd	s1,8(sp)
    800027c0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027c2:	00015497          	auipc	s1,0x15
    800027c6:	d3e48493          	addi	s1,s1,-706 # 80017500 <tickslock>
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	40a080e7          	jalr	1034(ra) # 80000bd6 <acquire>
  ticks++;
    800027d4:	00007517          	auipc	a0,0x7
    800027d8:	a8c50513          	addi	a0,a0,-1396 # 80009260 <ticks>
    800027dc:	411c                	lw	a5,0(a0)
    800027de:	2785                	addiw	a5,a5,1
    800027e0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	998080e7          	jalr	-1640(ra) # 8000217a <wakeup>
  release(&tickslock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	49e080e7          	jalr	1182(ra) # 80000c8a <release>
}
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6105                	addi	sp,sp,32
    800027fc:	8082                	ret

00000000800027fe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027fe:	1101                	addi	sp,sp,-32
    80002800:	ec06                	sd	ra,24(sp)
    80002802:	e822                	sd	s0,16(sp)
    80002804:	e426                	sd	s1,8(sp)
    80002806:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002808:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000280c:	00074d63          	bltz	a4,80002826 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002810:	57fd                	li	a5,-1
    80002812:	17fe                	slli	a5,a5,0x3f
    80002814:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002816:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002818:	06f70363          	beq	a4,a5,8000287e <devintr+0x80>
  }
}
    8000281c:	60e2                	ld	ra,24(sp)
    8000281e:	6442                	ld	s0,16(sp)
    80002820:	64a2                	ld	s1,8(sp)
    80002822:	6105                	addi	sp,sp,32
    80002824:	8082                	ret
     (scause & 0xff) == 9){
    80002826:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000282a:	46a5                	li	a3,9
    8000282c:	fed792e3          	bne	a5,a3,80002810 <devintr+0x12>
    int irq = plic_claim();
    80002830:	00003097          	auipc	ra,0x3
    80002834:	628080e7          	jalr	1576(ra) # 80005e58 <plic_claim>
    80002838:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000283a:	47a9                	li	a5,10
    8000283c:	02f50763          	beq	a0,a5,8000286a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002840:	4785                	li	a5,1
    80002842:	02f50963          	beq	a0,a5,80002874 <devintr+0x76>
    return 1;
    80002846:	4505                	li	a0,1
    } else if(irq){
    80002848:	d8f1                	beqz	s1,8000281c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000284a:	85a6                	mv	a1,s1
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	ad450513          	addi	a0,a0,-1324 # 80008320 <states.0+0x38>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	d34080e7          	jalr	-716(ra) # 80000588 <printf>
      plic_complete(irq);
    8000285c:	8526                	mv	a0,s1
    8000285e:	00003097          	auipc	ra,0x3
    80002862:	61e080e7          	jalr	1566(ra) # 80005e7c <plic_complete>
    return 1;
    80002866:	4505                	li	a0,1
    80002868:	bf55                	j	8000281c <devintr+0x1e>
      uartintr();
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	130080e7          	jalr	304(ra) # 8000099a <uartintr>
    80002872:	b7ed                	j	8000285c <devintr+0x5e>
      virtio_disk_intr();
    80002874:	00004097          	auipc	ra,0x4
    80002878:	ad4080e7          	jalr	-1324(ra) # 80006348 <virtio_disk_intr>
    8000287c:	b7c5                	j	8000285c <devintr+0x5e>
    if(cpuid() == 0){
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	138080e7          	jalr	312(ra) # 800019b6 <cpuid>
    80002886:	c901                	beqz	a0,80002896 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002888:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000288c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000288e:	14479073          	csrw	sip,a5
    return 2;
    80002892:	4509                	li	a0,2
    80002894:	b761                	j	8000281c <devintr+0x1e>
      clockintr();
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	f22080e7          	jalr	-222(ra) # 800027b8 <clockintr>
    8000289e:	b7ed                	j	80002888 <devintr+0x8a>

00000000800028a0 <usertrap>:
{
    800028a0:	1101                	addi	sp,sp,-32
    800028a2:	ec06                	sd	ra,24(sp)
    800028a4:	e822                	sd	s0,16(sp)
    800028a6:	e426                	sd	s1,8(sp)
    800028a8:	e04a                	sd	s2,0(sp)
    800028aa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ac:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028b0:	1007f793          	andi	a5,a5,256
    800028b4:	e3b1                	bnez	a5,800028f8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b6:	00003797          	auipc	a5,0x3
    800028ba:	49a78793          	addi	a5,a5,1178 # 80005d50 <kernelvec>
    800028be:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028c2:	fffff097          	auipc	ra,0xfffff
    800028c6:	120080e7          	jalr	288(ra) # 800019e2 <myproc>
    800028ca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028cc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ce:	14102773          	csrr	a4,sepc
    800028d2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028d8:	47a1                	li	a5,8
    800028da:	02f70763          	beq	a4,a5,80002908 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	f20080e7          	jalr	-224(ra) # 800027fe <devintr>
    800028e6:	892a                	mv	s2,a0
    800028e8:	c151                	beqz	a0,8000296c <usertrap+0xcc>
  if(killed(p))
    800028ea:	8526                	mv	a0,s1
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	ad2080e7          	jalr	-1326(ra) # 800023be <killed>
    800028f4:	c929                	beqz	a0,80002946 <usertrap+0xa6>
    800028f6:	a099                	j	8000293c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	a4850513          	addi	a0,a0,-1464 # 80008340 <states.0+0x58>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c3e080e7          	jalr	-962(ra) # 8000053e <panic>
    if(killed(p))
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	ab6080e7          	jalr	-1354(ra) # 800023be <killed>
    80002910:	e921                	bnez	a0,80002960 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002912:	6cb8                	ld	a4,88(s1)
    80002914:	6f1c                	ld	a5,24(a4)
    80002916:	0791                	addi	a5,a5,4
    80002918:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000291e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002922:	10079073          	csrw	sstatus,a5
    syscall();
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	2d4080e7          	jalr	724(ra) # 80002bfa <syscall>
  if(killed(p))
    8000292e:	8526                	mv	a0,s1
    80002930:	00000097          	auipc	ra,0x0
    80002934:	a8e080e7          	jalr	-1394(ra) # 800023be <killed>
    80002938:	c911                	beqz	a0,8000294c <usertrap+0xac>
    8000293a:	4901                	li	s2,0
    exit(-1);
    8000293c:	557d                	li	a0,-1
    8000293e:	00000097          	auipc	ra,0x0
    80002942:	90c080e7          	jalr	-1780(ra) # 8000224a <exit>
  if(which_dev == 2)
    80002946:	4789                	li	a5,2
    80002948:	04f90f63          	beq	s2,a5,800029a6 <usertrap+0x106>
  usertrapret();
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	dd6080e7          	jalr	-554(ra) # 80002722 <usertrapret>
}
    80002954:	60e2                	ld	ra,24(sp)
    80002956:	6442                	ld	s0,16(sp)
    80002958:	64a2                	ld	s1,8(sp)
    8000295a:	6902                	ld	s2,0(sp)
    8000295c:	6105                	addi	sp,sp,32
    8000295e:	8082                	ret
      exit(-1);
    80002960:	557d                	li	a0,-1
    80002962:	00000097          	auipc	ra,0x0
    80002966:	8e8080e7          	jalr	-1816(ra) # 8000224a <exit>
    8000296a:	b765                	j	80002912 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000296c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002970:	5890                	lw	a2,48(s1)
    80002972:	00006517          	auipc	a0,0x6
    80002976:	9ee50513          	addi	a0,a0,-1554 # 80008360 <states.0+0x78>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	c0e080e7          	jalr	-1010(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002982:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002986:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	a0650513          	addi	a0,a0,-1530 # 80008390 <states.0+0xa8>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf6080e7          	jalr	-1034(ra) # 80000588 <printf>
    setkilled(p);
    8000299a:	8526                	mv	a0,s1
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	9f6080e7          	jalr	-1546(ra) # 80002392 <setkilled>
    800029a4:	b769                	j	8000292e <usertrap+0x8e>
    yield();
    800029a6:	fffff097          	auipc	ra,0xfffff
    800029aa:	734080e7          	jalr	1844(ra) # 800020da <yield>
    800029ae:	bf79                	j	8000294c <usertrap+0xac>

00000000800029b0 <kerneltrap>:
{
    800029b0:	7179                	addi	sp,sp,-48
    800029b2:	f406                	sd	ra,40(sp)
    800029b4:	f022                	sd	s0,32(sp)
    800029b6:	ec26                	sd	s1,24(sp)
    800029b8:	e84a                	sd	s2,16(sp)
    800029ba:	e44e                	sd	s3,8(sp)
    800029bc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029be:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ca:	1004f793          	andi	a5,s1,256
    800029ce:	cb85                	beqz	a5,800029fe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d6:	ef85                	bnez	a5,80002a0e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	e26080e7          	jalr	-474(ra) # 800027fe <devintr>
    800029e0:	cd1d                	beqz	a0,80002a1e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e2:	4789                	li	a5,2
    800029e4:	06f50a63          	beq	a0,a5,80002a58 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10049073          	csrw	sstatus,s1
}
    800029f0:	70a2                	ld	ra,40(sp)
    800029f2:	7402                	ld	s0,32(sp)
    800029f4:	64e2                	ld	s1,24(sp)
    800029f6:	6942                	ld	s2,16(sp)
    800029f8:	69a2                	ld	s3,8(sp)
    800029fa:	6145                	addi	sp,sp,48
    800029fc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	9b250513          	addi	a0,a0,-1614 # 800083b0 <states.0+0xc8>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b38080e7          	jalr	-1224(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9ca50513          	addi	a0,a0,-1590 # 800083d8 <states.0+0xf0>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a1e:	85ce                	mv	a1,s3
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	9d850513          	addi	a0,a0,-1576 # 800083f8 <states.0+0x110>
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b60080e7          	jalr	-1184(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a30:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a34:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	9d050513          	addi	a0,a0,-1584 # 80008408 <states.0+0x120>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	9d850513          	addi	a0,a0,-1576 # 80008420 <states.0+0x138>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	aee080e7          	jalr	-1298(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	f8a080e7          	jalr	-118(ra) # 800019e2 <myproc>
    80002a60:	d541                	beqz	a0,800029e8 <kerneltrap+0x38>
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	f80080e7          	jalr	-128(ra) # 800019e2 <myproc>
    80002a6a:	4d18                	lw	a4,24(a0)
    80002a6c:	4791                	li	a5,4
    80002a6e:	f6f71de3          	bne	a4,a5,800029e8 <kerneltrap+0x38>
    yield();
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	668080e7          	jalr	1640(ra) # 800020da <yield>
    80002a7a:	b7bd                	j	800029e8 <kerneltrap+0x38>

0000000080002a7c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a7c:	1101                	addi	sp,sp,-32
    80002a7e:	ec06                	sd	ra,24(sp)
    80002a80:	e822                	sd	s0,16(sp)
    80002a82:	e426                	sd	s1,8(sp)
    80002a84:	1000                	addi	s0,sp,32
    80002a86:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	f5a080e7          	jalr	-166(ra) # 800019e2 <myproc>
  switch (n) {
    80002a90:	4795                	li	a5,5
    80002a92:	0497e163          	bltu	a5,s1,80002ad4 <argraw+0x58>
    80002a96:	048a                	slli	s1,s1,0x2
    80002a98:	00006717          	auipc	a4,0x6
    80002a9c:	9c070713          	addi	a4,a4,-1600 # 80008458 <states.0+0x170>
    80002aa0:	94ba                	add	s1,s1,a4
    80002aa2:	409c                	lw	a5,0(s1)
    80002aa4:	97ba                	add	a5,a5,a4
    80002aa6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
    return p->trapframe->a1;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	7fa8                	ld	a0,120(a5)
    80002aba:	bfcd                	j	80002aac <argraw+0x30>
    return p->trapframe->a2;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	63c8                	ld	a0,128(a5)
    80002ac0:	b7f5                	j	80002aac <argraw+0x30>
    return p->trapframe->a3;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	67c8                	ld	a0,136(a5)
    80002ac6:	b7dd                	j	80002aac <argraw+0x30>
    return p->trapframe->a4;
    80002ac8:	6d3c                	ld	a5,88(a0)
    80002aca:	6bc8                	ld	a0,144(a5)
    80002acc:	b7c5                	j	80002aac <argraw+0x30>
    return p->trapframe->a5;
    80002ace:	6d3c                	ld	a5,88(a0)
    80002ad0:	6fc8                	ld	a0,152(a5)
    80002ad2:	bfe9                	j	80002aac <argraw+0x30>
  panic("argraw");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	95c50513          	addi	a0,a0,-1700 # 80008430 <states.0+0x148>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a62080e7          	jalr	-1438(ra) # 8000053e <panic>

0000000080002ae4 <fetchaddr>:
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	e04a                	sd	s2,0(sp)
    80002aee:	1000                	addi	s0,sp,32
    80002af0:	84aa                	mv	s1,a0
    80002af2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	eee080e7          	jalr	-274(ra) # 800019e2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002afc:	653c                	ld	a5,72(a0)
    80002afe:	02f4f863          	bgeu	s1,a5,80002b2e <fetchaddr+0x4a>
    80002b02:	00848713          	addi	a4,s1,8
    80002b06:	02e7e663          	bltu	a5,a4,80002b32 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0a:	46a1                	li	a3,8
    80002b0c:	8626                	mv	a2,s1
    80002b0e:	85ca                	mv	a1,s2
    80002b10:	6928                	ld	a0,80(a0)
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	c18080e7          	jalr	-1000(ra) # 8000172a <copyin>
    80002b1a:	00a03533          	snez	a0,a0
    80002b1e:	40a00533          	neg	a0,a0
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret
    return -1;
    80002b2e:	557d                	li	a0,-1
    80002b30:	bfcd                	j	80002b22 <fetchaddr+0x3e>
    80002b32:	557d                	li	a0,-1
    80002b34:	b7fd                	j	80002b22 <fetchaddr+0x3e>

0000000080002b36 <fetchstr>:
{
    80002b36:	7179                	addi	sp,sp,-48
    80002b38:	f406                	sd	ra,40(sp)
    80002b3a:	f022                	sd	s0,32(sp)
    80002b3c:	ec26                	sd	s1,24(sp)
    80002b3e:	e84a                	sd	s2,16(sp)
    80002b40:	e44e                	sd	s3,8(sp)
    80002b42:	1800                	addi	s0,sp,48
    80002b44:	892a                	mv	s2,a0
    80002b46:	84ae                	mv	s1,a1
    80002b48:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	e98080e7          	jalr	-360(ra) # 800019e2 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b52:	86ce                	mv	a3,s3
    80002b54:	864a                	mv	a2,s2
    80002b56:	85a6                	mv	a1,s1
    80002b58:	6928                	ld	a0,80(a0)
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	c5e080e7          	jalr	-930(ra) # 800017b8 <copyinstr>
    80002b62:	00054e63          	bltz	a0,80002b7e <fetchstr+0x48>
  return strlen(buf);
    80002b66:	8526                	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	2e6080e7          	jalr	742(ra) # 80000e4e <strlen>
}
    80002b70:	70a2                	ld	ra,40(sp)
    80002b72:	7402                	ld	s0,32(sp)
    80002b74:	64e2                	ld	s1,24(sp)
    80002b76:	6942                	ld	s2,16(sp)
    80002b78:	69a2                	ld	s3,8(sp)
    80002b7a:	6145                	addi	sp,sp,48
    80002b7c:	8082                	ret
    return -1;
    80002b7e:	557d                	li	a0,-1
    80002b80:	bfc5                	j	80002b70 <fetchstr+0x3a>

0000000080002b82 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
    80002b8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	eee080e7          	jalr	-274(ra) # 80002a7c <argraw>
    80002b96:	c088                	sw	a0,0(s1)
}
    80002b98:	60e2                	ld	ra,24(sp)
    80002b9a:	6442                	ld	s0,16(sp)
    80002b9c:	64a2                	ld	s1,8(sp)
    80002b9e:	6105                	addi	sp,sp,32
    80002ba0:	8082                	ret

0000000080002ba2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ba2:	1101                	addi	sp,sp,-32
    80002ba4:	ec06                	sd	ra,24(sp)
    80002ba6:	e822                	sd	s0,16(sp)
    80002ba8:	e426                	sd	s1,8(sp)
    80002baa:	1000                	addi	s0,sp,32
    80002bac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	ece080e7          	jalr	-306(ra) # 80002a7c <argraw>
    80002bb6:	e088                	sd	a0,0(s1)
}
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret

0000000080002bc2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc2:	7179                	addi	sp,sp,-48
    80002bc4:	f406                	sd	ra,40(sp)
    80002bc6:	f022                	sd	s0,32(sp)
    80002bc8:	ec26                	sd	s1,24(sp)
    80002bca:	e84a                	sd	s2,16(sp)
    80002bcc:	1800                	addi	s0,sp,48
    80002bce:	84ae                	mv	s1,a1
    80002bd0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bd2:	fd840593          	addi	a1,s0,-40
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	fcc080e7          	jalr	-52(ra) # 80002ba2 <argaddr>
  return fetchstr(addr, buf, max);
    80002bde:	864a                	mv	a2,s2
    80002be0:	85a6                	mv	a1,s1
    80002be2:	fd843503          	ld	a0,-40(s0)
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	f50080e7          	jalr	-176(ra) # 80002b36 <fetchstr>
}
    80002bee:	70a2                	ld	ra,40(sp)
    80002bf0:	7402                	ld	s0,32(sp)
    80002bf2:	64e2                	ld	s1,24(sp)
    80002bf4:	6942                	ld	s2,16(sp)
    80002bf6:	6145                	addi	sp,sp,48
    80002bf8:	8082                	ret

0000000080002bfa <syscall>:
[SYS_map_display]    sys_map_display,
};

void
syscall(void)
{
    80002bfa:	1101                	addi	sp,sp,-32
    80002bfc:	ec06                	sd	ra,24(sp)
    80002bfe:	e822                	sd	s0,16(sp)
    80002c00:	e426                	sd	s1,8(sp)
    80002c02:	e04a                	sd	s2,0(sp)
    80002c04:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	ddc080e7          	jalr	-548(ra) # 800019e2 <myproc>
    80002c0e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c10:	05853903          	ld	s2,88(a0)
    80002c14:	0a893783          	ld	a5,168(s2)
    80002c18:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c1c:	37fd                	addiw	a5,a5,-1
    80002c1e:	4759                	li	a4,22
    80002c20:	00f76f63          	bltu	a4,a5,80002c3e <syscall+0x44>
    80002c24:	00369713          	slli	a4,a3,0x3
    80002c28:	00006797          	auipc	a5,0x6
    80002c2c:	84878793          	addi	a5,a5,-1976 # 80008470 <syscalls>
    80002c30:	97ba                	add	a5,a5,a4
    80002c32:	639c                	ld	a5,0(a5)
    80002c34:	c789                	beqz	a5,80002c3e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c36:	9782                	jalr	a5
    80002c38:	06a93823          	sd	a0,112(s2)
    80002c3c:	a839                	j	80002c5a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c3e:	15848613          	addi	a2,s1,344
    80002c42:	588c                	lw	a1,48(s1)
    80002c44:	00005517          	auipc	a0,0x5
    80002c48:	7f450513          	addi	a0,a0,2036 # 80008438 <states.0+0x150>
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	93c080e7          	jalr	-1732(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c54:	6cbc                	ld	a5,88(s1)
    80002c56:	577d                	li	a4,-1
    80002c58:	fbb8                	sd	a4,112(a5)
  }
}
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	64a2                	ld	s1,8(sp)
    80002c60:	6902                	ld	s2,0(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret

0000000080002c66 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c66:	1101                	addi	sp,sp,-32
    80002c68:	ec06                	sd	ra,24(sp)
    80002c6a:	e822                	sd	s0,16(sp)
    80002c6c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c6e:	fec40593          	addi	a1,s0,-20
    80002c72:	4501                	li	a0,0
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	f0e080e7          	jalr	-242(ra) # 80002b82 <argint>
  exit(n);
    80002c7c:	fec42503          	lw	a0,-20(s0)
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	5ca080e7          	jalr	1482(ra) # 8000224a <exit>
  return 0;  // not reached
}
    80002c88:	4501                	li	a0,0
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	6105                	addi	sp,sp,32
    80002c90:	8082                	ret

0000000080002c92 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c92:	1141                	addi	sp,sp,-16
    80002c94:	e406                	sd	ra,8(sp)
    80002c96:	e022                	sd	s0,0(sp)
    80002c98:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	d48080e7          	jalr	-696(ra) # 800019e2 <myproc>
}
    80002ca2:	5908                	lw	a0,48(a0)
    80002ca4:	60a2                	ld	ra,8(sp)
    80002ca6:	6402                	ld	s0,0(sp)
    80002ca8:	0141                	addi	sp,sp,16
    80002caa:	8082                	ret

0000000080002cac <sys_fork>:

uint64
sys_fork(void)
{
    80002cac:	1141                	addi	sp,sp,-16
    80002cae:	e406                	sd	ra,8(sp)
    80002cb0:	e022                	sd	s0,0(sp)
    80002cb2:	0800                	addi	s0,sp,16
  return fork();
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	170080e7          	jalr	368(ra) # 80001e24 <fork>
}
    80002cbc:	60a2                	ld	ra,8(sp)
    80002cbe:	6402                	ld	s0,0(sp)
    80002cc0:	0141                	addi	sp,sp,16
    80002cc2:	8082                	ret

0000000080002cc4 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ccc:	fe840593          	addi	a1,s0,-24
    80002cd0:	4501                	li	a0,0
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	ed0080e7          	jalr	-304(ra) # 80002ba2 <argaddr>
  return wait(p);
    80002cda:	fe843503          	ld	a0,-24(s0)
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	712080e7          	jalr	1810(ra) # 800023f0 <wait>
}
    80002ce6:	60e2                	ld	ra,24(sp)
    80002ce8:	6442                	ld	s0,16(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cee:	7179                	addi	sp,sp,-48
    80002cf0:	f406                	sd	ra,40(sp)
    80002cf2:	f022                	sd	s0,32(sp)
    80002cf4:	ec26                	sd	s1,24(sp)
    80002cf6:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002cf8:	fdc40593          	addi	a1,s0,-36
    80002cfc:	4501                	li	a0,0
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	e84080e7          	jalr	-380(ra) # 80002b82 <argint>
  addr = myproc()->sz;
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	cdc080e7          	jalr	-804(ra) # 800019e2 <myproc>
    80002d0e:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d10:	fdc42503          	lw	a0,-36(s0)
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	0b4080e7          	jalr	180(ra) # 80001dc8 <growproc>
    80002d1c:	00054863          	bltz	a0,80002d2c <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d20:	8526                	mv	a0,s1
    80002d22:	70a2                	ld	ra,40(sp)
    80002d24:	7402                	ld	s0,32(sp)
    80002d26:	64e2                	ld	s1,24(sp)
    80002d28:	6145                	addi	sp,sp,48
    80002d2a:	8082                	ret
    return -1;
    80002d2c:	54fd                	li	s1,-1
    80002d2e:	bfcd                	j	80002d20 <sys_sbrk+0x32>

0000000080002d30 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d30:	7139                	addi	sp,sp,-64
    80002d32:	fc06                	sd	ra,56(sp)
    80002d34:	f822                	sd	s0,48(sp)
    80002d36:	f426                	sd	s1,40(sp)
    80002d38:	f04a                	sd	s2,32(sp)
    80002d3a:	ec4e                	sd	s3,24(sp)
    80002d3c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d3e:	fcc40593          	addi	a1,s0,-52
    80002d42:	4501                	li	a0,0
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	e3e080e7          	jalr	-450(ra) # 80002b82 <argint>
  acquire(&tickslock);
    80002d4c:	00014517          	auipc	a0,0x14
    80002d50:	7b450513          	addi	a0,a0,1972 # 80017500 <tickslock>
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	e82080e7          	jalr	-382(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d5c:	00006917          	auipc	s2,0x6
    80002d60:	50492903          	lw	s2,1284(s2) # 80009260 <ticks>
  while(ticks - ticks0 < n){
    80002d64:	fcc42783          	lw	a5,-52(s0)
    80002d68:	cf9d                	beqz	a5,80002da6 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d6a:	00014997          	auipc	s3,0x14
    80002d6e:	79698993          	addi	s3,s3,1942 # 80017500 <tickslock>
    80002d72:	00006497          	auipc	s1,0x6
    80002d76:	4ee48493          	addi	s1,s1,1262 # 80009260 <ticks>
    if(killed(myproc())){
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	c68080e7          	jalr	-920(ra) # 800019e2 <myproc>
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	63c080e7          	jalr	1596(ra) # 800023be <killed>
    80002d8a:	ed15                	bnez	a0,80002dc6 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d8c:	85ce                	mv	a1,s3
    80002d8e:	8526                	mv	a0,s1
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	386080e7          	jalr	902(ra) # 80002116 <sleep>
  while(ticks - ticks0 < n){
    80002d98:	409c                	lw	a5,0(s1)
    80002d9a:	412787bb          	subw	a5,a5,s2
    80002d9e:	fcc42703          	lw	a4,-52(s0)
    80002da2:	fce7ece3          	bltu	a5,a4,80002d7a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002da6:	00014517          	auipc	a0,0x14
    80002daa:	75a50513          	addi	a0,a0,1882 # 80017500 <tickslock>
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	edc080e7          	jalr	-292(ra) # 80000c8a <release>
  return 0;
    80002db6:	4501                	li	a0,0
}
    80002db8:	70e2                	ld	ra,56(sp)
    80002dba:	7442                	ld	s0,48(sp)
    80002dbc:	74a2                	ld	s1,40(sp)
    80002dbe:	7902                	ld	s2,32(sp)
    80002dc0:	69e2                	ld	s3,24(sp)
    80002dc2:	6121                	addi	sp,sp,64
    80002dc4:	8082                	ret
      release(&tickslock);
    80002dc6:	00014517          	auipc	a0,0x14
    80002dca:	73a50513          	addi	a0,a0,1850 # 80017500 <tickslock>
    80002dce:	ffffe097          	auipc	ra,0xffffe
    80002dd2:	ebc080e7          	jalr	-324(ra) # 80000c8a <release>
      return -1;
    80002dd6:	557d                	li	a0,-1
    80002dd8:	b7c5                	j	80002db8 <sys_sleep+0x88>

0000000080002dda <sys_kill>:

uint64
sys_kill(void)
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002de2:	fec40593          	addi	a1,s0,-20
    80002de6:	4501                	li	a0,0
    80002de8:	00000097          	auipc	ra,0x0
    80002dec:	d9a080e7          	jalr	-614(ra) # 80002b82 <argint>
  return kill(pid);
    80002df0:	fec42503          	lw	a0,-20(s0)
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	52c080e7          	jalr	1324(ra) # 80002320 <kill>
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e0e:	00014517          	auipc	a0,0x14
    80002e12:	6f250513          	addi	a0,a0,1778 # 80017500 <tickslock>
    80002e16:	ffffe097          	auipc	ra,0xffffe
    80002e1a:	dc0080e7          	jalr	-576(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002e1e:	00006497          	auipc	s1,0x6
    80002e22:	4424a483          	lw	s1,1090(s1) # 80009260 <ticks>
  release(&tickslock);
    80002e26:	00014517          	auipc	a0,0x14
    80002e2a:	6da50513          	addi	a0,a0,1754 # 80017500 <tickslock>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	e5c080e7          	jalr	-420(ra) # 80000c8a <release>
  return xticks;
}
    80002e36:	02049513          	slli	a0,s1,0x20
    80002e3a:	9101                	srli	a0,a0,0x20
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	64a2                	ld	s1,8(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <sys_flip_display>:
// underlying the user buffer buf.  No pixel data is copied.
// buf must be page-aligned and all GPU_FB_PAGES pages must be mapped
// with user permission.  Returns 0 on success, -1 on error.
uint64
sys_flip_display(void)
{
    80002e46:	7121                	addi	sp,sp,-448
    80002e48:	ff06                	sd	ra,440(sp)
    80002e4a:	fb22                	sd	s0,432(sp)
    80002e4c:	f726                	sd	s1,424(sp)
    80002e4e:	f34a                	sd	s2,416(sp)
    80002e50:	ef4e                	sd	s3,408(sp)
    80002e52:	eb52                	sd	s4,400(sp)
    80002e54:	e756                	sd	s5,392(sp)
    80002e56:	e35a                	sd	s6,384(sp)
    80002e58:	0380                	addi	s0,sp,448
    80002e5a:	81010113          	addi	sp,sp,-2032
  uint64 buf;
  argaddr(0, &buf);
    80002e5e:	fb840593          	addi	a1,s0,-72
    80002e62:	4501                	li	a0,0
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	d3e080e7          	jalr	-706(ra) # 80002ba2 <argaddr>

  struct proc *p = myproc();
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	b76080e7          	jalr	-1162(ra) # 800019e2 <myproc>

  if (buf % PGSIZE != 0)
    80002e74:	fb843783          	ld	a5,-72(s0)
    80002e78:	17d2                	slli	a5,a5,0x34
    return -1;
    80002e7a:	5b7d                	li	s6,-1
  if (buf % PGSIZE != 0)
    80002e7c:	ebb9                	bnez	a5,80002ed2 <sys_flip_display+0x8c>
    80002e7e:	89aa                	mv	s3,a0
    80002e80:	0347db13          	srli	s6,a5,0x34
    80002e84:	74fd                	lui	s1,0xfffff
    80002e86:	69848493          	addi	s1,s1,1688 # fffffffffffff698 <end+0xffffffff7ffd7800>
    80002e8a:	fc040793          	addi	a5,s0,-64
    80002e8e:	94be                	add	s1,s1,a5
    80002e90:	fb840a93          	addi	s5,s0,-72
    80002e94:	895a                	mv	s2,s6

  // Walk the user page table to collect physical addresses for each page.
  uint64 phys_pages[GPU_FB_PAGES];
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    80002e96:	6a05                	lui	s4,0x1
    uint64 va = buf + (uint64)i * PGSIZE;
    // walkaddr verifies PTE_V | PTE_U; returns 0 if not mapped or no user perm
    uint64 pa = walkaddr(p->pagetable, va);
    80002e98:	fb843583          	ld	a1,-72(s0)
    80002e9c:	95ca                	add	a1,a1,s2
    80002e9e:	0509b503          	ld	a0,80(s3)
    80002ea2:	ffffe097          	auipc	ra,0xffffe
    80002ea6:	1da080e7          	jalr	474(ra) # 8000107c <walkaddr>
    if (pa == 0)
    80002eaa:	c11d                	beqz	a0,80002ed0 <sys_flip_display+0x8a>
      return -1;
    phys_pages[i] = pa;
    80002eac:	e088                	sd	a0,0(s1)
  for (int i = 0; i < GPU_FB_PAGES; i++) {
    80002eae:	9952                	add	s2,s2,s4
    80002eb0:	04a1                	addi	s1,s1,8
    80002eb2:	ff5493e3          	bne	s1,s5,80002e98 <sys_flip_display+0x52>
  }

  virtio_gpu_flip(phys_pages, GPU_FB_PAGES);
    80002eb6:	12c00593          	li	a1,300
    80002eba:	757d                	lui	a0,0xfffff
    80002ebc:	69850513          	addi	a0,a0,1688 # fffffffffffff698 <end+0xffffffff7ffd7800>
    80002ec0:	fc040793          	addi	a5,s0,-64
    80002ec4:	953e                	add	a0,a0,a5
    80002ec6:	00004097          	auipc	ra,0x4
    80002eca:	cce080e7          	jalr	-818(ra) # 80006b94 <virtio_gpu_flip>
  return 0;
    80002ece:	a011                	j	80002ed2 <sys_flip_display+0x8c>
      return -1;
    80002ed0:	5b7d                	li	s6,-1
}
    80002ed2:	855a                	mv	a0,s6
    80002ed4:	7f010113          	addi	sp,sp,2032
    80002ed8:	70fa                	ld	ra,440(sp)
    80002eda:	745a                	ld	s0,432(sp)
    80002edc:	74ba                	ld	s1,424(sp)
    80002ede:	791a                	ld	s2,416(sp)
    80002ee0:	69fa                	ld	s3,408(sp)
    80002ee2:	6a5a                	ld	s4,400(sp)
    80002ee4:	6aba                	ld	s5,392(sp)
    80002ee6:	6b1a                	ld	s6,384(sp)
    80002ee8:	6139                	addi	sp,sp,448
    80002eea:	8082                	ret

0000000080002eec <sys_map_display>:
// Argument 0: desired virtual address (page-aligned), or 0 to let the
// kernel auto-select a free VA above p->sz.
// Returns the mapped VA on success, (uint64)-1 on failure.
uint64
sys_map_display(void)
{
    80002eec:	7139                	addi	sp,sp,-64
    80002eee:	fc06                	sd	ra,56(sp)
    80002ef0:	f822                	sd	s0,48(sp)
    80002ef2:	f426                	sd	s1,40(sp)
    80002ef4:	f04a                	sd	s2,32(sp)
    80002ef6:	ec4e                	sd	s3,24(sp)
    80002ef8:	e852                	sd	s4,16(sp)
    80002efa:	0080                	addi	s0,sp,64
  uint64 addr;
  argaddr(0, &addr);
    80002efc:	fc840593          	addi	a1,s0,-56
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	ca0080e7          	jalr	-864(ra) # 80002ba2 <argaddr>

  struct proc *p = myproc();
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	ad8080e7          	jalr	-1320(ra) # 800019e2 <myproc>
    80002f12:	892a                	mv	s2,a0

  if (addr == 0) {
    80002f14:	fc843783          	ld	a5,-56(s0)
    80002f18:	eb9d                	bnez	a5,80002f4e <sys_map_display+0x62>
    // Auto-select: first page-aligned VA above the current heap.
    addr = PGROUNDUP(p->sz);
    80002f1a:	653c                	ld	a5,72(a0)
    80002f1c:	6705                	lui	a4,0x1
    80002f1e:	177d                	addi	a4,a4,-1
    80002f20:	97ba                	add	a5,a5,a4
    80002f22:	777d                	lui	a4,0xfffff
    80002f24:	8ff9                	and	a5,a5,a4
    80002f26:	fcf43423          	sd	a5,-56(s0)
    if (addr % PGSIZE != 0)
      return -1;
  }

  // The entire region must fit below the trapframe.
  if (addr + (uint64)GPU_FB_PAGES * PGSIZE > TRAPFRAME)
    80002f2a:	fc843483          	ld	s1,-56(s0)
    80002f2e:	0012c737          	lui	a4,0x12c
    80002f32:	9726                	add	a4,a4,s1
    80002f34:	020007b7          	lui	a5,0x2000
    80002f38:	17fd                	addi	a5,a5,-1
    80002f3a:	07b6                	slli	a5,a5,0xd
    return -1;
    80002f3c:	557d                	li	a0,-1
  if (addr + (uint64)GPU_FB_PAGES * PGSIZE > TRAPFRAME)
    80002f3e:	04e7ef63          	bltu	a5,a4,80002f9c <sys_map_display+0xb0>

  // Verify that no page in the region is already mapped.
  for (uint64 va = addr; va < addr + (uint64)GPU_FB_PAGES * PGSIZE; va += PGSIZE) {
    80002f42:	02e4ff63          	bgeu	s1,a4,80002f80 <sys_map_display+0x94>
    80002f46:	6a05                	lui	s4,0x1
    80002f48:	0012c9b7          	lui	s3,0x12c
    80002f4c:	a821                	j	80002f64 <sys_map_display+0x78>
    if (addr % PGSIZE != 0)
    80002f4e:	17d2                	slli	a5,a5,0x34
      return -1;
    80002f50:	557d                	li	a0,-1
    if (addr % PGSIZE != 0)
    80002f52:	dfe1                	beqz	a5,80002f2a <sys_map_display+0x3e>
    80002f54:	a0a1                	j	80002f9c <sys_map_display+0xb0>
  for (uint64 va = addr; va < addr + (uint64)GPU_FB_PAGES * PGSIZE; va += PGSIZE) {
    80002f56:	94d2                	add	s1,s1,s4
    80002f58:	fc843583          	ld	a1,-56(s0)
    80002f5c:	013587b3          	add	a5,a1,s3
    80002f60:	02f4f163          	bgeu	s1,a5,80002f82 <sys_map_display+0x96>
    pte_t *pte = walk(p->pagetable, va, 0);
    80002f64:	4601                	li	a2,0
    80002f66:	85a6                	mv	a1,s1
    80002f68:	05093503          	ld	a0,80(s2)
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	06a080e7          	jalr	106(ra) # 80000fd6 <walk>
    if (pte && (*pte & PTE_V))
    80002f74:	d16d                	beqz	a0,80002f56 <sys_map_display+0x6a>
    80002f76:	611c                	ld	a5,0(a0)
    80002f78:	8b85                	andi	a5,a5,1
    80002f7a:	dff1                	beqz	a5,80002f56 <sys_map_display+0x6a>
      return -1;
    80002f7c:	557d                	li	a0,-1
    80002f7e:	a839                	j	80002f9c <sys_map_display+0xb0>
  for (uint64 va = addr; va < addr + (uint64)GPU_FB_PAGES * PGSIZE; va += PGSIZE) {
    80002f80:	85a6                	mv	a1,s1
  }

  if (virtio_gpu_map_fb(p->pagetable, addr) != 0)
    80002f82:	05093503          	ld	a0,80(s2)
    80002f86:	00004097          	auipc	ra,0x4
    80002f8a:	b8c080e7          	jalr	-1140(ra) # 80006b12 <virtio_gpu_map_fb>
    80002f8e:	87aa                	mv	a5,a0
    return -1;
    80002f90:	557d                	li	a0,-1
  if (virtio_gpu_map_fb(p->pagetable, addr) != 0)
    80002f92:	e789                	bnez	a5,80002f9c <sys_map_display+0xb0>

  p->fb_map_va = addr;
    80002f94:	fc843503          	ld	a0,-56(s0)
    80002f98:	16a93423          	sd	a0,360(s2)
  return addr;
}
    80002f9c:	70e2                	ld	ra,56(sp)
    80002f9e:	7442                	ld	s0,48(sp)
    80002fa0:	74a2                	ld	s1,40(sp)
    80002fa2:	7902                	ld	s2,32(sp)
    80002fa4:	69e2                	ld	s3,24(sp)
    80002fa6:	6a42                	ld	s4,16(sp)
    80002fa8:	6121                	addi	sp,sp,64
    80002faa:	8082                	ret

0000000080002fac <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fac:	7179                	addi	sp,sp,-48
    80002fae:	f406                	sd	ra,40(sp)
    80002fb0:	f022                	sd	s0,32(sp)
    80002fb2:	ec26                	sd	s1,24(sp)
    80002fb4:	e84a                	sd	s2,16(sp)
    80002fb6:	e44e                	sd	s3,8(sp)
    80002fb8:	e052                	sd	s4,0(sp)
    80002fba:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fbc:	00005597          	auipc	a1,0x5
    80002fc0:	57458593          	addi	a1,a1,1396 # 80008530 <syscalls+0xc0>
    80002fc4:	00014517          	auipc	a0,0x14
    80002fc8:	55450513          	addi	a0,a0,1364 # 80017518 <bcache>
    80002fcc:	ffffe097          	auipc	ra,0xffffe
    80002fd0:	b7a080e7          	jalr	-1158(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fd4:	0001c797          	auipc	a5,0x1c
    80002fd8:	54478793          	addi	a5,a5,1348 # 8001f518 <bcache+0x8000>
    80002fdc:	0001c717          	auipc	a4,0x1c
    80002fe0:	7a470713          	addi	a4,a4,1956 # 8001f780 <bcache+0x8268>
    80002fe4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fe8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fec:	00014497          	auipc	s1,0x14
    80002ff0:	54448493          	addi	s1,s1,1348 # 80017530 <bcache+0x18>
    b->next = bcache.head.next;
    80002ff4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ff6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ff8:	00005a17          	auipc	s4,0x5
    80002ffc:	540a0a13          	addi	s4,s4,1344 # 80008538 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003000:	2b893783          	ld	a5,696(s2)
    80003004:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003006:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000300a:	85d2                	mv	a1,s4
    8000300c:	01048513          	addi	a0,s1,16
    80003010:	00001097          	auipc	ra,0x1
    80003014:	4c4080e7          	jalr	1220(ra) # 800044d4 <initsleeplock>
    bcache.head.next->prev = b;
    80003018:	2b893783          	ld	a5,696(s2)
    8000301c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000301e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003022:	45848493          	addi	s1,s1,1112
    80003026:	fd349de3          	bne	s1,s3,80003000 <binit+0x54>
  }
}
    8000302a:	70a2                	ld	ra,40(sp)
    8000302c:	7402                	ld	s0,32(sp)
    8000302e:	64e2                	ld	s1,24(sp)
    80003030:	6942                	ld	s2,16(sp)
    80003032:	69a2                	ld	s3,8(sp)
    80003034:	6a02                	ld	s4,0(sp)
    80003036:	6145                	addi	sp,sp,48
    80003038:	8082                	ret

000000008000303a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000303a:	7179                	addi	sp,sp,-48
    8000303c:	f406                	sd	ra,40(sp)
    8000303e:	f022                	sd	s0,32(sp)
    80003040:	ec26                	sd	s1,24(sp)
    80003042:	e84a                	sd	s2,16(sp)
    80003044:	e44e                	sd	s3,8(sp)
    80003046:	1800                	addi	s0,sp,48
    80003048:	892a                	mv	s2,a0
    8000304a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000304c:	00014517          	auipc	a0,0x14
    80003050:	4cc50513          	addi	a0,a0,1228 # 80017518 <bcache>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	b82080e7          	jalr	-1150(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000305c:	0001c497          	auipc	s1,0x1c
    80003060:	7744b483          	ld	s1,1908(s1) # 8001f7d0 <bcache+0x82b8>
    80003064:	0001c797          	auipc	a5,0x1c
    80003068:	71c78793          	addi	a5,a5,1820 # 8001f780 <bcache+0x8268>
    8000306c:	02f48f63          	beq	s1,a5,800030aa <bread+0x70>
    80003070:	873e                	mv	a4,a5
    80003072:	a021                	j	8000307a <bread+0x40>
    80003074:	68a4                	ld	s1,80(s1)
    80003076:	02e48a63          	beq	s1,a4,800030aa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000307a:	449c                	lw	a5,8(s1)
    8000307c:	ff279ce3          	bne	a5,s2,80003074 <bread+0x3a>
    80003080:	44dc                	lw	a5,12(s1)
    80003082:	ff3799e3          	bne	a5,s3,80003074 <bread+0x3a>
      b->refcnt++;
    80003086:	40bc                	lw	a5,64(s1)
    80003088:	2785                	addiw	a5,a5,1
    8000308a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	48c50513          	addi	a0,a0,1164 # 80017518 <bcache>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	bf6080e7          	jalr	-1034(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000309c:	01048513          	addi	a0,s1,16
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	46e080e7          	jalr	1134(ra) # 8000450e <acquiresleep>
      return b;
    800030a8:	a8b9                	j	80003106 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030aa:	0001c497          	auipc	s1,0x1c
    800030ae:	71e4b483          	ld	s1,1822(s1) # 8001f7c8 <bcache+0x82b0>
    800030b2:	0001c797          	auipc	a5,0x1c
    800030b6:	6ce78793          	addi	a5,a5,1742 # 8001f780 <bcache+0x8268>
    800030ba:	00f48863          	beq	s1,a5,800030ca <bread+0x90>
    800030be:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030c0:	40bc                	lw	a5,64(s1)
    800030c2:	cf81                	beqz	a5,800030da <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c4:	64a4                	ld	s1,72(s1)
    800030c6:	fee49de3          	bne	s1,a4,800030c0 <bread+0x86>
  panic("bget: no buffers");
    800030ca:	00005517          	auipc	a0,0x5
    800030ce:	47650513          	addi	a0,a0,1142 # 80008540 <syscalls+0xd0>
    800030d2:	ffffd097          	auipc	ra,0xffffd
    800030d6:	46c080e7          	jalr	1132(ra) # 8000053e <panic>
      b->dev = dev;
    800030da:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030de:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030e2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030e6:	4785                	li	a5,1
    800030e8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	42e50513          	addi	a0,a0,1070 # 80017518 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	b98080e7          	jalr	-1128(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030fa:	01048513          	addi	a0,s1,16
    800030fe:	00001097          	auipc	ra,0x1
    80003102:	410080e7          	jalr	1040(ra) # 8000450e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003106:	409c                	lw	a5,0(s1)
    80003108:	cb89                	beqz	a5,8000311a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000310a:	8526                	mv	a0,s1
    8000310c:	70a2                	ld	ra,40(sp)
    8000310e:	7402                	ld	s0,32(sp)
    80003110:	64e2                	ld	s1,24(sp)
    80003112:	6942                	ld	s2,16(sp)
    80003114:	69a2                	ld	s3,8(sp)
    80003116:	6145                	addi	sp,sp,48
    80003118:	8082                	ret
    virtio_disk_rw(b, 0);
    8000311a:	4581                	li	a1,0
    8000311c:	8526                	mv	a0,s1
    8000311e:	00003097          	auipc	ra,0x3
    80003122:	ff6080e7          	jalr	-10(ra) # 80006114 <virtio_disk_rw>
    b->valid = 1;
    80003126:	4785                	li	a5,1
    80003128:	c09c                	sw	a5,0(s1)
  return b;
    8000312a:	b7c5                	j	8000310a <bread+0xd0>

000000008000312c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000312c:	1101                	addi	sp,sp,-32
    8000312e:	ec06                	sd	ra,24(sp)
    80003130:	e822                	sd	s0,16(sp)
    80003132:	e426                	sd	s1,8(sp)
    80003134:	1000                	addi	s0,sp,32
    80003136:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003138:	0541                	addi	a0,a0,16
    8000313a:	00001097          	auipc	ra,0x1
    8000313e:	46e080e7          	jalr	1134(ra) # 800045a8 <holdingsleep>
    80003142:	cd01                	beqz	a0,8000315a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003144:	4585                	li	a1,1
    80003146:	8526                	mv	a0,s1
    80003148:	00003097          	auipc	ra,0x3
    8000314c:	fcc080e7          	jalr	-52(ra) # 80006114 <virtio_disk_rw>
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6105                	addi	sp,sp,32
    80003158:	8082                	ret
    panic("bwrite");
    8000315a:	00005517          	auipc	a0,0x5
    8000315e:	3fe50513          	addi	a0,a0,1022 # 80008558 <syscalls+0xe8>
    80003162:	ffffd097          	auipc	ra,0xffffd
    80003166:	3dc080e7          	jalr	988(ra) # 8000053e <panic>

000000008000316a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	e04a                	sd	s2,0(sp)
    80003174:	1000                	addi	s0,sp,32
    80003176:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003178:	01050913          	addi	s2,a0,16
    8000317c:	854a                	mv	a0,s2
    8000317e:	00001097          	auipc	ra,0x1
    80003182:	42a080e7          	jalr	1066(ra) # 800045a8 <holdingsleep>
    80003186:	c92d                	beqz	a0,800031f8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003188:	854a                	mv	a0,s2
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	3da080e7          	jalr	986(ra) # 80004564 <releasesleep>

  acquire(&bcache.lock);
    80003192:	00014517          	auipc	a0,0x14
    80003196:	38650513          	addi	a0,a0,902 # 80017518 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	a3c080e7          	jalr	-1476(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031a2:	40bc                	lw	a5,64(s1)
    800031a4:	37fd                	addiw	a5,a5,-1
    800031a6:	0007871b          	sext.w	a4,a5
    800031aa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031ac:	eb05                	bnez	a4,800031dc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031ae:	68bc                	ld	a5,80(s1)
    800031b0:	64b8                	ld	a4,72(s1)
    800031b2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031b4:	64bc                	ld	a5,72(s1)
    800031b6:	68b8                	ld	a4,80(s1)
    800031b8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031ba:	0001c797          	auipc	a5,0x1c
    800031be:	35e78793          	addi	a5,a5,862 # 8001f518 <bcache+0x8000>
    800031c2:	2b87b703          	ld	a4,696(a5)
    800031c6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031c8:	0001c717          	auipc	a4,0x1c
    800031cc:	5b870713          	addi	a4,a4,1464 # 8001f780 <bcache+0x8268>
    800031d0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031d2:	2b87b703          	ld	a4,696(a5)
    800031d6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031d8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031dc:	00014517          	auipc	a0,0x14
    800031e0:	33c50513          	addi	a0,a0,828 # 80017518 <bcache>
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	aa6080e7          	jalr	-1370(ra) # 80000c8a <release>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6902                	ld	s2,0(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret
    panic("brelse");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	36850513          	addi	a0,a0,872 # 80008560 <syscalls+0xf0>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	33e080e7          	jalr	830(ra) # 8000053e <panic>

0000000080003208 <bpin>:

void
bpin(struct buf *b) {
    80003208:	1101                	addi	sp,sp,-32
    8000320a:	ec06                	sd	ra,24(sp)
    8000320c:	e822                	sd	s0,16(sp)
    8000320e:	e426                	sd	s1,8(sp)
    80003210:	1000                	addi	s0,sp,32
    80003212:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003214:	00014517          	auipc	a0,0x14
    80003218:	30450513          	addi	a0,a0,772 # 80017518 <bcache>
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	9ba080e7          	jalr	-1606(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003224:	40bc                	lw	a5,64(s1)
    80003226:	2785                	addiw	a5,a5,1
    80003228:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000322a:	00014517          	auipc	a0,0x14
    8000322e:	2ee50513          	addi	a0,a0,750 # 80017518 <bcache>
    80003232:	ffffe097          	auipc	ra,0xffffe
    80003236:	a58080e7          	jalr	-1448(ra) # 80000c8a <release>
}
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	64a2                	ld	s1,8(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret

0000000080003244 <bunpin>:

void
bunpin(struct buf *b) {
    80003244:	1101                	addi	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	e426                	sd	s1,8(sp)
    8000324c:	1000                	addi	s0,sp,32
    8000324e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003250:	00014517          	auipc	a0,0x14
    80003254:	2c850513          	addi	a0,a0,712 # 80017518 <bcache>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	97e080e7          	jalr	-1666(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003260:	40bc                	lw	a5,64(s1)
    80003262:	37fd                	addiw	a5,a5,-1
    80003264:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	2b250513          	addi	a0,a0,690 # 80017518 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	a1c080e7          	jalr	-1508(ra) # 80000c8a <release>
}
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	64a2                	ld	s1,8(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret

0000000080003280 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003280:	1101                	addi	sp,sp,-32
    80003282:	ec06                	sd	ra,24(sp)
    80003284:	e822                	sd	s0,16(sp)
    80003286:	e426                	sd	s1,8(sp)
    80003288:	e04a                	sd	s2,0(sp)
    8000328a:	1000                	addi	s0,sp,32
    8000328c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000328e:	00d5d59b          	srliw	a1,a1,0xd
    80003292:	0001d797          	auipc	a5,0x1d
    80003296:	9627a783          	lw	a5,-1694(a5) # 8001fbf4 <sb+0x1c>
    8000329a:	9dbd                	addw	a1,a1,a5
    8000329c:	00000097          	auipc	ra,0x0
    800032a0:	d9e080e7          	jalr	-610(ra) # 8000303a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032a4:	0074f713          	andi	a4,s1,7
    800032a8:	4785                	li	a5,1
    800032aa:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032ae:	14ce                	slli	s1,s1,0x33
    800032b0:	90d9                	srli	s1,s1,0x36
    800032b2:	00950733          	add	a4,a0,s1
    800032b6:	05874703          	lbu	a4,88(a4)
    800032ba:	00e7f6b3          	and	a3,a5,a4
    800032be:	c69d                	beqz	a3,800032ec <bfree+0x6c>
    800032c0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032c2:	94aa                	add	s1,s1,a0
    800032c4:	fff7c793          	not	a5,a5
    800032c8:	8ff9                	and	a5,a5,a4
    800032ca:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032ce:	00001097          	auipc	ra,0x1
    800032d2:	120080e7          	jalr	288(ra) # 800043ee <log_write>
  brelse(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	e92080e7          	jalr	-366(ra) # 8000316a <brelse>
}
    800032e0:	60e2                	ld	ra,24(sp)
    800032e2:	6442                	ld	s0,16(sp)
    800032e4:	64a2                	ld	s1,8(sp)
    800032e6:	6902                	ld	s2,0(sp)
    800032e8:	6105                	addi	sp,sp,32
    800032ea:	8082                	ret
    panic("freeing free block");
    800032ec:	00005517          	auipc	a0,0x5
    800032f0:	27c50513          	addi	a0,a0,636 # 80008568 <syscalls+0xf8>
    800032f4:	ffffd097          	auipc	ra,0xffffd
    800032f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>

00000000800032fc <balloc>:
{
    800032fc:	711d                	addi	sp,sp,-96
    800032fe:	ec86                	sd	ra,88(sp)
    80003300:	e8a2                	sd	s0,80(sp)
    80003302:	e4a6                	sd	s1,72(sp)
    80003304:	e0ca                	sd	s2,64(sp)
    80003306:	fc4e                	sd	s3,56(sp)
    80003308:	f852                	sd	s4,48(sp)
    8000330a:	f456                	sd	s5,40(sp)
    8000330c:	f05a                	sd	s6,32(sp)
    8000330e:	ec5e                	sd	s7,24(sp)
    80003310:	e862                	sd	s8,16(sp)
    80003312:	e466                	sd	s9,8(sp)
    80003314:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003316:	0001d797          	auipc	a5,0x1d
    8000331a:	8c67a783          	lw	a5,-1850(a5) # 8001fbdc <sb+0x4>
    8000331e:	10078163          	beqz	a5,80003420 <balloc+0x124>
    80003322:	8baa                	mv	s7,a0
    80003324:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003326:	0001db17          	auipc	s6,0x1d
    8000332a:	8b2b0b13          	addi	s6,s6,-1870 # 8001fbd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003330:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003332:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003334:	6c89                	lui	s9,0x2
    80003336:	a061                	j	800033be <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003338:	974a                	add	a4,a4,s2
    8000333a:	8fd5                	or	a5,a5,a3
    8000333c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003340:	854a                	mv	a0,s2
    80003342:	00001097          	auipc	ra,0x1
    80003346:	0ac080e7          	jalr	172(ra) # 800043ee <log_write>
        brelse(bp);
    8000334a:	854a                	mv	a0,s2
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	e1e080e7          	jalr	-482(ra) # 8000316a <brelse>
  bp = bread(dev, bno);
    80003354:	85a6                	mv	a1,s1
    80003356:	855e                	mv	a0,s7
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	ce2080e7          	jalr	-798(ra) # 8000303a <bread>
    80003360:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003362:	40000613          	li	a2,1024
    80003366:	4581                	li	a1,0
    80003368:	05850513          	addi	a0,a0,88
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	966080e7          	jalr	-1690(ra) # 80000cd2 <memset>
  log_write(bp);
    80003374:	854a                	mv	a0,s2
    80003376:	00001097          	auipc	ra,0x1
    8000337a:	078080e7          	jalr	120(ra) # 800043ee <log_write>
  brelse(bp);
    8000337e:	854a                	mv	a0,s2
    80003380:	00000097          	auipc	ra,0x0
    80003384:	dea080e7          	jalr	-534(ra) # 8000316a <brelse>
}
    80003388:	8526                	mv	a0,s1
    8000338a:	60e6                	ld	ra,88(sp)
    8000338c:	6446                	ld	s0,80(sp)
    8000338e:	64a6                	ld	s1,72(sp)
    80003390:	6906                	ld	s2,64(sp)
    80003392:	79e2                	ld	s3,56(sp)
    80003394:	7a42                	ld	s4,48(sp)
    80003396:	7aa2                	ld	s5,40(sp)
    80003398:	7b02                	ld	s6,32(sp)
    8000339a:	6be2                	ld	s7,24(sp)
    8000339c:	6c42                	ld	s8,16(sp)
    8000339e:	6ca2                	ld	s9,8(sp)
    800033a0:	6125                	addi	sp,sp,96
    800033a2:	8082                	ret
    brelse(bp);
    800033a4:	854a                	mv	a0,s2
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	dc4080e7          	jalr	-572(ra) # 8000316a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033ae:	015c87bb          	addw	a5,s9,s5
    800033b2:	00078a9b          	sext.w	s5,a5
    800033b6:	004b2703          	lw	a4,4(s6)
    800033ba:	06eaf363          	bgeu	s5,a4,80003420 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800033be:	41fad79b          	sraiw	a5,s5,0x1f
    800033c2:	0137d79b          	srliw	a5,a5,0x13
    800033c6:	015787bb          	addw	a5,a5,s5
    800033ca:	40d7d79b          	sraiw	a5,a5,0xd
    800033ce:	01cb2583          	lw	a1,28(s6)
    800033d2:	9dbd                	addw	a1,a1,a5
    800033d4:	855e                	mv	a0,s7
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	c64080e7          	jalr	-924(ra) # 8000303a <bread>
    800033de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033e0:	004b2503          	lw	a0,4(s6)
    800033e4:	000a849b          	sext.w	s1,s5
    800033e8:	8662                	mv	a2,s8
    800033ea:	faa4fde3          	bgeu	s1,a0,800033a4 <balloc+0xa8>
      m = 1 << (bi % 8);
    800033ee:	41f6579b          	sraiw	a5,a2,0x1f
    800033f2:	01d7d69b          	srliw	a3,a5,0x1d
    800033f6:	00c6873b          	addw	a4,a3,a2
    800033fa:	00777793          	andi	a5,a4,7
    800033fe:	9f95                	subw	a5,a5,a3
    80003400:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003404:	4037571b          	sraiw	a4,a4,0x3
    80003408:	00e906b3          	add	a3,s2,a4
    8000340c:	0586c683          	lbu	a3,88(a3)
    80003410:	00d7f5b3          	and	a1,a5,a3
    80003414:	d195                	beqz	a1,80003338 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003416:	2605                	addiw	a2,a2,1
    80003418:	2485                	addiw	s1,s1,1
    8000341a:	fd4618e3          	bne	a2,s4,800033ea <balloc+0xee>
    8000341e:	b759                	j	800033a4 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003420:	00005517          	auipc	a0,0x5
    80003424:	16050513          	addi	a0,a0,352 # 80008580 <syscalls+0x110>
    80003428:	ffffd097          	auipc	ra,0xffffd
    8000342c:	160080e7          	jalr	352(ra) # 80000588 <printf>
  return 0;
    80003430:	4481                	li	s1,0
    80003432:	bf99                	j	80003388 <balloc+0x8c>

0000000080003434 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003434:	7179                	addi	sp,sp,-48
    80003436:	f406                	sd	ra,40(sp)
    80003438:	f022                	sd	s0,32(sp)
    8000343a:	ec26                	sd	s1,24(sp)
    8000343c:	e84a                	sd	s2,16(sp)
    8000343e:	e44e                	sd	s3,8(sp)
    80003440:	e052                	sd	s4,0(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003446:	47ad                	li	a5,11
    80003448:	02b7e763          	bltu	a5,a1,80003476 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000344c:	02059493          	slli	s1,a1,0x20
    80003450:	9081                	srli	s1,s1,0x20
    80003452:	048a                	slli	s1,s1,0x2
    80003454:	94aa                	add	s1,s1,a0
    80003456:	0504a903          	lw	s2,80(s1)
    8000345a:	06091e63          	bnez	s2,800034d6 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000345e:	4108                	lw	a0,0(a0)
    80003460:	00000097          	auipc	ra,0x0
    80003464:	e9c080e7          	jalr	-356(ra) # 800032fc <balloc>
    80003468:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000346c:	06090563          	beqz	s2,800034d6 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003470:	0524a823          	sw	s2,80(s1)
    80003474:	a08d                	j	800034d6 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003476:	ff45849b          	addiw	s1,a1,-12
    8000347a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000347e:	0ff00793          	li	a5,255
    80003482:	08e7e563          	bltu	a5,a4,8000350c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003486:	08052903          	lw	s2,128(a0)
    8000348a:	00091d63          	bnez	s2,800034a4 <bmap+0x70>
      addr = balloc(ip->dev);
    8000348e:	4108                	lw	a0,0(a0)
    80003490:	00000097          	auipc	ra,0x0
    80003494:	e6c080e7          	jalr	-404(ra) # 800032fc <balloc>
    80003498:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000349c:	02090d63          	beqz	s2,800034d6 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034a0:	0929a023          	sw	s2,128(s3) # 12c080 <_entry-0x7fed3f80>
    }
    bp = bread(ip->dev, addr);
    800034a4:	85ca                	mv	a1,s2
    800034a6:	0009a503          	lw	a0,0(s3)
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	b90080e7          	jalr	-1136(ra) # 8000303a <bread>
    800034b2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034b4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034b8:	02049593          	slli	a1,s1,0x20
    800034bc:	9181                	srli	a1,a1,0x20
    800034be:	058a                	slli	a1,a1,0x2
    800034c0:	00b784b3          	add	s1,a5,a1
    800034c4:	0004a903          	lw	s2,0(s1)
    800034c8:	02090063          	beqz	s2,800034e8 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034cc:	8552                	mv	a0,s4
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	c9c080e7          	jalr	-868(ra) # 8000316a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034d6:	854a                	mv	a0,s2
    800034d8:	70a2                	ld	ra,40(sp)
    800034da:	7402                	ld	s0,32(sp)
    800034dc:	64e2                	ld	s1,24(sp)
    800034de:	6942                	ld	s2,16(sp)
    800034e0:	69a2                	ld	s3,8(sp)
    800034e2:	6a02                	ld	s4,0(sp)
    800034e4:	6145                	addi	sp,sp,48
    800034e6:	8082                	ret
      addr = balloc(ip->dev);
    800034e8:	0009a503          	lw	a0,0(s3)
    800034ec:	00000097          	auipc	ra,0x0
    800034f0:	e10080e7          	jalr	-496(ra) # 800032fc <balloc>
    800034f4:	0005091b          	sext.w	s2,a0
      if(addr){
    800034f8:	fc090ae3          	beqz	s2,800034cc <bmap+0x98>
        a[bn] = addr;
    800034fc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003500:	8552                	mv	a0,s4
    80003502:	00001097          	auipc	ra,0x1
    80003506:	eec080e7          	jalr	-276(ra) # 800043ee <log_write>
    8000350a:	b7c9                	j	800034cc <bmap+0x98>
  panic("bmap: out of range");
    8000350c:	00005517          	auipc	a0,0x5
    80003510:	08c50513          	addi	a0,a0,140 # 80008598 <syscalls+0x128>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	02a080e7          	jalr	42(ra) # 8000053e <panic>

000000008000351c <iget>:
{
    8000351c:	7179                	addi	sp,sp,-48
    8000351e:	f406                	sd	ra,40(sp)
    80003520:	f022                	sd	s0,32(sp)
    80003522:	ec26                	sd	s1,24(sp)
    80003524:	e84a                	sd	s2,16(sp)
    80003526:	e44e                	sd	s3,8(sp)
    80003528:	e052                	sd	s4,0(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	89aa                	mv	s3,a0
    8000352e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003530:	0001c517          	auipc	a0,0x1c
    80003534:	6c850513          	addi	a0,a0,1736 # 8001fbf8 <itable>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	69e080e7          	jalr	1694(ra) # 80000bd6 <acquire>
  empty = 0;
    80003540:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003542:	0001c497          	auipc	s1,0x1c
    80003546:	6ce48493          	addi	s1,s1,1742 # 8001fc10 <itable+0x18>
    8000354a:	0001e697          	auipc	a3,0x1e
    8000354e:	15668693          	addi	a3,a3,342 # 800216a0 <log>
    80003552:	a039                	j	80003560 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003554:	02090b63          	beqz	s2,8000358a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003558:	08848493          	addi	s1,s1,136
    8000355c:	02d48a63          	beq	s1,a3,80003590 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003560:	449c                	lw	a5,8(s1)
    80003562:	fef059e3          	blez	a5,80003554 <iget+0x38>
    80003566:	4098                	lw	a4,0(s1)
    80003568:	ff3716e3          	bne	a4,s3,80003554 <iget+0x38>
    8000356c:	40d8                	lw	a4,4(s1)
    8000356e:	ff4713e3          	bne	a4,s4,80003554 <iget+0x38>
      ip->ref++;
    80003572:	2785                	addiw	a5,a5,1
    80003574:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003576:	0001c517          	auipc	a0,0x1c
    8000357a:	68250513          	addi	a0,a0,1666 # 8001fbf8 <itable>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	70c080e7          	jalr	1804(ra) # 80000c8a <release>
      return ip;
    80003586:	8926                	mv	s2,s1
    80003588:	a03d                	j	800035b6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358a:	f7f9                	bnez	a5,80003558 <iget+0x3c>
    8000358c:	8926                	mv	s2,s1
    8000358e:	b7e9                	j	80003558 <iget+0x3c>
  if(empty == 0)
    80003590:	02090c63          	beqz	s2,800035c8 <iget+0xac>
  ip->dev = dev;
    80003594:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003598:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000359c:	4785                	li	a5,1
    8000359e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035a6:	0001c517          	auipc	a0,0x1c
    800035aa:	65250513          	addi	a0,a0,1618 # 8001fbf8 <itable>
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	6dc080e7          	jalr	1756(ra) # 80000c8a <release>
}
    800035b6:	854a                	mv	a0,s2
    800035b8:	70a2                	ld	ra,40(sp)
    800035ba:	7402                	ld	s0,32(sp)
    800035bc:	64e2                	ld	s1,24(sp)
    800035be:	6942                	ld	s2,16(sp)
    800035c0:	69a2                	ld	s3,8(sp)
    800035c2:	6a02                	ld	s4,0(sp)
    800035c4:	6145                	addi	sp,sp,48
    800035c6:	8082                	ret
    panic("iget: no inodes");
    800035c8:	00005517          	auipc	a0,0x5
    800035cc:	fe850513          	addi	a0,a0,-24 # 800085b0 <syscalls+0x140>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>

00000000800035d8 <fsinit>:
fsinit(int dev) {
    800035d8:	7179                	addi	sp,sp,-48
    800035da:	f406                	sd	ra,40(sp)
    800035dc:	f022                	sd	s0,32(sp)
    800035de:	ec26                	sd	s1,24(sp)
    800035e0:	e84a                	sd	s2,16(sp)
    800035e2:	e44e                	sd	s3,8(sp)
    800035e4:	1800                	addi	s0,sp,48
    800035e6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035e8:	4585                	li	a1,1
    800035ea:	00000097          	auipc	ra,0x0
    800035ee:	a50080e7          	jalr	-1456(ra) # 8000303a <bread>
    800035f2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035f4:	0001c997          	auipc	s3,0x1c
    800035f8:	5e498993          	addi	s3,s3,1508 # 8001fbd8 <sb>
    800035fc:	02000613          	li	a2,32
    80003600:	05850593          	addi	a1,a0,88
    80003604:	854e                	mv	a0,s3
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	728080e7          	jalr	1832(ra) # 80000d2e <memmove>
  brelse(bp);
    8000360e:	8526                	mv	a0,s1
    80003610:	00000097          	auipc	ra,0x0
    80003614:	b5a080e7          	jalr	-1190(ra) # 8000316a <brelse>
  if(sb.magic != FSMAGIC)
    80003618:	0009a703          	lw	a4,0(s3)
    8000361c:	102037b7          	lui	a5,0x10203
    80003620:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003624:	02f71263          	bne	a4,a5,80003648 <fsinit+0x70>
  initlog(dev, &sb);
    80003628:	0001c597          	auipc	a1,0x1c
    8000362c:	5b058593          	addi	a1,a1,1456 # 8001fbd8 <sb>
    80003630:	854a                	mv	a0,s2
    80003632:	00001097          	auipc	ra,0x1
    80003636:	b40080e7          	jalr	-1216(ra) # 80004172 <initlog>
}
    8000363a:	70a2                	ld	ra,40(sp)
    8000363c:	7402                	ld	s0,32(sp)
    8000363e:	64e2                	ld	s1,24(sp)
    80003640:	6942                	ld	s2,16(sp)
    80003642:	69a2                	ld	s3,8(sp)
    80003644:	6145                	addi	sp,sp,48
    80003646:	8082                	ret
    panic("invalid file system");
    80003648:	00005517          	auipc	a0,0x5
    8000364c:	f7850513          	addi	a0,a0,-136 # 800085c0 <syscalls+0x150>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	eee080e7          	jalr	-274(ra) # 8000053e <panic>

0000000080003658 <iinit>:
{
    80003658:	7179                	addi	sp,sp,-48
    8000365a:	f406                	sd	ra,40(sp)
    8000365c:	f022                	sd	s0,32(sp)
    8000365e:	ec26                	sd	s1,24(sp)
    80003660:	e84a                	sd	s2,16(sp)
    80003662:	e44e                	sd	s3,8(sp)
    80003664:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003666:	00005597          	auipc	a1,0x5
    8000366a:	f7258593          	addi	a1,a1,-142 # 800085d8 <syscalls+0x168>
    8000366e:	0001c517          	auipc	a0,0x1c
    80003672:	58a50513          	addi	a0,a0,1418 # 8001fbf8 <itable>
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	4d0080e7          	jalr	1232(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000367e:	0001c497          	auipc	s1,0x1c
    80003682:	5a248493          	addi	s1,s1,1442 # 8001fc20 <itable+0x28>
    80003686:	0001e997          	auipc	s3,0x1e
    8000368a:	02a98993          	addi	s3,s3,42 # 800216b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000368e:	00005917          	auipc	s2,0x5
    80003692:	f5290913          	addi	s2,s2,-174 # 800085e0 <syscalls+0x170>
    80003696:	85ca                	mv	a1,s2
    80003698:	8526                	mv	a0,s1
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	e3a080e7          	jalr	-454(ra) # 800044d4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a2:	08848493          	addi	s1,s1,136
    800036a6:	ff3498e3          	bne	s1,s3,80003696 <iinit+0x3e>
}
    800036aa:	70a2                	ld	ra,40(sp)
    800036ac:	7402                	ld	s0,32(sp)
    800036ae:	64e2                	ld	s1,24(sp)
    800036b0:	6942                	ld	s2,16(sp)
    800036b2:	69a2                	ld	s3,8(sp)
    800036b4:	6145                	addi	sp,sp,48
    800036b6:	8082                	ret

00000000800036b8 <ialloc>:
{
    800036b8:	715d                	addi	sp,sp,-80
    800036ba:	e486                	sd	ra,72(sp)
    800036bc:	e0a2                	sd	s0,64(sp)
    800036be:	fc26                	sd	s1,56(sp)
    800036c0:	f84a                	sd	s2,48(sp)
    800036c2:	f44e                	sd	s3,40(sp)
    800036c4:	f052                	sd	s4,32(sp)
    800036c6:	ec56                	sd	s5,24(sp)
    800036c8:	e85a                	sd	s6,16(sp)
    800036ca:	e45e                	sd	s7,8(sp)
    800036cc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ce:	0001c717          	auipc	a4,0x1c
    800036d2:	51672703          	lw	a4,1302(a4) # 8001fbe4 <sb+0xc>
    800036d6:	4785                	li	a5,1
    800036d8:	04e7fa63          	bgeu	a5,a4,8000372c <ialloc+0x74>
    800036dc:	8aaa                	mv	s5,a0
    800036de:	8bae                	mv	s7,a1
    800036e0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e2:	0001ca17          	auipc	s4,0x1c
    800036e6:	4f6a0a13          	addi	s4,s4,1270 # 8001fbd8 <sb>
    800036ea:	00048b1b          	sext.w	s6,s1
    800036ee:	0044d793          	srli	a5,s1,0x4
    800036f2:	018a2583          	lw	a1,24(s4)
    800036f6:	9dbd                	addw	a1,a1,a5
    800036f8:	8556                	mv	a0,s5
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	940080e7          	jalr	-1728(ra) # 8000303a <bread>
    80003702:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003704:	05850993          	addi	s3,a0,88
    80003708:	00f4f793          	andi	a5,s1,15
    8000370c:	079a                	slli	a5,a5,0x6
    8000370e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003710:	00099783          	lh	a5,0(s3)
    80003714:	c3a1                	beqz	a5,80003754 <ialloc+0x9c>
    brelse(bp);
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	a54080e7          	jalr	-1452(ra) # 8000316a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000371e:	0485                	addi	s1,s1,1
    80003720:	00ca2703          	lw	a4,12(s4)
    80003724:	0004879b          	sext.w	a5,s1
    80003728:	fce7e1e3          	bltu	a5,a4,800036ea <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000372c:	00005517          	auipc	a0,0x5
    80003730:	ebc50513          	addi	a0,a0,-324 # 800085e8 <syscalls+0x178>
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	e54080e7          	jalr	-428(ra) # 80000588 <printf>
  return 0;
    8000373c:	4501                	li	a0,0
}
    8000373e:	60a6                	ld	ra,72(sp)
    80003740:	6406                	ld	s0,64(sp)
    80003742:	74e2                	ld	s1,56(sp)
    80003744:	7942                	ld	s2,48(sp)
    80003746:	79a2                	ld	s3,40(sp)
    80003748:	7a02                	ld	s4,32(sp)
    8000374a:	6ae2                	ld	s5,24(sp)
    8000374c:	6b42                	ld	s6,16(sp)
    8000374e:	6ba2                	ld	s7,8(sp)
    80003750:	6161                	addi	sp,sp,80
    80003752:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003754:	04000613          	li	a2,64
    80003758:	4581                	li	a1,0
    8000375a:	854e                	mv	a0,s3
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	576080e7          	jalr	1398(ra) # 80000cd2 <memset>
      dip->type = type;
    80003764:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003768:	854a                	mv	a0,s2
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	c84080e7          	jalr	-892(ra) # 800043ee <log_write>
      brelse(bp);
    80003772:	854a                	mv	a0,s2
    80003774:	00000097          	auipc	ra,0x0
    80003778:	9f6080e7          	jalr	-1546(ra) # 8000316a <brelse>
      return iget(dev, inum);
    8000377c:	85da                	mv	a1,s6
    8000377e:	8556                	mv	a0,s5
    80003780:	00000097          	auipc	ra,0x0
    80003784:	d9c080e7          	jalr	-612(ra) # 8000351c <iget>
    80003788:	bf5d                	j	8000373e <ialloc+0x86>

000000008000378a <iupdate>:
{
    8000378a:	1101                	addi	sp,sp,-32
    8000378c:	ec06                	sd	ra,24(sp)
    8000378e:	e822                	sd	s0,16(sp)
    80003790:	e426                	sd	s1,8(sp)
    80003792:	e04a                	sd	s2,0(sp)
    80003794:	1000                	addi	s0,sp,32
    80003796:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003798:	415c                	lw	a5,4(a0)
    8000379a:	0047d79b          	srliw	a5,a5,0x4
    8000379e:	0001c597          	auipc	a1,0x1c
    800037a2:	4525a583          	lw	a1,1106(a1) # 8001fbf0 <sb+0x18>
    800037a6:	9dbd                	addw	a1,a1,a5
    800037a8:	4108                	lw	a0,0(a0)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	890080e7          	jalr	-1904(ra) # 8000303a <bread>
    800037b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037b4:	05850793          	addi	a5,a0,88
    800037b8:	40c8                	lw	a0,4(s1)
    800037ba:	893d                	andi	a0,a0,15
    800037bc:	051a                	slli	a0,a0,0x6
    800037be:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037c0:	04449703          	lh	a4,68(s1)
    800037c4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037c8:	04649703          	lh	a4,70(s1)
    800037cc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037d0:	04849703          	lh	a4,72(s1)
    800037d4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037d8:	04a49703          	lh	a4,74(s1)
    800037dc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037e0:	44f8                	lw	a4,76(s1)
    800037e2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037e4:	03400613          	li	a2,52
    800037e8:	05048593          	addi	a1,s1,80
    800037ec:	0531                	addi	a0,a0,12
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	540080e7          	jalr	1344(ra) # 80000d2e <memmove>
  log_write(bp);
    800037f6:	854a                	mv	a0,s2
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	bf6080e7          	jalr	-1034(ra) # 800043ee <log_write>
  brelse(bp);
    80003800:	854a                	mv	a0,s2
    80003802:	00000097          	auipc	ra,0x0
    80003806:	968080e7          	jalr	-1688(ra) # 8000316a <brelse>
}
    8000380a:	60e2                	ld	ra,24(sp)
    8000380c:	6442                	ld	s0,16(sp)
    8000380e:	64a2                	ld	s1,8(sp)
    80003810:	6902                	ld	s2,0(sp)
    80003812:	6105                	addi	sp,sp,32
    80003814:	8082                	ret

0000000080003816 <idup>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003822:	0001c517          	auipc	a0,0x1c
    80003826:	3d650513          	addi	a0,a0,982 # 8001fbf8 <itable>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	3ac080e7          	jalr	940(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003832:	449c                	lw	a5,8(s1)
    80003834:	2785                	addiw	a5,a5,1
    80003836:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003838:	0001c517          	auipc	a0,0x1c
    8000383c:	3c050513          	addi	a0,a0,960 # 8001fbf8 <itable>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	44a080e7          	jalr	1098(ra) # 80000c8a <release>
}
    80003848:	8526                	mv	a0,s1
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6105                	addi	sp,sp,32
    80003852:	8082                	ret

0000000080003854 <ilock>:
{
    80003854:	1101                	addi	sp,sp,-32
    80003856:	ec06                	sd	ra,24(sp)
    80003858:	e822                	sd	s0,16(sp)
    8000385a:	e426                	sd	s1,8(sp)
    8000385c:	e04a                	sd	s2,0(sp)
    8000385e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003860:	c115                	beqz	a0,80003884 <ilock+0x30>
    80003862:	84aa                	mv	s1,a0
    80003864:	451c                	lw	a5,8(a0)
    80003866:	00f05f63          	blez	a5,80003884 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000386a:	0541                	addi	a0,a0,16
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	ca2080e7          	jalr	-862(ra) # 8000450e <acquiresleep>
  if(ip->valid == 0){
    80003874:	40bc                	lw	a5,64(s1)
    80003876:	cf99                	beqz	a5,80003894 <ilock+0x40>
}
    80003878:	60e2                	ld	ra,24(sp)
    8000387a:	6442                	ld	s0,16(sp)
    8000387c:	64a2                	ld	s1,8(sp)
    8000387e:	6902                	ld	s2,0(sp)
    80003880:	6105                	addi	sp,sp,32
    80003882:	8082                	ret
    panic("ilock");
    80003884:	00005517          	auipc	a0,0x5
    80003888:	d7c50513          	addi	a0,a0,-644 # 80008600 <syscalls+0x190>
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	cb2080e7          	jalr	-846(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003894:	40dc                	lw	a5,4(s1)
    80003896:	0047d79b          	srliw	a5,a5,0x4
    8000389a:	0001c597          	auipc	a1,0x1c
    8000389e:	3565a583          	lw	a1,854(a1) # 8001fbf0 <sb+0x18>
    800038a2:	9dbd                	addw	a1,a1,a5
    800038a4:	4088                	lw	a0,0(s1)
    800038a6:	fffff097          	auipc	ra,0xfffff
    800038aa:	794080e7          	jalr	1940(ra) # 8000303a <bread>
    800038ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038b0:	05850593          	addi	a1,a0,88
    800038b4:	40dc                	lw	a5,4(s1)
    800038b6:	8bbd                	andi	a5,a5,15
    800038b8:	079a                	slli	a5,a5,0x6
    800038ba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038bc:	00059783          	lh	a5,0(a1)
    800038c0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038c4:	00259783          	lh	a5,2(a1)
    800038c8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038cc:	00459783          	lh	a5,4(a1)
    800038d0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038d4:	00659783          	lh	a5,6(a1)
    800038d8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038dc:	459c                	lw	a5,8(a1)
    800038de:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038e0:	03400613          	li	a2,52
    800038e4:	05b1                	addi	a1,a1,12
    800038e6:	05048513          	addi	a0,s1,80
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	444080e7          	jalr	1092(ra) # 80000d2e <memmove>
    brelse(bp);
    800038f2:	854a                	mv	a0,s2
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	876080e7          	jalr	-1930(ra) # 8000316a <brelse>
    ip->valid = 1;
    800038fc:	4785                	li	a5,1
    800038fe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003900:	04449783          	lh	a5,68(s1)
    80003904:	fbb5                	bnez	a5,80003878 <ilock+0x24>
      panic("ilock: no type");
    80003906:	00005517          	auipc	a0,0x5
    8000390a:	d0250513          	addi	a0,a0,-766 # 80008608 <syscalls+0x198>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>

0000000080003916 <iunlock>:
{
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	e04a                	sd	s2,0(sp)
    80003920:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003922:	c905                	beqz	a0,80003952 <iunlock+0x3c>
    80003924:	84aa                	mv	s1,a0
    80003926:	01050913          	addi	s2,a0,16
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	c7c080e7          	jalr	-900(ra) # 800045a8 <holdingsleep>
    80003934:	cd19                	beqz	a0,80003952 <iunlock+0x3c>
    80003936:	449c                	lw	a5,8(s1)
    80003938:	00f05d63          	blez	a5,80003952 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000393c:	854a                	mv	a0,s2
    8000393e:	00001097          	auipc	ra,0x1
    80003942:	c26080e7          	jalr	-986(ra) # 80004564 <releasesleep>
}
    80003946:	60e2                	ld	ra,24(sp)
    80003948:	6442                	ld	s0,16(sp)
    8000394a:	64a2                	ld	s1,8(sp)
    8000394c:	6902                	ld	s2,0(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret
    panic("iunlock");
    80003952:	00005517          	auipc	a0,0x5
    80003956:	cc650513          	addi	a0,a0,-826 # 80008618 <syscalls+0x1a8>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	be4080e7          	jalr	-1052(ra) # 8000053e <panic>

0000000080003962 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003962:	7179                	addi	sp,sp,-48
    80003964:	f406                	sd	ra,40(sp)
    80003966:	f022                	sd	s0,32(sp)
    80003968:	ec26                	sd	s1,24(sp)
    8000396a:	e84a                	sd	s2,16(sp)
    8000396c:	e44e                	sd	s3,8(sp)
    8000396e:	e052                	sd	s4,0(sp)
    80003970:	1800                	addi	s0,sp,48
    80003972:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003974:	05050493          	addi	s1,a0,80
    80003978:	08050913          	addi	s2,a0,128
    8000397c:	a021                	j	80003984 <itrunc+0x22>
    8000397e:	0491                	addi	s1,s1,4
    80003980:	01248d63          	beq	s1,s2,8000399a <itrunc+0x38>
    if(ip->addrs[i]){
    80003984:	408c                	lw	a1,0(s1)
    80003986:	dde5                	beqz	a1,8000397e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003988:	0009a503          	lw	a0,0(s3)
    8000398c:	00000097          	auipc	ra,0x0
    80003990:	8f4080e7          	jalr	-1804(ra) # 80003280 <bfree>
      ip->addrs[i] = 0;
    80003994:	0004a023          	sw	zero,0(s1)
    80003998:	b7dd                	j	8000397e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000399a:	0809a583          	lw	a1,128(s3)
    8000399e:	e185                	bnez	a1,800039be <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039a0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039a4:	854e                	mv	a0,s3
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	de4080e7          	jalr	-540(ra) # 8000378a <iupdate>
}
    800039ae:	70a2                	ld	ra,40(sp)
    800039b0:	7402                	ld	s0,32(sp)
    800039b2:	64e2                	ld	s1,24(sp)
    800039b4:	6942                	ld	s2,16(sp)
    800039b6:	69a2                	ld	s3,8(sp)
    800039b8:	6a02                	ld	s4,0(sp)
    800039ba:	6145                	addi	sp,sp,48
    800039bc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039be:	0009a503          	lw	a0,0(s3)
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	678080e7          	jalr	1656(ra) # 8000303a <bread>
    800039ca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039cc:	05850493          	addi	s1,a0,88
    800039d0:	45850913          	addi	s2,a0,1112
    800039d4:	a021                	j	800039dc <itrunc+0x7a>
    800039d6:	0491                	addi	s1,s1,4
    800039d8:	01248b63          	beq	s1,s2,800039ee <itrunc+0x8c>
      if(a[j])
    800039dc:	408c                	lw	a1,0(s1)
    800039de:	dde5                	beqz	a1,800039d6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039e0:	0009a503          	lw	a0,0(s3)
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	89c080e7          	jalr	-1892(ra) # 80003280 <bfree>
    800039ec:	b7ed                	j	800039d6 <itrunc+0x74>
    brelse(bp);
    800039ee:	8552                	mv	a0,s4
    800039f0:	fffff097          	auipc	ra,0xfffff
    800039f4:	77a080e7          	jalr	1914(ra) # 8000316a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039f8:	0809a583          	lw	a1,128(s3)
    800039fc:	0009a503          	lw	a0,0(s3)
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	880080e7          	jalr	-1920(ra) # 80003280 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a08:	0809a023          	sw	zero,128(s3)
    80003a0c:	bf51                	j	800039a0 <itrunc+0x3e>

0000000080003a0e <iput>:
{
    80003a0e:	1101                	addi	sp,sp,-32
    80003a10:	ec06                	sd	ra,24(sp)
    80003a12:	e822                	sd	s0,16(sp)
    80003a14:	e426                	sd	s1,8(sp)
    80003a16:	e04a                	sd	s2,0(sp)
    80003a18:	1000                	addi	s0,sp,32
    80003a1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a1c:	0001c517          	auipc	a0,0x1c
    80003a20:	1dc50513          	addi	a0,a0,476 # 8001fbf8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	1b2080e7          	jalr	434(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2c:	4498                	lw	a4,8(s1)
    80003a2e:	4785                	li	a5,1
    80003a30:	02f70363          	beq	a4,a5,80003a56 <iput+0x48>
  ip->ref--;
    80003a34:	449c                	lw	a5,8(s1)
    80003a36:	37fd                	addiw	a5,a5,-1
    80003a38:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a3a:	0001c517          	auipc	a0,0x1c
    80003a3e:	1be50513          	addi	a0,a0,446 # 8001fbf8 <itable>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	248080e7          	jalr	584(ra) # 80000c8a <release>
}
    80003a4a:	60e2                	ld	ra,24(sp)
    80003a4c:	6442                	ld	s0,16(sp)
    80003a4e:	64a2                	ld	s1,8(sp)
    80003a50:	6902                	ld	s2,0(sp)
    80003a52:	6105                	addi	sp,sp,32
    80003a54:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a56:	40bc                	lw	a5,64(s1)
    80003a58:	dff1                	beqz	a5,80003a34 <iput+0x26>
    80003a5a:	04a49783          	lh	a5,74(s1)
    80003a5e:	fbf9                	bnez	a5,80003a34 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a60:	01048913          	addi	s2,s1,16
    80003a64:	854a                	mv	a0,s2
    80003a66:	00001097          	auipc	ra,0x1
    80003a6a:	aa8080e7          	jalr	-1368(ra) # 8000450e <acquiresleep>
    release(&itable.lock);
    80003a6e:	0001c517          	auipc	a0,0x1c
    80003a72:	18a50513          	addi	a0,a0,394 # 8001fbf8 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	214080e7          	jalr	532(ra) # 80000c8a <release>
    itrunc(ip);
    80003a7e:	8526                	mv	a0,s1
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	ee2080e7          	jalr	-286(ra) # 80003962 <itrunc>
    ip->type = 0;
    80003a88:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a8c:	8526                	mv	a0,s1
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	cfc080e7          	jalr	-772(ra) # 8000378a <iupdate>
    ip->valid = 0;
    80003a96:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a9a:	854a                	mv	a0,s2
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	ac8080e7          	jalr	-1336(ra) # 80004564 <releasesleep>
    acquire(&itable.lock);
    80003aa4:	0001c517          	auipc	a0,0x1c
    80003aa8:	15450513          	addi	a0,a0,340 # 8001fbf8 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	12a080e7          	jalr	298(ra) # 80000bd6 <acquire>
    80003ab4:	b741                	j	80003a34 <iput+0x26>

0000000080003ab6 <iunlockput>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	1000                	addi	s0,sp,32
    80003ac0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	e54080e7          	jalr	-428(ra) # 80003916 <iunlock>
  iput(ip);
    80003aca:	8526                	mv	a0,s1
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	f42080e7          	jalr	-190(ra) # 80003a0e <iput>
}
    80003ad4:	60e2                	ld	ra,24(sp)
    80003ad6:	6442                	ld	s0,16(sp)
    80003ad8:	64a2                	ld	s1,8(sp)
    80003ada:	6105                	addi	sp,sp,32
    80003adc:	8082                	ret

0000000080003ade <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ade:	1141                	addi	sp,sp,-16
    80003ae0:	e422                	sd	s0,8(sp)
    80003ae2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ae4:	411c                	lw	a5,0(a0)
    80003ae6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ae8:	415c                	lw	a5,4(a0)
    80003aea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aec:	04451783          	lh	a5,68(a0)
    80003af0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003af4:	04a51783          	lh	a5,74(a0)
    80003af8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003afc:	04c56783          	lwu	a5,76(a0)
    80003b00:	e99c                	sd	a5,16(a1)
}
    80003b02:	6422                	ld	s0,8(sp)
    80003b04:	0141                	addi	sp,sp,16
    80003b06:	8082                	ret

0000000080003b08 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b08:	457c                	lw	a5,76(a0)
    80003b0a:	0ed7e963          	bltu	a5,a3,80003bfc <readi+0xf4>
{
    80003b0e:	7159                	addi	sp,sp,-112
    80003b10:	f486                	sd	ra,104(sp)
    80003b12:	f0a2                	sd	s0,96(sp)
    80003b14:	eca6                	sd	s1,88(sp)
    80003b16:	e8ca                	sd	s2,80(sp)
    80003b18:	e4ce                	sd	s3,72(sp)
    80003b1a:	e0d2                	sd	s4,64(sp)
    80003b1c:	fc56                	sd	s5,56(sp)
    80003b1e:	f85a                	sd	s6,48(sp)
    80003b20:	f45e                	sd	s7,40(sp)
    80003b22:	f062                	sd	s8,32(sp)
    80003b24:	ec66                	sd	s9,24(sp)
    80003b26:	e86a                	sd	s10,16(sp)
    80003b28:	e46e                	sd	s11,8(sp)
    80003b2a:	1880                	addi	s0,sp,112
    80003b2c:	8b2a                	mv	s6,a0
    80003b2e:	8bae                	mv	s7,a1
    80003b30:	8a32                	mv	s4,a2
    80003b32:	84b6                	mv	s1,a3
    80003b34:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b36:	9f35                	addw	a4,a4,a3
    return 0;
    80003b38:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b3a:	0ad76063          	bltu	a4,a3,80003bda <readi+0xd2>
  if(off + n > ip->size)
    80003b3e:	00e7f463          	bgeu	a5,a4,80003b46 <readi+0x3e>
    n = ip->size - off;
    80003b42:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b46:	0a0a8963          	beqz	s5,80003bf8 <readi+0xf0>
    80003b4a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b50:	5c7d                	li	s8,-1
    80003b52:	a82d                	j	80003b8c <readi+0x84>
    80003b54:	020d1d93          	slli	s11,s10,0x20
    80003b58:	020ddd93          	srli	s11,s11,0x20
    80003b5c:	05890793          	addi	a5,s2,88
    80003b60:	86ee                	mv	a3,s11
    80003b62:	963e                	add	a2,a2,a5
    80003b64:	85d2                	mv	a1,s4
    80003b66:	855e                	mv	a0,s7
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	9b6080e7          	jalr	-1610(ra) # 8000251e <either_copyout>
    80003b70:	05850d63          	beq	a0,s8,80003bca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	5f4080e7          	jalr	1524(ra) # 8000316a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7e:	013d09bb          	addw	s3,s10,s3
    80003b82:	009d04bb          	addw	s1,s10,s1
    80003b86:	9a6e                	add	s4,s4,s11
    80003b88:	0559f763          	bgeu	s3,s5,80003bd6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b8c:	00a4d59b          	srliw	a1,s1,0xa
    80003b90:	855a                	mv	a0,s6
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	8a2080e7          	jalr	-1886(ra) # 80003434 <bmap>
    80003b9a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b9e:	cd85                	beqz	a1,80003bd6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ba0:	000b2503          	lw	a0,0(s6)
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	496080e7          	jalr	1174(ra) # 8000303a <bread>
    80003bac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bae:	3ff4f613          	andi	a2,s1,1023
    80003bb2:	40cc87bb          	subw	a5,s9,a2
    80003bb6:	413a873b          	subw	a4,s5,s3
    80003bba:	8d3e                	mv	s10,a5
    80003bbc:	2781                	sext.w	a5,a5
    80003bbe:	0007069b          	sext.w	a3,a4
    80003bc2:	f8f6f9e3          	bgeu	a3,a5,80003b54 <readi+0x4c>
    80003bc6:	8d3a                	mv	s10,a4
    80003bc8:	b771                	j	80003b54 <readi+0x4c>
      brelse(bp);
    80003bca:	854a                	mv	a0,s2
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	59e080e7          	jalr	1438(ra) # 8000316a <brelse>
      tot = -1;
    80003bd4:	59fd                	li	s3,-1
  }
  return tot;
    80003bd6:	0009851b          	sext.w	a0,s3
}
    80003bda:	70a6                	ld	ra,104(sp)
    80003bdc:	7406                	ld	s0,96(sp)
    80003bde:	64e6                	ld	s1,88(sp)
    80003be0:	6946                	ld	s2,80(sp)
    80003be2:	69a6                	ld	s3,72(sp)
    80003be4:	6a06                	ld	s4,64(sp)
    80003be6:	7ae2                	ld	s5,56(sp)
    80003be8:	7b42                	ld	s6,48(sp)
    80003bea:	7ba2                	ld	s7,40(sp)
    80003bec:	7c02                	ld	s8,32(sp)
    80003bee:	6ce2                	ld	s9,24(sp)
    80003bf0:	6d42                	ld	s10,16(sp)
    80003bf2:	6da2                	ld	s11,8(sp)
    80003bf4:	6165                	addi	sp,sp,112
    80003bf6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf8:	89d6                	mv	s3,s5
    80003bfa:	bff1                	j	80003bd6 <readi+0xce>
    return 0;
    80003bfc:	4501                	li	a0,0
}
    80003bfe:	8082                	ret

0000000080003c00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c00:	457c                	lw	a5,76(a0)
    80003c02:	10d7e863          	bltu	a5,a3,80003d12 <writei+0x112>
{
    80003c06:	7159                	addi	sp,sp,-112
    80003c08:	f486                	sd	ra,104(sp)
    80003c0a:	f0a2                	sd	s0,96(sp)
    80003c0c:	eca6                	sd	s1,88(sp)
    80003c0e:	e8ca                	sd	s2,80(sp)
    80003c10:	e4ce                	sd	s3,72(sp)
    80003c12:	e0d2                	sd	s4,64(sp)
    80003c14:	fc56                	sd	s5,56(sp)
    80003c16:	f85a                	sd	s6,48(sp)
    80003c18:	f45e                	sd	s7,40(sp)
    80003c1a:	f062                	sd	s8,32(sp)
    80003c1c:	ec66                	sd	s9,24(sp)
    80003c1e:	e86a                	sd	s10,16(sp)
    80003c20:	e46e                	sd	s11,8(sp)
    80003c22:	1880                	addi	s0,sp,112
    80003c24:	8aaa                	mv	s5,a0
    80003c26:	8bae                	mv	s7,a1
    80003c28:	8a32                	mv	s4,a2
    80003c2a:	8936                	mv	s2,a3
    80003c2c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c2e:	00e687bb          	addw	a5,a3,a4
    80003c32:	0ed7e263          	bltu	a5,a3,80003d16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c36:	00043737          	lui	a4,0x43
    80003c3a:	0ef76063          	bltu	a4,a5,80003d1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3e:	0c0b0863          	beqz	s6,80003d0e <writei+0x10e>
    80003c42:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c44:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c48:	5c7d                	li	s8,-1
    80003c4a:	a091                	j	80003c8e <writei+0x8e>
    80003c4c:	020d1d93          	slli	s11,s10,0x20
    80003c50:	020ddd93          	srli	s11,s11,0x20
    80003c54:	05848793          	addi	a5,s1,88
    80003c58:	86ee                	mv	a3,s11
    80003c5a:	8652                	mv	a2,s4
    80003c5c:	85de                	mv	a1,s7
    80003c5e:	953e                	add	a0,a0,a5
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	914080e7          	jalr	-1772(ra) # 80002574 <either_copyin>
    80003c68:	07850263          	beq	a0,s8,80003ccc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c6c:	8526                	mv	a0,s1
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	780080e7          	jalr	1920(ra) # 800043ee <log_write>
    brelse(bp);
    80003c76:	8526                	mv	a0,s1
    80003c78:	fffff097          	auipc	ra,0xfffff
    80003c7c:	4f2080e7          	jalr	1266(ra) # 8000316a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c80:	013d09bb          	addw	s3,s10,s3
    80003c84:	012d093b          	addw	s2,s10,s2
    80003c88:	9a6e                	add	s4,s4,s11
    80003c8a:	0569f663          	bgeu	s3,s6,80003cd6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c8e:	00a9559b          	srliw	a1,s2,0xa
    80003c92:	8556                	mv	a0,s5
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	7a0080e7          	jalr	1952(ra) # 80003434 <bmap>
    80003c9c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ca0:	c99d                	beqz	a1,80003cd6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ca2:	000aa503          	lw	a0,0(s5)
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	394080e7          	jalr	916(ra) # 8000303a <bread>
    80003cae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb0:	3ff97513          	andi	a0,s2,1023
    80003cb4:	40ac87bb          	subw	a5,s9,a0
    80003cb8:	413b073b          	subw	a4,s6,s3
    80003cbc:	8d3e                	mv	s10,a5
    80003cbe:	2781                	sext.w	a5,a5
    80003cc0:	0007069b          	sext.w	a3,a4
    80003cc4:	f8f6f4e3          	bgeu	a3,a5,80003c4c <writei+0x4c>
    80003cc8:	8d3a                	mv	s10,a4
    80003cca:	b749                	j	80003c4c <writei+0x4c>
      brelse(bp);
    80003ccc:	8526                	mv	a0,s1
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	49c080e7          	jalr	1180(ra) # 8000316a <brelse>
  }

  if(off > ip->size)
    80003cd6:	04caa783          	lw	a5,76(s5)
    80003cda:	0127f463          	bgeu	a5,s2,80003ce2 <writei+0xe2>
    ip->size = off;
    80003cde:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ce2:	8556                	mv	a0,s5
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	aa6080e7          	jalr	-1370(ra) # 8000378a <iupdate>

  return tot;
    80003cec:	0009851b          	sext.w	a0,s3
}
    80003cf0:	70a6                	ld	ra,104(sp)
    80003cf2:	7406                	ld	s0,96(sp)
    80003cf4:	64e6                	ld	s1,88(sp)
    80003cf6:	6946                	ld	s2,80(sp)
    80003cf8:	69a6                	ld	s3,72(sp)
    80003cfa:	6a06                	ld	s4,64(sp)
    80003cfc:	7ae2                	ld	s5,56(sp)
    80003cfe:	7b42                	ld	s6,48(sp)
    80003d00:	7ba2                	ld	s7,40(sp)
    80003d02:	7c02                	ld	s8,32(sp)
    80003d04:	6ce2                	ld	s9,24(sp)
    80003d06:	6d42                	ld	s10,16(sp)
    80003d08:	6da2                	ld	s11,8(sp)
    80003d0a:	6165                	addi	sp,sp,112
    80003d0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0e:	89da                	mv	s3,s6
    80003d10:	bfc9                	j	80003ce2 <writei+0xe2>
    return -1;
    80003d12:	557d                	li	a0,-1
}
    80003d14:	8082                	ret
    return -1;
    80003d16:	557d                	li	a0,-1
    80003d18:	bfe1                	j	80003cf0 <writei+0xf0>
    return -1;
    80003d1a:	557d                	li	a0,-1
    80003d1c:	bfd1                	j	80003cf0 <writei+0xf0>

0000000080003d1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d1e:	1141                	addi	sp,sp,-16
    80003d20:	e406                	sd	ra,8(sp)
    80003d22:	e022                	sd	s0,0(sp)
    80003d24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d26:	4639                	li	a2,14
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	07a080e7          	jalr	122(ra) # 80000da2 <strncmp>
}
    80003d30:	60a2                	ld	ra,8(sp)
    80003d32:	6402                	ld	s0,0(sp)
    80003d34:	0141                	addi	sp,sp,16
    80003d36:	8082                	ret

0000000080003d38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d38:	7139                	addi	sp,sp,-64
    80003d3a:	fc06                	sd	ra,56(sp)
    80003d3c:	f822                	sd	s0,48(sp)
    80003d3e:	f426                	sd	s1,40(sp)
    80003d40:	f04a                	sd	s2,32(sp)
    80003d42:	ec4e                	sd	s3,24(sp)
    80003d44:	e852                	sd	s4,16(sp)
    80003d46:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d48:	04451703          	lh	a4,68(a0)
    80003d4c:	4785                	li	a5,1
    80003d4e:	00f71a63          	bne	a4,a5,80003d62 <dirlookup+0x2a>
    80003d52:	892a                	mv	s2,a0
    80003d54:	89ae                	mv	s3,a1
    80003d56:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d58:	457c                	lw	a5,76(a0)
    80003d5a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d5c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	e79d                	bnez	a5,80003d8c <dirlookup+0x54>
    80003d60:	a8a5                	j	80003dd8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	8be50513          	addi	a0,a0,-1858 # 80008620 <syscalls+0x1b0>
    80003d6a:	ffffc097          	auipc	ra,0xffffc
    80003d6e:	7d4080e7          	jalr	2004(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d72:	00005517          	auipc	a0,0x5
    80003d76:	8c650513          	addi	a0,a0,-1850 # 80008638 <syscalls+0x1c8>
    80003d7a:	ffffc097          	auipc	ra,0xffffc
    80003d7e:	7c4080e7          	jalr	1988(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d82:	24c1                	addiw	s1,s1,16
    80003d84:	04c92783          	lw	a5,76(s2)
    80003d88:	04f4f763          	bgeu	s1,a5,80003dd6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d8c:	4741                	li	a4,16
    80003d8e:	86a6                	mv	a3,s1
    80003d90:	fc040613          	addi	a2,s0,-64
    80003d94:	4581                	li	a1,0
    80003d96:	854a                	mv	a0,s2
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	d70080e7          	jalr	-656(ra) # 80003b08 <readi>
    80003da0:	47c1                	li	a5,16
    80003da2:	fcf518e3          	bne	a0,a5,80003d72 <dirlookup+0x3a>
    if(de.inum == 0)
    80003da6:	fc045783          	lhu	a5,-64(s0)
    80003daa:	dfe1                	beqz	a5,80003d82 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dac:	fc240593          	addi	a1,s0,-62
    80003db0:	854e                	mv	a0,s3
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	f6c080e7          	jalr	-148(ra) # 80003d1e <namecmp>
    80003dba:	f561                	bnez	a0,80003d82 <dirlookup+0x4a>
      if(poff)
    80003dbc:	000a0463          	beqz	s4,80003dc4 <dirlookup+0x8c>
        *poff = off;
    80003dc0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dc4:	fc045583          	lhu	a1,-64(s0)
    80003dc8:	00092503          	lw	a0,0(s2)
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	750080e7          	jalr	1872(ra) # 8000351c <iget>
    80003dd4:	a011                	j	80003dd8 <dirlookup+0xa0>
  return 0;
    80003dd6:	4501                	li	a0,0
}
    80003dd8:	70e2                	ld	ra,56(sp)
    80003dda:	7442                	ld	s0,48(sp)
    80003ddc:	74a2                	ld	s1,40(sp)
    80003dde:	7902                	ld	s2,32(sp)
    80003de0:	69e2                	ld	s3,24(sp)
    80003de2:	6a42                	ld	s4,16(sp)
    80003de4:	6121                	addi	sp,sp,64
    80003de6:	8082                	ret

0000000080003de8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003de8:	711d                	addi	sp,sp,-96
    80003dea:	ec86                	sd	ra,88(sp)
    80003dec:	e8a2                	sd	s0,80(sp)
    80003dee:	e4a6                	sd	s1,72(sp)
    80003df0:	e0ca                	sd	s2,64(sp)
    80003df2:	fc4e                	sd	s3,56(sp)
    80003df4:	f852                	sd	s4,48(sp)
    80003df6:	f456                	sd	s5,40(sp)
    80003df8:	f05a                	sd	s6,32(sp)
    80003dfa:	ec5e                	sd	s7,24(sp)
    80003dfc:	e862                	sd	s8,16(sp)
    80003dfe:	e466                	sd	s9,8(sp)
    80003e00:	1080                	addi	s0,sp,96
    80003e02:	84aa                	mv	s1,a0
    80003e04:	8aae                	mv	s5,a1
    80003e06:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e08:	00054703          	lbu	a4,0(a0)
    80003e0c:	02f00793          	li	a5,47
    80003e10:	02f70363          	beq	a4,a5,80003e36 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e14:	ffffe097          	auipc	ra,0xffffe
    80003e18:	bce080e7          	jalr	-1074(ra) # 800019e2 <myproc>
    80003e1c:	15053503          	ld	a0,336(a0)
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	9f6080e7          	jalr	-1546(ra) # 80003816 <idup>
    80003e28:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e2a:	02f00913          	li	s2,47
  len = path - s;
    80003e2e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e30:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e32:	4b85                	li	s7,1
    80003e34:	a865                	j	80003eec <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e36:	4585                	li	a1,1
    80003e38:	4505                	li	a0,1
    80003e3a:	fffff097          	auipc	ra,0xfffff
    80003e3e:	6e2080e7          	jalr	1762(ra) # 8000351c <iget>
    80003e42:	89aa                	mv	s3,a0
    80003e44:	b7dd                	j	80003e2a <namex+0x42>
      iunlockput(ip);
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	c6e080e7          	jalr	-914(ra) # 80003ab6 <iunlockput>
      return 0;
    80003e50:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e52:	854e                	mv	a0,s3
    80003e54:	60e6                	ld	ra,88(sp)
    80003e56:	6446                	ld	s0,80(sp)
    80003e58:	64a6                	ld	s1,72(sp)
    80003e5a:	6906                	ld	s2,64(sp)
    80003e5c:	79e2                	ld	s3,56(sp)
    80003e5e:	7a42                	ld	s4,48(sp)
    80003e60:	7aa2                	ld	s5,40(sp)
    80003e62:	7b02                	ld	s6,32(sp)
    80003e64:	6be2                	ld	s7,24(sp)
    80003e66:	6c42                	ld	s8,16(sp)
    80003e68:	6ca2                	ld	s9,8(sp)
    80003e6a:	6125                	addi	sp,sp,96
    80003e6c:	8082                	ret
      iunlock(ip);
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	aa6080e7          	jalr	-1370(ra) # 80003916 <iunlock>
      return ip;
    80003e78:	bfe9                	j	80003e52 <namex+0x6a>
      iunlockput(ip);
    80003e7a:	854e                	mv	a0,s3
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	c3a080e7          	jalr	-966(ra) # 80003ab6 <iunlockput>
      return 0;
    80003e84:	89e6                	mv	s3,s9
    80003e86:	b7f1                	j	80003e52 <namex+0x6a>
  len = path - s;
    80003e88:	40b48633          	sub	a2,s1,a1
    80003e8c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e90:	099c5463          	bge	s8,s9,80003f18 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e94:	4639                	li	a2,14
    80003e96:	8552                	mv	a0,s4
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	e96080e7          	jalr	-362(ra) # 80000d2e <memmove>
  while(*path == '/')
    80003ea0:	0004c783          	lbu	a5,0(s1)
    80003ea4:	01279763          	bne	a5,s2,80003eb2 <namex+0xca>
    path++;
    80003ea8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eaa:	0004c783          	lbu	a5,0(s1)
    80003eae:	ff278de3          	beq	a5,s2,80003ea8 <namex+0xc0>
    ilock(ip);
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	9a0080e7          	jalr	-1632(ra) # 80003854 <ilock>
    if(ip->type != T_DIR){
    80003ebc:	04499783          	lh	a5,68(s3)
    80003ec0:	f97793e3          	bne	a5,s7,80003e46 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ec4:	000a8563          	beqz	s5,80003ece <namex+0xe6>
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	d3cd                	beqz	a5,80003e6e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ece:	865a                	mv	a2,s6
    80003ed0:	85d2                	mv	a1,s4
    80003ed2:	854e                	mv	a0,s3
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	e64080e7          	jalr	-412(ra) # 80003d38 <dirlookup>
    80003edc:	8caa                	mv	s9,a0
    80003ede:	dd51                	beqz	a0,80003e7a <namex+0x92>
    iunlockput(ip);
    80003ee0:	854e                	mv	a0,s3
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	bd4080e7          	jalr	-1068(ra) # 80003ab6 <iunlockput>
    ip = next;
    80003eea:	89e6                	mv	s3,s9
  while(*path == '/')
    80003eec:	0004c783          	lbu	a5,0(s1)
    80003ef0:	05279763          	bne	a5,s2,80003f3e <namex+0x156>
    path++;
    80003ef4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ef6:	0004c783          	lbu	a5,0(s1)
    80003efa:	ff278de3          	beq	a5,s2,80003ef4 <namex+0x10c>
  if(*path == 0)
    80003efe:	c79d                	beqz	a5,80003f2c <namex+0x144>
    path++;
    80003f00:	85a6                	mv	a1,s1
  len = path - s;
    80003f02:	8cda                	mv	s9,s6
    80003f04:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f06:	01278963          	beq	a5,s2,80003f18 <namex+0x130>
    80003f0a:	dfbd                	beqz	a5,80003e88 <namex+0xa0>
    path++;
    80003f0c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f0e:	0004c783          	lbu	a5,0(s1)
    80003f12:	ff279ce3          	bne	a5,s2,80003f0a <namex+0x122>
    80003f16:	bf8d                	j	80003e88 <namex+0xa0>
    memmove(name, s, len);
    80003f18:	2601                	sext.w	a2,a2
    80003f1a:	8552                	mv	a0,s4
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	e12080e7          	jalr	-494(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003f24:	9cd2                	add	s9,s9,s4
    80003f26:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f2a:	bf9d                	j	80003ea0 <namex+0xb8>
  if(nameiparent){
    80003f2c:	f20a83e3          	beqz	s5,80003e52 <namex+0x6a>
    iput(ip);
    80003f30:	854e                	mv	a0,s3
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	adc080e7          	jalr	-1316(ra) # 80003a0e <iput>
    return 0;
    80003f3a:	4981                	li	s3,0
    80003f3c:	bf19                	j	80003e52 <namex+0x6a>
  if(*path == 0)
    80003f3e:	d7fd                	beqz	a5,80003f2c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	85a6                	mv	a1,s1
    80003f46:	b7d1                	j	80003f0a <namex+0x122>

0000000080003f48 <dirlink>:
{
    80003f48:	7139                	addi	sp,sp,-64
    80003f4a:	fc06                	sd	ra,56(sp)
    80003f4c:	f822                	sd	s0,48(sp)
    80003f4e:	f426                	sd	s1,40(sp)
    80003f50:	f04a                	sd	s2,32(sp)
    80003f52:	ec4e                	sd	s3,24(sp)
    80003f54:	e852                	sd	s4,16(sp)
    80003f56:	0080                	addi	s0,sp,64
    80003f58:	892a                	mv	s2,a0
    80003f5a:	8a2e                	mv	s4,a1
    80003f5c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f5e:	4601                	li	a2,0
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	dd8080e7          	jalr	-552(ra) # 80003d38 <dirlookup>
    80003f68:	e93d                	bnez	a0,80003fde <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6a:	04c92483          	lw	s1,76(s2)
    80003f6e:	c49d                	beqz	s1,80003f9c <dirlink+0x54>
    80003f70:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f72:	4741                	li	a4,16
    80003f74:	86a6                	mv	a3,s1
    80003f76:	fc040613          	addi	a2,s0,-64
    80003f7a:	4581                	li	a1,0
    80003f7c:	854a                	mv	a0,s2
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	b8a080e7          	jalr	-1142(ra) # 80003b08 <readi>
    80003f86:	47c1                	li	a5,16
    80003f88:	06f51163          	bne	a0,a5,80003fea <dirlink+0xa2>
    if(de.inum == 0)
    80003f8c:	fc045783          	lhu	a5,-64(s0)
    80003f90:	c791                	beqz	a5,80003f9c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f92:	24c1                	addiw	s1,s1,16
    80003f94:	04c92783          	lw	a5,76(s2)
    80003f98:	fcf4ede3          	bltu	s1,a5,80003f72 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f9c:	4639                	li	a2,14
    80003f9e:	85d2                	mv	a1,s4
    80003fa0:	fc240513          	addi	a0,s0,-62
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	e3a080e7          	jalr	-454(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003fac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb0:	4741                	li	a4,16
    80003fb2:	86a6                	mv	a3,s1
    80003fb4:	fc040613          	addi	a2,s0,-64
    80003fb8:	4581                	li	a1,0
    80003fba:	854a                	mv	a0,s2
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	c44080e7          	jalr	-956(ra) # 80003c00 <writei>
    80003fc4:	1541                	addi	a0,a0,-16
    80003fc6:	00a03533          	snez	a0,a0
    80003fca:	40a00533          	neg	a0,a0
}
    80003fce:	70e2                	ld	ra,56(sp)
    80003fd0:	7442                	ld	s0,48(sp)
    80003fd2:	74a2                	ld	s1,40(sp)
    80003fd4:	7902                	ld	s2,32(sp)
    80003fd6:	69e2                	ld	s3,24(sp)
    80003fd8:	6a42                	ld	s4,16(sp)
    80003fda:	6121                	addi	sp,sp,64
    80003fdc:	8082                	ret
    iput(ip);
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	a30080e7          	jalr	-1488(ra) # 80003a0e <iput>
    return -1;
    80003fe6:	557d                	li	a0,-1
    80003fe8:	b7dd                	j	80003fce <dirlink+0x86>
      panic("dirlink read");
    80003fea:	00004517          	auipc	a0,0x4
    80003fee:	65e50513          	addi	a0,a0,1630 # 80008648 <syscalls+0x1d8>
    80003ff2:	ffffc097          	auipc	ra,0xffffc
    80003ff6:	54c080e7          	jalr	1356(ra) # 8000053e <panic>

0000000080003ffa <namei>:

struct inode*
namei(char *path)
{
    80003ffa:	1101                	addi	sp,sp,-32
    80003ffc:	ec06                	sd	ra,24(sp)
    80003ffe:	e822                	sd	s0,16(sp)
    80004000:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004002:	fe040613          	addi	a2,s0,-32
    80004006:	4581                	li	a1,0
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	de0080e7          	jalr	-544(ra) # 80003de8 <namex>
}
    80004010:	60e2                	ld	ra,24(sp)
    80004012:	6442                	ld	s0,16(sp)
    80004014:	6105                	addi	sp,sp,32
    80004016:	8082                	ret

0000000080004018 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004018:	1141                	addi	sp,sp,-16
    8000401a:	e406                	sd	ra,8(sp)
    8000401c:	e022                	sd	s0,0(sp)
    8000401e:	0800                	addi	s0,sp,16
    80004020:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004022:	4585                	li	a1,1
    80004024:	00000097          	auipc	ra,0x0
    80004028:	dc4080e7          	jalr	-572(ra) # 80003de8 <namex>
}
    8000402c:	60a2                	ld	ra,8(sp)
    8000402e:	6402                	ld	s0,0(sp)
    80004030:	0141                	addi	sp,sp,16
    80004032:	8082                	ret

0000000080004034 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004034:	1101                	addi	sp,sp,-32
    80004036:	ec06                	sd	ra,24(sp)
    80004038:	e822                	sd	s0,16(sp)
    8000403a:	e426                	sd	s1,8(sp)
    8000403c:	e04a                	sd	s2,0(sp)
    8000403e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004040:	0001d917          	auipc	s2,0x1d
    80004044:	66090913          	addi	s2,s2,1632 # 800216a0 <log>
    80004048:	01892583          	lw	a1,24(s2)
    8000404c:	02892503          	lw	a0,40(s2)
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	fea080e7          	jalr	-22(ra) # 8000303a <bread>
    80004058:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000405a:	02c92683          	lw	a3,44(s2)
    8000405e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004060:	02d05763          	blez	a3,8000408e <write_head+0x5a>
    80004064:	0001d797          	auipc	a5,0x1d
    80004068:	66c78793          	addi	a5,a5,1644 # 800216d0 <log+0x30>
    8000406c:	05c50713          	addi	a4,a0,92
    80004070:	36fd                	addiw	a3,a3,-1
    80004072:	1682                	slli	a3,a3,0x20
    80004074:	9281                	srli	a3,a3,0x20
    80004076:	068a                	slli	a3,a3,0x2
    80004078:	0001d617          	auipc	a2,0x1d
    8000407c:	65c60613          	addi	a2,a2,1628 # 800216d4 <log+0x34>
    80004080:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004082:	4390                	lw	a2,0(a5)
    80004084:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004086:	0791                	addi	a5,a5,4
    80004088:	0711                	addi	a4,a4,4
    8000408a:	fed79ce3          	bne	a5,a3,80004082 <write_head+0x4e>
  }
  bwrite(buf);
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	09c080e7          	jalr	156(ra) # 8000312c <bwrite>
  brelse(buf);
    80004098:	8526                	mv	a0,s1
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	0d0080e7          	jalr	208(ra) # 8000316a <brelse>
}
    800040a2:	60e2                	ld	ra,24(sp)
    800040a4:	6442                	ld	s0,16(sp)
    800040a6:	64a2                	ld	s1,8(sp)
    800040a8:	6902                	ld	s2,0(sp)
    800040aa:	6105                	addi	sp,sp,32
    800040ac:	8082                	ret

00000000800040ae <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ae:	0001d797          	auipc	a5,0x1d
    800040b2:	61e7a783          	lw	a5,1566(a5) # 800216cc <log+0x2c>
    800040b6:	0af05d63          	blez	a5,80004170 <install_trans+0xc2>
{
    800040ba:	7139                	addi	sp,sp,-64
    800040bc:	fc06                	sd	ra,56(sp)
    800040be:	f822                	sd	s0,48(sp)
    800040c0:	f426                	sd	s1,40(sp)
    800040c2:	f04a                	sd	s2,32(sp)
    800040c4:	ec4e                	sd	s3,24(sp)
    800040c6:	e852                	sd	s4,16(sp)
    800040c8:	e456                	sd	s5,8(sp)
    800040ca:	e05a                	sd	s6,0(sp)
    800040cc:	0080                	addi	s0,sp,64
    800040ce:	8b2a                	mv	s6,a0
    800040d0:	0001da97          	auipc	s5,0x1d
    800040d4:	600a8a93          	addi	s5,s5,1536 # 800216d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040da:	0001d997          	auipc	s3,0x1d
    800040de:	5c698993          	addi	s3,s3,1478 # 800216a0 <log>
    800040e2:	a00d                	j	80004104 <install_trans+0x56>
    brelse(lbuf);
    800040e4:	854a                	mv	a0,s2
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	084080e7          	jalr	132(ra) # 8000316a <brelse>
    brelse(dbuf);
    800040ee:	8526                	mv	a0,s1
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	07a080e7          	jalr	122(ra) # 8000316a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f8:	2a05                	addiw	s4,s4,1
    800040fa:	0a91                	addi	s5,s5,4
    800040fc:	02c9a783          	lw	a5,44(s3)
    80004100:	04fa5e63          	bge	s4,a5,8000415c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004104:	0189a583          	lw	a1,24(s3)
    80004108:	014585bb          	addw	a1,a1,s4
    8000410c:	2585                	addiw	a1,a1,1
    8000410e:	0289a503          	lw	a0,40(s3)
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	f28080e7          	jalr	-216(ra) # 8000303a <bread>
    8000411a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000411c:	000aa583          	lw	a1,0(s5)
    80004120:	0289a503          	lw	a0,40(s3)
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	f16080e7          	jalr	-234(ra) # 8000303a <bread>
    8000412c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000412e:	40000613          	li	a2,1024
    80004132:	05890593          	addi	a1,s2,88
    80004136:	05850513          	addi	a0,a0,88
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	bf4080e7          	jalr	-1036(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004142:	8526                	mv	a0,s1
    80004144:	fffff097          	auipc	ra,0xfffff
    80004148:	fe8080e7          	jalr	-24(ra) # 8000312c <bwrite>
    if(recovering == 0)
    8000414c:	f80b1ce3          	bnez	s6,800040e4 <install_trans+0x36>
      bunpin(dbuf);
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	0f2080e7          	jalr	242(ra) # 80003244 <bunpin>
    8000415a:	b769                	j	800040e4 <install_trans+0x36>
}
    8000415c:	70e2                	ld	ra,56(sp)
    8000415e:	7442                	ld	s0,48(sp)
    80004160:	74a2                	ld	s1,40(sp)
    80004162:	7902                	ld	s2,32(sp)
    80004164:	69e2                	ld	s3,24(sp)
    80004166:	6a42                	ld	s4,16(sp)
    80004168:	6aa2                	ld	s5,8(sp)
    8000416a:	6b02                	ld	s6,0(sp)
    8000416c:	6121                	addi	sp,sp,64
    8000416e:	8082                	ret
    80004170:	8082                	ret

0000000080004172 <initlog>:
{
    80004172:	7179                	addi	sp,sp,-48
    80004174:	f406                	sd	ra,40(sp)
    80004176:	f022                	sd	s0,32(sp)
    80004178:	ec26                	sd	s1,24(sp)
    8000417a:	e84a                	sd	s2,16(sp)
    8000417c:	e44e                	sd	s3,8(sp)
    8000417e:	1800                	addi	s0,sp,48
    80004180:	892a                	mv	s2,a0
    80004182:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004184:	0001d497          	auipc	s1,0x1d
    80004188:	51c48493          	addi	s1,s1,1308 # 800216a0 <log>
    8000418c:	00004597          	auipc	a1,0x4
    80004190:	4cc58593          	addi	a1,a1,1228 # 80008658 <syscalls+0x1e8>
    80004194:	8526                	mv	a0,s1
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	9b0080e7          	jalr	-1616(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000419e:	0149a583          	lw	a1,20(s3)
    800041a2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041a4:	0109a783          	lw	a5,16(s3)
    800041a8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041aa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041ae:	854a                	mv	a0,s2
    800041b0:	fffff097          	auipc	ra,0xfffff
    800041b4:	e8a080e7          	jalr	-374(ra) # 8000303a <bread>
  log.lh.n = lh->n;
    800041b8:	4d34                	lw	a3,88(a0)
    800041ba:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041bc:	02d05563          	blez	a3,800041e6 <initlog+0x74>
    800041c0:	05c50793          	addi	a5,a0,92
    800041c4:	0001d717          	auipc	a4,0x1d
    800041c8:	50c70713          	addi	a4,a4,1292 # 800216d0 <log+0x30>
    800041cc:	36fd                	addiw	a3,a3,-1
    800041ce:	1682                	slli	a3,a3,0x20
    800041d0:	9281                	srli	a3,a3,0x20
    800041d2:	068a                	slli	a3,a3,0x2
    800041d4:	06050613          	addi	a2,a0,96
    800041d8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041da:	4390                	lw	a2,0(a5)
    800041dc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041de:	0791                	addi	a5,a5,4
    800041e0:	0711                	addi	a4,a4,4
    800041e2:	fed79ce3          	bne	a5,a3,800041da <initlog+0x68>
  brelse(buf);
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	f84080e7          	jalr	-124(ra) # 8000316a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ee:	4505                	li	a0,1
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	ebe080e7          	jalr	-322(ra) # 800040ae <install_trans>
  log.lh.n = 0;
    800041f8:	0001d797          	auipc	a5,0x1d
    800041fc:	4c07aa23          	sw	zero,1236(a5) # 800216cc <log+0x2c>
  write_head(); // clear the log
    80004200:	00000097          	auipc	ra,0x0
    80004204:	e34080e7          	jalr	-460(ra) # 80004034 <write_head>
}
    80004208:	70a2                	ld	ra,40(sp)
    8000420a:	7402                	ld	s0,32(sp)
    8000420c:	64e2                	ld	s1,24(sp)
    8000420e:	6942                	ld	s2,16(sp)
    80004210:	69a2                	ld	s3,8(sp)
    80004212:	6145                	addi	sp,sp,48
    80004214:	8082                	ret

0000000080004216 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004216:	1101                	addi	sp,sp,-32
    80004218:	ec06                	sd	ra,24(sp)
    8000421a:	e822                	sd	s0,16(sp)
    8000421c:	e426                	sd	s1,8(sp)
    8000421e:	e04a                	sd	s2,0(sp)
    80004220:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004222:	0001d517          	auipc	a0,0x1d
    80004226:	47e50513          	addi	a0,a0,1150 # 800216a0 <log>
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004232:	0001d497          	auipc	s1,0x1d
    80004236:	46e48493          	addi	s1,s1,1134 # 800216a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000423a:	4979                	li	s2,30
    8000423c:	a039                	j	8000424a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000423e:	85a6                	mv	a1,s1
    80004240:	8526                	mv	a0,s1
    80004242:	ffffe097          	auipc	ra,0xffffe
    80004246:	ed4080e7          	jalr	-300(ra) # 80002116 <sleep>
    if(log.committing){
    8000424a:	50dc                	lw	a5,36(s1)
    8000424c:	fbed                	bnez	a5,8000423e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424e:	509c                	lw	a5,32(s1)
    80004250:	0017871b          	addiw	a4,a5,1
    80004254:	0007069b          	sext.w	a3,a4
    80004258:	0027179b          	slliw	a5,a4,0x2
    8000425c:	9fb9                	addw	a5,a5,a4
    8000425e:	0017979b          	slliw	a5,a5,0x1
    80004262:	54d8                	lw	a4,44(s1)
    80004264:	9fb9                	addw	a5,a5,a4
    80004266:	00f95963          	bge	s2,a5,80004278 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000426a:	85a6                	mv	a1,s1
    8000426c:	8526                	mv	a0,s1
    8000426e:	ffffe097          	auipc	ra,0xffffe
    80004272:	ea8080e7          	jalr	-344(ra) # 80002116 <sleep>
    80004276:	bfd1                	j	8000424a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004278:	0001d517          	auipc	a0,0x1d
    8000427c:	42850513          	addi	a0,a0,1064 # 800216a0 <log>
    80004280:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	a08080e7          	jalr	-1528(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000428a:	60e2                	ld	ra,24(sp)
    8000428c:	6442                	ld	s0,16(sp)
    8000428e:	64a2                	ld	s1,8(sp)
    80004290:	6902                	ld	s2,0(sp)
    80004292:	6105                	addi	sp,sp,32
    80004294:	8082                	ret

0000000080004296 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004296:	7139                	addi	sp,sp,-64
    80004298:	fc06                	sd	ra,56(sp)
    8000429a:	f822                	sd	s0,48(sp)
    8000429c:	f426                	sd	s1,40(sp)
    8000429e:	f04a                	sd	s2,32(sp)
    800042a0:	ec4e                	sd	s3,24(sp)
    800042a2:	e852                	sd	s4,16(sp)
    800042a4:	e456                	sd	s5,8(sp)
    800042a6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042a8:	0001d497          	auipc	s1,0x1d
    800042ac:	3f848493          	addi	s1,s1,1016 # 800216a0 <log>
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	924080e7          	jalr	-1756(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800042ba:	509c                	lw	a5,32(s1)
    800042bc:	37fd                	addiw	a5,a5,-1
    800042be:	0007891b          	sext.w	s2,a5
    800042c2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042c4:	50dc                	lw	a5,36(s1)
    800042c6:	e7b9                	bnez	a5,80004314 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042c8:	04091e63          	bnez	s2,80004324 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042cc:	0001d497          	auipc	s1,0x1d
    800042d0:	3d448493          	addi	s1,s1,980 # 800216a0 <log>
    800042d4:	4785                	li	a5,1
    800042d6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	9b0080e7          	jalr	-1616(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042e2:	54dc                	lw	a5,44(s1)
    800042e4:	06f04763          	bgtz	a5,80004352 <end_op+0xbc>
    acquire(&log.lock);
    800042e8:	0001d497          	auipc	s1,0x1d
    800042ec:	3b848493          	addi	s1,s1,952 # 800216a0 <log>
    800042f0:	8526                	mv	a0,s1
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	8e4080e7          	jalr	-1820(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800042fa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffe097          	auipc	ra,0xffffe
    80004304:	e7a080e7          	jalr	-390(ra) # 8000217a <wakeup>
    release(&log.lock);
    80004308:	8526                	mv	a0,s1
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	980080e7          	jalr	-1664(ra) # 80000c8a <release>
}
    80004312:	a03d                	j	80004340 <end_op+0xaa>
    panic("log.committing");
    80004314:	00004517          	auipc	a0,0x4
    80004318:	34c50513          	addi	a0,a0,844 # 80008660 <syscalls+0x1f0>
    8000431c:	ffffc097          	auipc	ra,0xffffc
    80004320:	222080e7          	jalr	546(ra) # 8000053e <panic>
    wakeup(&log);
    80004324:	0001d497          	auipc	s1,0x1d
    80004328:	37c48493          	addi	s1,s1,892 # 800216a0 <log>
    8000432c:	8526                	mv	a0,s1
    8000432e:	ffffe097          	auipc	ra,0xffffe
    80004332:	e4c080e7          	jalr	-436(ra) # 8000217a <wakeup>
  release(&log.lock);
    80004336:	8526                	mv	a0,s1
    80004338:	ffffd097          	auipc	ra,0xffffd
    8000433c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
}
    80004340:	70e2                	ld	ra,56(sp)
    80004342:	7442                	ld	s0,48(sp)
    80004344:	74a2                	ld	s1,40(sp)
    80004346:	7902                	ld	s2,32(sp)
    80004348:	69e2                	ld	s3,24(sp)
    8000434a:	6a42                	ld	s4,16(sp)
    8000434c:	6aa2                	ld	s5,8(sp)
    8000434e:	6121                	addi	sp,sp,64
    80004350:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004352:	0001da97          	auipc	s5,0x1d
    80004356:	37ea8a93          	addi	s5,s5,894 # 800216d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000435a:	0001da17          	auipc	s4,0x1d
    8000435e:	346a0a13          	addi	s4,s4,838 # 800216a0 <log>
    80004362:	018a2583          	lw	a1,24(s4)
    80004366:	012585bb          	addw	a1,a1,s2
    8000436a:	2585                	addiw	a1,a1,1
    8000436c:	028a2503          	lw	a0,40(s4)
    80004370:	fffff097          	auipc	ra,0xfffff
    80004374:	cca080e7          	jalr	-822(ra) # 8000303a <bread>
    80004378:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000437a:	000aa583          	lw	a1,0(s5)
    8000437e:	028a2503          	lw	a0,40(s4)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	cb8080e7          	jalr	-840(ra) # 8000303a <bread>
    8000438a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000438c:	40000613          	li	a2,1024
    80004390:	05850593          	addi	a1,a0,88
    80004394:	05848513          	addi	a0,s1,88
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	996080e7          	jalr	-1642(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800043a0:	8526                	mv	a0,s1
    800043a2:	fffff097          	auipc	ra,0xfffff
    800043a6:	d8a080e7          	jalr	-630(ra) # 8000312c <bwrite>
    brelse(from);
    800043aa:	854e                	mv	a0,s3
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	dbe080e7          	jalr	-578(ra) # 8000316a <brelse>
    brelse(to);
    800043b4:	8526                	mv	a0,s1
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	db4080e7          	jalr	-588(ra) # 8000316a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043be:	2905                	addiw	s2,s2,1
    800043c0:	0a91                	addi	s5,s5,4
    800043c2:	02ca2783          	lw	a5,44(s4)
    800043c6:	f8f94ee3          	blt	s2,a5,80004362 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	c6a080e7          	jalr	-918(ra) # 80004034 <write_head>
    install_trans(0); // Now install writes to home locations
    800043d2:	4501                	li	a0,0
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	cda080e7          	jalr	-806(ra) # 800040ae <install_trans>
    log.lh.n = 0;
    800043dc:	0001d797          	auipc	a5,0x1d
    800043e0:	2e07a823          	sw	zero,752(a5) # 800216cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	c50080e7          	jalr	-944(ra) # 80004034 <write_head>
    800043ec:	bdf5                	j	800042e8 <end_op+0x52>

00000000800043ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ee:	1101                	addi	sp,sp,-32
    800043f0:	ec06                	sd	ra,24(sp)
    800043f2:	e822                	sd	s0,16(sp)
    800043f4:	e426                	sd	s1,8(sp)
    800043f6:	e04a                	sd	s2,0(sp)
    800043f8:	1000                	addi	s0,sp,32
    800043fa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043fc:	0001d917          	auipc	s2,0x1d
    80004400:	2a490913          	addi	s2,s2,676 # 800216a0 <log>
    80004404:	854a                	mv	a0,s2
    80004406:	ffffc097          	auipc	ra,0xffffc
    8000440a:	7d0080e7          	jalr	2000(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000440e:	02c92603          	lw	a2,44(s2)
    80004412:	47f5                	li	a5,29
    80004414:	06c7c563          	blt	a5,a2,8000447e <log_write+0x90>
    80004418:	0001d797          	auipc	a5,0x1d
    8000441c:	2a47a783          	lw	a5,676(a5) # 800216bc <log+0x1c>
    80004420:	37fd                	addiw	a5,a5,-1
    80004422:	04f65e63          	bge	a2,a5,8000447e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004426:	0001d797          	auipc	a5,0x1d
    8000442a:	29a7a783          	lw	a5,666(a5) # 800216c0 <log+0x20>
    8000442e:	06f05063          	blez	a5,8000448e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004432:	4781                	li	a5,0
    80004434:	06c05563          	blez	a2,8000449e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004438:	44cc                	lw	a1,12(s1)
    8000443a:	0001d717          	auipc	a4,0x1d
    8000443e:	29670713          	addi	a4,a4,662 # 800216d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004442:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004444:	4314                	lw	a3,0(a4)
    80004446:	04b68c63          	beq	a3,a1,8000449e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000444a:	2785                	addiw	a5,a5,1
    8000444c:	0711                	addi	a4,a4,4
    8000444e:	fef61be3          	bne	a2,a5,80004444 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004452:	0621                	addi	a2,a2,8
    80004454:	060a                	slli	a2,a2,0x2
    80004456:	0001d797          	auipc	a5,0x1d
    8000445a:	24a78793          	addi	a5,a5,586 # 800216a0 <log>
    8000445e:	963e                	add	a2,a2,a5
    80004460:	44dc                	lw	a5,12(s1)
    80004462:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004464:	8526                	mv	a0,s1
    80004466:	fffff097          	auipc	ra,0xfffff
    8000446a:	da2080e7          	jalr	-606(ra) # 80003208 <bpin>
    log.lh.n++;
    8000446e:	0001d717          	auipc	a4,0x1d
    80004472:	23270713          	addi	a4,a4,562 # 800216a0 <log>
    80004476:	575c                	lw	a5,44(a4)
    80004478:	2785                	addiw	a5,a5,1
    8000447a:	d75c                	sw	a5,44(a4)
    8000447c:	a835                	j	800044b8 <log_write+0xca>
    panic("too big a transaction");
    8000447e:	00004517          	auipc	a0,0x4
    80004482:	1f250513          	addi	a0,a0,498 # 80008670 <syscalls+0x200>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	0b8080e7          	jalr	184(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	1fa50513          	addi	a0,a0,506 # 80008688 <syscalls+0x218>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	0a8080e7          	jalr	168(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000449e:	00878713          	addi	a4,a5,8
    800044a2:	00271693          	slli	a3,a4,0x2
    800044a6:	0001d717          	auipc	a4,0x1d
    800044aa:	1fa70713          	addi	a4,a4,506 # 800216a0 <log>
    800044ae:	9736                	add	a4,a4,a3
    800044b0:	44d4                	lw	a3,12(s1)
    800044b2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b4:	faf608e3          	beq	a2,a5,80004464 <log_write+0x76>
  }
  release(&log.lock);
    800044b8:	0001d517          	auipc	a0,0x1d
    800044bc:	1e850513          	addi	a0,a0,488 # 800216a0 <log>
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	7ca080e7          	jalr	1994(ra) # 80000c8a <release>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret

00000000800044d4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d4:	1101                	addi	sp,sp,-32
    800044d6:	ec06                	sd	ra,24(sp)
    800044d8:	e822                	sd	s0,16(sp)
    800044da:	e426                	sd	s1,8(sp)
    800044dc:	e04a                	sd	s2,0(sp)
    800044de:	1000                	addi	s0,sp,32
    800044e0:	84aa                	mv	s1,a0
    800044e2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e4:	00004597          	auipc	a1,0x4
    800044e8:	1c458593          	addi	a1,a1,452 # 800086a8 <syscalls+0x238>
    800044ec:	0521                	addi	a0,a0,8
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	658080e7          	jalr	1624(ra) # 80000b46 <initlock>
  lk->name = name;
    800044f6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fe:	0204a423          	sw	zero,40(s1)
}
    80004502:	60e2                	ld	ra,24(sp)
    80004504:	6442                	ld	s0,16(sp)
    80004506:	64a2                	ld	s1,8(sp)
    80004508:	6902                	ld	s2,0(sp)
    8000450a:	6105                	addi	sp,sp,32
    8000450c:	8082                	ret

000000008000450e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000450e:	1101                	addi	sp,sp,-32
    80004510:	ec06                	sd	ra,24(sp)
    80004512:	e822                	sd	s0,16(sp)
    80004514:	e426                	sd	s1,8(sp)
    80004516:	e04a                	sd	s2,0(sp)
    80004518:	1000                	addi	s0,sp,32
    8000451a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000451c:	00850913          	addi	s2,a0,8
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	6b4080e7          	jalr	1716(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000452a:	409c                	lw	a5,0(s1)
    8000452c:	cb89                	beqz	a5,8000453e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000452e:	85ca                	mv	a1,s2
    80004530:	8526                	mv	a0,s1
    80004532:	ffffe097          	auipc	ra,0xffffe
    80004536:	be4080e7          	jalr	-1052(ra) # 80002116 <sleep>
  while (lk->locked) {
    8000453a:	409c                	lw	a5,0(s1)
    8000453c:	fbed                	bnez	a5,8000452e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000453e:	4785                	li	a5,1
    80004540:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004542:	ffffd097          	auipc	ra,0xffffd
    80004546:	4a0080e7          	jalr	1184(ra) # 800019e2 <myproc>
    8000454a:	591c                	lw	a5,48(a0)
    8000454c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000454e:	854a                	mv	a0,s2
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	73a080e7          	jalr	1850(ra) # 80000c8a <release>
}
    80004558:	60e2                	ld	ra,24(sp)
    8000455a:	6442                	ld	s0,16(sp)
    8000455c:	64a2                	ld	s1,8(sp)
    8000455e:	6902                	ld	s2,0(sp)
    80004560:	6105                	addi	sp,sp,32
    80004562:	8082                	ret

0000000080004564 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	e426                	sd	s1,8(sp)
    8000456c:	e04a                	sd	s2,0(sp)
    8000456e:	1000                	addi	s0,sp,32
    80004570:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004572:	00850913          	addi	s2,a0,8
    80004576:	854a                	mv	a0,s2
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	65e080e7          	jalr	1630(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004580:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004584:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffe097          	auipc	ra,0xffffe
    8000458e:	bf0080e7          	jalr	-1040(ra) # 8000217a <wakeup>
  release(&lk->lk);
    80004592:	854a                	mv	a0,s2
    80004594:	ffffc097          	auipc	ra,0xffffc
    80004598:	6f6080e7          	jalr	1782(ra) # 80000c8a <release>
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	64a2                	ld	s1,8(sp)
    800045a2:	6902                	ld	s2,0(sp)
    800045a4:	6105                	addi	sp,sp,32
    800045a6:	8082                	ret

00000000800045a8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a8:	7179                	addi	sp,sp,-48
    800045aa:	f406                	sd	ra,40(sp)
    800045ac:	f022                	sd	s0,32(sp)
    800045ae:	ec26                	sd	s1,24(sp)
    800045b0:	e84a                	sd	s2,16(sp)
    800045b2:	e44e                	sd	s3,8(sp)
    800045b4:	1800                	addi	s0,sp,48
    800045b6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b8:	00850913          	addi	s2,a0,8
    800045bc:	854a                	mv	a0,s2
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	618080e7          	jalr	1560(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c6:	409c                	lw	a5,0(s1)
    800045c8:	ef99                	bnez	a5,800045e6 <holdingsleep+0x3e>
    800045ca:	4481                	li	s1,0
  release(&lk->lk);
    800045cc:	854a                	mv	a0,s2
    800045ce:	ffffc097          	auipc	ra,0xffffc
    800045d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
  return r;
}
    800045d6:	8526                	mv	a0,s1
    800045d8:	70a2                	ld	ra,40(sp)
    800045da:	7402                	ld	s0,32(sp)
    800045dc:	64e2                	ld	s1,24(sp)
    800045de:	6942                	ld	s2,16(sp)
    800045e0:	69a2                	ld	s3,8(sp)
    800045e2:	6145                	addi	sp,sp,48
    800045e4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e6:	0284a983          	lw	s3,40(s1)
    800045ea:	ffffd097          	auipc	ra,0xffffd
    800045ee:	3f8080e7          	jalr	1016(ra) # 800019e2 <myproc>
    800045f2:	5904                	lw	s1,48(a0)
    800045f4:	413484b3          	sub	s1,s1,s3
    800045f8:	0014b493          	seqz	s1,s1
    800045fc:	bfc1                	j	800045cc <holdingsleep+0x24>

00000000800045fe <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045fe:	1141                	addi	sp,sp,-16
    80004600:	e406                	sd	ra,8(sp)
    80004602:	e022                	sd	s0,0(sp)
    80004604:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004606:	00004597          	auipc	a1,0x4
    8000460a:	0b258593          	addi	a1,a1,178 # 800086b8 <syscalls+0x248>
    8000460e:	0001d517          	auipc	a0,0x1d
    80004612:	1da50513          	addi	a0,a0,474 # 800217e8 <ftable>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	530080e7          	jalr	1328(ra) # 80000b46 <initlock>
}
    8000461e:	60a2                	ld	ra,8(sp)
    80004620:	6402                	ld	s0,0(sp)
    80004622:	0141                	addi	sp,sp,16
    80004624:	8082                	ret

0000000080004626 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004626:	1101                	addi	sp,sp,-32
    80004628:	ec06                	sd	ra,24(sp)
    8000462a:	e822                	sd	s0,16(sp)
    8000462c:	e426                	sd	s1,8(sp)
    8000462e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004630:	0001d517          	auipc	a0,0x1d
    80004634:	1b850513          	addi	a0,a0,440 # 800217e8 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	59e080e7          	jalr	1438(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004640:	0001d497          	auipc	s1,0x1d
    80004644:	1c048493          	addi	s1,s1,448 # 80021800 <ftable+0x18>
    80004648:	0001e717          	auipc	a4,0x1e
    8000464c:	15870713          	addi	a4,a4,344 # 800227a0 <disk>
    if(f->ref == 0){
    80004650:	40dc                	lw	a5,4(s1)
    80004652:	cf99                	beqz	a5,80004670 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004654:	02848493          	addi	s1,s1,40
    80004658:	fee49ce3          	bne	s1,a4,80004650 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	18c50513          	addi	a0,a0,396 # 800217e8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	626080e7          	jalr	1574(ra) # 80000c8a <release>
  return 0;
    8000466c:	4481                	li	s1,0
    8000466e:	a819                	j	80004684 <filealloc+0x5e>
      f->ref = 1;
    80004670:	4785                	li	a5,1
    80004672:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004674:	0001d517          	auipc	a0,0x1d
    80004678:	17450513          	addi	a0,a0,372 # 800217e8 <ftable>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	60e080e7          	jalr	1550(ra) # 80000c8a <release>
}
    80004684:	8526                	mv	a0,s1
    80004686:	60e2                	ld	ra,24(sp)
    80004688:	6442                	ld	s0,16(sp)
    8000468a:	64a2                	ld	s1,8(sp)
    8000468c:	6105                	addi	sp,sp,32
    8000468e:	8082                	ret

0000000080004690 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004690:	1101                	addi	sp,sp,-32
    80004692:	ec06                	sd	ra,24(sp)
    80004694:	e822                	sd	s0,16(sp)
    80004696:	e426                	sd	s1,8(sp)
    80004698:	1000                	addi	s0,sp,32
    8000469a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000469c:	0001d517          	auipc	a0,0x1d
    800046a0:	14c50513          	addi	a0,a0,332 # 800217e8 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	532080e7          	jalr	1330(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046ac:	40dc                	lw	a5,4(s1)
    800046ae:	02f05263          	blez	a5,800046d2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046b2:	2785                	addiw	a5,a5,1
    800046b4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b6:	0001d517          	auipc	a0,0x1d
    800046ba:	13250513          	addi	a0,a0,306 # 800217e8 <ftable>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5cc080e7          	jalr	1484(ra) # 80000c8a <release>
  return f;
}
    800046c6:	8526                	mv	a0,s1
    800046c8:	60e2                	ld	ra,24(sp)
    800046ca:	6442                	ld	s0,16(sp)
    800046cc:	64a2                	ld	s1,8(sp)
    800046ce:	6105                	addi	sp,sp,32
    800046d0:	8082                	ret
    panic("filedup");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	fee50513          	addi	a0,a0,-18 # 800086c0 <syscalls+0x250>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e64080e7          	jalr	-412(ra) # 8000053e <panic>

00000000800046e2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046e2:	7139                	addi	sp,sp,-64
    800046e4:	fc06                	sd	ra,56(sp)
    800046e6:	f822                	sd	s0,48(sp)
    800046e8:	f426                	sd	s1,40(sp)
    800046ea:	f04a                	sd	s2,32(sp)
    800046ec:	ec4e                	sd	s3,24(sp)
    800046ee:	e852                	sd	s4,16(sp)
    800046f0:	e456                	sd	s5,8(sp)
    800046f2:	0080                	addi	s0,sp,64
    800046f4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f6:	0001d517          	auipc	a0,0x1d
    800046fa:	0f250513          	addi	a0,a0,242 # 800217e8 <ftable>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	4d8080e7          	jalr	1240(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004706:	40dc                	lw	a5,4(s1)
    80004708:	06f05163          	blez	a5,8000476a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000470c:	37fd                	addiw	a5,a5,-1
    8000470e:	0007871b          	sext.w	a4,a5
    80004712:	c0dc                	sw	a5,4(s1)
    80004714:	06e04363          	bgtz	a4,8000477a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004718:	0004a903          	lw	s2,0(s1)
    8000471c:	0094ca83          	lbu	s5,9(s1)
    80004720:	0104ba03          	ld	s4,16(s1)
    80004724:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004728:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000472c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004730:	0001d517          	auipc	a0,0x1d
    80004734:	0b850513          	addi	a0,a0,184 # 800217e8 <ftable>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	552080e7          	jalr	1362(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004740:	4785                	li	a5,1
    80004742:	04f90d63          	beq	s2,a5,8000479c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004746:	3979                	addiw	s2,s2,-2
    80004748:	4785                	li	a5,1
    8000474a:	0527e063          	bltu	a5,s2,8000478a <fileclose+0xa8>
    begin_op();
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	ac8080e7          	jalr	-1336(ra) # 80004216 <begin_op>
    iput(ff.ip);
    80004756:	854e                	mv	a0,s3
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	2b6080e7          	jalr	694(ra) # 80003a0e <iput>
    end_op();
    80004760:	00000097          	auipc	ra,0x0
    80004764:	b36080e7          	jalr	-1226(ra) # 80004296 <end_op>
    80004768:	a00d                	j	8000478a <fileclose+0xa8>
    panic("fileclose");
    8000476a:	00004517          	auipc	a0,0x4
    8000476e:	f5e50513          	addi	a0,a0,-162 # 800086c8 <syscalls+0x258>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>
    release(&ftable.lock);
    8000477a:	0001d517          	auipc	a0,0x1d
    8000477e:	06e50513          	addi	a0,a0,110 # 800217e8 <ftable>
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	508080e7          	jalr	1288(ra) # 80000c8a <release>
  }
}
    8000478a:	70e2                	ld	ra,56(sp)
    8000478c:	7442                	ld	s0,48(sp)
    8000478e:	74a2                	ld	s1,40(sp)
    80004790:	7902                	ld	s2,32(sp)
    80004792:	69e2                	ld	s3,24(sp)
    80004794:	6a42                	ld	s4,16(sp)
    80004796:	6aa2                	ld	s5,8(sp)
    80004798:	6121                	addi	sp,sp,64
    8000479a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000479c:	85d6                	mv	a1,s5
    8000479e:	8552                	mv	a0,s4
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	34c080e7          	jalr	844(ra) # 80004aec <pipeclose>
    800047a8:	b7cd                	j	8000478a <fileclose+0xa8>

00000000800047aa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047aa:	715d                	addi	sp,sp,-80
    800047ac:	e486                	sd	ra,72(sp)
    800047ae:	e0a2                	sd	s0,64(sp)
    800047b0:	fc26                	sd	s1,56(sp)
    800047b2:	f84a                	sd	s2,48(sp)
    800047b4:	f44e                	sd	s3,40(sp)
    800047b6:	0880                	addi	s0,sp,80
    800047b8:	84aa                	mv	s1,a0
    800047ba:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047bc:	ffffd097          	auipc	ra,0xffffd
    800047c0:	226080e7          	jalr	550(ra) # 800019e2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047c4:	409c                	lw	a5,0(s1)
    800047c6:	37f9                	addiw	a5,a5,-2
    800047c8:	4705                	li	a4,1
    800047ca:	04f76763          	bltu	a4,a5,80004818 <filestat+0x6e>
    800047ce:	892a                	mv	s2,a0
    ilock(f->ip);
    800047d0:	6c88                	ld	a0,24(s1)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	082080e7          	jalr	130(ra) # 80003854 <ilock>
    stati(f->ip, &st);
    800047da:	fb840593          	addi	a1,s0,-72
    800047de:	6c88                	ld	a0,24(s1)
    800047e0:	fffff097          	auipc	ra,0xfffff
    800047e4:	2fe080e7          	jalr	766(ra) # 80003ade <stati>
    iunlock(f->ip);
    800047e8:	6c88                	ld	a0,24(s1)
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	12c080e7          	jalr	300(ra) # 80003916 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047f2:	46e1                	li	a3,24
    800047f4:	fb840613          	addi	a2,s0,-72
    800047f8:	85ce                	mv	a1,s3
    800047fa:	05093503          	ld	a0,80(s2)
    800047fe:	ffffd097          	auipc	ra,0xffffd
    80004802:	ea0080e7          	jalr	-352(ra) # 8000169e <copyout>
    80004806:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000480a:	60a6                	ld	ra,72(sp)
    8000480c:	6406                	ld	s0,64(sp)
    8000480e:	74e2                	ld	s1,56(sp)
    80004810:	7942                	ld	s2,48(sp)
    80004812:	79a2                	ld	s3,40(sp)
    80004814:	6161                	addi	sp,sp,80
    80004816:	8082                	ret
  return -1;
    80004818:	557d                	li	a0,-1
    8000481a:	bfc5                	j	8000480a <filestat+0x60>

000000008000481c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000481c:	7179                	addi	sp,sp,-48
    8000481e:	f406                	sd	ra,40(sp)
    80004820:	f022                	sd	s0,32(sp)
    80004822:	ec26                	sd	s1,24(sp)
    80004824:	e84a                	sd	s2,16(sp)
    80004826:	e44e                	sd	s3,8(sp)
    80004828:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000482a:	00854783          	lbu	a5,8(a0)
    8000482e:	c3d5                	beqz	a5,800048d2 <fileread+0xb6>
    80004830:	84aa                	mv	s1,a0
    80004832:	89ae                	mv	s3,a1
    80004834:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004836:	411c                	lw	a5,0(a0)
    80004838:	4705                	li	a4,1
    8000483a:	04e78963          	beq	a5,a4,8000488c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000483e:	470d                	li	a4,3
    80004840:	04e78d63          	beq	a5,a4,8000489a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004844:	4709                	li	a4,2
    80004846:	06e79e63          	bne	a5,a4,800048c2 <fileread+0xa6>
    ilock(f->ip);
    8000484a:	6d08                	ld	a0,24(a0)
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	008080e7          	jalr	8(ra) # 80003854 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004854:	874a                	mv	a4,s2
    80004856:	5094                	lw	a3,32(s1)
    80004858:	864e                	mv	a2,s3
    8000485a:	4585                	li	a1,1
    8000485c:	6c88                	ld	a0,24(s1)
    8000485e:	fffff097          	auipc	ra,0xfffff
    80004862:	2aa080e7          	jalr	682(ra) # 80003b08 <readi>
    80004866:	892a                	mv	s2,a0
    80004868:	00a05563          	blez	a0,80004872 <fileread+0x56>
      f->off += r;
    8000486c:	509c                	lw	a5,32(s1)
    8000486e:	9fa9                	addw	a5,a5,a0
    80004870:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004872:	6c88                	ld	a0,24(s1)
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	0a2080e7          	jalr	162(ra) # 80003916 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000487c:	854a                	mv	a0,s2
    8000487e:	70a2                	ld	ra,40(sp)
    80004880:	7402                	ld	s0,32(sp)
    80004882:	64e2                	ld	s1,24(sp)
    80004884:	6942                	ld	s2,16(sp)
    80004886:	69a2                	ld	s3,8(sp)
    80004888:	6145                	addi	sp,sp,48
    8000488a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000488c:	6908                	ld	a0,16(a0)
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	3c6080e7          	jalr	966(ra) # 80004c54 <piperead>
    80004896:	892a                	mv	s2,a0
    80004898:	b7d5                	j	8000487c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000489a:	02451783          	lh	a5,36(a0)
    8000489e:	03079693          	slli	a3,a5,0x30
    800048a2:	92c1                	srli	a3,a3,0x30
    800048a4:	4725                	li	a4,9
    800048a6:	02d76863          	bltu	a4,a3,800048d6 <fileread+0xba>
    800048aa:	0792                	slli	a5,a5,0x4
    800048ac:	0001d717          	auipc	a4,0x1d
    800048b0:	e9c70713          	addi	a4,a4,-356 # 80021748 <devsw>
    800048b4:	97ba                	add	a5,a5,a4
    800048b6:	639c                	ld	a5,0(a5)
    800048b8:	c38d                	beqz	a5,800048da <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048ba:	4505                	li	a0,1
    800048bc:	9782                	jalr	a5
    800048be:	892a                	mv	s2,a0
    800048c0:	bf75                	j	8000487c <fileread+0x60>
    panic("fileread");
    800048c2:	00004517          	auipc	a0,0x4
    800048c6:	e1650513          	addi	a0,a0,-490 # 800086d8 <syscalls+0x268>
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	c74080e7          	jalr	-908(ra) # 8000053e <panic>
    return -1;
    800048d2:	597d                	li	s2,-1
    800048d4:	b765                	j	8000487c <fileread+0x60>
      return -1;
    800048d6:	597d                	li	s2,-1
    800048d8:	b755                	j	8000487c <fileread+0x60>
    800048da:	597d                	li	s2,-1
    800048dc:	b745                	j	8000487c <fileread+0x60>

00000000800048de <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048de:	715d                	addi	sp,sp,-80
    800048e0:	e486                	sd	ra,72(sp)
    800048e2:	e0a2                	sd	s0,64(sp)
    800048e4:	fc26                	sd	s1,56(sp)
    800048e6:	f84a                	sd	s2,48(sp)
    800048e8:	f44e                	sd	s3,40(sp)
    800048ea:	f052                	sd	s4,32(sp)
    800048ec:	ec56                	sd	s5,24(sp)
    800048ee:	e85a                	sd	s6,16(sp)
    800048f0:	e45e                	sd	s7,8(sp)
    800048f2:	e062                	sd	s8,0(sp)
    800048f4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048f6:	00954783          	lbu	a5,9(a0)
    800048fa:	10078663          	beqz	a5,80004a06 <filewrite+0x128>
    800048fe:	892a                	mv	s2,a0
    80004900:	8aae                	mv	s5,a1
    80004902:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004904:	411c                	lw	a5,0(a0)
    80004906:	4705                	li	a4,1
    80004908:	02e78263          	beq	a5,a4,8000492c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000490c:	470d                	li	a4,3
    8000490e:	02e78663          	beq	a5,a4,8000493a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004912:	4709                	li	a4,2
    80004914:	0ee79163          	bne	a5,a4,800049f6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004918:	0ac05d63          	blez	a2,800049d2 <filewrite+0xf4>
    int i = 0;
    8000491c:	4981                	li	s3,0
    8000491e:	6b05                	lui	s6,0x1
    80004920:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004924:	6b85                	lui	s7,0x1
    80004926:	c00b8b9b          	addiw	s7,s7,-1024
    8000492a:	a861                	j	800049c2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000492c:	6908                	ld	a0,16(a0)
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	22e080e7          	jalr	558(ra) # 80004b5c <pipewrite>
    80004936:	8a2a                	mv	s4,a0
    80004938:	a045                	j	800049d8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000493a:	02451783          	lh	a5,36(a0)
    8000493e:	03079693          	slli	a3,a5,0x30
    80004942:	92c1                	srli	a3,a3,0x30
    80004944:	4725                	li	a4,9
    80004946:	0cd76263          	bltu	a4,a3,80004a0a <filewrite+0x12c>
    8000494a:	0792                	slli	a5,a5,0x4
    8000494c:	0001d717          	auipc	a4,0x1d
    80004950:	dfc70713          	addi	a4,a4,-516 # 80021748 <devsw>
    80004954:	97ba                	add	a5,a5,a4
    80004956:	679c                	ld	a5,8(a5)
    80004958:	cbdd                	beqz	a5,80004a0e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000495a:	4505                	li	a0,1
    8000495c:	9782                	jalr	a5
    8000495e:	8a2a                	mv	s4,a0
    80004960:	a8a5                	j	800049d8 <filewrite+0xfa>
    80004962:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	8b0080e7          	jalr	-1872(ra) # 80004216 <begin_op>
      ilock(f->ip);
    8000496e:	01893503          	ld	a0,24(s2)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	ee2080e7          	jalr	-286(ra) # 80003854 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000497a:	8762                	mv	a4,s8
    8000497c:	02092683          	lw	a3,32(s2)
    80004980:	01598633          	add	a2,s3,s5
    80004984:	4585                	li	a1,1
    80004986:	01893503          	ld	a0,24(s2)
    8000498a:	fffff097          	auipc	ra,0xfffff
    8000498e:	276080e7          	jalr	630(ra) # 80003c00 <writei>
    80004992:	84aa                	mv	s1,a0
    80004994:	00a05763          	blez	a0,800049a2 <filewrite+0xc4>
        f->off += r;
    80004998:	02092783          	lw	a5,32(s2)
    8000499c:	9fa9                	addw	a5,a5,a0
    8000499e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049a2:	01893503          	ld	a0,24(s2)
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	f70080e7          	jalr	-144(ra) # 80003916 <iunlock>
      end_op();
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	8e8080e7          	jalr	-1816(ra) # 80004296 <end_op>

      if(r != n1){
    800049b6:	009c1f63          	bne	s8,s1,800049d4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049ba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049be:	0149db63          	bge	s3,s4,800049d4 <filewrite+0xf6>
      int n1 = n - i;
    800049c2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049c6:	84be                	mv	s1,a5
    800049c8:	2781                	sext.w	a5,a5
    800049ca:	f8fb5ce3          	bge	s6,a5,80004962 <filewrite+0x84>
    800049ce:	84de                	mv	s1,s7
    800049d0:	bf49                	j	80004962 <filewrite+0x84>
    int i = 0;
    800049d2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049d4:	013a1f63          	bne	s4,s3,800049f2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049d8:	8552                	mv	a0,s4
    800049da:	60a6                	ld	ra,72(sp)
    800049dc:	6406                	ld	s0,64(sp)
    800049de:	74e2                	ld	s1,56(sp)
    800049e0:	7942                	ld	s2,48(sp)
    800049e2:	79a2                	ld	s3,40(sp)
    800049e4:	7a02                	ld	s4,32(sp)
    800049e6:	6ae2                	ld	s5,24(sp)
    800049e8:	6b42                	ld	s6,16(sp)
    800049ea:	6ba2                	ld	s7,8(sp)
    800049ec:	6c02                	ld	s8,0(sp)
    800049ee:	6161                	addi	sp,sp,80
    800049f0:	8082                	ret
    ret = (i == n ? n : -1);
    800049f2:	5a7d                	li	s4,-1
    800049f4:	b7d5                	j	800049d8 <filewrite+0xfa>
    panic("filewrite");
    800049f6:	00004517          	auipc	a0,0x4
    800049fa:	cf250513          	addi	a0,a0,-782 # 800086e8 <syscalls+0x278>
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>
    return -1;
    80004a06:	5a7d                	li	s4,-1
    80004a08:	bfc1                	j	800049d8 <filewrite+0xfa>
      return -1;
    80004a0a:	5a7d                	li	s4,-1
    80004a0c:	b7f1                	j	800049d8 <filewrite+0xfa>
    80004a0e:	5a7d                	li	s4,-1
    80004a10:	b7e1                	j	800049d8 <filewrite+0xfa>

0000000080004a12 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a12:	7179                	addi	sp,sp,-48
    80004a14:	f406                	sd	ra,40(sp)
    80004a16:	f022                	sd	s0,32(sp)
    80004a18:	ec26                	sd	s1,24(sp)
    80004a1a:	e84a                	sd	s2,16(sp)
    80004a1c:	e44e                	sd	s3,8(sp)
    80004a1e:	e052                	sd	s4,0(sp)
    80004a20:	1800                	addi	s0,sp,48
    80004a22:	84aa                	mv	s1,a0
    80004a24:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a26:	0005b023          	sd	zero,0(a1)
    80004a2a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	bf8080e7          	jalr	-1032(ra) # 80004626 <filealloc>
    80004a36:	e088                	sd	a0,0(s1)
    80004a38:	c551                	beqz	a0,80004ac4 <pipealloc+0xb2>
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	bec080e7          	jalr	-1044(ra) # 80004626 <filealloc>
    80004a42:	00aa3023          	sd	a0,0(s4)
    80004a46:	c92d                	beqz	a0,80004ab8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	09e080e7          	jalr	158(ra) # 80000ae6 <kalloc>
    80004a50:	892a                	mv	s2,a0
    80004a52:	c125                	beqz	a0,80004ab2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a54:	4985                	li	s3,1
    80004a56:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a5a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a5e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a62:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a66:	00004597          	auipc	a1,0x4
    80004a6a:	c9258593          	addi	a1,a1,-878 # 800086f8 <syscalls+0x288>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	0d8080e7          	jalr	216(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a76:	609c                	ld	a5,0(s1)
    80004a78:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a7c:	609c                	ld	a5,0(s1)
    80004a7e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a82:	609c                	ld	a5,0(s1)
    80004a84:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a88:	609c                	ld	a5,0(s1)
    80004a8a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a8e:	000a3783          	ld	a5,0(s4)
    80004a92:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a96:	000a3783          	ld	a5,0(s4)
    80004a9a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a9e:	000a3783          	ld	a5,0(s4)
    80004aa2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aa6:	000a3783          	ld	a5,0(s4)
    80004aaa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aae:	4501                	li	a0,0
    80004ab0:	a025                	j	80004ad8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ab2:	6088                	ld	a0,0(s1)
    80004ab4:	e501                	bnez	a0,80004abc <pipealloc+0xaa>
    80004ab6:	a039                	j	80004ac4 <pipealloc+0xb2>
    80004ab8:	6088                	ld	a0,0(s1)
    80004aba:	c51d                	beqz	a0,80004ae8 <pipealloc+0xd6>
    fileclose(*f0);
    80004abc:	00000097          	auipc	ra,0x0
    80004ac0:	c26080e7          	jalr	-986(ra) # 800046e2 <fileclose>
  if(*f1)
    80004ac4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac8:	557d                	li	a0,-1
  if(*f1)
    80004aca:	c799                	beqz	a5,80004ad8 <pipealloc+0xc6>
    fileclose(*f1);
    80004acc:	853e                	mv	a0,a5
    80004ace:	00000097          	auipc	ra,0x0
    80004ad2:	c14080e7          	jalr	-1004(ra) # 800046e2 <fileclose>
  return -1;
    80004ad6:	557d                	li	a0,-1
}
    80004ad8:	70a2                	ld	ra,40(sp)
    80004ada:	7402                	ld	s0,32(sp)
    80004adc:	64e2                	ld	s1,24(sp)
    80004ade:	6942                	ld	s2,16(sp)
    80004ae0:	69a2                	ld	s3,8(sp)
    80004ae2:	6a02                	ld	s4,0(sp)
    80004ae4:	6145                	addi	sp,sp,48
    80004ae6:	8082                	ret
  return -1;
    80004ae8:	557d                	li	a0,-1
    80004aea:	b7fd                	j	80004ad8 <pipealloc+0xc6>

0000000080004aec <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aec:	1101                	addi	sp,sp,-32
    80004aee:	ec06                	sd	ra,24(sp)
    80004af0:	e822                	sd	s0,16(sp)
    80004af2:	e426                	sd	s1,8(sp)
    80004af4:	e04a                	sd	s2,0(sp)
    80004af6:	1000                	addi	s0,sp,32
    80004af8:	84aa                	mv	s1,a0
    80004afa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	0da080e7          	jalr	218(ra) # 80000bd6 <acquire>
  if(writable){
    80004b04:	02090d63          	beqz	s2,80004b3e <pipeclose+0x52>
    pi->writeopen = 0;
    80004b08:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b0c:	21848513          	addi	a0,s1,536
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	66a080e7          	jalr	1642(ra) # 8000217a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b18:	2204b783          	ld	a5,544(s1)
    80004b1c:	eb95                	bnez	a5,80004b50 <pipeclose+0x64>
    release(&pi->lock);
    80004b1e:	8526                	mv	a0,s1
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	16a080e7          	jalr	362(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b28:	8526                	mv	a0,s1
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	ec0080e7          	jalr	-320(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004b32:	60e2                	ld	ra,24(sp)
    80004b34:	6442                	ld	s0,16(sp)
    80004b36:	64a2                	ld	s1,8(sp)
    80004b38:	6902                	ld	s2,0(sp)
    80004b3a:	6105                	addi	sp,sp,32
    80004b3c:	8082                	ret
    pi->readopen = 0;
    80004b3e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b42:	21c48513          	addi	a0,s1,540
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	634080e7          	jalr	1588(ra) # 8000217a <wakeup>
    80004b4e:	b7e9                	j	80004b18 <pipeclose+0x2c>
    release(&pi->lock);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	138080e7          	jalr	312(ra) # 80000c8a <release>
}
    80004b5a:	bfe1                	j	80004b32 <pipeclose+0x46>

0000000080004b5c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b5c:	711d                	addi	sp,sp,-96
    80004b5e:	ec86                	sd	ra,88(sp)
    80004b60:	e8a2                	sd	s0,80(sp)
    80004b62:	e4a6                	sd	s1,72(sp)
    80004b64:	e0ca                	sd	s2,64(sp)
    80004b66:	fc4e                	sd	s3,56(sp)
    80004b68:	f852                	sd	s4,48(sp)
    80004b6a:	f456                	sd	s5,40(sp)
    80004b6c:	f05a                	sd	s6,32(sp)
    80004b6e:	ec5e                	sd	s7,24(sp)
    80004b70:	e862                	sd	s8,16(sp)
    80004b72:	1080                	addi	s0,sp,96
    80004b74:	84aa                	mv	s1,a0
    80004b76:	8aae                	mv	s5,a1
    80004b78:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	e68080e7          	jalr	-408(ra) # 800019e2 <myproc>
    80004b82:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	050080e7          	jalr	80(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b8e:	0b405663          	blez	s4,80004c3a <pipewrite+0xde>
  int i = 0;
    80004b92:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b94:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b96:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b9a:	21c48b93          	addi	s7,s1,540
    80004b9e:	a089                	j	80004be0 <pipewrite+0x84>
      release(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0e8080e7          	jalr	232(ra) # 80000c8a <release>
      return -1;
    80004baa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bac:	854a                	mv	a0,s2
    80004bae:	60e6                	ld	ra,88(sp)
    80004bb0:	6446                	ld	s0,80(sp)
    80004bb2:	64a6                	ld	s1,72(sp)
    80004bb4:	6906                	ld	s2,64(sp)
    80004bb6:	79e2                	ld	s3,56(sp)
    80004bb8:	7a42                	ld	s4,48(sp)
    80004bba:	7aa2                	ld	s5,40(sp)
    80004bbc:	7b02                	ld	s6,32(sp)
    80004bbe:	6be2                	ld	s7,24(sp)
    80004bc0:	6c42                	ld	s8,16(sp)
    80004bc2:	6125                	addi	sp,sp,96
    80004bc4:	8082                	ret
      wakeup(&pi->nread);
    80004bc6:	8562                	mv	a0,s8
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	5b2080e7          	jalr	1458(ra) # 8000217a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd0:	85a6                	mv	a1,s1
    80004bd2:	855e                	mv	a0,s7
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	542080e7          	jalr	1346(ra) # 80002116 <sleep>
  while(i < n){
    80004bdc:	07495063          	bge	s2,s4,80004c3c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004be0:	2204a783          	lw	a5,544(s1)
    80004be4:	dfd5                	beqz	a5,80004ba0 <pipewrite+0x44>
    80004be6:	854e                	mv	a0,s3
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	7d6080e7          	jalr	2006(ra) # 800023be <killed>
    80004bf0:	f945                	bnez	a0,80004ba0 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bf2:	2184a783          	lw	a5,536(s1)
    80004bf6:	21c4a703          	lw	a4,540(s1)
    80004bfa:	2007879b          	addiw	a5,a5,512
    80004bfe:	fcf704e3          	beq	a4,a5,80004bc6 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c02:	4685                	li	a3,1
    80004c04:	01590633          	add	a2,s2,s5
    80004c08:	faf40593          	addi	a1,s0,-81
    80004c0c:	0509b503          	ld	a0,80(s3)
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	b1a080e7          	jalr	-1254(ra) # 8000172a <copyin>
    80004c18:	03650263          	beq	a0,s6,80004c3c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c1c:	21c4a783          	lw	a5,540(s1)
    80004c20:	0017871b          	addiw	a4,a5,1
    80004c24:	20e4ae23          	sw	a4,540(s1)
    80004c28:	1ff7f793          	andi	a5,a5,511
    80004c2c:	97a6                	add	a5,a5,s1
    80004c2e:	faf44703          	lbu	a4,-81(s0)
    80004c32:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c36:	2905                	addiw	s2,s2,1
    80004c38:	b755                	j	80004bdc <pipewrite+0x80>
  int i = 0;
    80004c3a:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c3c:	21848513          	addi	a0,s1,536
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	53a080e7          	jalr	1338(ra) # 8000217a <wakeup>
  release(&pi->lock);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	040080e7          	jalr	64(ra) # 80000c8a <release>
  return i;
    80004c52:	bfa9                	j	80004bac <pipewrite+0x50>

0000000080004c54 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c54:	715d                	addi	sp,sp,-80
    80004c56:	e486                	sd	ra,72(sp)
    80004c58:	e0a2                	sd	s0,64(sp)
    80004c5a:	fc26                	sd	s1,56(sp)
    80004c5c:	f84a                	sd	s2,48(sp)
    80004c5e:	f44e                	sd	s3,40(sp)
    80004c60:	f052                	sd	s4,32(sp)
    80004c62:	ec56                	sd	s5,24(sp)
    80004c64:	e85a                	sd	s6,16(sp)
    80004c66:	0880                	addi	s0,sp,80
    80004c68:	84aa                	mv	s1,a0
    80004c6a:	892e                	mv	s2,a1
    80004c6c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	d74080e7          	jalr	-652(ra) # 800019e2 <myproc>
    80004c76:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	f5c080e7          	jalr	-164(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c82:	2184a703          	lw	a4,536(s1)
    80004c86:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c8a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8e:	02f71763          	bne	a4,a5,80004cbc <piperead+0x68>
    80004c92:	2244a783          	lw	a5,548(s1)
    80004c96:	c39d                	beqz	a5,80004cbc <piperead+0x68>
    if(killed(pr)){
    80004c98:	8552                	mv	a0,s4
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	724080e7          	jalr	1828(ra) # 800023be <killed>
    80004ca2:	e941                	bnez	a0,80004d32 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ca4:	85a6                	mv	a1,s1
    80004ca6:	854e                	mv	a0,s3
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	46e080e7          	jalr	1134(ra) # 80002116 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb0:	2184a703          	lw	a4,536(s1)
    80004cb4:	21c4a783          	lw	a5,540(s1)
    80004cb8:	fcf70de3          	beq	a4,a5,80004c92 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cbc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cbe:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc0:	05505363          	blez	s5,80004d06 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004cc4:	2184a783          	lw	a5,536(s1)
    80004cc8:	21c4a703          	lw	a4,540(s1)
    80004ccc:	02f70d63          	beq	a4,a5,80004d06 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cd0:	0017871b          	addiw	a4,a5,1
    80004cd4:	20e4ac23          	sw	a4,536(s1)
    80004cd8:	1ff7f793          	andi	a5,a5,511
    80004cdc:	97a6                	add	a5,a5,s1
    80004cde:	0187c783          	lbu	a5,24(a5)
    80004ce2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce6:	4685                	li	a3,1
    80004ce8:	fbf40613          	addi	a2,s0,-65
    80004cec:	85ca                	mv	a1,s2
    80004cee:	050a3503          	ld	a0,80(s4)
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	9ac080e7          	jalr	-1620(ra) # 8000169e <copyout>
    80004cfa:	01650663          	beq	a0,s6,80004d06 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfe:	2985                	addiw	s3,s3,1
    80004d00:	0905                	addi	s2,s2,1
    80004d02:	fd3a91e3          	bne	s5,s3,80004cc4 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d06:	21c48513          	addi	a0,s1,540
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	470080e7          	jalr	1136(ra) # 8000217a <wakeup>
  release(&pi->lock);
    80004d12:	8526                	mv	a0,s1
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	f76080e7          	jalr	-138(ra) # 80000c8a <release>
  return i;
}
    80004d1c:	854e                	mv	a0,s3
    80004d1e:	60a6                	ld	ra,72(sp)
    80004d20:	6406                	ld	s0,64(sp)
    80004d22:	74e2                	ld	s1,56(sp)
    80004d24:	7942                	ld	s2,48(sp)
    80004d26:	79a2                	ld	s3,40(sp)
    80004d28:	7a02                	ld	s4,32(sp)
    80004d2a:	6ae2                	ld	s5,24(sp)
    80004d2c:	6b42                	ld	s6,16(sp)
    80004d2e:	6161                	addi	sp,sp,80
    80004d30:	8082                	ret
      release(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	f56080e7          	jalr	-170(ra) # 80000c8a <release>
      return -1;
    80004d3c:	59fd                	li	s3,-1
    80004d3e:	bff9                	j	80004d1c <piperead+0xc8>

0000000080004d40 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d40:	1141                	addi	sp,sp,-16
    80004d42:	e422                	sd	s0,8(sp)
    80004d44:	0800                	addi	s0,sp,16
    80004d46:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d48:	8905                	andi	a0,a0,1
    80004d4a:	c111                	beqz	a0,80004d4e <flags2perm+0xe>
      perm = PTE_X;
    80004d4c:	4521                	li	a0,8
    if(flags & 0x2)
    80004d4e:	8b89                	andi	a5,a5,2
    80004d50:	c399                	beqz	a5,80004d56 <flags2perm+0x16>
      perm |= PTE_W;
    80004d52:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d56:	6422                	ld	s0,8(sp)
    80004d58:	0141                	addi	sp,sp,16
    80004d5a:	8082                	ret

0000000080004d5c <exec>:

int
exec(char *path, char **argv)
{
    80004d5c:	de010113          	addi	sp,sp,-544
    80004d60:	20113c23          	sd	ra,536(sp)
    80004d64:	20813823          	sd	s0,528(sp)
    80004d68:	20913423          	sd	s1,520(sp)
    80004d6c:	21213023          	sd	s2,512(sp)
    80004d70:	ffce                	sd	s3,504(sp)
    80004d72:	fbd2                	sd	s4,496(sp)
    80004d74:	f7d6                	sd	s5,488(sp)
    80004d76:	f3da                	sd	s6,480(sp)
    80004d78:	efde                	sd	s7,472(sp)
    80004d7a:	ebe2                	sd	s8,464(sp)
    80004d7c:	e7e6                	sd	s9,456(sp)
    80004d7e:	e3ea                	sd	s10,448(sp)
    80004d80:	ff6e                	sd	s11,440(sp)
    80004d82:	1400                	addi	s0,sp,544
    80004d84:	892a                	mv	s2,a0
    80004d86:	dea43423          	sd	a0,-536(s0)
    80004d8a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	c54080e7          	jalr	-940(ra) # 800019e2 <myproc>
    80004d96:	84aa                	mv	s1,a0

  begin_op();
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	47e080e7          	jalr	1150(ra) # 80004216 <begin_op>

  if((ip = namei(path)) == 0){
    80004da0:	854a                	mv	a0,s2
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	258080e7          	jalr	600(ra) # 80003ffa <namei>
    80004daa:	c93d                	beqz	a0,80004e20 <exec+0xc4>
    80004dac:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	aa6080e7          	jalr	-1370(ra) # 80003854 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004db6:	04000713          	li	a4,64
    80004dba:	4681                	li	a3,0
    80004dbc:	e5040613          	addi	a2,s0,-432
    80004dc0:	4581                	li	a1,0
    80004dc2:	8556                	mv	a0,s5
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	d44080e7          	jalr	-700(ra) # 80003b08 <readi>
    80004dcc:	04000793          	li	a5,64
    80004dd0:	00f51a63          	bne	a0,a5,80004de4 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004dd4:	e5042703          	lw	a4,-432(s0)
    80004dd8:	464c47b7          	lui	a5,0x464c4
    80004ddc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004de0:	04f70663          	beq	a4,a5,80004e2c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004de4:	8556                	mv	a0,s5
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	cd0080e7          	jalr	-816(ra) # 80003ab6 <iunlockput>
    end_op();
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	4a8080e7          	jalr	1192(ra) # 80004296 <end_op>
  }
  return -1;
    80004df6:	557d                	li	a0,-1
}
    80004df8:	21813083          	ld	ra,536(sp)
    80004dfc:	21013403          	ld	s0,528(sp)
    80004e00:	20813483          	ld	s1,520(sp)
    80004e04:	20013903          	ld	s2,512(sp)
    80004e08:	79fe                	ld	s3,504(sp)
    80004e0a:	7a5e                	ld	s4,496(sp)
    80004e0c:	7abe                	ld	s5,488(sp)
    80004e0e:	7b1e                	ld	s6,480(sp)
    80004e10:	6bfe                	ld	s7,472(sp)
    80004e12:	6c5e                	ld	s8,464(sp)
    80004e14:	6cbe                	ld	s9,456(sp)
    80004e16:	6d1e                	ld	s10,448(sp)
    80004e18:	7dfa                	ld	s11,440(sp)
    80004e1a:	22010113          	addi	sp,sp,544
    80004e1e:	8082                	ret
    end_op();
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	476080e7          	jalr	1142(ra) # 80004296 <end_op>
    return -1;
    80004e28:	557d                	li	a0,-1
    80004e2a:	b7f9                	j	80004df8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	c78080e7          	jalr	-904(ra) # 80001aa6 <proc_pagetable>
    80004e36:	8b2a                	mv	s6,a0
    80004e38:	d555                	beqz	a0,80004de4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e3a:	e7042783          	lw	a5,-400(s0)
    80004e3e:	e8845703          	lhu	a4,-376(s0)
    80004e42:	c735                	beqz	a4,80004eae <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e44:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e46:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e4a:	6a05                	lui	s4,0x1
    80004e4c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e50:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e54:	6d85                	lui	s11,0x1
    80004e56:	7d7d                	lui	s10,0xfffff
    80004e58:	acb9                	j	800050b6 <exec+0x35a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e5a:	00004517          	auipc	a0,0x4
    80004e5e:	8a650513          	addi	a0,a0,-1882 # 80008700 <syscalls+0x290>
    80004e62:	ffffb097          	auipc	ra,0xffffb
    80004e66:	6dc080e7          	jalr	1756(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e6a:	874a                	mv	a4,s2
    80004e6c:	009c86bb          	addw	a3,s9,s1
    80004e70:	4581                	li	a1,0
    80004e72:	8556                	mv	a0,s5
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	c94080e7          	jalr	-876(ra) # 80003b08 <readi>
    80004e7c:	2501                	sext.w	a0,a0
    80004e7e:	1ca91963          	bne	s2,a0,80005050 <exec+0x2f4>
  for(i = 0; i < sz; i += PGSIZE){
    80004e82:	009d84bb          	addw	s1,s11,s1
    80004e86:	013d09bb          	addw	s3,s10,s3
    80004e8a:	2174f663          	bgeu	s1,s7,80005096 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    80004e8e:	02049593          	slli	a1,s1,0x20
    80004e92:	9181                	srli	a1,a1,0x20
    80004e94:	95e2                	add	a1,a1,s8
    80004e96:	855a                	mv	a0,s6
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	1e4080e7          	jalr	484(ra) # 8000107c <walkaddr>
    80004ea0:	862a                	mv	a2,a0
    if(pa == 0)
    80004ea2:	dd45                	beqz	a0,80004e5a <exec+0xfe>
      n = PGSIZE;
    80004ea4:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ea6:	fd49f2e3          	bgeu	s3,s4,80004e6a <exec+0x10e>
      n = sz - i;
    80004eaa:	894e                	mv	s2,s3
    80004eac:	bf7d                	j	80004e6a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eae:	4901                	li	s2,0
  iunlockput(ip);
    80004eb0:	8556                	mv	a0,s5
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	c04080e7          	jalr	-1020(ra) # 80003ab6 <iunlockput>
  end_op();
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	3dc080e7          	jalr	988(ra) # 80004296 <end_op>
  p = myproc();
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	b20080e7          	jalr	-1248(ra) # 800019e2 <myproc>
    80004eca:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ecc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ed0:	6785                	lui	a5,0x1
    80004ed2:	17fd                	addi	a5,a5,-1
    80004ed4:	993e                	add	s2,s2,a5
    80004ed6:	77fd                	lui	a5,0xfffff
    80004ed8:	00f977b3          	and	a5,s2,a5
    80004edc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ee0:	4691                	li	a3,4
    80004ee2:	6609                	lui	a2,0x2
    80004ee4:	963e                	add	a2,a2,a5
    80004ee6:	85be                	mv	a1,a5
    80004ee8:	855a                	mv	a0,s6
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	55c080e7          	jalr	1372(ra) # 80001446 <uvmalloc>
    80004ef2:	8c2a                	mv	s8,a0
  ip = 0;
    80004ef4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ef6:	14050d63          	beqz	a0,80005050 <exec+0x2f4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004efa:	75f9                	lui	a1,0xffffe
    80004efc:	95aa                	add	a1,a1,a0
    80004efe:	855a                	mv	a0,s6
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	76c080e7          	jalr	1900(ra) # 8000166c <uvmclear>
  stackbase = sp - PGSIZE;
    80004f08:	7afd                	lui	s5,0xfffff
    80004f0a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f0c:	df043783          	ld	a5,-528(s0)
    80004f10:	6388                	ld	a0,0(a5)
    80004f12:	c925                	beqz	a0,80004f82 <exec+0x226>
    80004f14:	e9040993          	addi	s3,s0,-368
    80004f18:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f1c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f1e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	f2e080e7          	jalr	-210(ra) # 80000e4e <strlen>
    80004f28:	0015079b          	addiw	a5,a0,1
    80004f2c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f30:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f34:	15596563          	bltu	s2,s5,8000507e <exec+0x322>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f38:	df043d83          	ld	s11,-528(s0)
    80004f3c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f40:	8552                	mv	a0,s4
    80004f42:	ffffc097          	auipc	ra,0xffffc
    80004f46:	f0c080e7          	jalr	-244(ra) # 80000e4e <strlen>
    80004f4a:	0015069b          	addiw	a3,a0,1
    80004f4e:	8652                	mv	a2,s4
    80004f50:	85ca                	mv	a1,s2
    80004f52:	855a                	mv	a0,s6
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	74a080e7          	jalr	1866(ra) # 8000169e <copyout>
    80004f5c:	12054563          	bltz	a0,80005086 <exec+0x32a>
    ustack[argc] = sp;
    80004f60:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f64:	0485                	addi	s1,s1,1
    80004f66:	008d8793          	addi	a5,s11,8
    80004f6a:	def43823          	sd	a5,-528(s0)
    80004f6e:	008db503          	ld	a0,8(s11)
    80004f72:	c911                	beqz	a0,80004f86 <exec+0x22a>
    if(argc >= MAXARG)
    80004f74:	09a1                	addi	s3,s3,8
    80004f76:	fb3c95e3          	bne	s9,s3,80004f20 <exec+0x1c4>
  sz = sz1;
    80004f7a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f7e:	4a81                	li	s5,0
    80004f80:	a8c1                	j	80005050 <exec+0x2f4>
  sp = sz;
    80004f82:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f84:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f86:	00349793          	slli	a5,s1,0x3
    80004f8a:	f9040713          	addi	a4,s0,-112
    80004f8e:	97ba                	add	a5,a5,a4
    80004f90:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd7068>
  sp -= (argc+1) * sizeof(uint64);
    80004f94:	00148693          	addi	a3,s1,1
    80004f98:	068e                	slli	a3,a3,0x3
    80004f9a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f9e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fa2:	01597663          	bgeu	s2,s5,80004fae <exec+0x252>
  sz = sz1;
    80004fa6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004faa:	4a81                	li	s5,0
    80004fac:	a055                	j	80005050 <exec+0x2f4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fae:	e9040613          	addi	a2,s0,-368
    80004fb2:	85ca                	mv	a1,s2
    80004fb4:	855a                	mv	a0,s6
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	6e8080e7          	jalr	1768(ra) # 8000169e <copyout>
    80004fbe:	0c054863          	bltz	a0,8000508e <exec+0x332>
  p->trapframe->a1 = sp;
    80004fc2:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004fc6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fca:	de843783          	ld	a5,-536(s0)
    80004fce:	0007c703          	lbu	a4,0(a5)
    80004fd2:	cf11                	beqz	a4,80004fee <exec+0x292>
    80004fd4:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fd6:	02f00693          	li	a3,47
    80004fda:	a039                	j	80004fe8 <exec+0x28c>
      last = s+1;
    80004fdc:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fe0:	0785                	addi	a5,a5,1
    80004fe2:	fff7c703          	lbu	a4,-1(a5)
    80004fe6:	c701                	beqz	a4,80004fee <exec+0x292>
    if(*s == '/')
    80004fe8:	fed71ce3          	bne	a4,a3,80004fe0 <exec+0x284>
    80004fec:	bfc5                	j	80004fdc <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fee:	4641                	li	a2,16
    80004ff0:	de843583          	ld	a1,-536(s0)
    80004ff4:	158b8513          	addi	a0,s7,344
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	e24080e7          	jalr	-476(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005000:	050bb983          	ld	s3,80(s7)
  p->pagetable = pagetable;
    80005004:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005008:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000500c:	058bb783          	ld	a5,88(s7)
    80005010:	e6843703          	ld	a4,-408(s0)
    80005014:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005016:	058bb783          	ld	a5,88(s7)
    8000501a:	0327b823          	sd	s2,48(a5)
  if(p->fb_map_va) {
    8000501e:	168bb583          	ld	a1,360(s7)
    80005022:	e991                	bnez	a1,80005036 <exec+0x2da>
  proc_freepagetable(oldpagetable, oldsz);
    80005024:	85ea                	mv	a1,s10
    80005026:	854e                	mv	a0,s3
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	b1a080e7          	jalr	-1254(ra) # 80001b42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005030:	0004851b          	sext.w	a0,s1
    80005034:	b3d1                	j	80004df8 <exec+0x9c>
    uvmunmap(oldpagetable, p->fb_map_va, GPU_FB_PAGES, 0);
    80005036:	4681                	li	a3,0
    80005038:	12c00613          	li	a2,300
    8000503c:	854e                	mv	a0,s3
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	25c080e7          	jalr	604(ra) # 8000129a <uvmunmap>
    p->fb_map_va = 0;
    80005046:	160bb423          	sd	zero,360(s7)
    8000504a:	bfe9                	j	80005024 <exec+0x2c8>
    8000504c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005050:	df843583          	ld	a1,-520(s0)
    80005054:	855a                	mv	a0,s6
    80005056:	ffffd097          	auipc	ra,0xffffd
    8000505a:	aec080e7          	jalr	-1300(ra) # 80001b42 <proc_freepagetable>
  if(ip){
    8000505e:	d80a93e3          	bnez	s5,80004de4 <exec+0x88>
  return -1;
    80005062:	557d                	li	a0,-1
    80005064:	bb51                	j	80004df8 <exec+0x9c>
    80005066:	df243c23          	sd	s2,-520(s0)
    8000506a:	b7dd                	j	80005050 <exec+0x2f4>
    8000506c:	df243c23          	sd	s2,-520(s0)
    80005070:	b7c5                	j	80005050 <exec+0x2f4>
    80005072:	df243c23          	sd	s2,-520(s0)
    80005076:	bfe9                	j	80005050 <exec+0x2f4>
    80005078:	df243c23          	sd	s2,-520(s0)
    8000507c:	bfd1                	j	80005050 <exec+0x2f4>
  sz = sz1;
    8000507e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005082:	4a81                	li	s5,0
    80005084:	b7f1                	j	80005050 <exec+0x2f4>
  sz = sz1;
    80005086:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000508a:	4a81                	li	s5,0
    8000508c:	b7d1                	j	80005050 <exec+0x2f4>
  sz = sz1;
    8000508e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005092:	4a81                	li	s5,0
    80005094:	bf75                	j	80005050 <exec+0x2f4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005096:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000509a:	e0843783          	ld	a5,-504(s0)
    8000509e:	0017869b          	addiw	a3,a5,1
    800050a2:	e0d43423          	sd	a3,-504(s0)
    800050a6:	e0043783          	ld	a5,-512(s0)
    800050aa:	0387879b          	addiw	a5,a5,56
    800050ae:	e8845703          	lhu	a4,-376(s0)
    800050b2:	dee6dfe3          	bge	a3,a4,80004eb0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050b6:	2781                	sext.w	a5,a5
    800050b8:	e0f43023          	sd	a5,-512(s0)
    800050bc:	03800713          	li	a4,56
    800050c0:	86be                	mv	a3,a5
    800050c2:	e1840613          	addi	a2,s0,-488
    800050c6:	4581                	li	a1,0
    800050c8:	8556                	mv	a0,s5
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	a3e080e7          	jalr	-1474(ra) # 80003b08 <readi>
    800050d2:	03800793          	li	a5,56
    800050d6:	f6f51be3          	bne	a0,a5,8000504c <exec+0x2f0>
    if(ph.type != ELF_PROG_LOAD)
    800050da:	e1842783          	lw	a5,-488(s0)
    800050de:	4705                	li	a4,1
    800050e0:	fae79de3          	bne	a5,a4,8000509a <exec+0x33e>
    if(ph.memsz < ph.filesz)
    800050e4:	e4043483          	ld	s1,-448(s0)
    800050e8:	e3843783          	ld	a5,-456(s0)
    800050ec:	f6f4ede3          	bltu	s1,a5,80005066 <exec+0x30a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050f0:	e2843783          	ld	a5,-472(s0)
    800050f4:	94be                	add	s1,s1,a5
    800050f6:	f6f4ebe3          	bltu	s1,a5,8000506c <exec+0x310>
    if(ph.vaddr % PGSIZE != 0)
    800050fa:	de043703          	ld	a4,-544(s0)
    800050fe:	8ff9                	and	a5,a5,a4
    80005100:	fbad                	bnez	a5,80005072 <exec+0x316>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005102:	e1c42503          	lw	a0,-484(s0)
    80005106:	00000097          	auipc	ra,0x0
    8000510a:	c3a080e7          	jalr	-966(ra) # 80004d40 <flags2perm>
    8000510e:	86aa                	mv	a3,a0
    80005110:	8626                	mv	a2,s1
    80005112:	85ca                	mv	a1,s2
    80005114:	855a                	mv	a0,s6
    80005116:	ffffc097          	auipc	ra,0xffffc
    8000511a:	330080e7          	jalr	816(ra) # 80001446 <uvmalloc>
    8000511e:	dea43c23          	sd	a0,-520(s0)
    80005122:	d939                	beqz	a0,80005078 <exec+0x31c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005124:	e2843c03          	ld	s8,-472(s0)
    80005128:	e2042c83          	lw	s9,-480(s0)
    8000512c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005130:	f60b83e3          	beqz	s7,80005096 <exec+0x33a>
    80005134:	89de                	mv	s3,s7
    80005136:	4481                	li	s1,0
    80005138:	bb99                	j	80004e8e <exec+0x132>

000000008000513a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000513a:	7179                	addi	sp,sp,-48
    8000513c:	f406                	sd	ra,40(sp)
    8000513e:	f022                	sd	s0,32(sp)
    80005140:	ec26                	sd	s1,24(sp)
    80005142:	e84a                	sd	s2,16(sp)
    80005144:	1800                	addi	s0,sp,48
    80005146:	892e                	mv	s2,a1
    80005148:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000514a:	fdc40593          	addi	a1,s0,-36
    8000514e:	ffffe097          	auipc	ra,0xffffe
    80005152:	a34080e7          	jalr	-1484(ra) # 80002b82 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005156:	fdc42703          	lw	a4,-36(s0)
    8000515a:	47bd                	li	a5,15
    8000515c:	02e7eb63          	bltu	a5,a4,80005192 <argfd+0x58>
    80005160:	ffffd097          	auipc	ra,0xffffd
    80005164:	882080e7          	jalr	-1918(ra) # 800019e2 <myproc>
    80005168:	fdc42703          	lw	a4,-36(s0)
    8000516c:	01a70793          	addi	a5,a4,26
    80005170:	078e                	slli	a5,a5,0x3
    80005172:	953e                	add	a0,a0,a5
    80005174:	611c                	ld	a5,0(a0)
    80005176:	c385                	beqz	a5,80005196 <argfd+0x5c>
    return -1;
  if(pfd)
    80005178:	00090463          	beqz	s2,80005180 <argfd+0x46>
    *pfd = fd;
    8000517c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005180:	4501                	li	a0,0
  if(pf)
    80005182:	c091                	beqz	s1,80005186 <argfd+0x4c>
    *pf = f;
    80005184:	e09c                	sd	a5,0(s1)
}
    80005186:	70a2                	ld	ra,40(sp)
    80005188:	7402                	ld	s0,32(sp)
    8000518a:	64e2                	ld	s1,24(sp)
    8000518c:	6942                	ld	s2,16(sp)
    8000518e:	6145                	addi	sp,sp,48
    80005190:	8082                	ret
    return -1;
    80005192:	557d                	li	a0,-1
    80005194:	bfcd                	j	80005186 <argfd+0x4c>
    80005196:	557d                	li	a0,-1
    80005198:	b7fd                	j	80005186 <argfd+0x4c>

000000008000519a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000519a:	1101                	addi	sp,sp,-32
    8000519c:	ec06                	sd	ra,24(sp)
    8000519e:	e822                	sd	s0,16(sp)
    800051a0:	e426                	sd	s1,8(sp)
    800051a2:	1000                	addi	s0,sp,32
    800051a4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051a6:	ffffd097          	auipc	ra,0xffffd
    800051aa:	83c080e7          	jalr	-1988(ra) # 800019e2 <myproc>
    800051ae:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051b0:	0d050793          	addi	a5,a0,208
    800051b4:	4501                	li	a0,0
    800051b6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051b8:	6398                	ld	a4,0(a5)
    800051ba:	cb19                	beqz	a4,800051d0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051bc:	2505                	addiw	a0,a0,1
    800051be:	07a1                	addi	a5,a5,8
    800051c0:	fed51ce3          	bne	a0,a3,800051b8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051c4:	557d                	li	a0,-1
}
    800051c6:	60e2                	ld	ra,24(sp)
    800051c8:	6442                	ld	s0,16(sp)
    800051ca:	64a2                	ld	s1,8(sp)
    800051cc:	6105                	addi	sp,sp,32
    800051ce:	8082                	ret
      p->ofile[fd] = f;
    800051d0:	01a50793          	addi	a5,a0,26
    800051d4:	078e                	slli	a5,a5,0x3
    800051d6:	963e                	add	a2,a2,a5
    800051d8:	e204                	sd	s1,0(a2)
      return fd;
    800051da:	b7f5                	j	800051c6 <fdalloc+0x2c>

00000000800051dc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051dc:	715d                	addi	sp,sp,-80
    800051de:	e486                	sd	ra,72(sp)
    800051e0:	e0a2                	sd	s0,64(sp)
    800051e2:	fc26                	sd	s1,56(sp)
    800051e4:	f84a                	sd	s2,48(sp)
    800051e6:	f44e                	sd	s3,40(sp)
    800051e8:	f052                	sd	s4,32(sp)
    800051ea:	ec56                	sd	s5,24(sp)
    800051ec:	e85a                	sd	s6,16(sp)
    800051ee:	0880                	addi	s0,sp,80
    800051f0:	8b2e                	mv	s6,a1
    800051f2:	89b2                	mv	s3,a2
    800051f4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051f6:	fb040593          	addi	a1,s0,-80
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	e1e080e7          	jalr	-482(ra) # 80004018 <nameiparent>
    80005202:	84aa                	mv	s1,a0
    80005204:	14050f63          	beqz	a0,80005362 <create+0x186>
    return 0;

  ilock(dp);
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	64c080e7          	jalr	1612(ra) # 80003854 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005210:	4601                	li	a2,0
    80005212:	fb040593          	addi	a1,s0,-80
    80005216:	8526                	mv	a0,s1
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	b20080e7          	jalr	-1248(ra) # 80003d38 <dirlookup>
    80005220:	8aaa                	mv	s5,a0
    80005222:	c931                	beqz	a0,80005276 <create+0x9a>
    iunlockput(dp);
    80005224:	8526                	mv	a0,s1
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	890080e7          	jalr	-1904(ra) # 80003ab6 <iunlockput>
    ilock(ip);
    8000522e:	8556                	mv	a0,s5
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	624080e7          	jalr	1572(ra) # 80003854 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005238:	000b059b          	sext.w	a1,s6
    8000523c:	4789                	li	a5,2
    8000523e:	02f59563          	bne	a1,a5,80005268 <create+0x8c>
    80005242:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd71ac>
    80005246:	37f9                	addiw	a5,a5,-2
    80005248:	17c2                	slli	a5,a5,0x30
    8000524a:	93c1                	srli	a5,a5,0x30
    8000524c:	4705                	li	a4,1
    8000524e:	00f76d63          	bltu	a4,a5,80005268 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005252:	8556                	mv	a0,s5
    80005254:	60a6                	ld	ra,72(sp)
    80005256:	6406                	ld	s0,64(sp)
    80005258:	74e2                	ld	s1,56(sp)
    8000525a:	7942                	ld	s2,48(sp)
    8000525c:	79a2                	ld	s3,40(sp)
    8000525e:	7a02                	ld	s4,32(sp)
    80005260:	6ae2                	ld	s5,24(sp)
    80005262:	6b42                	ld	s6,16(sp)
    80005264:	6161                	addi	sp,sp,80
    80005266:	8082                	ret
    iunlockput(ip);
    80005268:	8556                	mv	a0,s5
    8000526a:	fffff097          	auipc	ra,0xfffff
    8000526e:	84c080e7          	jalr	-1972(ra) # 80003ab6 <iunlockput>
    return 0;
    80005272:	4a81                	li	s5,0
    80005274:	bff9                	j	80005252 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005276:	85da                	mv	a1,s6
    80005278:	4088                	lw	a0,0(s1)
    8000527a:	ffffe097          	auipc	ra,0xffffe
    8000527e:	43e080e7          	jalr	1086(ra) # 800036b8 <ialloc>
    80005282:	8a2a                	mv	s4,a0
    80005284:	c539                	beqz	a0,800052d2 <create+0xf6>
  ilock(ip);
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	5ce080e7          	jalr	1486(ra) # 80003854 <ilock>
  ip->major = major;
    8000528e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005292:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005296:	4905                	li	s2,1
    80005298:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000529c:	8552                	mv	a0,s4
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	4ec080e7          	jalr	1260(ra) # 8000378a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052a6:	000b059b          	sext.w	a1,s6
    800052aa:	03258b63          	beq	a1,s2,800052e0 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800052ae:	004a2603          	lw	a2,4(s4)
    800052b2:	fb040593          	addi	a1,s0,-80
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	c90080e7          	jalr	-880(ra) # 80003f48 <dirlink>
    800052c0:	06054f63          	bltz	a0,8000533e <create+0x162>
  iunlockput(dp);
    800052c4:	8526                	mv	a0,s1
    800052c6:	ffffe097          	auipc	ra,0xffffe
    800052ca:	7f0080e7          	jalr	2032(ra) # 80003ab6 <iunlockput>
  return ip;
    800052ce:	8ad2                	mv	s5,s4
    800052d0:	b749                	j	80005252 <create+0x76>
    iunlockput(dp);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	7e2080e7          	jalr	2018(ra) # 80003ab6 <iunlockput>
    return 0;
    800052dc:	8ad2                	mv	s5,s4
    800052de:	bf95                	j	80005252 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052e0:	004a2603          	lw	a2,4(s4)
    800052e4:	00003597          	auipc	a1,0x3
    800052e8:	43c58593          	addi	a1,a1,1084 # 80008720 <syscalls+0x2b0>
    800052ec:	8552                	mv	a0,s4
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	c5a080e7          	jalr	-934(ra) # 80003f48 <dirlink>
    800052f6:	04054463          	bltz	a0,8000533e <create+0x162>
    800052fa:	40d0                	lw	a2,4(s1)
    800052fc:	00003597          	auipc	a1,0x3
    80005300:	42c58593          	addi	a1,a1,1068 # 80008728 <syscalls+0x2b8>
    80005304:	8552                	mv	a0,s4
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	c42080e7          	jalr	-958(ra) # 80003f48 <dirlink>
    8000530e:	02054863          	bltz	a0,8000533e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005312:	004a2603          	lw	a2,4(s4)
    80005316:	fb040593          	addi	a1,s0,-80
    8000531a:	8526                	mv	a0,s1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	c2c080e7          	jalr	-980(ra) # 80003f48 <dirlink>
    80005324:	00054d63          	bltz	a0,8000533e <create+0x162>
    dp->nlink++;  // for ".."
    80005328:	04a4d783          	lhu	a5,74(s1)
    8000532c:	2785                	addiw	a5,a5,1
    8000532e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005332:	8526                	mv	a0,s1
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	456080e7          	jalr	1110(ra) # 8000378a <iupdate>
    8000533c:	b761                	j	800052c4 <create+0xe8>
  ip->nlink = 0;
    8000533e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005342:	8552                	mv	a0,s4
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	446080e7          	jalr	1094(ra) # 8000378a <iupdate>
  iunlockput(ip);
    8000534c:	8552                	mv	a0,s4
    8000534e:	ffffe097          	auipc	ra,0xffffe
    80005352:	768080e7          	jalr	1896(ra) # 80003ab6 <iunlockput>
  iunlockput(dp);
    80005356:	8526                	mv	a0,s1
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	75e080e7          	jalr	1886(ra) # 80003ab6 <iunlockput>
  return 0;
    80005360:	bdcd                	j	80005252 <create+0x76>
    return 0;
    80005362:	8aaa                	mv	s5,a0
    80005364:	b5fd                	j	80005252 <create+0x76>

0000000080005366 <sys_dup>:
{
    80005366:	7179                	addi	sp,sp,-48
    80005368:	f406                	sd	ra,40(sp)
    8000536a:	f022                	sd	s0,32(sp)
    8000536c:	ec26                	sd	s1,24(sp)
    8000536e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005370:	fd840613          	addi	a2,s0,-40
    80005374:	4581                	li	a1,0
    80005376:	4501                	li	a0,0
    80005378:	00000097          	auipc	ra,0x0
    8000537c:	dc2080e7          	jalr	-574(ra) # 8000513a <argfd>
    return -1;
    80005380:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005382:	02054363          	bltz	a0,800053a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005386:	fd843503          	ld	a0,-40(s0)
    8000538a:	00000097          	auipc	ra,0x0
    8000538e:	e10080e7          	jalr	-496(ra) # 8000519a <fdalloc>
    80005392:	84aa                	mv	s1,a0
    return -1;
    80005394:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005396:	00054963          	bltz	a0,800053a8 <sys_dup+0x42>
  filedup(f);
    8000539a:	fd843503          	ld	a0,-40(s0)
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	2f2080e7          	jalr	754(ra) # 80004690 <filedup>
  return fd;
    800053a6:	87a6                	mv	a5,s1
}
    800053a8:	853e                	mv	a0,a5
    800053aa:	70a2                	ld	ra,40(sp)
    800053ac:	7402                	ld	s0,32(sp)
    800053ae:	64e2                	ld	s1,24(sp)
    800053b0:	6145                	addi	sp,sp,48
    800053b2:	8082                	ret

00000000800053b4 <sys_read>:
{
    800053b4:	7179                	addi	sp,sp,-48
    800053b6:	f406                	sd	ra,40(sp)
    800053b8:	f022                	sd	s0,32(sp)
    800053ba:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053bc:	fd840593          	addi	a1,s0,-40
    800053c0:	4505                	li	a0,1
    800053c2:	ffffd097          	auipc	ra,0xffffd
    800053c6:	7e0080e7          	jalr	2016(ra) # 80002ba2 <argaddr>
  argint(2, &n);
    800053ca:	fe440593          	addi	a1,s0,-28
    800053ce:	4509                	li	a0,2
    800053d0:	ffffd097          	auipc	ra,0xffffd
    800053d4:	7b2080e7          	jalr	1970(ra) # 80002b82 <argint>
  if(argfd(0, 0, &f) < 0)
    800053d8:	fe840613          	addi	a2,s0,-24
    800053dc:	4581                	li	a1,0
    800053de:	4501                	li	a0,0
    800053e0:	00000097          	auipc	ra,0x0
    800053e4:	d5a080e7          	jalr	-678(ra) # 8000513a <argfd>
    800053e8:	87aa                	mv	a5,a0
    return -1;
    800053ea:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053ec:	0007cc63          	bltz	a5,80005404 <sys_read+0x50>
  return fileread(f, p, n);
    800053f0:	fe442603          	lw	a2,-28(s0)
    800053f4:	fd843583          	ld	a1,-40(s0)
    800053f8:	fe843503          	ld	a0,-24(s0)
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	420080e7          	jalr	1056(ra) # 8000481c <fileread>
}
    80005404:	70a2                	ld	ra,40(sp)
    80005406:	7402                	ld	s0,32(sp)
    80005408:	6145                	addi	sp,sp,48
    8000540a:	8082                	ret

000000008000540c <sys_write>:
{
    8000540c:	7179                	addi	sp,sp,-48
    8000540e:	f406                	sd	ra,40(sp)
    80005410:	f022                	sd	s0,32(sp)
    80005412:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005414:	fd840593          	addi	a1,s0,-40
    80005418:	4505                	li	a0,1
    8000541a:	ffffd097          	auipc	ra,0xffffd
    8000541e:	788080e7          	jalr	1928(ra) # 80002ba2 <argaddr>
  argint(2, &n);
    80005422:	fe440593          	addi	a1,s0,-28
    80005426:	4509                	li	a0,2
    80005428:	ffffd097          	auipc	ra,0xffffd
    8000542c:	75a080e7          	jalr	1882(ra) # 80002b82 <argint>
  if(argfd(0, 0, &f) < 0)
    80005430:	fe840613          	addi	a2,s0,-24
    80005434:	4581                	li	a1,0
    80005436:	4501                	li	a0,0
    80005438:	00000097          	auipc	ra,0x0
    8000543c:	d02080e7          	jalr	-766(ra) # 8000513a <argfd>
    80005440:	87aa                	mv	a5,a0
    return -1;
    80005442:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005444:	0007cc63          	bltz	a5,8000545c <sys_write+0x50>
  return filewrite(f, p, n);
    80005448:	fe442603          	lw	a2,-28(s0)
    8000544c:	fd843583          	ld	a1,-40(s0)
    80005450:	fe843503          	ld	a0,-24(s0)
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	48a080e7          	jalr	1162(ra) # 800048de <filewrite>
}
    8000545c:	70a2                	ld	ra,40(sp)
    8000545e:	7402                	ld	s0,32(sp)
    80005460:	6145                	addi	sp,sp,48
    80005462:	8082                	ret

0000000080005464 <sys_close>:
{
    80005464:	1101                	addi	sp,sp,-32
    80005466:	ec06                	sd	ra,24(sp)
    80005468:	e822                	sd	s0,16(sp)
    8000546a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000546c:	fe040613          	addi	a2,s0,-32
    80005470:	fec40593          	addi	a1,s0,-20
    80005474:	4501                	li	a0,0
    80005476:	00000097          	auipc	ra,0x0
    8000547a:	cc4080e7          	jalr	-828(ra) # 8000513a <argfd>
    return -1;
    8000547e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005480:	02054463          	bltz	a0,800054a8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	55e080e7          	jalr	1374(ra) # 800019e2 <myproc>
    8000548c:	fec42783          	lw	a5,-20(s0)
    80005490:	07e9                	addi	a5,a5,26
    80005492:	078e                	slli	a5,a5,0x3
    80005494:	97aa                	add	a5,a5,a0
    80005496:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000549a:	fe043503          	ld	a0,-32(s0)
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	244080e7          	jalr	580(ra) # 800046e2 <fileclose>
  return 0;
    800054a6:	4781                	li	a5,0
}
    800054a8:	853e                	mv	a0,a5
    800054aa:	60e2                	ld	ra,24(sp)
    800054ac:	6442                	ld	s0,16(sp)
    800054ae:	6105                	addi	sp,sp,32
    800054b0:	8082                	ret

00000000800054b2 <sys_fstat>:
{
    800054b2:	1101                	addi	sp,sp,-32
    800054b4:	ec06                	sd	ra,24(sp)
    800054b6:	e822                	sd	s0,16(sp)
    800054b8:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800054ba:	fe040593          	addi	a1,s0,-32
    800054be:	4505                	li	a0,1
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	6e2080e7          	jalr	1762(ra) # 80002ba2 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800054c8:	fe840613          	addi	a2,s0,-24
    800054cc:	4581                	li	a1,0
    800054ce:	4501                	li	a0,0
    800054d0:	00000097          	auipc	ra,0x0
    800054d4:	c6a080e7          	jalr	-918(ra) # 8000513a <argfd>
    800054d8:	87aa                	mv	a5,a0
    return -1;
    800054da:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054dc:	0007ca63          	bltz	a5,800054f0 <sys_fstat+0x3e>
  return filestat(f, st);
    800054e0:	fe043583          	ld	a1,-32(s0)
    800054e4:	fe843503          	ld	a0,-24(s0)
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	2c2080e7          	jalr	706(ra) # 800047aa <filestat>
}
    800054f0:	60e2                	ld	ra,24(sp)
    800054f2:	6442                	ld	s0,16(sp)
    800054f4:	6105                	addi	sp,sp,32
    800054f6:	8082                	ret

00000000800054f8 <sys_link>:
{
    800054f8:	7169                	addi	sp,sp,-304
    800054fa:	f606                	sd	ra,296(sp)
    800054fc:	f222                	sd	s0,288(sp)
    800054fe:	ee26                	sd	s1,280(sp)
    80005500:	ea4a                	sd	s2,272(sp)
    80005502:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005504:	08000613          	li	a2,128
    80005508:	ed040593          	addi	a1,s0,-304
    8000550c:	4501                	li	a0,0
    8000550e:	ffffd097          	auipc	ra,0xffffd
    80005512:	6b4080e7          	jalr	1716(ra) # 80002bc2 <argstr>
    return -1;
    80005516:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005518:	10054e63          	bltz	a0,80005634 <sys_link+0x13c>
    8000551c:	08000613          	li	a2,128
    80005520:	f5040593          	addi	a1,s0,-176
    80005524:	4505                	li	a0,1
    80005526:	ffffd097          	auipc	ra,0xffffd
    8000552a:	69c080e7          	jalr	1692(ra) # 80002bc2 <argstr>
    return -1;
    8000552e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005530:	10054263          	bltz	a0,80005634 <sys_link+0x13c>
  begin_op();
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	ce2080e7          	jalr	-798(ra) # 80004216 <begin_op>
  if((ip = namei(old)) == 0){
    8000553c:	ed040513          	addi	a0,s0,-304
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	aba080e7          	jalr	-1350(ra) # 80003ffa <namei>
    80005548:	84aa                	mv	s1,a0
    8000554a:	c551                	beqz	a0,800055d6 <sys_link+0xde>
  ilock(ip);
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	308080e7          	jalr	776(ra) # 80003854 <ilock>
  if(ip->type == T_DIR){
    80005554:	04449703          	lh	a4,68(s1)
    80005558:	4785                	li	a5,1
    8000555a:	08f70463          	beq	a4,a5,800055e2 <sys_link+0xea>
  ip->nlink++;
    8000555e:	04a4d783          	lhu	a5,74(s1)
    80005562:	2785                	addiw	a5,a5,1
    80005564:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	220080e7          	jalr	544(ra) # 8000378a <iupdate>
  iunlock(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	3a2080e7          	jalr	930(ra) # 80003916 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000557c:	fd040593          	addi	a1,s0,-48
    80005580:	f5040513          	addi	a0,s0,-176
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	a94080e7          	jalr	-1388(ra) # 80004018 <nameiparent>
    8000558c:	892a                	mv	s2,a0
    8000558e:	c935                	beqz	a0,80005602 <sys_link+0x10a>
  ilock(dp);
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	2c4080e7          	jalr	708(ra) # 80003854 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005598:	00092703          	lw	a4,0(s2)
    8000559c:	409c                	lw	a5,0(s1)
    8000559e:	04f71d63          	bne	a4,a5,800055f8 <sys_link+0x100>
    800055a2:	40d0                	lw	a2,4(s1)
    800055a4:	fd040593          	addi	a1,s0,-48
    800055a8:	854a                	mv	a0,s2
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	99e080e7          	jalr	-1634(ra) # 80003f48 <dirlink>
    800055b2:	04054363          	bltz	a0,800055f8 <sys_link+0x100>
  iunlockput(dp);
    800055b6:	854a                	mv	a0,s2
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	4fe080e7          	jalr	1278(ra) # 80003ab6 <iunlockput>
  iput(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	44c080e7          	jalr	1100(ra) # 80003a0e <iput>
  end_op();
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	ccc080e7          	jalr	-820(ra) # 80004296 <end_op>
  return 0;
    800055d2:	4781                	li	a5,0
    800055d4:	a085                	j	80005634 <sys_link+0x13c>
    end_op();
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	cc0080e7          	jalr	-832(ra) # 80004296 <end_op>
    return -1;
    800055de:	57fd                	li	a5,-1
    800055e0:	a891                	j	80005634 <sys_link+0x13c>
    iunlockput(ip);
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	4d2080e7          	jalr	1234(ra) # 80003ab6 <iunlockput>
    end_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	caa080e7          	jalr	-854(ra) # 80004296 <end_op>
    return -1;
    800055f4:	57fd                	li	a5,-1
    800055f6:	a83d                	j	80005634 <sys_link+0x13c>
    iunlockput(dp);
    800055f8:	854a                	mv	a0,s2
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	4bc080e7          	jalr	1212(ra) # 80003ab6 <iunlockput>
  ilock(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	250080e7          	jalr	592(ra) # 80003854 <ilock>
  ip->nlink--;
    8000560c:	04a4d783          	lhu	a5,74(s1)
    80005610:	37fd                	addiw	a5,a5,-1
    80005612:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005616:	8526                	mv	a0,s1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	172080e7          	jalr	370(ra) # 8000378a <iupdate>
  iunlockput(ip);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	494080e7          	jalr	1172(ra) # 80003ab6 <iunlockput>
  end_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	c6c080e7          	jalr	-916(ra) # 80004296 <end_op>
  return -1;
    80005632:	57fd                	li	a5,-1
}
    80005634:	853e                	mv	a0,a5
    80005636:	70b2                	ld	ra,296(sp)
    80005638:	7412                	ld	s0,288(sp)
    8000563a:	64f2                	ld	s1,280(sp)
    8000563c:	6952                	ld	s2,272(sp)
    8000563e:	6155                	addi	sp,sp,304
    80005640:	8082                	ret

0000000080005642 <sys_unlink>:
{
    80005642:	7151                	addi	sp,sp,-240
    80005644:	f586                	sd	ra,232(sp)
    80005646:	f1a2                	sd	s0,224(sp)
    80005648:	eda6                	sd	s1,216(sp)
    8000564a:	e9ca                	sd	s2,208(sp)
    8000564c:	e5ce                	sd	s3,200(sp)
    8000564e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005650:	08000613          	li	a2,128
    80005654:	f3040593          	addi	a1,s0,-208
    80005658:	4501                	li	a0,0
    8000565a:	ffffd097          	auipc	ra,0xffffd
    8000565e:	568080e7          	jalr	1384(ra) # 80002bc2 <argstr>
    80005662:	18054163          	bltz	a0,800057e4 <sys_unlink+0x1a2>
  begin_op();
    80005666:	fffff097          	auipc	ra,0xfffff
    8000566a:	bb0080e7          	jalr	-1104(ra) # 80004216 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000566e:	fb040593          	addi	a1,s0,-80
    80005672:	f3040513          	addi	a0,s0,-208
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	9a2080e7          	jalr	-1630(ra) # 80004018 <nameiparent>
    8000567e:	84aa                	mv	s1,a0
    80005680:	c979                	beqz	a0,80005756 <sys_unlink+0x114>
  ilock(dp);
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	1d2080e7          	jalr	466(ra) # 80003854 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000568a:	00003597          	auipc	a1,0x3
    8000568e:	09658593          	addi	a1,a1,150 # 80008720 <syscalls+0x2b0>
    80005692:	fb040513          	addi	a0,s0,-80
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	688080e7          	jalr	1672(ra) # 80003d1e <namecmp>
    8000569e:	14050a63          	beqz	a0,800057f2 <sys_unlink+0x1b0>
    800056a2:	00003597          	auipc	a1,0x3
    800056a6:	08658593          	addi	a1,a1,134 # 80008728 <syscalls+0x2b8>
    800056aa:	fb040513          	addi	a0,s0,-80
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	670080e7          	jalr	1648(ra) # 80003d1e <namecmp>
    800056b6:	12050e63          	beqz	a0,800057f2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056ba:	f2c40613          	addi	a2,s0,-212
    800056be:	fb040593          	addi	a1,s0,-80
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	674080e7          	jalr	1652(ra) # 80003d38 <dirlookup>
    800056cc:	892a                	mv	s2,a0
    800056ce:	12050263          	beqz	a0,800057f2 <sys_unlink+0x1b0>
  ilock(ip);
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	182080e7          	jalr	386(ra) # 80003854 <ilock>
  if(ip->nlink < 1)
    800056da:	04a91783          	lh	a5,74(s2)
    800056de:	08f05263          	blez	a5,80005762 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056e2:	04491703          	lh	a4,68(s2)
    800056e6:	4785                	li	a5,1
    800056e8:	08f70563          	beq	a4,a5,80005772 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056ec:	4641                	li	a2,16
    800056ee:	4581                	li	a1,0
    800056f0:	fc040513          	addi	a0,s0,-64
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	5de080e7          	jalr	1502(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056fc:	4741                	li	a4,16
    800056fe:	f2c42683          	lw	a3,-212(s0)
    80005702:	fc040613          	addi	a2,s0,-64
    80005706:	4581                	li	a1,0
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	4f6080e7          	jalr	1270(ra) # 80003c00 <writei>
    80005712:	47c1                	li	a5,16
    80005714:	0af51563          	bne	a0,a5,800057be <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005718:	04491703          	lh	a4,68(s2)
    8000571c:	4785                	li	a5,1
    8000571e:	0af70863          	beq	a4,a5,800057ce <sys_unlink+0x18c>
  iunlockput(dp);
    80005722:	8526                	mv	a0,s1
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	392080e7          	jalr	914(ra) # 80003ab6 <iunlockput>
  ip->nlink--;
    8000572c:	04a95783          	lhu	a5,74(s2)
    80005730:	37fd                	addiw	a5,a5,-1
    80005732:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	052080e7          	jalr	82(ra) # 8000378a <iupdate>
  iunlockput(ip);
    80005740:	854a                	mv	a0,s2
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	374080e7          	jalr	884(ra) # 80003ab6 <iunlockput>
  end_op();
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	b4c080e7          	jalr	-1204(ra) # 80004296 <end_op>
  return 0;
    80005752:	4501                	li	a0,0
    80005754:	a84d                	j	80005806 <sys_unlink+0x1c4>
    end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	b40080e7          	jalr	-1216(ra) # 80004296 <end_op>
    return -1;
    8000575e:	557d                	li	a0,-1
    80005760:	a05d                	j	80005806 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005762:	00003517          	auipc	a0,0x3
    80005766:	fce50513          	addi	a0,a0,-50 # 80008730 <syscalls+0x2c0>
    8000576a:	ffffb097          	auipc	ra,0xffffb
    8000576e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005772:	04c92703          	lw	a4,76(s2)
    80005776:	02000793          	li	a5,32
    8000577a:	f6e7f9e3          	bgeu	a5,a4,800056ec <sys_unlink+0xaa>
    8000577e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005782:	4741                	li	a4,16
    80005784:	86ce                	mv	a3,s3
    80005786:	f1840613          	addi	a2,s0,-232
    8000578a:	4581                	li	a1,0
    8000578c:	854a                	mv	a0,s2
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	37a080e7          	jalr	890(ra) # 80003b08 <readi>
    80005796:	47c1                	li	a5,16
    80005798:	00f51b63          	bne	a0,a5,800057ae <sys_unlink+0x16c>
    if(de.inum != 0)
    8000579c:	f1845783          	lhu	a5,-232(s0)
    800057a0:	e7a1                	bnez	a5,800057e8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a2:	29c1                	addiw	s3,s3,16
    800057a4:	04c92783          	lw	a5,76(s2)
    800057a8:	fcf9ede3          	bltu	s3,a5,80005782 <sys_unlink+0x140>
    800057ac:	b781                	j	800056ec <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057ae:	00003517          	auipc	a0,0x3
    800057b2:	f9a50513          	addi	a0,a0,-102 # 80008748 <syscalls+0x2d8>
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	d88080e7          	jalr	-632(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057be:	00003517          	auipc	a0,0x3
    800057c2:	fa250513          	addi	a0,a0,-94 # 80008760 <syscalls+0x2f0>
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	d78080e7          	jalr	-648(ra) # 8000053e <panic>
    dp->nlink--;
    800057ce:	04a4d783          	lhu	a5,74(s1)
    800057d2:	37fd                	addiw	a5,a5,-1
    800057d4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	fb0080e7          	jalr	-80(ra) # 8000378a <iupdate>
    800057e2:	b781                	j	80005722 <sys_unlink+0xe0>
    return -1;
    800057e4:	557d                	li	a0,-1
    800057e6:	a005                	j	80005806 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057e8:	854a                	mv	a0,s2
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	2cc080e7          	jalr	716(ra) # 80003ab6 <iunlockput>
  iunlockput(dp);
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	2c2080e7          	jalr	706(ra) # 80003ab6 <iunlockput>
  end_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	a9a080e7          	jalr	-1382(ra) # 80004296 <end_op>
  return -1;
    80005804:	557d                	li	a0,-1
}
    80005806:	70ae                	ld	ra,232(sp)
    80005808:	740e                	ld	s0,224(sp)
    8000580a:	64ee                	ld	s1,216(sp)
    8000580c:	694e                	ld	s2,208(sp)
    8000580e:	69ae                	ld	s3,200(sp)
    80005810:	616d                	addi	sp,sp,240
    80005812:	8082                	ret

0000000080005814 <sys_open>:

uint64
sys_open(void)
{
    80005814:	7131                	addi	sp,sp,-192
    80005816:	fd06                	sd	ra,184(sp)
    80005818:	f922                	sd	s0,176(sp)
    8000581a:	f526                	sd	s1,168(sp)
    8000581c:	f14a                	sd	s2,160(sp)
    8000581e:	ed4e                	sd	s3,152(sp)
    80005820:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005822:	f4c40593          	addi	a1,s0,-180
    80005826:	4505                	li	a0,1
    80005828:	ffffd097          	auipc	ra,0xffffd
    8000582c:	35a080e7          	jalr	858(ra) # 80002b82 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005830:	08000613          	li	a2,128
    80005834:	f5040593          	addi	a1,s0,-176
    80005838:	4501                	li	a0,0
    8000583a:	ffffd097          	auipc	ra,0xffffd
    8000583e:	388080e7          	jalr	904(ra) # 80002bc2 <argstr>
    80005842:	87aa                	mv	a5,a0
    return -1;
    80005844:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005846:	0a07c963          	bltz	a5,800058f8 <sys_open+0xe4>

  begin_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	9cc080e7          	jalr	-1588(ra) # 80004216 <begin_op>

  if(omode & O_CREATE){
    80005852:	f4c42783          	lw	a5,-180(s0)
    80005856:	2007f793          	andi	a5,a5,512
    8000585a:	cfc5                	beqz	a5,80005912 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000585c:	4681                	li	a3,0
    8000585e:	4601                	li	a2,0
    80005860:	4589                	li	a1,2
    80005862:	f5040513          	addi	a0,s0,-176
    80005866:	00000097          	auipc	ra,0x0
    8000586a:	976080e7          	jalr	-1674(ra) # 800051dc <create>
    8000586e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005870:	c959                	beqz	a0,80005906 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005872:	04449703          	lh	a4,68(s1)
    80005876:	478d                	li	a5,3
    80005878:	00f71763          	bne	a4,a5,80005886 <sys_open+0x72>
    8000587c:	0464d703          	lhu	a4,70(s1)
    80005880:	47a5                	li	a5,9
    80005882:	0ce7ed63          	bltu	a5,a4,8000595c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	da0080e7          	jalr	-608(ra) # 80004626 <filealloc>
    8000588e:	89aa                	mv	s3,a0
    80005890:	10050363          	beqz	a0,80005996 <sys_open+0x182>
    80005894:	00000097          	auipc	ra,0x0
    80005898:	906080e7          	jalr	-1786(ra) # 8000519a <fdalloc>
    8000589c:	892a                	mv	s2,a0
    8000589e:	0e054763          	bltz	a0,8000598c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058a2:	04449703          	lh	a4,68(s1)
    800058a6:	478d                	li	a5,3
    800058a8:	0cf70563          	beq	a4,a5,80005972 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058ac:	4789                	li	a5,2
    800058ae:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058b2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058b6:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058ba:	f4c42783          	lw	a5,-180(s0)
    800058be:	0017c713          	xori	a4,a5,1
    800058c2:	8b05                	andi	a4,a4,1
    800058c4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058c8:	0037f713          	andi	a4,a5,3
    800058cc:	00e03733          	snez	a4,a4
    800058d0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058d4:	4007f793          	andi	a5,a5,1024
    800058d8:	c791                	beqz	a5,800058e4 <sys_open+0xd0>
    800058da:	04449703          	lh	a4,68(s1)
    800058de:	4789                	li	a5,2
    800058e0:	0af70063          	beq	a4,a5,80005980 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058e4:	8526                	mv	a0,s1
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	030080e7          	jalr	48(ra) # 80003916 <iunlock>
  end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	9a8080e7          	jalr	-1624(ra) # 80004296 <end_op>

  return fd;
    800058f6:	854a                	mv	a0,s2
}
    800058f8:	70ea                	ld	ra,184(sp)
    800058fa:	744a                	ld	s0,176(sp)
    800058fc:	74aa                	ld	s1,168(sp)
    800058fe:	790a                	ld	s2,160(sp)
    80005900:	69ea                	ld	s3,152(sp)
    80005902:	6129                	addi	sp,sp,192
    80005904:	8082                	ret
      end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	990080e7          	jalr	-1648(ra) # 80004296 <end_op>
      return -1;
    8000590e:	557d                	li	a0,-1
    80005910:	b7e5                	j	800058f8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005912:	f5040513          	addi	a0,s0,-176
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	6e4080e7          	jalr	1764(ra) # 80003ffa <namei>
    8000591e:	84aa                	mv	s1,a0
    80005920:	c905                	beqz	a0,80005950 <sys_open+0x13c>
    ilock(ip);
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	f32080e7          	jalr	-206(ra) # 80003854 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000592a:	04449703          	lh	a4,68(s1)
    8000592e:	4785                	li	a5,1
    80005930:	f4f711e3          	bne	a4,a5,80005872 <sys_open+0x5e>
    80005934:	f4c42783          	lw	a5,-180(s0)
    80005938:	d7b9                	beqz	a5,80005886 <sys_open+0x72>
      iunlockput(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	17a080e7          	jalr	378(ra) # 80003ab6 <iunlockput>
      end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	952080e7          	jalr	-1710(ra) # 80004296 <end_op>
      return -1;
    8000594c:	557d                	li	a0,-1
    8000594e:	b76d                	j	800058f8 <sys_open+0xe4>
      end_op();
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	946080e7          	jalr	-1722(ra) # 80004296 <end_op>
      return -1;
    80005958:	557d                	li	a0,-1
    8000595a:	bf79                	j	800058f8 <sys_open+0xe4>
    iunlockput(ip);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	158080e7          	jalr	344(ra) # 80003ab6 <iunlockput>
    end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	930080e7          	jalr	-1744(ra) # 80004296 <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	b761                	j	800058f8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005972:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005976:	04649783          	lh	a5,70(s1)
    8000597a:	02f99223          	sh	a5,36(s3)
    8000597e:	bf25                	j	800058b6 <sys_open+0xa2>
    itrunc(ip);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	fe0080e7          	jalr	-32(ra) # 80003962 <itrunc>
    8000598a:	bfa9                	j	800058e4 <sys_open+0xd0>
      fileclose(f);
    8000598c:	854e                	mv	a0,s3
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	d54080e7          	jalr	-684(ra) # 800046e2 <fileclose>
    iunlockput(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	11e080e7          	jalr	286(ra) # 80003ab6 <iunlockput>
    end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8f6080e7          	jalr	-1802(ra) # 80004296 <end_op>
    return -1;
    800059a8:	557d                	li	a0,-1
    800059aa:	b7b9                	j	800058f8 <sys_open+0xe4>

00000000800059ac <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059ac:	7175                	addi	sp,sp,-144
    800059ae:	e506                	sd	ra,136(sp)
    800059b0:	e122                	sd	s0,128(sp)
    800059b2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	862080e7          	jalr	-1950(ra) # 80004216 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059bc:	08000613          	li	a2,128
    800059c0:	f7040593          	addi	a1,s0,-144
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	1fc080e7          	jalr	508(ra) # 80002bc2 <argstr>
    800059ce:	02054963          	bltz	a0,80005a00 <sys_mkdir+0x54>
    800059d2:	4681                	li	a3,0
    800059d4:	4601                	li	a2,0
    800059d6:	4585                	li	a1,1
    800059d8:	f7040513          	addi	a0,s0,-144
    800059dc:	00000097          	auipc	ra,0x0
    800059e0:	800080e7          	jalr	-2048(ra) # 800051dc <create>
    800059e4:	cd11                	beqz	a0,80005a00 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	0d0080e7          	jalr	208(ra) # 80003ab6 <iunlockput>
  end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	8a8080e7          	jalr	-1880(ra) # 80004296 <end_op>
  return 0;
    800059f6:	4501                	li	a0,0
}
    800059f8:	60aa                	ld	ra,136(sp)
    800059fa:	640a                	ld	s0,128(sp)
    800059fc:	6149                	addi	sp,sp,144
    800059fe:	8082                	ret
    end_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	896080e7          	jalr	-1898(ra) # 80004296 <end_op>
    return -1;
    80005a08:	557d                	li	a0,-1
    80005a0a:	b7fd                	j	800059f8 <sys_mkdir+0x4c>

0000000080005a0c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a0c:	7135                	addi	sp,sp,-160
    80005a0e:	ed06                	sd	ra,152(sp)
    80005a10:	e922                	sd	s0,144(sp)
    80005a12:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	802080e7          	jalr	-2046(ra) # 80004216 <begin_op>
  argint(1, &major);
    80005a1c:	f6c40593          	addi	a1,s0,-148
    80005a20:	4505                	li	a0,1
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	160080e7          	jalr	352(ra) # 80002b82 <argint>
  argint(2, &minor);
    80005a2a:	f6840593          	addi	a1,s0,-152
    80005a2e:	4509                	li	a0,2
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	152080e7          	jalr	338(ra) # 80002b82 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a38:	08000613          	li	a2,128
    80005a3c:	f7040593          	addi	a1,s0,-144
    80005a40:	4501                	li	a0,0
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	180080e7          	jalr	384(ra) # 80002bc2 <argstr>
    80005a4a:	02054b63          	bltz	a0,80005a80 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a4e:	f6841683          	lh	a3,-152(s0)
    80005a52:	f6c41603          	lh	a2,-148(s0)
    80005a56:	458d                	li	a1,3
    80005a58:	f7040513          	addi	a0,s0,-144
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	780080e7          	jalr	1920(ra) # 800051dc <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a64:	cd11                	beqz	a0,80005a80 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	050080e7          	jalr	80(ra) # 80003ab6 <iunlockput>
  end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	828080e7          	jalr	-2008(ra) # 80004296 <end_op>
  return 0;
    80005a76:	4501                	li	a0,0
}
    80005a78:	60ea                	ld	ra,152(sp)
    80005a7a:	644a                	ld	s0,144(sp)
    80005a7c:	610d                	addi	sp,sp,160
    80005a7e:	8082                	ret
    end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	816080e7          	jalr	-2026(ra) # 80004296 <end_op>
    return -1;
    80005a88:	557d                	li	a0,-1
    80005a8a:	b7fd                	j	80005a78 <sys_mknod+0x6c>

0000000080005a8c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a8c:	7135                	addi	sp,sp,-160
    80005a8e:	ed06                	sd	ra,152(sp)
    80005a90:	e922                	sd	s0,144(sp)
    80005a92:	e526                	sd	s1,136(sp)
    80005a94:	e14a                	sd	s2,128(sp)
    80005a96:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a98:	ffffc097          	auipc	ra,0xffffc
    80005a9c:	f4a080e7          	jalr	-182(ra) # 800019e2 <myproc>
    80005aa0:	892a                	mv	s2,a0
  
  begin_op();
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	774080e7          	jalr	1908(ra) # 80004216 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005aaa:	08000613          	li	a2,128
    80005aae:	f6040593          	addi	a1,s0,-160
    80005ab2:	4501                	li	a0,0
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	10e080e7          	jalr	270(ra) # 80002bc2 <argstr>
    80005abc:	04054b63          	bltz	a0,80005b12 <sys_chdir+0x86>
    80005ac0:	f6040513          	addi	a0,s0,-160
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	536080e7          	jalr	1334(ra) # 80003ffa <namei>
    80005acc:	84aa                	mv	s1,a0
    80005ace:	c131                	beqz	a0,80005b12 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	d84080e7          	jalr	-636(ra) # 80003854 <ilock>
  if(ip->type != T_DIR){
    80005ad8:	04449703          	lh	a4,68(s1)
    80005adc:	4785                	li	a5,1
    80005ade:	04f71063          	bne	a4,a5,80005b1e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	e32080e7          	jalr	-462(ra) # 80003916 <iunlock>
  iput(p->cwd);
    80005aec:	15093503          	ld	a0,336(s2)
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	f1e080e7          	jalr	-226(ra) # 80003a0e <iput>
  end_op();
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	79e080e7          	jalr	1950(ra) # 80004296 <end_op>
  p->cwd = ip;
    80005b00:	14993823          	sd	s1,336(s2)
  return 0;
    80005b04:	4501                	li	a0,0
}
    80005b06:	60ea                	ld	ra,152(sp)
    80005b08:	644a                	ld	s0,144(sp)
    80005b0a:	64aa                	ld	s1,136(sp)
    80005b0c:	690a                	ld	s2,128(sp)
    80005b0e:	610d                	addi	sp,sp,160
    80005b10:	8082                	ret
    end_op();
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	784080e7          	jalr	1924(ra) # 80004296 <end_op>
    return -1;
    80005b1a:	557d                	li	a0,-1
    80005b1c:	b7ed                	j	80005b06 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	f96080e7          	jalr	-106(ra) # 80003ab6 <iunlockput>
    end_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	76e080e7          	jalr	1902(ra) # 80004296 <end_op>
    return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	bfd1                	j	80005b06 <sys_chdir+0x7a>

0000000080005b34 <sys_exec>:

uint64
sys_exec(void)
{
    80005b34:	7145                	addi	sp,sp,-464
    80005b36:	e786                	sd	ra,456(sp)
    80005b38:	e3a2                	sd	s0,448(sp)
    80005b3a:	ff26                	sd	s1,440(sp)
    80005b3c:	fb4a                	sd	s2,432(sp)
    80005b3e:	f74e                	sd	s3,424(sp)
    80005b40:	f352                	sd	s4,416(sp)
    80005b42:	ef56                	sd	s5,408(sp)
    80005b44:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b46:	e3840593          	addi	a1,s0,-456
    80005b4a:	4505                	li	a0,1
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	056080e7          	jalr	86(ra) # 80002ba2 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b54:	08000613          	li	a2,128
    80005b58:	f4040593          	addi	a1,s0,-192
    80005b5c:	4501                	li	a0,0
    80005b5e:	ffffd097          	auipc	ra,0xffffd
    80005b62:	064080e7          	jalr	100(ra) # 80002bc2 <argstr>
    80005b66:	87aa                	mv	a5,a0
    return -1;
    80005b68:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b6a:	0c07c263          	bltz	a5,80005c2e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b6e:	10000613          	li	a2,256
    80005b72:	4581                	li	a1,0
    80005b74:	e4040513          	addi	a0,s0,-448
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	15a080e7          	jalr	346(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b80:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b84:	89a6                	mv	s3,s1
    80005b86:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b88:	02000a13          	li	s4,32
    80005b8c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b90:	00391793          	slli	a5,s2,0x3
    80005b94:	e3040593          	addi	a1,s0,-464
    80005b98:	e3843503          	ld	a0,-456(s0)
    80005b9c:	953e                	add	a0,a0,a5
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	f46080e7          	jalr	-186(ra) # 80002ae4 <fetchaddr>
    80005ba6:	02054a63          	bltz	a0,80005bda <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005baa:	e3043783          	ld	a5,-464(s0)
    80005bae:	c3b9                	beqz	a5,80005bf4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bb0:	ffffb097          	auipc	ra,0xffffb
    80005bb4:	f36080e7          	jalr	-202(ra) # 80000ae6 <kalloc>
    80005bb8:	85aa                	mv	a1,a0
    80005bba:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bbe:	cd11                	beqz	a0,80005bda <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bc0:	6605                	lui	a2,0x1
    80005bc2:	e3043503          	ld	a0,-464(s0)
    80005bc6:	ffffd097          	auipc	ra,0xffffd
    80005bca:	f70080e7          	jalr	-144(ra) # 80002b36 <fetchstr>
    80005bce:	00054663          	bltz	a0,80005bda <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005bd2:	0905                	addi	s2,s2,1
    80005bd4:	09a1                	addi	s3,s3,8
    80005bd6:	fb491be3          	bne	s2,s4,80005b8c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	10048913          	addi	s2,s1,256
    80005bde:	6088                	ld	a0,0(s1)
    80005be0:	c531                	beqz	a0,80005c2c <sys_exec+0xf8>
    kfree(argv[i]);
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	e08080e7          	jalr	-504(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bea:	04a1                	addi	s1,s1,8
    80005bec:	ff2499e3          	bne	s1,s2,80005bde <sys_exec+0xaa>
  return -1;
    80005bf0:	557d                	li	a0,-1
    80005bf2:	a835                	j	80005c2e <sys_exec+0xfa>
      argv[i] = 0;
    80005bf4:	0a8e                	slli	s5,s5,0x3
    80005bf6:	fc040793          	addi	a5,s0,-64
    80005bfa:	9abe                	add	s5,s5,a5
    80005bfc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c00:	e4040593          	addi	a1,s0,-448
    80005c04:	f4040513          	addi	a0,s0,-192
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	154080e7          	jalr	340(ra) # 80004d5c <exec>
    80005c10:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c12:	10048993          	addi	s3,s1,256
    80005c16:	6088                	ld	a0,0(s1)
    80005c18:	c901                	beqz	a0,80005c28 <sys_exec+0xf4>
    kfree(argv[i]);
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	dd0080e7          	jalr	-560(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c22:	04a1                	addi	s1,s1,8
    80005c24:	ff3499e3          	bne	s1,s3,80005c16 <sys_exec+0xe2>
  return ret;
    80005c28:	854a                	mv	a0,s2
    80005c2a:	a011                	j	80005c2e <sys_exec+0xfa>
  return -1;
    80005c2c:	557d                	li	a0,-1
}
    80005c2e:	60be                	ld	ra,456(sp)
    80005c30:	641e                	ld	s0,448(sp)
    80005c32:	74fa                	ld	s1,440(sp)
    80005c34:	795a                	ld	s2,432(sp)
    80005c36:	79ba                	ld	s3,424(sp)
    80005c38:	7a1a                	ld	s4,416(sp)
    80005c3a:	6afa                	ld	s5,408(sp)
    80005c3c:	6179                	addi	sp,sp,464
    80005c3e:	8082                	ret

0000000080005c40 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c40:	7139                	addi	sp,sp,-64
    80005c42:	fc06                	sd	ra,56(sp)
    80005c44:	f822                	sd	s0,48(sp)
    80005c46:	f426                	sd	s1,40(sp)
    80005c48:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c4a:	ffffc097          	auipc	ra,0xffffc
    80005c4e:	d98080e7          	jalr	-616(ra) # 800019e2 <myproc>
    80005c52:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c54:	fd840593          	addi	a1,s0,-40
    80005c58:	4501                	li	a0,0
    80005c5a:	ffffd097          	auipc	ra,0xffffd
    80005c5e:	f48080e7          	jalr	-184(ra) # 80002ba2 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c62:	fc840593          	addi	a1,s0,-56
    80005c66:	fd040513          	addi	a0,s0,-48
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	da8080e7          	jalr	-600(ra) # 80004a12 <pipealloc>
    return -1;
    80005c72:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c74:	0c054463          	bltz	a0,80005d3c <sys_pipe+0xfc>
  fd0 = -1;
    80005c78:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c7c:	fd043503          	ld	a0,-48(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	51a080e7          	jalr	1306(ra) # 8000519a <fdalloc>
    80005c88:	fca42223          	sw	a0,-60(s0)
    80005c8c:	08054b63          	bltz	a0,80005d22 <sys_pipe+0xe2>
    80005c90:	fc843503          	ld	a0,-56(s0)
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	506080e7          	jalr	1286(ra) # 8000519a <fdalloc>
    80005c9c:	fca42023          	sw	a0,-64(s0)
    80005ca0:	06054863          	bltz	a0,80005d10 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca4:	4691                	li	a3,4
    80005ca6:	fc440613          	addi	a2,s0,-60
    80005caa:	fd843583          	ld	a1,-40(s0)
    80005cae:	68a8                	ld	a0,80(s1)
    80005cb0:	ffffc097          	auipc	ra,0xffffc
    80005cb4:	9ee080e7          	jalr	-1554(ra) # 8000169e <copyout>
    80005cb8:	02054063          	bltz	a0,80005cd8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cbc:	4691                	li	a3,4
    80005cbe:	fc040613          	addi	a2,s0,-64
    80005cc2:	fd843583          	ld	a1,-40(s0)
    80005cc6:	0591                	addi	a1,a1,4
    80005cc8:	68a8                	ld	a0,80(s1)
    80005cca:	ffffc097          	auipc	ra,0xffffc
    80005cce:	9d4080e7          	jalr	-1580(ra) # 8000169e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cd2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd4:	06055463          	bgez	a0,80005d3c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005cd8:	fc442783          	lw	a5,-60(s0)
    80005cdc:	07e9                	addi	a5,a5,26
    80005cde:	078e                	slli	a5,a5,0x3
    80005ce0:	97a6                	add	a5,a5,s1
    80005ce2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ce6:	fc042503          	lw	a0,-64(s0)
    80005cea:	0569                	addi	a0,a0,26
    80005cec:	050e                	slli	a0,a0,0x3
    80005cee:	94aa                	add	s1,s1,a0
    80005cf0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cf4:	fd043503          	ld	a0,-48(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	9ea080e7          	jalr	-1558(ra) # 800046e2 <fileclose>
    fileclose(wf);
    80005d00:	fc843503          	ld	a0,-56(s0)
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	9de080e7          	jalr	-1570(ra) # 800046e2 <fileclose>
    return -1;
    80005d0c:	57fd                	li	a5,-1
    80005d0e:	a03d                	j	80005d3c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d10:	fc442783          	lw	a5,-60(s0)
    80005d14:	0007c763          	bltz	a5,80005d22 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d18:	07e9                	addi	a5,a5,26
    80005d1a:	078e                	slli	a5,a5,0x3
    80005d1c:	94be                	add	s1,s1,a5
    80005d1e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d22:	fd043503          	ld	a0,-48(s0)
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	9bc080e7          	jalr	-1604(ra) # 800046e2 <fileclose>
    fileclose(wf);
    80005d2e:	fc843503          	ld	a0,-56(s0)
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	9b0080e7          	jalr	-1616(ra) # 800046e2 <fileclose>
    return -1;
    80005d3a:	57fd                	li	a5,-1
}
    80005d3c:	853e                	mv	a0,a5
    80005d3e:	70e2                	ld	ra,56(sp)
    80005d40:	7442                	ld	s0,48(sp)
    80005d42:	74a2                	ld	s1,40(sp)
    80005d44:	6121                	addi	sp,sp,64
    80005d46:	8082                	ret
	...

0000000080005d50 <kernelvec>:
    80005d50:	7111                	addi	sp,sp,-256
    80005d52:	e006                	sd	ra,0(sp)
    80005d54:	e40a                	sd	sp,8(sp)
    80005d56:	e80e                	sd	gp,16(sp)
    80005d58:	ec12                	sd	tp,24(sp)
    80005d5a:	f016                	sd	t0,32(sp)
    80005d5c:	f41a                	sd	t1,40(sp)
    80005d5e:	f81e                	sd	t2,48(sp)
    80005d60:	fc22                	sd	s0,56(sp)
    80005d62:	e0a6                	sd	s1,64(sp)
    80005d64:	e4aa                	sd	a0,72(sp)
    80005d66:	e8ae                	sd	a1,80(sp)
    80005d68:	ecb2                	sd	a2,88(sp)
    80005d6a:	f0b6                	sd	a3,96(sp)
    80005d6c:	f4ba                	sd	a4,104(sp)
    80005d6e:	f8be                	sd	a5,112(sp)
    80005d70:	fcc2                	sd	a6,120(sp)
    80005d72:	e146                	sd	a7,128(sp)
    80005d74:	e54a                	sd	s2,136(sp)
    80005d76:	e94e                	sd	s3,144(sp)
    80005d78:	ed52                	sd	s4,152(sp)
    80005d7a:	f156                	sd	s5,160(sp)
    80005d7c:	f55a                	sd	s6,168(sp)
    80005d7e:	f95e                	sd	s7,176(sp)
    80005d80:	fd62                	sd	s8,184(sp)
    80005d82:	e1e6                	sd	s9,192(sp)
    80005d84:	e5ea                	sd	s10,200(sp)
    80005d86:	e9ee                	sd	s11,208(sp)
    80005d88:	edf2                	sd	t3,216(sp)
    80005d8a:	f1f6                	sd	t4,224(sp)
    80005d8c:	f5fa                	sd	t5,232(sp)
    80005d8e:	f9fe                	sd	t6,240(sp)
    80005d90:	c21fc0ef          	jal	ra,800029b0 <kerneltrap>
    80005d94:	6082                	ld	ra,0(sp)
    80005d96:	6122                	ld	sp,8(sp)
    80005d98:	61c2                	ld	gp,16(sp)
    80005d9a:	7282                	ld	t0,32(sp)
    80005d9c:	7322                	ld	t1,40(sp)
    80005d9e:	73c2                	ld	t2,48(sp)
    80005da0:	7462                	ld	s0,56(sp)
    80005da2:	6486                	ld	s1,64(sp)
    80005da4:	6526                	ld	a0,72(sp)
    80005da6:	65c6                	ld	a1,80(sp)
    80005da8:	6666                	ld	a2,88(sp)
    80005daa:	7686                	ld	a3,96(sp)
    80005dac:	7726                	ld	a4,104(sp)
    80005dae:	77c6                	ld	a5,112(sp)
    80005db0:	7866                	ld	a6,120(sp)
    80005db2:	688a                	ld	a7,128(sp)
    80005db4:	692a                	ld	s2,136(sp)
    80005db6:	69ca                	ld	s3,144(sp)
    80005db8:	6a6a                	ld	s4,152(sp)
    80005dba:	7a8a                	ld	s5,160(sp)
    80005dbc:	7b2a                	ld	s6,168(sp)
    80005dbe:	7bca                	ld	s7,176(sp)
    80005dc0:	7c6a                	ld	s8,184(sp)
    80005dc2:	6c8e                	ld	s9,192(sp)
    80005dc4:	6d2e                	ld	s10,200(sp)
    80005dc6:	6dce                	ld	s11,208(sp)
    80005dc8:	6e6e                	ld	t3,216(sp)
    80005dca:	7e8e                	ld	t4,224(sp)
    80005dcc:	7f2e                	ld	t5,232(sp)
    80005dce:	7fce                	ld	t6,240(sp)
    80005dd0:	6111                	addi	sp,sp,256
    80005dd2:	10200073          	sret
    80005dd6:	00000013          	nop
    80005dda:	00000013          	nop
    80005dde:	0001                	nop

0000000080005de0 <timervec>:
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	e10c                	sd	a1,0(a0)
    80005de6:	e510                	sd	a2,8(a0)
    80005de8:	e914                	sd	a3,16(a0)
    80005dea:	6d0c                	ld	a1,24(a0)
    80005dec:	7110                	ld	a2,32(a0)
    80005dee:	6194                	ld	a3,0(a1)
    80005df0:	96b2                	add	a3,a3,a2
    80005df2:	e194                	sd	a3,0(a1)
    80005df4:	4589                	li	a1,2
    80005df6:	14459073          	csrw	sip,a1
    80005dfa:	6914                	ld	a3,16(a0)
    80005dfc:	6510                	ld	a2,8(a0)
    80005dfe:	610c                	ld	a1,0(a0)
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	30200073          	mret
	...

0000000080005e0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e0a:	1141                	addi	sp,sp,-16
    80005e0c:	e422                	sd	s0,8(sp)
    80005e0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e10:	0c0007b7          	lui	a5,0xc000
    80005e14:	4705                	li	a4,1
    80005e16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e18:	c3d8                	sw	a4,4(a5)
}
    80005e1a:	6422                	ld	s0,8(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret

0000000080005e20 <plicinithart>:

void
plicinithart(void)
{
    80005e20:	1141                	addi	sp,sp,-16
    80005e22:	e406                	sd	ra,8(sp)
    80005e24:	e022                	sd	s0,0(sp)
    80005e26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b8e080e7          	jalr	-1138(ra) # 800019b6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e30:	0085171b          	slliw	a4,a0,0x8
    80005e34:	0c0027b7          	lui	a5,0xc002
    80005e38:	97ba                	add	a5,a5,a4
    80005e3a:	40200713          	li	a4,1026
    80005e3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e42:	00d5151b          	slliw	a0,a0,0xd
    80005e46:	0c2017b7          	lui	a5,0xc201
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	00052023          	sw	zero,0(a0)
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret

0000000080005e58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e58:	1141                	addi	sp,sp,-16
    80005e5a:	e406                	sd	ra,8(sp)
    80005e5c:	e022                	sd	s0,0(sp)
    80005e5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	b56080e7          	jalr	-1194(ra) # 800019b6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e68:	00d5179b          	slliw	a5,a0,0xd
    80005e6c:	0c201537          	lui	a0,0xc201
    80005e70:	953e                	add	a0,a0,a5
  return irq;
}
    80005e72:	4148                	lw	a0,4(a0)
    80005e74:	60a2                	ld	ra,8(sp)
    80005e76:	6402                	ld	s0,0(sp)
    80005e78:	0141                	addi	sp,sp,16
    80005e7a:	8082                	ret

0000000080005e7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e7c:	1101                	addi	sp,sp,-32
    80005e7e:	ec06                	sd	ra,24(sp)
    80005e80:	e822                	sd	s0,16(sp)
    80005e82:	e426                	sd	s1,8(sp)
    80005e84:	1000                	addi	s0,sp,32
    80005e86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	b2e080e7          	jalr	-1234(ra) # 800019b6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e90:	00d5151b          	slliw	a0,a0,0xd
    80005e94:	0c2017b7          	lui	a5,0xc201
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	c3c4                	sw	s1,4(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret

0000000080005ea6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ea6:	1141                	addi	sp,sp,-16
    80005ea8:	e406                	sd	ra,8(sp)
    80005eaa:	e022                	sd	s0,0(sp)
    80005eac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eae:	479d                	li	a5,7
    80005eb0:	04a7cc63          	blt	a5,a0,80005f08 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005eb4:	0001d797          	auipc	a5,0x1d
    80005eb8:	8ec78793          	addi	a5,a5,-1812 # 800227a0 <disk>
    80005ebc:	97aa                	add	a5,a5,a0
    80005ebe:	0187c783          	lbu	a5,24(a5)
    80005ec2:	ebb9                	bnez	a5,80005f18 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ec4:	00451613          	slli	a2,a0,0x4
    80005ec8:	0001d797          	auipc	a5,0x1d
    80005ecc:	8d878793          	addi	a5,a5,-1832 # 800227a0 <disk>
    80005ed0:	6394                	ld	a3,0(a5)
    80005ed2:	96b2                	add	a3,a3,a2
    80005ed4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ed8:	6398                	ld	a4,0(a5)
    80005eda:	9732                	add	a4,a4,a2
    80005edc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005ee0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005ee4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ee8:	953e                	add	a0,a0,a5
    80005eea:	4785                	li	a5,1
    80005eec:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005ef0:	0001d517          	auipc	a0,0x1d
    80005ef4:	8c850513          	addi	a0,a0,-1848 # 800227b8 <disk+0x18>
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	282080e7          	jalr	642(ra) # 8000217a <wakeup>
}
    80005f00:	60a2                	ld	ra,8(sp)
    80005f02:	6402                	ld	s0,0(sp)
    80005f04:	0141                	addi	sp,sp,16
    80005f06:	8082                	ret
    panic("free_desc 1");
    80005f08:	00003517          	auipc	a0,0x3
    80005f0c:	86850513          	addi	a0,a0,-1944 # 80008770 <syscalls+0x300>
    80005f10:	ffffa097          	auipc	ra,0xffffa
    80005f14:	62e080e7          	jalr	1582(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	86850513          	addi	a0,a0,-1944 # 80008780 <syscalls+0x310>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	61e080e7          	jalr	1566(ra) # 8000053e <panic>

0000000080005f28 <virtio_disk_init>:
{
    80005f28:	1101                	addi	sp,sp,-32
    80005f2a:	ec06                	sd	ra,24(sp)
    80005f2c:	e822                	sd	s0,16(sp)
    80005f2e:	e426                	sd	s1,8(sp)
    80005f30:	e04a                	sd	s2,0(sp)
    80005f32:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f34:	00003597          	auipc	a1,0x3
    80005f38:	85c58593          	addi	a1,a1,-1956 # 80008790 <syscalls+0x320>
    80005f3c:	0001d517          	auipc	a0,0x1d
    80005f40:	98c50513          	addi	a0,a0,-1652 # 800228c8 <disk+0x128>
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	c02080e7          	jalr	-1022(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f4c:	100017b7          	lui	a5,0x10001
    80005f50:	4398                	lw	a4,0(a5)
    80005f52:	2701                	sext.w	a4,a4
    80005f54:	747277b7          	lui	a5,0x74727
    80005f58:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f5c:	14f71c63          	bne	a4,a5,800060b4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f60:	100017b7          	lui	a5,0x10001
    80005f64:	43dc                	lw	a5,4(a5)
    80005f66:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f68:	4709                	li	a4,2
    80005f6a:	14e79563          	bne	a5,a4,800060b4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f6e:	100017b7          	lui	a5,0x10001
    80005f72:	479c                	lw	a5,8(a5)
    80005f74:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f76:	12e79f63          	bne	a5,a4,800060b4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f7a:	100017b7          	lui	a5,0x10001
    80005f7e:	47d8                	lw	a4,12(a5)
    80005f80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f82:	554d47b7          	lui	a5,0x554d4
    80005f86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f8a:	12f71563          	bne	a4,a5,800060b4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f8e:	100017b7          	lui	a5,0x10001
    80005f92:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f96:	4705                	li	a4,1
    80005f98:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f9a:	470d                	li	a4,3
    80005f9c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f9e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fa0:	c7ffe737          	lui	a4,0xc7ffe
    80005fa4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd68c7>
    80005fa8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fae:	472d                	li	a4,11
    80005fb0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005fb2:	5bbc                	lw	a5,112(a5)
    80005fb4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005fb8:	8ba1                	andi	a5,a5,8
    80005fba:	10078563          	beqz	a5,800060c4 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005fc6:	43fc                	lw	a5,68(a5)
    80005fc8:	2781                	sext.w	a5,a5
    80005fca:	10079563          	bnez	a5,800060d4 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	5bdc                	lw	a5,52(a5)
    80005fd4:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fd6:	10078763          	beqz	a5,800060e4 <virtio_disk_init+0x1bc>
  if(max < NUM)
    80005fda:	471d                	li	a4,7
    80005fdc:	10f77c63          	bgeu	a4,a5,800060f4 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80005fe0:	ffffb097          	auipc	ra,0xffffb
    80005fe4:	b06080e7          	jalr	-1274(ra) # 80000ae6 <kalloc>
    80005fe8:	0001c497          	auipc	s1,0x1c
    80005fec:	7b848493          	addi	s1,s1,1976 # 800227a0 <disk>
    80005ff0:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ff2:	ffffb097          	auipc	ra,0xffffb
    80005ff6:	af4080e7          	jalr	-1292(ra) # 80000ae6 <kalloc>
    80005ffa:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005ffc:	ffffb097          	auipc	ra,0xffffb
    80006000:	aea080e7          	jalr	-1302(ra) # 80000ae6 <kalloc>
    80006004:	87aa                	mv	a5,a0
    80006006:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006008:	6088                	ld	a0,0(s1)
    8000600a:	cd6d                	beqz	a0,80006104 <virtio_disk_init+0x1dc>
    8000600c:	0001c717          	auipc	a4,0x1c
    80006010:	79c73703          	ld	a4,1948(a4) # 800227a8 <disk+0x8>
    80006014:	cb65                	beqz	a4,80006104 <virtio_disk_init+0x1dc>
    80006016:	c7fd                	beqz	a5,80006104 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006018:	6605                	lui	a2,0x1
    8000601a:	4581                	li	a1,0
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	cb6080e7          	jalr	-842(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006024:	0001c497          	auipc	s1,0x1c
    80006028:	77c48493          	addi	s1,s1,1916 # 800227a0 <disk>
    8000602c:	6605                	lui	a2,0x1
    8000602e:	4581                	li	a1,0
    80006030:	6488                	ld	a0,8(s1)
    80006032:	ffffb097          	auipc	ra,0xffffb
    80006036:	ca0080e7          	jalr	-864(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000603a:	6605                	lui	a2,0x1
    8000603c:	4581                	li	a1,0
    8000603e:	6888                	ld	a0,16(s1)
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	c92080e7          	jalr	-878(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	4721                	li	a4,8
    8000604e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006050:	4098                	lw	a4,0(s1)
    80006052:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006056:	40d8                	lw	a4,4(s1)
    80006058:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000605c:	6498                	ld	a4,8(s1)
    8000605e:	0007069b          	sext.w	a3,a4
    80006062:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006066:	9701                	srai	a4,a4,0x20
    80006068:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000606c:	6898                	ld	a4,16(s1)
    8000606e:	0007069b          	sext.w	a3,a4
    80006072:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006076:	9701                	srai	a4,a4,0x20
    80006078:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000607c:	4705                	li	a4,1
    8000607e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006080:	00e48c23          	sb	a4,24(s1)
    80006084:	00e48ca3          	sb	a4,25(s1)
    80006088:	00e48d23          	sb	a4,26(s1)
    8000608c:	00e48da3          	sb	a4,27(s1)
    80006090:	00e48e23          	sb	a4,28(s1)
    80006094:	00e48ea3          	sb	a4,29(s1)
    80006098:	00e48f23          	sb	a4,30(s1)
    8000609c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060a0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a4:	0727a823          	sw	s2,112(a5)
}
    800060a8:	60e2                	ld	ra,24(sp)
    800060aa:	6442                	ld	s0,16(sp)
    800060ac:	64a2                	ld	s1,8(sp)
    800060ae:	6902                	ld	s2,0(sp)
    800060b0:	6105                	addi	sp,sp,32
    800060b2:	8082                	ret
    panic("could not find virtio disk");
    800060b4:	00002517          	auipc	a0,0x2
    800060b8:	6ec50513          	addi	a0,a0,1772 # 800087a0 <syscalls+0x330>
    800060bc:	ffffa097          	auipc	ra,0xffffa
    800060c0:	482080e7          	jalr	1154(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    800060c4:	00002517          	auipc	a0,0x2
    800060c8:	6fc50513          	addi	a0,a0,1788 # 800087c0 <syscalls+0x350>
    800060cc:	ffffa097          	auipc	ra,0xffffa
    800060d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    800060d4:	00002517          	auipc	a0,0x2
    800060d8:	70c50513          	addi	a0,a0,1804 # 800087e0 <syscalls+0x370>
    800060dc:	ffffa097          	auipc	ra,0xffffa
    800060e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800060e4:	00002517          	auipc	a0,0x2
    800060e8:	71c50513          	addi	a0,a0,1820 # 80008800 <syscalls+0x390>
    800060ec:	ffffa097          	auipc	ra,0xffffa
    800060f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800060f4:	00002517          	auipc	a0,0x2
    800060f8:	72c50513          	addi	a0,a0,1836 # 80008820 <syscalls+0x3b0>
    800060fc:	ffffa097          	auipc	ra,0xffffa
    80006100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006104:	00002517          	auipc	a0,0x2
    80006108:	73c50513          	addi	a0,a0,1852 # 80008840 <syscalls+0x3d0>
    8000610c:	ffffa097          	auipc	ra,0xffffa
    80006110:	432080e7          	jalr	1074(ra) # 8000053e <panic>

0000000080006114 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006114:	7119                	addi	sp,sp,-128
    80006116:	fc86                	sd	ra,120(sp)
    80006118:	f8a2                	sd	s0,112(sp)
    8000611a:	f4a6                	sd	s1,104(sp)
    8000611c:	f0ca                	sd	s2,96(sp)
    8000611e:	ecce                	sd	s3,88(sp)
    80006120:	e8d2                	sd	s4,80(sp)
    80006122:	e4d6                	sd	s5,72(sp)
    80006124:	e0da                	sd	s6,64(sp)
    80006126:	fc5e                	sd	s7,56(sp)
    80006128:	f862                	sd	s8,48(sp)
    8000612a:	f466                	sd	s9,40(sp)
    8000612c:	f06a                	sd	s10,32(sp)
    8000612e:	ec6e                	sd	s11,24(sp)
    80006130:	0100                	addi	s0,sp,128
    80006132:	8aaa                	mv	s5,a0
    80006134:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006136:	00c52d03          	lw	s10,12(a0)
    8000613a:	001d1d1b          	slliw	s10,s10,0x1
    8000613e:	1d02                	slli	s10,s10,0x20
    80006140:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006144:	0001c517          	auipc	a0,0x1c
    80006148:	78450513          	addi	a0,a0,1924 # 800228c8 <disk+0x128>
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	a8a080e7          	jalr	-1398(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006154:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006156:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006158:	0001cb97          	auipc	s7,0x1c
    8000615c:	648b8b93          	addi	s7,s7,1608 # 800227a0 <disk>
  for(int i = 0; i < 3; i++){
    80006160:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006162:	0001cc97          	auipc	s9,0x1c
    80006166:	766c8c93          	addi	s9,s9,1894 # 800228c8 <disk+0x128>
    8000616a:	a08d                	j	800061cc <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000616c:	00fb8733          	add	a4,s7,a5
    80006170:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006174:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006176:	0207c563          	bltz	a5,800061a0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000617a:	2905                	addiw	s2,s2,1
    8000617c:	0611                	addi	a2,a2,4
    8000617e:	05690c63          	beq	s2,s6,800061d6 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006182:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006184:	0001c717          	auipc	a4,0x1c
    80006188:	61c70713          	addi	a4,a4,1564 # 800227a0 <disk>
    8000618c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000618e:	01874683          	lbu	a3,24(a4)
    80006192:	fee9                	bnez	a3,8000616c <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006194:	2785                	addiw	a5,a5,1
    80006196:	0705                	addi	a4,a4,1
    80006198:	fe979be3          	bne	a5,s1,8000618e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000619c:	57fd                	li	a5,-1
    8000619e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061a0:	01205d63          	blez	s2,800061ba <virtio_disk_rw+0xa6>
    800061a4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061a6:	000a2503          	lw	a0,0(s4)
    800061aa:	00000097          	auipc	ra,0x0
    800061ae:	cfc080e7          	jalr	-772(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    800061b2:	2d85                	addiw	s11,s11,1
    800061b4:	0a11                	addi	s4,s4,4
    800061b6:	ffb918e3          	bne	s2,s11,800061a6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061ba:	85e6                	mv	a1,s9
    800061bc:	0001c517          	auipc	a0,0x1c
    800061c0:	5fc50513          	addi	a0,a0,1532 # 800227b8 <disk+0x18>
    800061c4:	ffffc097          	auipc	ra,0xffffc
    800061c8:	f52080e7          	jalr	-174(ra) # 80002116 <sleep>
  for(int i = 0; i < 3; i++){
    800061cc:	f8040a13          	addi	s4,s0,-128
{
    800061d0:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061d2:	894e                	mv	s2,s3
    800061d4:	b77d                	j	80006182 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061d6:	f8042583          	lw	a1,-128(s0)
    800061da:	00a58793          	addi	a5,a1,10
    800061de:	0792                	slli	a5,a5,0x4

  if(write)
    800061e0:	0001c617          	auipc	a2,0x1c
    800061e4:	5c060613          	addi	a2,a2,1472 # 800227a0 <disk>
    800061e8:	00f60733          	add	a4,a2,a5
    800061ec:	018036b3          	snez	a3,s8
    800061f0:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061f2:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    800061f6:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061fa:	f6078693          	addi	a3,a5,-160
    800061fe:	6218                	ld	a4,0(a2)
    80006200:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006202:	00878513          	addi	a0,a5,8
    80006206:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006208:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000620a:	6208                	ld	a0,0(a2)
    8000620c:	96aa                	add	a3,a3,a0
    8000620e:	4741                	li	a4,16
    80006210:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006212:	4705                	li	a4,1
    80006214:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006218:	f8442703          	lw	a4,-124(s0)
    8000621c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006220:	0712                	slli	a4,a4,0x4
    80006222:	953a                	add	a0,a0,a4
    80006224:	058a8693          	addi	a3,s5,88
    80006228:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000622a:	6208                	ld	a0,0(a2)
    8000622c:	972a                	add	a4,a4,a0
    8000622e:	40000693          	li	a3,1024
    80006232:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006234:	001c3c13          	seqz	s8,s8
    80006238:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000623a:	001c6c13          	ori	s8,s8,1
    8000623e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006242:	f8842603          	lw	a2,-120(s0)
    80006246:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000624a:	0001c697          	auipc	a3,0x1c
    8000624e:	55668693          	addi	a3,a3,1366 # 800227a0 <disk>
    80006252:	00258713          	addi	a4,a1,2
    80006256:	0712                	slli	a4,a4,0x4
    80006258:	9736                	add	a4,a4,a3
    8000625a:	587d                	li	a6,-1
    8000625c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006260:	0612                	slli	a2,a2,0x4
    80006262:	9532                	add	a0,a0,a2
    80006264:	f9078793          	addi	a5,a5,-112
    80006268:	97b6                	add	a5,a5,a3
    8000626a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000626c:	629c                	ld	a5,0(a3)
    8000626e:	97b2                	add	a5,a5,a2
    80006270:	4605                	li	a2,1
    80006272:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006274:	4509                	li	a0,2
    80006276:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000627a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000627e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006282:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006286:	6698                	ld	a4,8(a3)
    80006288:	00275783          	lhu	a5,2(a4)
    8000628c:	8b9d                	andi	a5,a5,7
    8000628e:	0786                	slli	a5,a5,0x1
    80006290:	97ba                	add	a5,a5,a4
    80006292:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006296:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000629a:	6698                	ld	a4,8(a3)
    8000629c:	00275783          	lhu	a5,2(a4)
    800062a0:	2785                	addiw	a5,a5,1
    800062a2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062a6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062aa:	100017b7          	lui	a5,0x10001
    800062ae:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062b2:	004aa783          	lw	a5,4(s5)
    800062b6:	02c79163          	bne	a5,a2,800062d8 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062ba:	0001c917          	auipc	s2,0x1c
    800062be:	60e90913          	addi	s2,s2,1550 # 800228c8 <disk+0x128>
  while(b->disk == 1) {
    800062c2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062c4:	85ca                	mv	a1,s2
    800062c6:	8556                	mv	a0,s5
    800062c8:	ffffc097          	auipc	ra,0xffffc
    800062cc:	e4e080e7          	jalr	-434(ra) # 80002116 <sleep>
  while(b->disk == 1) {
    800062d0:	004aa783          	lw	a5,4(s5)
    800062d4:	fe9788e3          	beq	a5,s1,800062c4 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800062d8:	f8042903          	lw	s2,-128(s0)
    800062dc:	00290793          	addi	a5,s2,2
    800062e0:	00479713          	slli	a4,a5,0x4
    800062e4:	0001c797          	auipc	a5,0x1c
    800062e8:	4bc78793          	addi	a5,a5,1212 # 800227a0 <disk>
    800062ec:	97ba                	add	a5,a5,a4
    800062ee:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800062f2:	0001c997          	auipc	s3,0x1c
    800062f6:	4ae98993          	addi	s3,s3,1198 # 800227a0 <disk>
    800062fa:	00491713          	slli	a4,s2,0x4
    800062fe:	0009b783          	ld	a5,0(s3)
    80006302:	97ba                	add	a5,a5,a4
    80006304:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006308:	854a                	mv	a0,s2
    8000630a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000630e:	00000097          	auipc	ra,0x0
    80006312:	b98080e7          	jalr	-1128(ra) # 80005ea6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006316:	8885                	andi	s1,s1,1
    80006318:	f0ed                	bnez	s1,800062fa <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000631a:	0001c517          	auipc	a0,0x1c
    8000631e:	5ae50513          	addi	a0,a0,1454 # 800228c8 <disk+0x128>
    80006322:	ffffb097          	auipc	ra,0xffffb
    80006326:	968080e7          	jalr	-1688(ra) # 80000c8a <release>
}
    8000632a:	70e6                	ld	ra,120(sp)
    8000632c:	7446                	ld	s0,112(sp)
    8000632e:	74a6                	ld	s1,104(sp)
    80006330:	7906                	ld	s2,96(sp)
    80006332:	69e6                	ld	s3,88(sp)
    80006334:	6a46                	ld	s4,80(sp)
    80006336:	6aa6                	ld	s5,72(sp)
    80006338:	6b06                	ld	s6,64(sp)
    8000633a:	7be2                	ld	s7,56(sp)
    8000633c:	7c42                	ld	s8,48(sp)
    8000633e:	7ca2                	ld	s9,40(sp)
    80006340:	7d02                	ld	s10,32(sp)
    80006342:	6de2                	ld	s11,24(sp)
    80006344:	6109                	addi	sp,sp,128
    80006346:	8082                	ret

0000000080006348 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006348:	1101                	addi	sp,sp,-32
    8000634a:	ec06                	sd	ra,24(sp)
    8000634c:	e822                	sd	s0,16(sp)
    8000634e:	e426                	sd	s1,8(sp)
    80006350:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006352:	0001c497          	auipc	s1,0x1c
    80006356:	44e48493          	addi	s1,s1,1102 # 800227a0 <disk>
    8000635a:	0001c517          	auipc	a0,0x1c
    8000635e:	56e50513          	addi	a0,a0,1390 # 800228c8 <disk+0x128>
    80006362:	ffffb097          	auipc	ra,0xffffb
    80006366:	874080e7          	jalr	-1932(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000636a:	10001737          	lui	a4,0x10001
    8000636e:	533c                	lw	a5,96(a4)
    80006370:	8b8d                	andi	a5,a5,3
    80006372:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006374:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006378:	689c                	ld	a5,16(s1)
    8000637a:	0204d703          	lhu	a4,32(s1)
    8000637e:	0027d783          	lhu	a5,2(a5)
    80006382:	04f70863          	beq	a4,a5,800063d2 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006386:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000638a:	6898                	ld	a4,16(s1)
    8000638c:	0204d783          	lhu	a5,32(s1)
    80006390:	8b9d                	andi	a5,a5,7
    80006392:	078e                	slli	a5,a5,0x3
    80006394:	97ba                	add	a5,a5,a4
    80006396:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006398:	00278713          	addi	a4,a5,2
    8000639c:	0712                	slli	a4,a4,0x4
    8000639e:	9726                	add	a4,a4,s1
    800063a0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063a4:	e721                	bnez	a4,800063ec <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063a6:	0789                	addi	a5,a5,2
    800063a8:	0792                	slli	a5,a5,0x4
    800063aa:	97a6                	add	a5,a5,s1
    800063ac:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063ae:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063b2:	ffffc097          	auipc	ra,0xffffc
    800063b6:	dc8080e7          	jalr	-568(ra) # 8000217a <wakeup>

    disk.used_idx += 1;
    800063ba:	0204d783          	lhu	a5,32(s1)
    800063be:	2785                	addiw	a5,a5,1
    800063c0:	17c2                	slli	a5,a5,0x30
    800063c2:	93c1                	srli	a5,a5,0x30
    800063c4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063c8:	6898                	ld	a4,16(s1)
    800063ca:	00275703          	lhu	a4,2(a4)
    800063ce:	faf71ce3          	bne	a4,a5,80006386 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063d2:	0001c517          	auipc	a0,0x1c
    800063d6:	4f650513          	addi	a0,a0,1270 # 800228c8 <disk+0x128>
    800063da:	ffffb097          	auipc	ra,0xffffb
    800063de:	8b0080e7          	jalr	-1872(ra) # 80000c8a <release>
}
    800063e2:	60e2                	ld	ra,24(sp)
    800063e4:	6442                	ld	s0,16(sp)
    800063e6:	64a2                	ld	s1,8(sp)
    800063e8:	6105                	addi	sp,sp,32
    800063ea:	8082                	ret
      panic("virtio_disk_intr status");
    800063ec:	00002517          	auipc	a0,0x2
    800063f0:	46c50513          	addi	a0,a0,1132 # 80008858 <syscalls+0x3e8>
    800063f4:	ffffa097          	auipc	ra,0xffffa
    800063f8:	14a080e7          	jalr	330(ra) # 8000053e <panic>

00000000800063fc <free_desc>:
    panic("virtio_gpu: no free descriptors");
}

static void
free_desc(int i)
{
    800063fc:	1141                	addi	sp,sp,-16
    800063fe:	e422                	sd	s0,8(sp)
    80006400:	0800                	addi	s0,sp,16
    gq.desc[i].addr = 0;
    80006402:	0001c717          	auipc	a4,0x1c
    80006406:	4de70713          	addi	a4,a4,1246 # 800228e0 <gq>
    8000640a:	00451693          	slli	a3,a0,0x4
    8000640e:	631c                	ld	a5,0(a4)
    80006410:	97b6                	add	a5,a5,a3
    80006412:	0007b023          	sd	zero,0(a5)
    gq.desc[i].len = 0;
    80006416:	0007a423          	sw	zero,8(a5)
    gq.desc[i].flags = 0;
    8000641a:	00079623          	sh	zero,12(a5)
    gq.desc[i].next = 0;
    8000641e:	00079723          	sh	zero,14(a5)
    gq.free[i] = 1;
    80006422:	972a                	add	a4,a4,a0
    80006424:	4785                	li	a5,1
    80006426:	00f70c23          	sb	a5,24(a4)
}
    8000642a:	6422                	ld	s0,8(sp)
    8000642c:	0141                	addi	sp,sp,16
    8000642e:	8082                	ret

0000000080006430 <alloc_desc>:
    for (int i = 0; i < GPU_NUM; i++)
    80006430:	0001c797          	auipc	a5,0x1c
    80006434:	4b078793          	addi	a5,a5,1200 # 800228e0 <gq>
    80006438:	4501                	li	a0,0
    8000643a:	46a1                	li	a3,8
        if (gq.free[i])
    8000643c:	0187c703          	lbu	a4,24(a5)
    80006440:	e30d                	bnez	a4,80006462 <alloc_desc+0x32>
    for (int i = 0; i < GPU_NUM; i++)
    80006442:	2505                	addiw	a0,a0,1
    80006444:	0785                	addi	a5,a5,1
    80006446:	fed51be3          	bne	a0,a3,8000643c <alloc_desc+0xc>
{
    8000644a:	1141                	addi	sp,sp,-16
    8000644c:	e406                	sd	ra,8(sp)
    8000644e:	e022                	sd	s0,0(sp)
    80006450:	0800                	addi	s0,sp,16
    panic("virtio_gpu: no free descriptors");
    80006452:	00002517          	auipc	a0,0x2
    80006456:	41e50513          	addi	a0,a0,1054 # 80008870 <syscalls+0x400>
    8000645a:	ffffa097          	auipc	ra,0xffffa
    8000645e:	0e4080e7          	jalr	228(ra) # 8000053e <panic>
            gq.free[i] = 0;
    80006462:	0001c797          	auipc	a5,0x1c
    80006466:	47e78793          	addi	a5,a5,1150 # 800228e0 <gq>
    8000646a:	97aa                	add	a5,a5,a0
    8000646c:	00078c23          	sb	zero,24(a5)
}
    80006470:	8082                	ret

0000000080006472 <gpu_send>:

// Submit a 2-descriptor command (request + shared response) and block
// until the device completes it by advancing the used ring.
static void
gpu_send(void *req, int req_len)
{
    80006472:	7139                	addi	sp,sp,-64
    80006474:	fc06                	sd	ra,56(sp)
    80006476:	f822                	sd	s0,48(sp)
    80006478:	f426                	sd	s1,40(sp)
    8000647a:	f04a                	sd	s2,32(sp)
    8000647c:	ec4e                	sd	s3,24(sp)
    8000647e:	e852                	sd	s4,16(sp)
    80006480:	e456                	sd	s5,8(sp)
    80006482:	0080                	addi	s0,sp,64
    80006484:	8aaa                	mv	s5,a0
    80006486:	8a2e                	mv	s4,a1
    acquire(&gpu_lock);
    80006488:	0001c997          	auipc	s3,0x1c
    8000648c:	45898993          	addi	s3,s3,1112 # 800228e0 <gq>
    80006490:	0001c517          	auipc	a0,0x1c
    80006494:	47850513          	addi	a0,a0,1144 # 80022908 <gpu_lock>
    80006498:	ffffa097          	auipc	ra,0xffffa
    8000649c:	73e080e7          	jalr	1854(ra) # 80000bd6 <acquire>
    int d0 = alloc_desc();
    800064a0:	00000097          	auipc	ra,0x0
    800064a4:	f90080e7          	jalr	-112(ra) # 80006430 <alloc_desc>
    800064a8:	892a                	mv	s2,a0
    int d1 = alloc_desc();
    800064aa:	00000097          	auipc	ra,0x0
    800064ae:	f86080e7          	jalr	-122(ra) # 80006430 <alloc_desc>
    800064b2:	84aa                	mv	s1,a0

    gq.desc[d0].addr = (uint64)req;
    800064b4:	00491793          	slli	a5,s2,0x4
    800064b8:	0009b703          	ld	a4,0(s3)
    800064bc:	973e                	add	a4,a4,a5
    800064be:	01573023          	sd	s5,0(a4)
    gq.desc[d0].len = (uint32)req_len;
    800064c2:	0009b703          	ld	a4,0(s3)
    800064c6:	97ba                	add	a5,a5,a4
    800064c8:	0147a423          	sw	s4,8(a5)
    gq.desc[d0].flags = VRING_DESC_F_NEXT;
    800064cc:	4685                	li	a3,1
    800064ce:	00d79623          	sh	a3,12(a5)
    gq.desc[d0].next = d1;
    800064d2:	00a79723          	sh	a0,14(a5)

    gq.desc[d1].addr = (uint64)&cmd_resp;
    800064d6:	00451693          	slli	a3,a0,0x4
    800064da:	9736                	add	a4,a4,a3
    800064dc:	0001c797          	auipc	a5,0x1c
    800064e0:	44478793          	addi	a5,a5,1092 # 80022920 <cmd_resp>
    800064e4:	e31c                	sd	a5,0(a4)
    gq.desc[d1].len = sizeof(cmd_resp);
    800064e6:	0009b783          	ld	a5,0(s3)
    800064ea:	97b6                	add	a5,a5,a3
    800064ec:	4761                	li	a4,24
    800064ee:	c798                	sw	a4,8(a5)
    gq.desc[d1].flags = VRING_DESC_F_WRITE;
    800064f0:	4709                	li	a4,2
    800064f2:	00e79623          	sh	a4,12(a5)
    gq.desc[d1].next = 0;
    800064f6:	00079723          	sh	zero,14(a5)

    // Place head descriptor index in the available ring.
    gq.avail->ring[gq.avail->idx % GPU_NUM] = d0;
    800064fa:	0089b703          	ld	a4,8(s3)
    800064fe:	00275783          	lhu	a5,2(a4)
    80006502:	8b9d                	andi	a5,a5,7
    80006504:	0786                	slli	a5,a5,0x1
    80006506:	97ba                	add	a5,a5,a4
    80006508:	01279223          	sh	s2,4(a5)
    __sync_synchronize();
    8000650c:	0ff0000f          	fence
    gq.avail->idx++;
    80006510:	0089b703          	ld	a4,8(s3)
    80006514:	00275783          	lhu	a5,2(a4)
    80006518:	2785                	addiw	a5,a5,1
    8000651a:	00f71123          	sh	a5,2(a4)
    __sync_synchronize();
    8000651e:	0ff0000f          	fence

    // Notify device (queue index 0 = controlq).
    *R1(VIRTIO_MMIO_QUEUE_NOTIFY) = 0;
    80006522:	100027b7          	lui	a5,0x10002
    80006526:	0407a823          	sw	zero,80(a5) # 10002050 <_entry-0x6fffdfb0>

    // Poll until the device advances the used ring.
    while (1)
    {
        __sync_synchronize();
        if (gq.used->idx != gq.used_idx)
    8000652a:	874e                	mv	a4,s3
        __sync_synchronize();
    8000652c:	0ff0000f          	fence
        if (gq.used->idx != gq.used_idx)
    80006530:	02075783          	lhu	a5,32(a4)
    80006534:	6b14                	ld	a3,16(a4)
    80006536:	0026d683          	lhu	a3,2(a3)
    8000653a:	fef689e3          	beq	a3,a5,8000652c <gpu_send+0xba>
            break;
    }
    gq.used_idx++;
    8000653e:	2785                	addiw	a5,a5,1
    80006540:	0001c717          	auipc	a4,0x1c
    80006544:	3cf71023          	sh	a5,960(a4) # 80022900 <gq+0x20>

    free_desc(d0);
    80006548:	854a                	mv	a0,s2
    8000654a:	00000097          	auipc	ra,0x0
    8000654e:	eb2080e7          	jalr	-334(ra) # 800063fc <free_desc>
    free_desc(d1);
    80006552:	8526                	mv	a0,s1
    80006554:	00000097          	auipc	ra,0x0
    80006558:	ea8080e7          	jalr	-344(ra) # 800063fc <free_desc>
    release(&gpu_lock);
    8000655c:	0001c517          	auipc	a0,0x1c
    80006560:	3ac50513          	addi	a0,a0,940 # 80022908 <gpu_lock>
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	726080e7          	jalr	1830(ra) # 80000c8a <release>
}
    8000656c:	70e2                	ld	ra,56(sp)
    8000656e:	7442                	ld	s0,48(sp)
    80006570:	74a2                	ld	s1,40(sp)
    80006572:	7902                	ld	s2,32(sp)
    80006574:	69e2                	ld	s3,24(sp)
    80006576:	6a42                	ld	s4,16(sp)
    80006578:	6aa2                	ld	s5,8(sp)
    8000657a:	6121                	addi	sp,sp,64
    8000657c:	8082                	ret

000000008000657e <gpu_cmd_attach>:
{
    8000657e:	1141                	addi	sp,sp,-16
    80006580:	e406                	sd	ra,8(sp)
    80006582:	e022                	sd	s0,0(sp)
    80006584:	0800                	addi	s0,sp,16
    attach_buf.backing.hdr.type = VIRTIO_GPU_CMD_RESOURCE_ATTACH_BACKING;
    80006586:	00020797          	auipc	a5,0x20
    8000658a:	cd278793          	addi	a5,a5,-814 # 80026258 <attach_buf>
    8000658e:	10600713          	li	a4,262
    80006592:	c398                	sw	a4,0(a5)
    attach_buf.backing.resource_id = RESOURCE_ID;
    80006594:	4705                	li	a4,1
    80006596:	cf98                	sw	a4,24(a5)
    attach_buf.backing.nr_entries = n;
    80006598:	0005861b          	sext.w	a2,a1
    8000659c:	cfd0                	sw	a2,28(a5)
    for (int i = 0; i < n; i++)
    8000659e:	02b05663          	blez	a1,800065ca <gpu_cmd_attach+0x4c>
    800065a2:	87aa                	mv	a5,a0
    800065a4:	00020717          	auipc	a4,0x20
    800065a8:	cd470713          	addi	a4,a4,-812 # 80026278 <attach_buf+0x20>
    800065ac:	fff6069b          	addiw	a3,a2,-1
    800065b0:	1682                	slli	a3,a3,0x20
    800065b2:	9281                	srli	a3,a3,0x20
    800065b4:	0692                	slli	a3,a3,0x4
    800065b6:	0541                	addi	a0,a0,16
    800065b8:	96aa                	add	a3,a3,a0
        attach_buf.entries[i] = entries[i];
    800065ba:	6390                	ld	a2,0(a5)
    800065bc:	e310                	sd	a2,0(a4)
    800065be:	6790                	ld	a2,8(a5)
    800065c0:	e710                	sd	a2,8(a4)
    for (int i = 0; i < n; i++)
    800065c2:	07c1                	addi	a5,a5,16
    800065c4:	0741                	addi	a4,a4,16
    800065c6:	fed79ae3          	bne	a5,a3,800065ba <gpu_cmd_attach+0x3c>
    gpu_send(&attach_buf, sizeof(attach_buf));
    800065ca:	6585                	lui	a1,0x1
    800065cc:	2e058593          	addi	a1,a1,736 # 12e0 <_entry-0x7fffed20>
    800065d0:	00020517          	auipc	a0,0x20
    800065d4:	c8850513          	addi	a0,a0,-888 # 80026258 <attach_buf>
    800065d8:	00000097          	auipc	ra,0x0
    800065dc:	e9a080e7          	jalr	-358(ra) # 80006472 <gpu_send>
}
    800065e0:	60a2                	ld	ra,8(sp)
    800065e2:	6402                	ld	s0,0(sp)
    800065e4:	0141                	addi	sp,sp,16
    800065e6:	8082                	ret

00000000800065e8 <gpu_transfer_flush>:
{
    800065e8:	7139                	addi	sp,sp,-64
    800065ea:	fc06                	sd	ra,56(sp)
    800065ec:	f822                	sd	s0,48(sp)
    800065ee:	f426                	sd	s1,40(sp)
    800065f0:	f04a                	sd	s2,32(sp)
    800065f2:	ec4e                	sd	s3,24(sp)
    800065f4:	e852                	sd	s4,16(sp)
    800065f6:	e456                	sd	s5,8(sp)
    800065f8:	0080                	addi	s0,sp,64
    memset(&xfer, 0, sizeof(xfer));
    800065fa:	0001c497          	auipc	s1,0x1c
    800065fe:	2e648493          	addi	s1,s1,742 # 800228e0 <gq>
    80006602:	0001c917          	auipc	s2,0x1c
    80006606:	33690913          	addi	s2,s2,822 # 80022938 <xfer.4>
    8000660a:	03800613          	li	a2,56
    8000660e:	4581                	li	a1,0
    80006610:	854a                	mv	a0,s2
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	6c0080e7          	jalr	1728(ra) # 80000cd2 <memset>
    xfer.hdr.type = VIRTIO_GPU_CMD_TRANSFER_TO_HOST_2D;
    8000661a:	10500793          	li	a5,261
    8000661e:	ccbc                	sw	a5,88(s1)
    xfer.r.x = 0;
    80006620:	0604a823          	sw	zero,112(s1)
    xfer.r.y = 0;
    80006624:	0604aa23          	sw	zero,116(s1)
    xfer.r.width = SCREEN_W;
    80006628:	28000a93          	li	s5,640
    8000662c:	0754ac23          	sw	s5,120(s1)
    xfer.r.height = SCREEN_H;
    80006630:	1e000a13          	li	s4,480
    80006634:	0744ae23          	sw	s4,124(s1)
    xfer.resource_id = RESOURCE_ID;
    80006638:	4985                	li	s3,1
    8000663a:	0934a423          	sw	s3,136(s1)
    gpu_send(&xfer, sizeof(xfer));
    8000663e:	03800593          	li	a1,56
    80006642:	854a                	mv	a0,s2
    80006644:	00000097          	auipc	ra,0x0
    80006648:	e2e080e7          	jalr	-466(ra) # 80006472 <gpu_send>
    memset(&flush, 0, sizeof(flush));
    8000664c:	0001c917          	auipc	s2,0x1c
    80006650:	32490913          	addi	s2,s2,804 # 80022970 <flush.3>
    80006654:	03000613          	li	a2,48
    80006658:	4581                	li	a1,0
    8000665a:	854a                	mv	a0,s2
    8000665c:	ffffa097          	auipc	ra,0xffffa
    80006660:	676080e7          	jalr	1654(ra) # 80000cd2 <memset>
    flush.hdr.type = VIRTIO_GPU_CMD_RESOURCE_FLUSH;
    80006664:	10400793          	li	a5,260
    80006668:	08f4a823          	sw	a5,144(s1)
    flush.r.x = 0;
    8000666c:	0a04a423          	sw	zero,168(s1)
    flush.r.y = 0;
    80006670:	0a04a623          	sw	zero,172(s1)
    flush.r.width = SCREEN_W;
    80006674:	0b54a823          	sw	s5,176(s1)
    flush.r.height = SCREEN_H;
    80006678:	0b44aa23          	sw	s4,180(s1)
    flush.resource_id = RESOURCE_ID;
    8000667c:	0b34ac23          	sw	s3,184(s1)
    gpu_send(&flush, sizeof(flush));
    80006680:	03000593          	li	a1,48
    80006684:	854a                	mv	a0,s2
    80006686:	00000097          	auipc	ra,0x0
    8000668a:	dec080e7          	jalr	-532(ra) # 80006472 <gpu_send>
}
    8000668e:	70e2                	ld	ra,56(sp)
    80006690:	7442                	ld	s0,48(sp)
    80006692:	74a2                	ld	s1,40(sp)
    80006694:	7902                	ld	s2,32(sp)
    80006696:	69e2                	ld	s3,24(sp)
    80006698:	6a42                	ld	s4,16(sp)
    8000669a:	6aa2                	ld	s5,8(sp)
    8000669c:	6121                	addi	sp,sp,64
    8000669e:	8082                	ret

00000000800066a0 <gpu_cmd_detach>:
{
    800066a0:	1101                	addi	sp,sp,-32
    800066a2:	ec06                	sd	ra,24(sp)
    800066a4:	e822                	sd	s0,16(sp)
    800066a6:	e426                	sd	s1,8(sp)
    800066a8:	e04a                	sd	s2,0(sp)
    800066aa:	1000                	addi	s0,sp,32
    memset(&detach, 0, sizeof(detach));
    800066ac:	0001c917          	auipc	s2,0x1c
    800066b0:	23490913          	addi	s2,s2,564 # 800228e0 <gq>
    800066b4:	0001c497          	auipc	s1,0x1c
    800066b8:	2ec48493          	addi	s1,s1,748 # 800229a0 <detach.1>
    800066bc:	02000613          	li	a2,32
    800066c0:	4581                	li	a1,0
    800066c2:	8526                	mv	a0,s1
    800066c4:	ffffa097          	auipc	ra,0xffffa
    800066c8:	60e080e7          	jalr	1550(ra) # 80000cd2 <memset>
    detach.hdr.type = VIRTIO_GPU_CMD_RESOURCE_DETACH_BACKING;
    800066cc:	10700793          	li	a5,263
    800066d0:	0cf92023          	sw	a5,192(s2)
    detach.resource_id = RESOURCE_ID;
    800066d4:	4785                	li	a5,1
    800066d6:	0cf92c23          	sw	a5,216(s2)
    gpu_send(&detach, sizeof(detach));
    800066da:	02000593          	li	a1,32
    800066de:	8526                	mv	a0,s1
    800066e0:	00000097          	auipc	ra,0x0
    800066e4:	d92080e7          	jalr	-622(ra) # 80006472 <gpu_send>
}
    800066e8:	60e2                	ld	ra,24(sp)
    800066ea:	6442                	ld	s0,16(sp)
    800066ec:	64a2                	ld	s1,8(sp)
    800066ee:	6902                	ld	s2,0(sp)
    800066f0:	6105                	addi	sp,sp,32
    800066f2:	8082                	ret

00000000800066f4 <virtio_gpu_init>:

// ── Public init ───────────────────────────────────────────────────────

void virtio_gpu_init(void)
{
    800066f4:	7159                	addi	sp,sp,-112
    800066f6:	f486                	sd	ra,104(sp)
    800066f8:	f0a2                	sd	s0,96(sp)
    800066fa:	eca6                	sd	s1,88(sp)
    800066fc:	e8ca                	sd	s2,80(sp)
    800066fe:	e4ce                	sd	s3,72(sp)
    80006700:	e0d2                	sd	s4,64(sp)
    80006702:	fc56                	sd	s5,56(sp)
    80006704:	f85a                	sd	s6,48(sp)
    80006706:	f45e                	sd	s7,40(sp)
    80006708:	f062                	sd	s8,32(sp)
    8000670a:	ec66                	sd	s9,24(sp)
    8000670c:	e86a                	sd	s10,16(sp)
    8000670e:	e46e                	sd	s11,8(sp)
    80006710:	1880                	addi	s0,sp,112
    uint32 status = 0;
    initlock(&gpu_lock, "vgpu");
    80006712:	00002597          	auipc	a1,0x2
    80006716:	17e58593          	addi	a1,a1,382 # 80008890 <syscalls+0x420>
    8000671a:	0001c517          	auipc	a0,0x1c
    8000671e:	1ee50513          	addi	a0,a0,494 # 80022908 <gpu_lock>
    80006722:	ffffa097          	auipc	ra,0xffffa
    80006726:	424080e7          	jalr	1060(ra) # 80000b46 <initlock>

    // ── 1. VirtIO device handshake ──────────────────────────────────────
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000672a:	100027b7          	lui	a5,0x10002
    8000672e:	4398                	lw	a4,0(a5)
    80006730:	2701                	sext.w	a4,a4
    80006732:	747277b7          	lui	a5,0x74727
    80006736:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000673a:	02f71a63          	bne	a4,a5,8000676e <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    8000673e:	100027b7          	lui	a5,0x10002
    80006742:	43dc                	lw	a5,4(a5)
    80006744:	2781                	sext.w	a5,a5
    if (*R1(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006746:	4709                	li	a4,2
    80006748:	02e79363          	bne	a5,a4,8000676e <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    8000674c:	100027b7          	lui	a5,0x10002
    80006750:	479c                	lw	a5,8(a5)
    80006752:	2781                	sext.w	a5,a5
        *R1(VIRTIO_MMIO_VERSION) != 2 ||
    80006754:	4741                	li	a4,16
    80006756:	00e79c63          	bne	a5,a4,8000676e <virtio_gpu_init+0x7a>
        *R1(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551)
    8000675a:	100027b7          	lui	a5,0x10002
    8000675e:	47d8                	lw	a4,12(a5)
    80006760:	2701                	sext.w	a4,a4
        *R1(VIRTIO_MMIO_DEVICE_ID) != VIRTIO_ID_GPU ||
    80006762:	554d47b7          	lui	a5,0x554d4
    80006766:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000676a:	02f70963          	beq	a4,a5,8000679c <virtio_gpu_init+0xa8>
    {
        printf("virtio_gpu_init: GPU not found\n");
    8000676e:	00002517          	auipc	a0,0x2
    80006772:	12a50513          	addi	a0,a0,298 # 80008898 <syscalls+0x428>
    80006776:	ffffa097          	auipc	ra,0xffffa
    8000677a:	e12080e7          	jalr	-494(ra) # 80000588 <printf>
    gpu_send(&scanout_req, sizeof(scanout_req));

    // ── 8. TRANSFER_TO_HOST_2D (upload guest memory -> host GPU) ─────────
    gpu_transfer_flush();
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
}
    8000677e:	70a6                	ld	ra,104(sp)
    80006780:	7406                	ld	s0,96(sp)
    80006782:	64e6                	ld	s1,88(sp)
    80006784:	6946                	ld	s2,80(sp)
    80006786:	69a6                	ld	s3,72(sp)
    80006788:	6a06                	ld	s4,64(sp)
    8000678a:	7ae2                	ld	s5,56(sp)
    8000678c:	7b42                	ld	s6,48(sp)
    8000678e:	7ba2                	ld	s7,40(sp)
    80006790:	7c02                	ld	s8,32(sp)
    80006792:	6ce2                	ld	s9,24(sp)
    80006794:	6d42                	ld	s10,16(sp)
    80006796:	6da2                	ld	s11,8(sp)
    80006798:	6165                	addi	sp,sp,112
    8000679a:	8082                	ret
    *R1(VIRTIO_MMIO_STATUS) = status;
    8000679c:	100027b7          	lui	a5,0x10002
    800067a0:	0607a823          	sw	zero,112(a5) # 10002070 <_entry-0x6fffdf90>
    *R1(VIRTIO_MMIO_STATUS) = status;
    800067a4:	4705                	li	a4,1
    800067a6:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    800067a8:	470d                	li	a4,3
    800067aa:	dbb8                	sw	a4,112(a5)
    *R1(VIRTIO_MMIO_DRIVER_FEATURES) = 0;
    800067ac:	0207a023          	sw	zero,32(a5)
    *R1(VIRTIO_MMIO_STATUS) = status;
    800067b0:	472d                	li	a4,11
    800067b2:	dbb8                	sw	a4,112(a5)
    if (!(*R1(VIRTIO_MMIO_STATUS) & VIRTIO_CONFIG_S_FEATURES_OK))
    800067b4:	5bbc                	lw	a5,112(a5)
    800067b6:	8ba1                	andi	a5,a5,8
    800067b8:	1e078963          	beqz	a5,800069aa <virtio_gpu_init+0x2b6>
    *R1(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800067bc:	100027b7          	lui	a5,0x10002
    800067c0:	0207a823          	sw	zero,48(a5) # 10002030 <_entry-0x6fffdfd0>
    if (*R1(VIRTIO_MMIO_QUEUE_READY))
    800067c4:	43fc                	lw	a5,68(a5)
    800067c6:	2781                	sext.w	a5,a5
    800067c8:	1e079963          	bnez	a5,800069ba <virtio_gpu_init+0x2c6>
    if (*R1(VIRTIO_MMIO_QUEUE_NUM_MAX) < GPU_NUM)
    800067cc:	100027b7          	lui	a5,0x10002
    800067d0:	5bdc                	lw	a5,52(a5)
    800067d2:	2781                	sext.w	a5,a5
    800067d4:	471d                	li	a4,7
    800067d6:	1ef77a63          	bgeu	a4,a5,800069ca <virtio_gpu_init+0x2d6>
    gq.desc = kalloc();
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	30c080e7          	jalr	780(ra) # 80000ae6 <kalloc>
    800067e2:	0001c497          	auipc	s1,0x1c
    800067e6:	0fe48493          	addi	s1,s1,254 # 800228e0 <gq>
    800067ea:	e088                	sd	a0,0(s1)
    gq.avail = kalloc();
    800067ec:	ffffa097          	auipc	ra,0xffffa
    800067f0:	2fa080e7          	jalr	762(ra) # 80000ae6 <kalloc>
    800067f4:	e488                	sd	a0,8(s1)
    gq.used = kalloc();
    800067f6:	ffffa097          	auipc	ra,0xffffa
    800067fa:	2f0080e7          	jalr	752(ra) # 80000ae6 <kalloc>
    800067fe:	87aa                	mv	a5,a0
    80006800:	e888                	sd	a0,16(s1)
    if (!gq.desc || !gq.avail || !gq.used)
    80006802:	6088                	ld	a0,0(s1)
    80006804:	1c050b63          	beqz	a0,800069da <virtio_gpu_init+0x2e6>
    80006808:	0001c717          	auipc	a4,0x1c
    8000680c:	0e073703          	ld	a4,224(a4) # 800228e8 <gq+0x8>
    80006810:	1c070563          	beqz	a4,800069da <virtio_gpu_init+0x2e6>
    80006814:	1c078363          	beqz	a5,800069da <virtio_gpu_init+0x2e6>
    memset(gq.desc, 0, PGSIZE);
    80006818:	6605                	lui	a2,0x1
    8000681a:	4581                	li	a1,0
    8000681c:	ffffa097          	auipc	ra,0xffffa
    80006820:	4b6080e7          	jalr	1206(ra) # 80000cd2 <memset>
    memset(gq.avail, 0, PGSIZE);
    80006824:	0001c497          	auipc	s1,0x1c
    80006828:	0bc48493          	addi	s1,s1,188 # 800228e0 <gq>
    8000682c:	6605                	lui	a2,0x1
    8000682e:	4581                	li	a1,0
    80006830:	6488                	ld	a0,8(s1)
    80006832:	ffffa097          	auipc	ra,0xffffa
    80006836:	4a0080e7          	jalr	1184(ra) # 80000cd2 <memset>
    memset(gq.used, 0, PGSIZE);
    8000683a:	6605                	lui	a2,0x1
    8000683c:	4581                	li	a1,0
    8000683e:	6888                	ld	a0,16(s1)
    80006840:	ffffa097          	auipc	ra,0xffffa
    80006844:	492080e7          	jalr	1170(ra) # 80000cd2 <memset>
    *R1(VIRTIO_MMIO_QUEUE_NUM) = GPU_NUM;
    80006848:	100027b7          	lui	a5,0x10002
    8000684c:	4721                	li	a4,8
    8000684e:	df98                	sw	a4,56(a5)
    *R1(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)gq.desc;
    80006850:	4098                	lw	a4,0(s1)
    80006852:	08e7a023          	sw	a4,128(a5) # 10002080 <_entry-0x6fffdf80>
    *R1(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)gq.desc >> 32;
    80006856:	40d8                	lw	a4,4(s1)
    80006858:	08e7a223          	sw	a4,132(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)gq.avail;
    8000685c:	6498                	ld	a4,8(s1)
    8000685e:	0007069b          	sext.w	a3,a4
    80006862:	08d7a823          	sw	a3,144(a5)
    *R1(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)gq.avail >> 32;
    80006866:	9701                	srai	a4,a4,0x20
    80006868:	08e7aa23          	sw	a4,148(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)gq.used;
    8000686c:	6898                	ld	a4,16(s1)
    8000686e:	0007069b          	sext.w	a3,a4
    80006872:	0ad7a023          	sw	a3,160(a5)
    *R1(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)gq.used >> 32;
    80006876:	9701                	srai	a4,a4,0x20
    80006878:	0ae7a223          	sw	a4,164(a5)
    *R1(VIRTIO_MMIO_QUEUE_READY) = 1;
    8000687c:	4705                	li	a4,1
    8000687e:	c3f8                	sw	a4,68(a5)
        gq.free[i] = 1;
    80006880:	00e48c23          	sb	a4,24(s1)
    80006884:	00e48ca3          	sb	a4,25(s1)
    80006888:	00e48d23          	sb	a4,26(s1)
    8000688c:	00e48da3          	sb	a4,27(s1)
    80006890:	00e48e23          	sb	a4,28(s1)
    80006894:	00e48ea3          	sb	a4,29(s1)
    80006898:	00e48f23          	sb	a4,30(s1)
    8000689c:	00e48fa3          	sb	a4,31(s1)
    *R1(VIRTIO_MMIO_STATUS) = status;
    800068a0:	473d                	li	a4,15
    800068a2:	dbb8                	sw	a4,112(a5)
    for (int i = 0; i < FB_PAGES; i++)
    800068a4:	00021917          	auipc	s2,0x21
    800068a8:	c9490913          	addi	s2,s2,-876 # 80027538 <fb>
    800068ac:	00021997          	auipc	s3,0x21
    800068b0:	5ec98993          	addi	s3,s3,1516 # 80027e98 <end>
    *R1(VIRTIO_MMIO_STATUS) = status;
    800068b4:	84ca                	mv	s1,s2
        fb[i] = kalloc();
    800068b6:	ffffa097          	auipc	ra,0xffffa
    800068ba:	230080e7          	jalr	560(ra) # 80000ae6 <kalloc>
    800068be:	e088                	sd	a0,0(s1)
        if (!fb[i])
    800068c0:	12050563          	beqz	a0,800069ea <virtio_gpu_init+0x2f6>
        memset(fb[i], 0, PGSIZE); // fill with COLOR_BG (0 = black)
    800068c4:	6605                	lui	a2,0x1
    800068c6:	4581                	li	a1,0
    800068c8:	ffffa097          	auipc	ra,0xffffa
    800068cc:	40a080e7          	jalr	1034(ra) # 80000cd2 <memset>
    for (int i = 0; i < FB_PAGES; i++)
    800068d0:	04a1                	addi	s1,s1,8
    800068d2:	ff3492e3          	bne	s1,s3,800068b6 <virtio_gpu_init+0x1c2>
    memset(&create_req, 0, sizeof(create_req));
    800068d6:	0001c497          	auipc	s1,0x1c
    800068da:	00a48493          	addi	s1,s1,10 # 800228e0 <gq>
    800068de:	0001c997          	auipc	s3,0x1c
    800068e2:	0e298993          	addi	s3,s3,226 # 800229c0 <create_req.7>
    800068e6:	02800613          	li	a2,40
    800068ea:	4581                	li	a1,0
    800068ec:	854e                	mv	a0,s3
    800068ee:	ffffa097          	auipc	ra,0xffffa
    800068f2:	3e4080e7          	jalr	996(ra) # 80000cd2 <memset>
    create_req.hdr.type = VIRTIO_GPU_CMD_RESOURCE_CREATE_2D;
    800068f6:	10100793          	li	a5,257
    800068fa:	0ef4a023          	sw	a5,224(s1)
    create_req.resource_id = RESOURCE_ID;
    800068fe:	4785                	li	a5,1
    80006900:	0ef4ac23          	sw	a5,248(s1)
    create_req.format = VIRTIO_GPU_FORMAT_B8G8R8X8_UNORM;
    80006904:	4789                	li	a5,2
    80006906:	0ef4ae23          	sw	a5,252(s1)
    create_req.width = SCREEN_W;
    8000690a:	28000793          	li	a5,640
    8000690e:	10f4a023          	sw	a5,256(s1)
    create_req.height = SCREEN_H;
    80006912:	1e000793          	li	a5,480
    80006916:	10f4a223          	sw	a5,260(s1)
    gpu_send(&create_req, sizeof(create_req));
    8000691a:	02800593          	li	a1,40
    8000691e:	854e                	mv	a0,s3
    80006920:	00000097          	auipc	ra,0x0
    80006924:	b52080e7          	jalr	-1198(ra) # 80006472 <gpu_send>
    for (int i = 0; i < FB_PAGES; i++) {
    80006928:	0001e797          	auipc	a5,0x1e
    8000692c:	67078793          	addi	a5,a5,1648 # 80024f98 <fb_entries.6>
    80006930:	00020617          	auipc	a2,0x20
    80006934:	92860613          	addi	a2,a2,-1752 # 80026258 <attach_buf>
        fb_entries[i].length = PGSIZE;
    80006938:	6685                	lui	a3,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    8000693a:	00093703          	ld	a4,0(s2)
    8000693e:	e398                	sd	a4,0(a5)
        fb_entries[i].length = PGSIZE;
    80006940:	c794                	sw	a3,8(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    80006942:	0921                	addi	s2,s2,8
    80006944:	07c1                	addi	a5,a5,16
    80006946:	fec79ae3          	bne	a5,a2,8000693a <virtio_gpu_init+0x246>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    8000694a:	12c00593          	li	a1,300
    8000694e:	0001e517          	auipc	a0,0x1e
    80006952:	64a50513          	addi	a0,a0,1610 # 80024f98 <fb_entries.6>
    80006956:	00000097          	auipc	ra,0x0
    8000695a:	c28080e7          	jalr	-984(ra) # 8000657e <gpu_cmd_attach>
        for (int i = 0; msg[i]; i++)
    8000695e:	00002c17          	auipc	s8,0x2
    80006962:	012c0c13          	addi	s8,s8,18 # 80008970 <syscalls+0x500>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    80006966:	0008cbb7          	lui	s7,0x8c
    8000696a:	250b8b93          	addi	s7,s7,592 # 8c250 <_entry-0x7ff73db0>
        for (int i = 0; msg[i]; i++)
    8000696e:	04800793          	li	a5,72
    const uint8 *rows = font8x8[ch];
    80006972:	00002c97          	auipc	s9,0x2
    80006976:	046c8c93          	addi	s9,s9,70 # 800089b8 <font8x8>
    8000697a:	00024737          	lui	a4,0x24
    8000697e:	a0070d93          	addi	s11,a4,-1536 # 23a00 <_entry-0x7ffdc600>
        for (int col = 0; col < 8; col++)
    80006982:	4d01                	li	s10,0
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006984:	010004b7          	lui	s1,0x1000
    80006988:	14fd                	addi	s1,s1,-1
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    8000698a:	00021897          	auipc	a7,0x21
    8000698e:	bae88893          	addi	a7,a7,-1106 # 80027538 <fb>
    int off = byte_off % PGSIZE;
    80006992:	6805                	lui	a6,0x1
    80006994:	187d                	addi	a6,a6,-1
            for (int dy = 0; dy < SCALE; dy++)
    80006996:	6e05                	lui	t3,0x1
    80006998:	a00e0e1b          	addiw	t3,t3,-1536
        for (int col = 0; col < 8; col++)
    8000699c:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
    8000699e:	6a8d                	lui	s5,0x3
    800069a0:	800a8a9b          	addiw	s5,s5,-2048
    800069a4:	10000b13          	li	s6,256
    800069a8:	a0f1                	j	80006a74 <virtio_gpu_init+0x380>
        panic("virtio_gpu: FEATURES_OK not set");
    800069aa:	00002517          	auipc	a0,0x2
    800069ae:	f0e50513          	addi	a0,a0,-242 # 800088b8 <syscalls+0x448>
    800069b2:	ffffa097          	auipc	ra,0xffffa
    800069b6:	b8c080e7          	jalr	-1140(ra) # 8000053e <panic>
        panic("virtio_gpu: queue already ready");
    800069ba:	00002517          	auipc	a0,0x2
    800069be:	f1e50513          	addi	a0,a0,-226 # 800088d8 <syscalls+0x468>
    800069c2:	ffffa097          	auipc	ra,0xffffa
    800069c6:	b7c080e7          	jalr	-1156(ra) # 8000053e <panic>
        panic("virtio_gpu: queue too small");
    800069ca:	00002517          	auipc	a0,0x2
    800069ce:	f2e50513          	addi	a0,a0,-210 # 800088f8 <syscalls+0x488>
    800069d2:	ffffa097          	auipc	ra,0xffffa
    800069d6:	b6c080e7          	jalr	-1172(ra) # 8000053e <panic>
        panic("virtio_gpu: kalloc failed for queue");
    800069da:	00002517          	auipc	a0,0x2
    800069de:	f3e50513          	addi	a0,a0,-194 # 80008918 <syscalls+0x4a8>
    800069e2:	ffffa097          	auipc	ra,0xffffa
    800069e6:	b5c080e7          	jalr	-1188(ra) # 8000053e <panic>
            panic("virtio_gpu: kalloc failed for framebuffer");
    800069ea:	00002517          	auipc	a0,0x2
    800069ee:	f5650513          	addi	a0,a0,-170 # 80008940 <syscalls+0x4d0>
    800069f2:	ffffa097          	auipc	ra,0xffffa
    800069f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    800069fa:	85fe                	mv	a1,t6
    800069fc:	831e                	mv	t1,t2
                for (int dx = 0; dx < SCALE; dx++)
    800069fe:	ff05869b          	addiw	a3,a1,-16
    int pg = byte_off / PGSIZE;
    80006a02:	43f6d613          	srai	a2,a3,0x3f
    80006a06:	0146561b          	srliw	a2,a2,0x14
    80006a0a:	00d607bb          	addw	a5,a2,a3
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006a0e:	40c7d71b          	sraiw	a4,a5,0xc
    80006a12:	070e                	slli	a4,a4,0x3
    80006a14:	9746                	add	a4,a4,a7
    int off = byte_off % PGSIZE;
    80006a16:	0107f7b3          	and	a5,a5,a6
    uint32 *p = (uint32 *)((uint8 *)fb[pg] + off);
    80006a1a:	9f91                	subw	a5,a5,a2
    *p = color;
    80006a1c:	6310                	ld	a2,0(a4)
    80006a1e:	97b2                	add	a5,a5,a2
    80006a20:	c388                	sw	a0,0(a5)
                for (int dx = 0; dx < SCALE; dx++)
    80006a22:	2691                	addiw	a3,a3,4
    80006a24:	fcd59fe3          	bne	a1,a3,80006a02 <virtio_gpu_init+0x30e>
            for (int dy = 0; dy < SCALE; dy++)
    80006a28:	2803031b          	addiw	t1,t1,640
    80006a2c:	00be05bb          	addw	a1,t3,a1
    80006a30:	fdd317e3          	bne	t1,t4,800069fe <virtio_gpu_init+0x30a>
        for (int col = 0; col < 8; col++)
    80006a34:	2f05                	addiw	t5,t5,1
    80006a36:	2fc1                	addiw	t6,t6,16
    80006a38:	001f0a63          	beq	t5,ra,80006a4c <virtio_gpu_init+0x358>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006a3c:	0002c503          	lbu	a0,0(t0)
    80006a40:	01e5553b          	srlw	a0,a0,t5
    80006a44:	8905                	andi	a0,a0,1
    80006a46:	d955                	beqz	a0,800069fa <virtio_gpu_init+0x306>
    80006a48:	8526                	mv	a0,s1
    80006a4a:	bf45                	j	800069fa <virtio_gpu_init+0x306>
    for (int row = 0; row < 8; row++)
    80006a4c:	01de0ebb          	addw	t4,t3,t4
    80006a50:	012e093b          	addw	s2,t3,s2
    80006a54:	2991                	addiw	s3,s3,4
    80006a56:	014a8a3b          	addw	s4,s5,s4
    80006a5a:	0285                	addi	t0,t0,1
    80006a5c:	01698663          	beq	s3,s6,80006a68 <virtio_gpu_init+0x374>
        for (int i = 0; msg[i]; i++)
    80006a60:	8fd2                	mv	t6,s4
        for (int col = 0; col < 8; col++)
    80006a62:	8f6a                	mv	t5,s10
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
    80006a64:	83ca                	mv	t2,s2
    80006a66:	bfd9                	j	80006a3c <virtio_gpu_init+0x348>
        for (int i = 0; msg[i]; i++)
    80006a68:	001c4783          	lbu	a5,1(s8)
    80006a6c:	0c05                	addi	s8,s8,1
    80006a6e:	080b8b9b          	addiw	s7,s7,128
    80006a72:	cb99                	beqz	a5,80006a88 <virtio_gpu_init+0x394>
    const uint8 *rows = font8x8[ch];
    80006a74:	078e                	slli	a5,a5,0x3
    80006a76:	019782b3          	add	t0,a5,s9
    80006a7a:	8a5e                	mv	s4,s7
    80006a7c:	0e000993          	li	s3,224
    80006a80:	00023937          	lui	s2,0x23
    80006a84:	8eee                	mv	t4,s11
    80006a86:	bfe9                	j	80006a60 <virtio_gpu_init+0x36c>
    memset(&scanout_req, 0, sizeof(scanout_req));
    80006a88:	0001c497          	auipc	s1,0x1c
    80006a8c:	e5848493          	addi	s1,s1,-424 # 800228e0 <gq>
    80006a90:	0001c917          	auipc	s2,0x1c
    80006a94:	f5890913          	addi	s2,s2,-168 # 800229e8 <scanout_req.5>
    80006a98:	03000613          	li	a2,48
    80006a9c:	4581                	li	a1,0
    80006a9e:	854a                	mv	a0,s2
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	232080e7          	jalr	562(ra) # 80000cd2 <memset>
    scanout_req.hdr.type = VIRTIO_GPU_CMD_SET_SCANOUT;
    80006aa8:	10300793          	li	a5,259
    80006aac:	10f4a423          	sw	a5,264(s1)
    scanout_req.r.x = 0;
    80006ab0:	1204a023          	sw	zero,288(s1)
    scanout_req.r.y = 0;
    80006ab4:	1204a223          	sw	zero,292(s1)
    scanout_req.r.width = SCREEN_W;
    80006ab8:	28000793          	li	a5,640
    80006abc:	12f4a423          	sw	a5,296(s1)
    scanout_req.r.height = SCREEN_H;
    80006ac0:	1e000793          	li	a5,480
    80006ac4:	12f4a623          	sw	a5,300(s1)
    scanout_req.scanout_id = SCANOUT_ID;
    80006ac8:	1204a823          	sw	zero,304(s1)
    scanout_req.resource_id = RESOURCE_ID;
    80006acc:	4785                	li	a5,1
    80006ace:	12f4aa23          	sw	a5,308(s1)
    gpu_send(&scanout_req, sizeof(scanout_req));
    80006ad2:	03000593          	li	a1,48
    80006ad6:	854a                	mv	a0,s2
    80006ad8:	00000097          	auipc	ra,0x0
    80006adc:	99a080e7          	jalr	-1638(ra) # 80006472 <gpu_send>
    gpu_transfer_flush();
    80006ae0:	00000097          	auipc	ra,0x0
    80006ae4:	b08080e7          	jalr	-1272(ra) # 800065e8 <gpu_transfer_flush>
    printf("virtio_gpu: \"Hello World\" displayed on 640x480 window\n");
    80006ae8:	00002517          	auipc	a0,0x2
    80006aec:	e9850513          	addi	a0,a0,-360 # 80008980 <syscalls+0x510>
    80006af0:	ffffa097          	auipc	ra,0xffffa
    80006af4:	a98080e7          	jalr	-1384(ra) # 80000588 <printf>
    80006af8:	b159                	j	8000677e <virtio_gpu_init+0x8a>

0000000080006afa <virtio_gpu_commit>:

// ── Public: flush the kernel fb[] to the display ─────────────────────
// Called by display_daemon.  Sends TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
void virtio_gpu_commit(void)
{
    80006afa:	1141                	addi	sp,sp,-16
    80006afc:	e406                	sd	ra,8(sp)
    80006afe:	e022                	sd	s0,0(sp)
    80006b00:	0800                	addi	s0,sp,16
    gpu_transfer_flush();
    80006b02:	00000097          	auipc	ra,0x0
    80006b06:	ae6080e7          	jalr	-1306(ra) # 800065e8 <gpu_transfer_flush>
}
    80006b0a:	60a2                	ld	ra,8(sp)
    80006b0c:	6402                	ld	s0,0(sp)
    80006b0e:	0141                	addi	sp,sp,16
    80006b10:	8082                	ret

0000000080006b12 <virtio_gpu_map_fb>:
// Maps all FB_PAGES of fb[] at consecutive pages starting at va with
// PTE_U|PTE_R|PTE_W.  Caller must have verified va is page-aligned and
// the range is collision-free.  Returns 0 on success, -1 on OOM.
int
virtio_gpu_map_fb(pagetable_t pagetable, uint64 va)
{
    80006b12:	715d                	addi	sp,sp,-80
    80006b14:	e486                	sd	ra,72(sp)
    80006b16:	e0a2                	sd	s0,64(sp)
    80006b18:	fc26                	sd	s1,56(sp)
    80006b1a:	f84a                	sd	s2,48(sp)
    80006b1c:	f44e                	sd	s3,40(sp)
    80006b1e:	f052                	sd	s4,32(sp)
    80006b20:	ec56                	sd	s5,24(sp)
    80006b22:	e85a                	sd	s6,16(sp)
    80006b24:	e45e                	sd	s7,8(sp)
    80006b26:	0880                	addi	s0,sp,80
    80006b28:	8a2a                	mv	s4,a0
    80006b2a:	8bae                	mv	s7,a1
    for (int i = 0; i < FB_PAGES; i++) {
    80006b2c:	00021997          	auipc	s3,0x21
    80006b30:	a0c98993          	addi	s3,s3,-1524 # 80027538 <fb>
{
    80006b34:	892e                	mv	s2,a1
    80006b36:	4481                	li	s1,0
    for (int i = 0; i < FB_PAGES; i++) {
    80006b38:	12c00b13          	li	s6,300
    80006b3c:	00048a9b          	sext.w	s5,s1
        if (mappages(pagetable, va + (uint64)i * PGSIZE, PGSIZE,
    80006b40:	4759                	li	a4,22
    80006b42:	0009b683          	ld	a3,0(s3)
    80006b46:	6605                	lui	a2,0x1
    80006b48:	85ca                	mv	a1,s2
    80006b4a:	8552                	mv	a0,s4
    80006b4c:	ffffa097          	auipc	ra,0xffffa
    80006b50:	572080e7          	jalr	1394(ra) # 800010be <mappages>
    80006b54:	e901                	bnez	a0,80006b64 <virtio_gpu_map_fb+0x52>
    for (int i = 0; i < FB_PAGES; i++) {
    80006b56:	0485                	addi	s1,s1,1
    80006b58:	09a1                	addi	s3,s3,8
    80006b5a:	6785                	lui	a5,0x1
    80006b5c:	993e                	add	s2,s2,a5
    80006b5e:	fd649fe3          	bne	s1,s6,80006b3c <virtio_gpu_map_fb+0x2a>
    80006b62:	a021                	j	80006b6a <virtio_gpu_map_fb+0x58>
                     (uint64)fb[i], PTE_U | PTE_R | PTE_W) != 0) {
            if (i > 0)
                uvmunmap(pagetable, va, i, 0);
            return -1;
    80006b64:	557d                	li	a0,-1
            if (i > 0)
    80006b66:	01504d63          	bgtz	s5,80006b80 <virtio_gpu_map_fb+0x6e>
        }
    }
    return 0;
}
    80006b6a:	60a6                	ld	ra,72(sp)
    80006b6c:	6406                	ld	s0,64(sp)
    80006b6e:	74e2                	ld	s1,56(sp)
    80006b70:	7942                	ld	s2,48(sp)
    80006b72:	79a2                	ld	s3,40(sp)
    80006b74:	7a02                	ld	s4,32(sp)
    80006b76:	6ae2                	ld	s5,24(sp)
    80006b78:	6b42                	ld	s6,16(sp)
    80006b7a:	6ba2                	ld	s7,8(sp)
    80006b7c:	6161                	addi	sp,sp,80
    80006b7e:	8082                	ret
                uvmunmap(pagetable, va, i, 0);
    80006b80:	4681                	li	a3,0
    80006b82:	8626                	mv	a2,s1
    80006b84:	85de                	mv	a1,s7
    80006b86:	8552                	mv	a0,s4
    80006b88:	ffffa097          	auipc	ra,0xffffa
    80006b8c:	712080e7          	jalr	1810(ra) # 8000129a <uvmunmap>
            return -1;
    80006b90:	557d                	li	a0,-1
    80006b92:	bfe1                	j	80006b6a <virtio_gpu_map_fb+0x58>

0000000080006b94 <virtio_gpu_flip>:
// ── Public: zero-copy page flip ────────────────────────────────────────
// Detaches the current backing and re-attaches the device to the
// physical pages in phys_pages[0..n-1].
void
virtio_gpu_flip(uint64 *phys_pages, int n)
{
    80006b94:	1101                	addi	sp,sp,-32
    80006b96:	ec06                	sd	ra,24(sp)
    80006b98:	e822                	sd	s0,16(sp)
    80006b9a:	e426                	sd	s1,8(sp)
    80006b9c:	1000                	addi	s0,sp,32
    80006b9e:	84ae                	mv	s1,a1
    static struct virtio_gpu_mem_entry entries[FB_PAGES];
    for (int i = 0; i < n; i++) {
    80006ba0:	02b05a63          	blez	a1,80006bd4 <virtio_gpu_flip+0x40>
    80006ba4:	0001d797          	auipc	a5,0x1d
    80006ba8:	13478793          	addi	a5,a5,308 # 80023cd8 <entries.2>
    80006bac:	fff5869b          	addiw	a3,a1,-1
    80006bb0:	1682                	slli	a3,a3,0x20
    80006bb2:	9281                	srli	a3,a3,0x20
    80006bb4:	0692                	slli	a3,a3,0x4
    80006bb6:	0001d717          	auipc	a4,0x1d
    80006bba:	13270713          	addi	a4,a4,306 # 80023ce8 <entries.2+0x10>
    80006bbe:	96ba                	add	a3,a3,a4
        entries[i].addr    = phys_pages[i];
        entries[i].length  = PGSIZE;
    80006bc0:	6605                	lui	a2,0x1
        entries[i].addr    = phys_pages[i];
    80006bc2:	6118                	ld	a4,0(a0)
    80006bc4:	e398                	sd	a4,0(a5)
        entries[i].length  = PGSIZE;
    80006bc6:	c790                	sw	a2,8(a5)
        entries[i].padding = 0;
    80006bc8:	0007a623          	sw	zero,12(a5)
    for (int i = 0; i < n; i++) {
    80006bcc:	0521                	addi	a0,a0,8
    80006bce:	07c1                	addi	a5,a5,16
    80006bd0:	fed799e3          	bne	a5,a3,80006bc2 <virtio_gpu_flip+0x2e>
    }
    gpu_cmd_detach();
    80006bd4:	00000097          	auipc	ra,0x0
    80006bd8:	acc080e7          	jalr	-1332(ra) # 800066a0 <gpu_cmd_detach>
    gpu_cmd_attach(entries, n);
    80006bdc:	85a6                	mv	a1,s1
    80006bde:	0001d517          	auipc	a0,0x1d
    80006be2:	0fa50513          	addi	a0,a0,250 # 80023cd8 <entries.2>
    80006be6:	00000097          	auipc	ra,0x0
    80006bea:	998080e7          	jalr	-1640(ra) # 8000657e <gpu_cmd_attach>
    flip_owner = myproc();
    80006bee:	ffffb097          	auipc	ra,0xffffb
    80006bf2:	df4080e7          	jalr	-524(ra) # 800019e2 <myproc>
    80006bf6:	00002797          	auipc	a5,0x2
    80006bfa:	66a7b923          	sd	a0,1650(a5) # 80009268 <flip_owner>
}
    80006bfe:	60e2                	ld	ra,24(sp)
    80006c00:	6442                	ld	s0,16(sp)
    80006c02:	64a2                	ld	s1,8(sp)
    80006c04:	6105                	addi	sp,sp,32
    80006c06:	8082                	ret

0000000080006c08 <virtio_gpu_on_proc_exit>:
// device's backing to the kernel's own fb[] so the daemon can keep
// flushing valid pixel data.
void
virtio_gpu_on_proc_exit(struct proc *p)
{
    if (flip_owner != p)
    80006c08:	00002797          	auipc	a5,0x2
    80006c0c:	6607b783          	ld	a5,1632(a5) # 80009268 <flip_owner>
    80006c10:	00a78363          	beq	a5,a0,80006c16 <virtio_gpu_on_proc_exit+0xe>
    80006c14:	8082                	ret
{
    80006c16:	1141                	addi	sp,sp,-16
    80006c18:	e406                	sd	ra,8(sp)
    80006c1a:	e022                	sd	s0,0(sp)
    80006c1c:	0800                	addi	s0,sp,16
        return;
    flip_owner = 0;
    80006c1e:	00002797          	auipc	a5,0x2
    80006c22:	6407b523          	sd	zero,1610(a5) # 80009268 <flip_owner>
    static struct virtio_gpu_mem_entry fb_entries[FB_PAGES];
    for (int i = 0; i < FB_PAGES; i++) {
    80006c26:	00021717          	auipc	a4,0x21
    80006c2a:	91270713          	addi	a4,a4,-1774 # 80027538 <fb>
    80006c2e:	0001c797          	auipc	a5,0x1c
    80006c32:	dea78793          	addi	a5,a5,-534 # 80022a18 <fb_entries.0>
    80006c36:	0001d597          	auipc	a1,0x1d
    80006c3a:	0a258593          	addi	a1,a1,162 # 80023cd8 <entries.2>
        fb_entries[i].addr   = (uint64)fb[i];
        fb_entries[i].length = PGSIZE;
    80006c3e:	6605                	lui	a2,0x1
        fb_entries[i].addr   = (uint64)fb[i];
    80006c40:	6314                	ld	a3,0(a4)
    80006c42:	e394                	sd	a3,0(a5)
        fb_entries[i].length = PGSIZE;
    80006c44:	c790                	sw	a2,8(a5)
        fb_entries[i].padding = 0;
    80006c46:	0007a623          	sw	zero,12(a5)
    for (int i = 0; i < FB_PAGES; i++) {
    80006c4a:	0721                	addi	a4,a4,8
    80006c4c:	07c1                	addi	a5,a5,16
    80006c4e:	feb799e3          	bne	a5,a1,80006c40 <virtio_gpu_on_proc_exit+0x38>
    }
    gpu_cmd_detach();
    80006c52:	00000097          	auipc	ra,0x0
    80006c56:	a4e080e7          	jalr	-1458(ra) # 800066a0 <gpu_cmd_detach>
    gpu_cmd_attach(fb_entries, FB_PAGES);
    80006c5a:	12c00593          	li	a1,300
    80006c5e:	0001c517          	auipc	a0,0x1c
    80006c62:	dba50513          	addi	a0,a0,-582 # 80022a18 <fb_entries.0>
    80006c66:	00000097          	auipc	ra,0x0
    80006c6a:	918080e7          	jalr	-1768(ra) # 8000657e <gpu_cmd_attach>
}
    80006c6e:	60a2                	ld	ra,8(sp)
    80006c70:	6402                	ld	s0,0(sp)
    80006c72:	0141                	addi	sp,sp,16
    80006c74:	8082                	ret

0000000080006c76 <display_daemon>:
// Commit period: DISPLAY_DAEMON_TICKS ticks.  xv6's timer fires every
// ~1/10th of a second at QEMU's default rate, giving ~10fps.
#define DISPLAY_DAEMON_TICKS 1

void display_daemon(void)
{
    80006c76:	7179                	addi	sp,sp,-48
    80006c78:	f406                	sd	ra,40(sp)
    80006c7a:	f022                	sd	s0,32(sp)
    80006c7c:	ec26                	sd	s1,24(sp)
    80006c7e:	e84a                	sd	s2,16(sp)
    80006c80:	e44e                	sd	s3,8(sp)
    80006c82:	1800                	addi	s0,sp,48
    // The scheduler holds p->lock across swtch into a new process.
    // Release it here, just like forkret does for user processes.
    struct proc *p = myproc();
    80006c84:	ffffb097          	auipc	ra,0xffffb
    80006c88:	d5e080e7          	jalr	-674(ra) # 800019e2 <myproc>
    release(&p->lock);
    80006c8c:	ffffa097          	auipc	ra,0xffffa
    80006c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>

    acquire(&tickslock);
    80006c94:	00011517          	auipc	a0,0x11
    80006c98:	86c50513          	addi	a0,a0,-1940 # 80017500 <tickslock>
    80006c9c:	ffffa097          	auipc	ra,0xffffa
    80006ca0:	f3a080e7          	jalr	-198(ra) # 80000bd6 <acquire>
    for (;;)
    {
        // Sleep until DISPLAY_DAEMON_TICKS ticks have elapsed.
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006ca4:	00002917          	auipc	s2,0x2
    80006ca8:	5bc90913          	addi	s2,s2,1468 # 80009260 <ticks>
        while (ticks < deadline)
            sleep(&ticks, &tickslock);
    80006cac:	00011497          	auipc	s1,0x11
    80006cb0:	85448493          	addi	s1,s1,-1964 # 80017500 <tickslock>
    80006cb4:	a839                	j	80006cd2 <display_daemon+0x5c>

        release(&tickslock);
    80006cb6:	8526                	mv	a0,s1
    80006cb8:	ffffa097          	auipc	ra,0xffffa
    80006cbc:	fd2080e7          	jalr	-46(ra) # 80000c8a <release>
    gpu_transfer_flush();
    80006cc0:	00000097          	auipc	ra,0x0
    80006cc4:	928080e7          	jalr	-1752(ra) # 800065e8 <gpu_transfer_flush>
        virtio_gpu_commit();
        acquire(&tickslock);
    80006cc8:	8526                	mv	a0,s1
    80006cca:	ffffa097          	auipc	ra,0xffffa
    80006cce:	f0c080e7          	jalr	-244(ra) # 80000bd6 <acquire>
        uint deadline = ticks + DISPLAY_DAEMON_TICKS;
    80006cd2:	00092783          	lw	a5,0(s2)
    80006cd6:	0017899b          	addiw	s3,a5,1
        while (ticks < deadline)
    80006cda:	fd37fee3          	bgeu	a5,s3,80006cb6 <display_daemon+0x40>
            sleep(&ticks, &tickslock);
    80006cde:	85a6                	mv	a1,s1
    80006ce0:	854a                	mv	a0,s2
    80006ce2:	ffffb097          	auipc	ra,0xffffb
    80006ce6:	434080e7          	jalr	1076(ra) # 80002116 <sleep>
        while (ticks < deadline)
    80006cea:	00092783          	lw	a5,0(s2)
    80006cee:	ff37e8e3          	bltu	a5,s3,80006cde <display_daemon+0x68>
    80006cf2:	b7d1                	j	80006cb6 <display_daemon+0x40>
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
