
user/_show_flip:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
}

// ── main ──────────────────────────────────────────────────────────────

int main(int argc, char *argv[])
{
   0:	7109                	addi	sp,sp,-384
   2:	fe86                	sd	ra,376(sp)
   4:	faa2                	sd	s0,368(sp)
   6:	f6a6                	sd	s1,360(sp)
   8:	f2ca                	sd	s2,352(sp)
   a:	eece                	sd	s3,344(sp)
   c:	ead2                	sd	s4,336(sp)
   e:	e6d6                	sd	s5,328(sp)
  10:	e2da                	sd	s6,320(sp)
  12:	fe5e                	sd	s7,312(sp)
  14:	fa62                	sd	s8,304(sp)
  16:	f666                	sd	s9,296(sp)
  18:	f26a                	sd	s10,288(sp)
  1a:	ee6e                	sd	s11,280(sp)
  1c:	0300                	addi	s0,sp,384
    if (argc < 2)
  1e:	4785                	li	a5,1
  20:	00a7de63          	bge	a5,a0,3c <main+0x3c>
  24:	882a                	mv	a6,a0
  26:	05a1                	addi	a1,a1,8
    }

    // Join all arguments with spaces.
    char text[256];
    int pos = 0;
    for (int i = 1; i < argc && pos < (int)sizeof(text) - 1; i++)
  28:	4505                	li	a0,1
    int pos = 0;
  2a:	4981                	li	s3,0
    {
        if (i > 1 && pos < (int)sizeof(text) - 1)
            text[pos++] = ' ';
        for (char *s = argv[i]; *s && pos < (int)sizeof(text) - 1; s++)
  2c:	0fe00893          	li	a7,254
  30:	0ff00613          	li	a2,255
        if (i > 1 && pos < (int)sizeof(text) - 1)
  34:	4e05                	li	t3,1
            text[pos++] = ' ';
  36:	02000313          	li	t1,32
  3a:	a82d                	j	74 <main+0x74>
        fprintf(2, "Usage: show_flip <text>\n");
  3c:	00001597          	auipc	a1,0x1
  40:	9d458593          	addi	a1,a1,-1580 # a10 <malloc+0xea>
  44:	4509                	li	a0,2
  46:	00000097          	auipc	ra,0x0
  4a:	7f4080e7          	jalr	2036(ra) # 83a <fprintf>
        exit(1);
  4e:	4505                	li	a0,1
  50:	00000097          	auipc	ra,0x0
  54:	490080e7          	jalr	1168(ra) # 4e0 <exit>
    for (int i = 1; i < argc && pos < (int)sizeof(text) - 1; i++)
  58:	2505                	addiw	a0,a0,1
  5a:	04a80063          	beq	a6,a0,9a <main+0x9a>
  5e:	0d38c863          	blt	a7,s3,12e <main+0x12e>
        if (i > 1 && pos < (int)sizeof(text) - 1)
  62:	00ae5863          	bge	t3,a0,72 <main+0x72>
            text[pos++] = ' ';
  66:	f9040793          	addi	a5,s0,-112
  6a:	97ce                	add	a5,a5,s3
  6c:	f0678023          	sb	t1,-256(a5)
  70:	2985                	addiw	s3,s3,1
  72:	05a1                	addi	a1,a1,8
        for (char *s = argv[i]; *s && pos < (int)sizeof(text) - 1; s++)
  74:	6198                	ld	a4,0(a1)
  76:	00074783          	lbu	a5,0(a4)
  7a:	dff9                	beqz	a5,58 <main+0x58>
  7c:	0138cf63          	blt	a7,s3,9a <main+0x9a>
  80:	e9040693          	addi	a3,s0,-368
  84:	96ce                	add	a3,a3,s3
            text[pos++] = *s;
  86:	2985                	addiw	s3,s3,1
  88:	00f68023          	sb	a5,0(a3)
        for (char *s = argv[i]; *s && pos < (int)sizeof(text) - 1; s++)
  8c:	0705                	addi	a4,a4,1
  8e:	00074783          	lbu	a5,0(a4)
  92:	d3f9                	beqz	a5,58 <main+0x58>
  94:	0685                	addi	a3,a3,1
  96:	fec998e3          	bne	s3,a2,86 <main+0x86>
    }
    text[pos] = '\0';
  9a:	f9040793          	addi	a5,s0,-112
  9e:	97ce                	add	a5,a5,s3
  a0:	f0078023          	sb	zero,-256(a5)
    int max_chars = SCREEN_W / char_w;
    if (pos > max_chars)
        pos = max_chars;

    // Allocate a page-aligned framebuffer (FB_BYTES = 300 × PGSIZE).
    uint32 *fb = (uint32 *)sbrk(FB_BYTES);
  a4:	0012c537          	lui	a0,0x12c
  a8:	00000097          	auipc	ra,0x0
  ac:	4c0080e7          	jalr	1216(ra) # 568 <sbrk>
  b0:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
  b2:	57fd                	li	a5,-1
  b4:	08f50c63          	beq	a0,a5,14c <main+0x14c>
  b8:	8a4e                	mv	s4,s3
  ba:	47d1                	li	a5,20
  bc:	0137d363          	bge	a5,s3,c2 <main+0xc2>
  c0:	4a51                	li	s4,20
  c2:	000a091b          	sext.w	s2,s4
        fprintf(2, "show_flip: sbrk failed\n");
        exit(1);
    }

    // Clear to background.
    memset(fb, 0, FB_BYTES);
  c6:	0012c637          	lui	a2,0x12c
  ca:	4581                	li	a1,0
  cc:	8526                	mv	a0,s1
  ce:	00000097          	auipc	ra,0x0
  d2:	216080e7          	jalr	534(ra) # 2e4 <memset>

    // Render text centred on screen.
    int text_w = pos * char_w;
  d6:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
  da:	28000a13          	li	s4,640
  de:	40fa0a3b          	subw	s4,s4,a5
  e2:	4789                	li	a5,2
  e4:	02fa4a3b          	divw	s4,s4,a5
    int y0 = (SCREEN_H - char_h) / 2;
    for (int i = 0; i < pos; i++)
  e8:	11305563          	blez	s3,1f2 <main+0x1f2>
  ec:	e9040d13          	addi	s10,s0,-368
  f0:	4c81                	li	s9,0
  f2:	0008cc37          	lui	s8,0x8c
  f6:	9c26                	add	s8,s8,s1
    const uint8 *rows = font8x8[ch];
  f8:	00001d97          	auipc	s11,0x1
  fc:	970d8d93          	addi	s11,s11,-1680 # a68 <font8x8>
 100:	000247b7          	lui	a5,0x24
 104:	a0078793          	addi	a5,a5,-1536 # 23a00 <base+0x229f0>
 108:	e8f43423          	sd	a5,-376(s0)
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 10c:	010002b7          	lui	t0,0x1000
 110:	12fd                	addi	t0,t0,-1
 112:	4311                	li	t1,4
            for (int dy = 0; dy < SCALE; dy++)
 114:	6805                	lui	a6,0x1
 116:	a0080813          	addi	a6,a6,-1536 # a00 <malloc+0xda>
        for (int col = 0; col < 8; col++)
 11a:	4fa1                	li	t6,8
    for (int row = 0; row < 8; row++)
 11c:	6b05                	lui	s6,0x1
 11e:	a00b0b1b          	addiw	s6,s6,-1536
 122:	6a8d                	lui	s5,0x3
 124:	800a8a93          	addi	s5,s5,-2048 # 2800 <base+0x17f0>
 128:	10000b93          	li	s7,256
 12c:	a871                	j	1c8 <main+0x1c8>
    text[pos] = '\0';
 12e:	f9040793          	addi	a5,s0,-112
 132:	97ce                	add	a5,a5,s3
 134:	f0078023          	sb	zero,-256(a5)
    uint32 *fb = (uint32 *)sbrk(FB_BYTES);
 138:	0012c537          	lui	a0,0x12c
 13c:	00000097          	auipc	ra,0x0
 140:	42c080e7          	jalr	1068(ra) # 568 <sbrk>
 144:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
 146:	57fd                	li	a5,-1
 148:	0cf51f63          	bne	a0,a5,226 <main+0x226>
        fprintf(2, "show_flip: sbrk failed\n");
 14c:	00001597          	auipc	a1,0x1
 150:	8e458593          	addi	a1,a1,-1820 # a30 <malloc+0x10a>
 154:	4509                	li	a0,2
 156:	00000097          	auipc	ra,0x0
 15a:	6e4080e7          	jalr	1764(ra) # 83a <fprintf>
        exit(1);
 15e:	4505                	li	a0,1
 160:	00000097          	auipc	ra,0x0
 164:	380080e7          	jalr	896(ra) # 4e0 <exit>
        ch = '?';
 168:	03f00793          	li	a5,63
 16c:	a0b5                	j	1d8 <main+0x1d8>
            for (int dy = 0; dy < SCALE; dy++)
 16e:	9642                	add	a2,a2,a6
 170:	2805859b          	addiw	a1,a1,640
 174:	00a58963          	beq	a1,a0,186 <main+0x186>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 178:	8732                	mv	a4,a2
 17a:	879a                	mv	a5,t1
    fb[y * SCREEN_W + x] = color;
 17c:	c314                	sw	a3,0(a4)
                for (int dx = 0; dx < SCALE; dx++)
 17e:	37fd                	addiw	a5,a5,-1
 180:	0711                	addi	a4,a4,4
 182:	ffed                	bnez	a5,17c <main+0x17c>
 184:	b7ed                	j	16e <main+0x16e>
        for (int col = 0; col < 8; col++)
 186:	2885                	addiw	a7,a7,1
 188:	0e41                	addi	t3,t3,16
 18a:	01f88c63          	beq	a7,t6,1a2 <main+0x1a2>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 18e:	000ec683          	lbu	a3,0(t4)
 192:	0116d6bb          	srlw	a3,a3,a7
 196:	8a85                	andi	a3,a3,1
 198:	c291                	beqz	a3,19c <main+0x19c>
 19a:	8696                	mv	a3,t0
            for (int dy = 0; dy < SCALE; dy++)
 19c:	85fa                	mv	a1,t5
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 19e:	8672                	mv	a2,t3
 1a0:	bfe1                	j	178 <main+0x178>
    for (int row = 0; row < 8; row++)
 1a2:	00ab053b          	addw	a0,s6,a0
 1a6:	2091                	addiw	ra,ra,4
 1a8:	99c2                	add	s3,s3,a6
 1aa:	93d6                	add	t2,t2,s5
 1ac:	0e85                	addi	t4,t4,1
 1ae:	01708763          	beq	ra,s7,1bc <main+0x1bc>
        ch = '?';
 1b2:	8e1e                	mv	t3,t2
        for (int col = 0; col < 8; col++)
 1b4:	4881                	li	a7,0
 1b6:	00098f1b          	sext.w	t5,s3
 1ba:	bfd1                	j	18e <main+0x18e>
    for (int i = 0; i < pos; i++)
 1bc:	2c85                	addiw	s9,s9,1
 1be:	0d05                	addi	s10,s10,1
 1c0:	020a0a13          	addi	s4,s4,32
 1c4:	032cd763          	bge	s9,s2,1f2 <main+0x1f2>
        draw_char(fb, x0 + i * char_w, y0, (unsigned char)text[i]);
 1c8:	000d4783          	lbu	a5,0(s10)
    if (ch >= 128)
 1cc:	0187971b          	slliw	a4,a5,0x18
 1d0:	4187571b          	sraiw	a4,a4,0x18
 1d4:	f8074ae3          	bltz	a4,168 <main+0x168>
    for (int row = 0; row < 8; row++)
 1d8:	002a1393          	slli	t2,s4,0x2
 1dc:	93e2                	add	t2,t2,s8
    const uint8 *rows = font8x8[ch];
 1de:	078e                	slli	a5,a5,0x3
 1e0:	00fd8eb3          	add	t4,s11,a5
 1e4:	000239b7          	lui	s3,0x23
 1e8:	0e000093          	li	ra,224
 1ec:	e8843503          	ld	a0,-376(s0)
 1f0:	b7c9                	j	1b2 <main+0x1b2>

    // Zero-copy flip: the kernel re-points the GPU resource's backing
    // pages to fb's physical pages; no pixel data is copied.
    if (flip_display(fb) < 0)
 1f2:	8526                	mv	a0,s1
 1f4:	00000097          	auipc	ra,0x0
 1f8:	38c080e7          	jalr	908(ra) # 580 <flip_display>
 1fc:	00054763          	bltz	a0,20a <main+0x20a>
    {
        fprintf(2, "show_flip: flip_display failed\n");
        exit(1);
    }

    exit(0);
 200:	4501                	li	a0,0
 202:	00000097          	auipc	ra,0x0
 206:	2de080e7          	jalr	734(ra) # 4e0 <exit>
        fprintf(2, "show_flip: flip_display failed\n");
 20a:	00001597          	auipc	a1,0x1
 20e:	83e58593          	addi	a1,a1,-1986 # a48 <malloc+0x122>
 212:	4509                	li	a0,2
 214:	00000097          	auipc	ra,0x0
 218:	626080e7          	jalr	1574(ra) # 83a <fprintf>
        exit(1);
 21c:	4505                	li	a0,1
 21e:	00000097          	auipc	ra,0x0
 222:	2c2080e7          	jalr	706(ra) # 4e0 <exit>
 226:	8a4e                	mv	s4,s3
 228:	47d1                	li	a5,20
 22a:	0137d363          	bge	a5,s3,230 <main+0x230>
 22e:	4a51                	li	s4,20
 230:	000a091b          	sext.w	s2,s4
    memset(fb, 0, FB_BYTES);
 234:	0012c637          	lui	a2,0x12c
 238:	4581                	li	a1,0
 23a:	8526                	mv	a0,s1
 23c:	00000097          	auipc	ra,0x0
 240:	0a8080e7          	jalr	168(ra) # 2e4 <memset>
    int text_w = pos * char_w;
 244:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
 248:	28000a13          	li	s4,640
 24c:	40fa0a3b          	subw	s4,s4,a5
 250:	4789                	li	a5,2
 252:	02fa4a3b          	divw	s4,s4,a5
    for (int i = 0; i < pos; i++)
 256:	bd59                	j	ec <main+0xec>

0000000000000258 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 258:	1141                	addi	sp,sp,-16
 25a:	e406                	sd	ra,8(sp)
 25c:	e022                	sd	s0,0(sp)
 25e:	0800                	addi	s0,sp,16
  extern int main();
  main();
 260:	00000097          	auipc	ra,0x0
 264:	da0080e7          	jalr	-608(ra) # 0 <main>
  exit(0);
 268:	4501                	li	a0,0
 26a:	00000097          	auipc	ra,0x0
 26e:	276080e7          	jalr	630(ra) # 4e0 <exit>

0000000000000272 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 272:	1141                	addi	sp,sp,-16
 274:	e422                	sd	s0,8(sp)
 276:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 278:	87aa                	mv	a5,a0
 27a:	0585                	addi	a1,a1,1
 27c:	0785                	addi	a5,a5,1
 27e:	fff5c703          	lbu	a4,-1(a1)
 282:	fee78fa3          	sb	a4,-1(a5)
 286:	fb75                	bnez	a4,27a <strcpy+0x8>
    ;
  return os;
}
 288:	6422                	ld	s0,8(sp)
 28a:	0141                	addi	sp,sp,16
 28c:	8082                	ret

000000000000028e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 28e:	1141                	addi	sp,sp,-16
 290:	e422                	sd	s0,8(sp)
 292:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 294:	00054783          	lbu	a5,0(a0) # 12c000 <base+0x12aff0>
 298:	cb91                	beqz	a5,2ac <strcmp+0x1e>
 29a:	0005c703          	lbu	a4,0(a1)
 29e:	00f71763          	bne	a4,a5,2ac <strcmp+0x1e>
    p++, q++;
 2a2:	0505                	addi	a0,a0,1
 2a4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2a6:	00054783          	lbu	a5,0(a0)
 2aa:	fbe5                	bnez	a5,29a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2ac:	0005c503          	lbu	a0,0(a1)
}
 2b0:	40a7853b          	subw	a0,a5,a0
 2b4:	6422                	ld	s0,8(sp)
 2b6:	0141                	addi	sp,sp,16
 2b8:	8082                	ret

00000000000002ba <strlen>:

uint
strlen(const char *s)
{
 2ba:	1141                	addi	sp,sp,-16
 2bc:	e422                	sd	s0,8(sp)
 2be:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2c0:	00054783          	lbu	a5,0(a0)
 2c4:	cf91                	beqz	a5,2e0 <strlen+0x26>
 2c6:	0505                	addi	a0,a0,1
 2c8:	87aa                	mv	a5,a0
 2ca:	4685                	li	a3,1
 2cc:	9e89                	subw	a3,a3,a0
 2ce:	00f6853b          	addw	a0,a3,a5
 2d2:	0785                	addi	a5,a5,1
 2d4:	fff7c703          	lbu	a4,-1(a5)
 2d8:	fb7d                	bnez	a4,2ce <strlen+0x14>
    ;
  return n;
}
 2da:	6422                	ld	s0,8(sp)
 2dc:	0141                	addi	sp,sp,16
 2de:	8082                	ret
  for(n = 0; s[n]; n++)
 2e0:	4501                	li	a0,0
 2e2:	bfe5                	j	2da <strlen+0x20>

00000000000002e4 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2e4:	1141                	addi	sp,sp,-16
 2e6:	e422                	sd	s0,8(sp)
 2e8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2ea:	ca19                	beqz	a2,300 <memset+0x1c>
 2ec:	87aa                	mv	a5,a0
 2ee:	1602                	slli	a2,a2,0x20
 2f0:	9201                	srli	a2,a2,0x20
 2f2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 2f6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2fa:	0785                	addi	a5,a5,1
 2fc:	fee79de3          	bne	a5,a4,2f6 <memset+0x12>
  }
  return dst;
}
 300:	6422                	ld	s0,8(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret

0000000000000306 <strchr>:

char*
strchr(const char *s, char c)
{
 306:	1141                	addi	sp,sp,-16
 308:	e422                	sd	s0,8(sp)
 30a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 30c:	00054783          	lbu	a5,0(a0)
 310:	cb99                	beqz	a5,326 <strchr+0x20>
    if(*s == c)
 312:	00f58763          	beq	a1,a5,320 <strchr+0x1a>
  for(; *s; s++)
 316:	0505                	addi	a0,a0,1
 318:	00054783          	lbu	a5,0(a0)
 31c:	fbfd                	bnez	a5,312 <strchr+0xc>
      return (char*)s;
  return 0;
 31e:	4501                	li	a0,0
}
 320:	6422                	ld	s0,8(sp)
 322:	0141                	addi	sp,sp,16
 324:	8082                	ret
  return 0;
 326:	4501                	li	a0,0
 328:	bfe5                	j	320 <strchr+0x1a>

000000000000032a <gets>:

char*
gets(char *buf, int max)
{
 32a:	711d                	addi	sp,sp,-96
 32c:	ec86                	sd	ra,88(sp)
 32e:	e8a2                	sd	s0,80(sp)
 330:	e4a6                	sd	s1,72(sp)
 332:	e0ca                	sd	s2,64(sp)
 334:	fc4e                	sd	s3,56(sp)
 336:	f852                	sd	s4,48(sp)
 338:	f456                	sd	s5,40(sp)
 33a:	f05a                	sd	s6,32(sp)
 33c:	ec5e                	sd	s7,24(sp)
 33e:	1080                	addi	s0,sp,96
 340:	8baa                	mv	s7,a0
 342:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 344:	892a                	mv	s2,a0
 346:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 348:	4aa9                	li	s5,10
 34a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 34c:	89a6                	mv	s3,s1
 34e:	2485                	addiw	s1,s1,1
 350:	0344d863          	bge	s1,s4,380 <gets+0x56>
    cc = read(0, &c, 1);
 354:	4605                	li	a2,1
 356:	faf40593          	addi	a1,s0,-81
 35a:	4501                	li	a0,0
 35c:	00000097          	auipc	ra,0x0
 360:	19c080e7          	jalr	412(ra) # 4f8 <read>
    if(cc < 1)
 364:	00a05e63          	blez	a0,380 <gets+0x56>
    buf[i++] = c;
 368:	faf44783          	lbu	a5,-81(s0)
 36c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 370:	01578763          	beq	a5,s5,37e <gets+0x54>
 374:	0905                	addi	s2,s2,1
 376:	fd679be3          	bne	a5,s6,34c <gets+0x22>
  for(i=0; i+1 < max; ){
 37a:	89a6                	mv	s3,s1
 37c:	a011                	j	380 <gets+0x56>
 37e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 380:	99de                	add	s3,s3,s7
 382:	00098023          	sb	zero,0(s3) # 23000 <base+0x21ff0>
  return buf;
}
 386:	855e                	mv	a0,s7
 388:	60e6                	ld	ra,88(sp)
 38a:	6446                	ld	s0,80(sp)
 38c:	64a6                	ld	s1,72(sp)
 38e:	6906                	ld	s2,64(sp)
 390:	79e2                	ld	s3,56(sp)
 392:	7a42                	ld	s4,48(sp)
 394:	7aa2                	ld	s5,40(sp)
 396:	7b02                	ld	s6,32(sp)
 398:	6be2                	ld	s7,24(sp)
 39a:	6125                	addi	sp,sp,96
 39c:	8082                	ret

000000000000039e <stat>:

int
stat(const char *n, struct stat *st)
{
 39e:	1101                	addi	sp,sp,-32
 3a0:	ec06                	sd	ra,24(sp)
 3a2:	e822                	sd	s0,16(sp)
 3a4:	e426                	sd	s1,8(sp)
 3a6:	e04a                	sd	s2,0(sp)
 3a8:	1000                	addi	s0,sp,32
 3aa:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3ac:	4581                	li	a1,0
 3ae:	00000097          	auipc	ra,0x0
 3b2:	172080e7          	jalr	370(ra) # 520 <open>
  if(fd < 0)
 3b6:	02054563          	bltz	a0,3e0 <stat+0x42>
 3ba:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3bc:	85ca                	mv	a1,s2
 3be:	00000097          	auipc	ra,0x0
 3c2:	17a080e7          	jalr	378(ra) # 538 <fstat>
 3c6:	892a                	mv	s2,a0
  close(fd);
 3c8:	8526                	mv	a0,s1
 3ca:	00000097          	auipc	ra,0x0
 3ce:	13e080e7          	jalr	318(ra) # 508 <close>
  return r;
}
 3d2:	854a                	mv	a0,s2
 3d4:	60e2                	ld	ra,24(sp)
 3d6:	6442                	ld	s0,16(sp)
 3d8:	64a2                	ld	s1,8(sp)
 3da:	6902                	ld	s2,0(sp)
 3dc:	6105                	addi	sp,sp,32
 3de:	8082                	ret
    return -1;
 3e0:	597d                	li	s2,-1
 3e2:	bfc5                	j	3d2 <stat+0x34>

00000000000003e4 <atoi>:

int
atoi(const char *s)
{
 3e4:	1141                	addi	sp,sp,-16
 3e6:	e422                	sd	s0,8(sp)
 3e8:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3ea:	00054603          	lbu	a2,0(a0)
 3ee:	fd06079b          	addiw	a5,a2,-48
 3f2:	0ff7f793          	andi	a5,a5,255
 3f6:	4725                	li	a4,9
 3f8:	02f76963          	bltu	a4,a5,42a <atoi+0x46>
 3fc:	86aa                	mv	a3,a0
  n = 0;
 3fe:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 400:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 402:	0685                	addi	a3,a3,1
 404:	0025179b          	slliw	a5,a0,0x2
 408:	9fa9                	addw	a5,a5,a0
 40a:	0017979b          	slliw	a5,a5,0x1
 40e:	9fb1                	addw	a5,a5,a2
 410:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 414:	0006c603          	lbu	a2,0(a3)
 418:	fd06071b          	addiw	a4,a2,-48
 41c:	0ff77713          	andi	a4,a4,255
 420:	fee5f1e3          	bgeu	a1,a4,402 <atoi+0x1e>
  return n;
}
 424:	6422                	ld	s0,8(sp)
 426:	0141                	addi	sp,sp,16
 428:	8082                	ret
  n = 0;
 42a:	4501                	li	a0,0
 42c:	bfe5                	j	424 <atoi+0x40>

000000000000042e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 42e:	1141                	addi	sp,sp,-16
 430:	e422                	sd	s0,8(sp)
 432:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 434:	02b57463          	bgeu	a0,a1,45c <memmove+0x2e>
    while(n-- > 0)
 438:	00c05f63          	blez	a2,456 <memmove+0x28>
 43c:	1602                	slli	a2,a2,0x20
 43e:	9201                	srli	a2,a2,0x20
 440:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 444:	872a                	mv	a4,a0
      *dst++ = *src++;
 446:	0585                	addi	a1,a1,1
 448:	0705                	addi	a4,a4,1
 44a:	fff5c683          	lbu	a3,-1(a1)
 44e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 452:	fee79ae3          	bne	a5,a4,446 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 456:	6422                	ld	s0,8(sp)
 458:	0141                	addi	sp,sp,16
 45a:	8082                	ret
    dst += n;
 45c:	00c50733          	add	a4,a0,a2
    src += n;
 460:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 462:	fec05ae3          	blez	a2,456 <memmove+0x28>
 466:	fff6079b          	addiw	a5,a2,-1
 46a:	1782                	slli	a5,a5,0x20
 46c:	9381                	srli	a5,a5,0x20
 46e:	fff7c793          	not	a5,a5
 472:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 474:	15fd                	addi	a1,a1,-1
 476:	177d                	addi	a4,a4,-1
 478:	0005c683          	lbu	a3,0(a1)
 47c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 480:	fee79ae3          	bne	a5,a4,474 <memmove+0x46>
 484:	bfc9                	j	456 <memmove+0x28>

0000000000000486 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 486:	1141                	addi	sp,sp,-16
 488:	e422                	sd	s0,8(sp)
 48a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 48c:	ca05                	beqz	a2,4bc <memcmp+0x36>
 48e:	fff6069b          	addiw	a3,a2,-1
 492:	1682                	slli	a3,a3,0x20
 494:	9281                	srli	a3,a3,0x20
 496:	0685                	addi	a3,a3,1
 498:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 49a:	00054783          	lbu	a5,0(a0)
 49e:	0005c703          	lbu	a4,0(a1)
 4a2:	00e79863          	bne	a5,a4,4b2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4a6:	0505                	addi	a0,a0,1
    p2++;
 4a8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4aa:	fed518e3          	bne	a0,a3,49a <memcmp+0x14>
  }
  return 0;
 4ae:	4501                	li	a0,0
 4b0:	a019                	j	4b6 <memcmp+0x30>
      return *p1 - *p2;
 4b2:	40e7853b          	subw	a0,a5,a4
}
 4b6:	6422                	ld	s0,8(sp)
 4b8:	0141                	addi	sp,sp,16
 4ba:	8082                	ret
  return 0;
 4bc:	4501                	li	a0,0
 4be:	bfe5                	j	4b6 <memcmp+0x30>

00000000000004c0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4c0:	1141                	addi	sp,sp,-16
 4c2:	e406                	sd	ra,8(sp)
 4c4:	e022                	sd	s0,0(sp)
 4c6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4c8:	00000097          	auipc	ra,0x0
 4cc:	f66080e7          	jalr	-154(ra) # 42e <memmove>
}
 4d0:	60a2                	ld	ra,8(sp)
 4d2:	6402                	ld	s0,0(sp)
 4d4:	0141                	addi	sp,sp,16
 4d6:	8082                	ret

00000000000004d8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4d8:	4885                	li	a7,1
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 4e0:	4889                	li	a7,2
 ecall
 4e2:	00000073          	ecall
 ret
 4e6:	8082                	ret

00000000000004e8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4e8:	488d                	li	a7,3
 ecall
 4ea:	00000073          	ecall
 ret
 4ee:	8082                	ret

00000000000004f0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4f0:	4891                	li	a7,4
 ecall
 4f2:	00000073          	ecall
 ret
 4f6:	8082                	ret

00000000000004f8 <read>:
.global read
read:
 li a7, SYS_read
 4f8:	4895                	li	a7,5
 ecall
 4fa:	00000073          	ecall
 ret
 4fe:	8082                	ret

0000000000000500 <write>:
.global write
write:
 li a7, SYS_write
 500:	48c1                	li	a7,16
 ecall
 502:	00000073          	ecall
 ret
 506:	8082                	ret

0000000000000508 <close>:
.global close
close:
 li a7, SYS_close
 508:	48d5                	li	a7,21
 ecall
 50a:	00000073          	ecall
 ret
 50e:	8082                	ret

0000000000000510 <kill>:
.global kill
kill:
 li a7, SYS_kill
 510:	4899                	li	a7,6
 ecall
 512:	00000073          	ecall
 ret
 516:	8082                	ret

0000000000000518 <exec>:
.global exec
exec:
 li a7, SYS_exec
 518:	489d                	li	a7,7
 ecall
 51a:	00000073          	ecall
 ret
 51e:	8082                	ret

0000000000000520 <open>:
.global open
open:
 li a7, SYS_open
 520:	48bd                	li	a7,15
 ecall
 522:	00000073          	ecall
 ret
 526:	8082                	ret

0000000000000528 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 528:	48c5                	li	a7,17
 ecall
 52a:	00000073          	ecall
 ret
 52e:	8082                	ret

0000000000000530 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 530:	48c9                	li	a7,18
 ecall
 532:	00000073          	ecall
 ret
 536:	8082                	ret

0000000000000538 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 538:	48a1                	li	a7,8
 ecall
 53a:	00000073          	ecall
 ret
 53e:	8082                	ret

0000000000000540 <link>:
.global link
link:
 li a7, SYS_link
 540:	48cd                	li	a7,19
 ecall
 542:	00000073          	ecall
 ret
 546:	8082                	ret

0000000000000548 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 548:	48d1                	li	a7,20
 ecall
 54a:	00000073          	ecall
 ret
 54e:	8082                	ret

0000000000000550 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 550:	48a5                	li	a7,9
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <dup>:
.global dup
dup:
 li a7, SYS_dup
 558:	48a9                	li	a7,10
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 560:	48ad                	li	a7,11
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 568:	48b1                	li	a7,12
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 570:	48b5                	li	a7,13
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 578:	48b9                	li	a7,14
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <flip_display>:
.global flip_display
flip_display:
 li a7, SYS_flip_display
 580:	48d9                	li	a7,22
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <map_display>:
.global map_display
map_display:
 li a7, SYS_map_display
 588:	48dd                	li	a7,23
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 590:	1101                	addi	sp,sp,-32
 592:	ec06                	sd	ra,24(sp)
 594:	e822                	sd	s0,16(sp)
 596:	1000                	addi	s0,sp,32
 598:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 59c:	4605                	li	a2,1
 59e:	fef40593          	addi	a1,s0,-17
 5a2:	00000097          	auipc	ra,0x0
 5a6:	f5e080e7          	jalr	-162(ra) # 500 <write>
}
 5aa:	60e2                	ld	ra,24(sp)
 5ac:	6442                	ld	s0,16(sp)
 5ae:	6105                	addi	sp,sp,32
 5b0:	8082                	ret

00000000000005b2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5b2:	7139                	addi	sp,sp,-64
 5b4:	fc06                	sd	ra,56(sp)
 5b6:	f822                	sd	s0,48(sp)
 5b8:	f426                	sd	s1,40(sp)
 5ba:	f04a                	sd	s2,32(sp)
 5bc:	ec4e                	sd	s3,24(sp)
 5be:	0080                	addi	s0,sp,64
 5c0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5c2:	c299                	beqz	a3,5c8 <printint+0x16>
 5c4:	0805c863          	bltz	a1,654 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5c8:	2581                	sext.w	a1,a1
  neg = 0;
 5ca:	4881                	li	a7,0
 5cc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5d0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5d2:	2601                	sext.w	a2,a2
 5d4:	00001517          	auipc	a0,0x1
 5d8:	89c50513          	addi	a0,a0,-1892 # e70 <digits>
 5dc:	883a                	mv	a6,a4
 5de:	2705                	addiw	a4,a4,1
 5e0:	02c5f7bb          	remuw	a5,a1,a2
 5e4:	1782                	slli	a5,a5,0x20
 5e6:	9381                	srli	a5,a5,0x20
 5e8:	97aa                	add	a5,a5,a0
 5ea:	0007c783          	lbu	a5,0(a5)
 5ee:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5f2:	0005879b          	sext.w	a5,a1
 5f6:	02c5d5bb          	divuw	a1,a1,a2
 5fa:	0685                	addi	a3,a3,1
 5fc:	fec7f0e3          	bgeu	a5,a2,5dc <printint+0x2a>
  if(neg)
 600:	00088b63          	beqz	a7,616 <printint+0x64>
    buf[i++] = '-';
 604:	fd040793          	addi	a5,s0,-48
 608:	973e                	add	a4,a4,a5
 60a:	02d00793          	li	a5,45
 60e:	fef70823          	sb	a5,-16(a4)
 612:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 616:	02e05863          	blez	a4,646 <printint+0x94>
 61a:	fc040793          	addi	a5,s0,-64
 61e:	00e78933          	add	s2,a5,a4
 622:	fff78993          	addi	s3,a5,-1
 626:	99ba                	add	s3,s3,a4
 628:	377d                	addiw	a4,a4,-1
 62a:	1702                	slli	a4,a4,0x20
 62c:	9301                	srli	a4,a4,0x20
 62e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 632:	fff94583          	lbu	a1,-1(s2)
 636:	8526                	mv	a0,s1
 638:	00000097          	auipc	ra,0x0
 63c:	f58080e7          	jalr	-168(ra) # 590 <putc>
  while(--i >= 0)
 640:	197d                	addi	s2,s2,-1
 642:	ff3918e3          	bne	s2,s3,632 <printint+0x80>
}
 646:	70e2                	ld	ra,56(sp)
 648:	7442                	ld	s0,48(sp)
 64a:	74a2                	ld	s1,40(sp)
 64c:	7902                	ld	s2,32(sp)
 64e:	69e2                	ld	s3,24(sp)
 650:	6121                	addi	sp,sp,64
 652:	8082                	ret
    x = -xx;
 654:	40b005bb          	negw	a1,a1
    neg = 1;
 658:	4885                	li	a7,1
    x = -xx;
 65a:	bf8d                	j	5cc <printint+0x1a>

000000000000065c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 65c:	7119                	addi	sp,sp,-128
 65e:	fc86                	sd	ra,120(sp)
 660:	f8a2                	sd	s0,112(sp)
 662:	f4a6                	sd	s1,104(sp)
 664:	f0ca                	sd	s2,96(sp)
 666:	ecce                	sd	s3,88(sp)
 668:	e8d2                	sd	s4,80(sp)
 66a:	e4d6                	sd	s5,72(sp)
 66c:	e0da                	sd	s6,64(sp)
 66e:	fc5e                	sd	s7,56(sp)
 670:	f862                	sd	s8,48(sp)
 672:	f466                	sd	s9,40(sp)
 674:	f06a                	sd	s10,32(sp)
 676:	ec6e                	sd	s11,24(sp)
 678:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 67a:	0005c903          	lbu	s2,0(a1)
 67e:	18090f63          	beqz	s2,81c <vprintf+0x1c0>
 682:	8aaa                	mv	s5,a0
 684:	8b32                	mv	s6,a2
 686:	00158493          	addi	s1,a1,1
  state = 0;
 68a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 68c:	02500a13          	li	s4,37
      if(c == 'd'){
 690:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 694:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 698:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 69c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6a0:	00000b97          	auipc	s7,0x0
 6a4:	7d0b8b93          	addi	s7,s7,2000 # e70 <digits>
 6a8:	a839                	j	6c6 <vprintf+0x6a>
        putc(fd, c);
 6aa:	85ca                	mv	a1,s2
 6ac:	8556                	mv	a0,s5
 6ae:	00000097          	auipc	ra,0x0
 6b2:	ee2080e7          	jalr	-286(ra) # 590 <putc>
 6b6:	a019                	j	6bc <vprintf+0x60>
    } else if(state == '%'){
 6b8:	01498f63          	beq	s3,s4,6d6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6bc:	0485                	addi	s1,s1,1
 6be:	fff4c903          	lbu	s2,-1(s1)
 6c2:	14090d63          	beqz	s2,81c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6c6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6ca:	fe0997e3          	bnez	s3,6b8 <vprintf+0x5c>
      if(c == '%'){
 6ce:	fd479ee3          	bne	a5,s4,6aa <vprintf+0x4e>
        state = '%';
 6d2:	89be                	mv	s3,a5
 6d4:	b7e5                	j	6bc <vprintf+0x60>
      if(c == 'd'){
 6d6:	05878063          	beq	a5,s8,716 <vprintf+0xba>
      } else if(c == 'l') {
 6da:	05978c63          	beq	a5,s9,732 <vprintf+0xd6>
      } else if(c == 'x') {
 6de:	07a78863          	beq	a5,s10,74e <vprintf+0xf2>
      } else if(c == 'p') {
 6e2:	09b78463          	beq	a5,s11,76a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6e6:	07300713          	li	a4,115
 6ea:	0ce78663          	beq	a5,a4,7b6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6ee:	06300713          	li	a4,99
 6f2:	0ee78e63          	beq	a5,a4,7ee <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6f6:	11478863          	beq	a5,s4,806 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6fa:	85d2                	mv	a1,s4
 6fc:	8556                	mv	a0,s5
 6fe:	00000097          	auipc	ra,0x0
 702:	e92080e7          	jalr	-366(ra) # 590 <putc>
        putc(fd, c);
 706:	85ca                	mv	a1,s2
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	e86080e7          	jalr	-378(ra) # 590 <putc>
      }
      state = 0;
 712:	4981                	li	s3,0
 714:	b765                	j	6bc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 716:	008b0913          	addi	s2,s6,8 # 1008 <freep+0x8>
 71a:	4685                	li	a3,1
 71c:	4629                	li	a2,10
 71e:	000b2583          	lw	a1,0(s6)
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	e8e080e7          	jalr	-370(ra) # 5b2 <printint>
 72c:	8b4a                	mv	s6,s2
      state = 0;
 72e:	4981                	li	s3,0
 730:	b771                	j	6bc <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 732:	008b0913          	addi	s2,s6,8
 736:	4681                	li	a3,0
 738:	4629                	li	a2,10
 73a:	000b2583          	lw	a1,0(s6)
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	e72080e7          	jalr	-398(ra) # 5b2 <printint>
 748:	8b4a                	mv	s6,s2
      state = 0;
 74a:	4981                	li	s3,0
 74c:	bf85                	j	6bc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 74e:	008b0913          	addi	s2,s6,8
 752:	4681                	li	a3,0
 754:	4641                	li	a2,16
 756:	000b2583          	lw	a1,0(s6)
 75a:	8556                	mv	a0,s5
 75c:	00000097          	auipc	ra,0x0
 760:	e56080e7          	jalr	-426(ra) # 5b2 <printint>
 764:	8b4a                	mv	s6,s2
      state = 0;
 766:	4981                	li	s3,0
 768:	bf91                	j	6bc <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 76a:	008b0793          	addi	a5,s6,8
 76e:	f8f43423          	sd	a5,-120(s0)
 772:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 776:	03000593          	li	a1,48
 77a:	8556                	mv	a0,s5
 77c:	00000097          	auipc	ra,0x0
 780:	e14080e7          	jalr	-492(ra) # 590 <putc>
  putc(fd, 'x');
 784:	85ea                	mv	a1,s10
 786:	8556                	mv	a0,s5
 788:	00000097          	auipc	ra,0x0
 78c:	e08080e7          	jalr	-504(ra) # 590 <putc>
 790:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 792:	03c9d793          	srli	a5,s3,0x3c
 796:	97de                	add	a5,a5,s7
 798:	0007c583          	lbu	a1,0(a5)
 79c:	8556                	mv	a0,s5
 79e:	00000097          	auipc	ra,0x0
 7a2:	df2080e7          	jalr	-526(ra) # 590 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7a6:	0992                	slli	s3,s3,0x4
 7a8:	397d                	addiw	s2,s2,-1
 7aa:	fe0914e3          	bnez	s2,792 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7ae:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7b2:	4981                	li	s3,0
 7b4:	b721                	j	6bc <vprintf+0x60>
        s = va_arg(ap, char*);
 7b6:	008b0993          	addi	s3,s6,8
 7ba:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7be:	02090163          	beqz	s2,7e0 <vprintf+0x184>
        while(*s != 0){
 7c2:	00094583          	lbu	a1,0(s2)
 7c6:	c9a1                	beqz	a1,816 <vprintf+0x1ba>
          putc(fd, *s);
 7c8:	8556                	mv	a0,s5
 7ca:	00000097          	auipc	ra,0x0
 7ce:	dc6080e7          	jalr	-570(ra) # 590 <putc>
          s++;
 7d2:	0905                	addi	s2,s2,1
        while(*s != 0){
 7d4:	00094583          	lbu	a1,0(s2)
 7d8:	f9e5                	bnez	a1,7c8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7da:	8b4e                	mv	s6,s3
      state = 0;
 7dc:	4981                	li	s3,0
 7de:	bdf9                	j	6bc <vprintf+0x60>
          s = "(null)";
 7e0:	00000917          	auipc	s2,0x0
 7e4:	68890913          	addi	s2,s2,1672 # e68 <font8x8+0x400>
        while(*s != 0){
 7e8:	02800593          	li	a1,40
 7ec:	bff1                	j	7c8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7ee:	008b0913          	addi	s2,s6,8
 7f2:	000b4583          	lbu	a1,0(s6)
 7f6:	8556                	mv	a0,s5
 7f8:	00000097          	auipc	ra,0x0
 7fc:	d98080e7          	jalr	-616(ra) # 590 <putc>
 800:	8b4a                	mv	s6,s2
      state = 0;
 802:	4981                	li	s3,0
 804:	bd65                	j	6bc <vprintf+0x60>
        putc(fd, c);
 806:	85d2                	mv	a1,s4
 808:	8556                	mv	a0,s5
 80a:	00000097          	auipc	ra,0x0
 80e:	d86080e7          	jalr	-634(ra) # 590 <putc>
      state = 0;
 812:	4981                	li	s3,0
 814:	b565                	j	6bc <vprintf+0x60>
        s = va_arg(ap, char*);
 816:	8b4e                	mv	s6,s3
      state = 0;
 818:	4981                	li	s3,0
 81a:	b54d                	j	6bc <vprintf+0x60>
    }
  }
}
 81c:	70e6                	ld	ra,120(sp)
 81e:	7446                	ld	s0,112(sp)
 820:	74a6                	ld	s1,104(sp)
 822:	7906                	ld	s2,96(sp)
 824:	69e6                	ld	s3,88(sp)
 826:	6a46                	ld	s4,80(sp)
 828:	6aa6                	ld	s5,72(sp)
 82a:	6b06                	ld	s6,64(sp)
 82c:	7be2                	ld	s7,56(sp)
 82e:	7c42                	ld	s8,48(sp)
 830:	7ca2                	ld	s9,40(sp)
 832:	7d02                	ld	s10,32(sp)
 834:	6de2                	ld	s11,24(sp)
 836:	6109                	addi	sp,sp,128
 838:	8082                	ret

000000000000083a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 83a:	715d                	addi	sp,sp,-80
 83c:	ec06                	sd	ra,24(sp)
 83e:	e822                	sd	s0,16(sp)
 840:	1000                	addi	s0,sp,32
 842:	e010                	sd	a2,0(s0)
 844:	e414                	sd	a3,8(s0)
 846:	e818                	sd	a4,16(s0)
 848:	ec1c                	sd	a5,24(s0)
 84a:	03043023          	sd	a6,32(s0)
 84e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 852:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 856:	8622                	mv	a2,s0
 858:	00000097          	auipc	ra,0x0
 85c:	e04080e7          	jalr	-508(ra) # 65c <vprintf>
}
 860:	60e2                	ld	ra,24(sp)
 862:	6442                	ld	s0,16(sp)
 864:	6161                	addi	sp,sp,80
 866:	8082                	ret

0000000000000868 <printf>:

void
printf(const char *fmt, ...)
{
 868:	711d                	addi	sp,sp,-96
 86a:	ec06                	sd	ra,24(sp)
 86c:	e822                	sd	s0,16(sp)
 86e:	1000                	addi	s0,sp,32
 870:	e40c                	sd	a1,8(s0)
 872:	e810                	sd	a2,16(s0)
 874:	ec14                	sd	a3,24(s0)
 876:	f018                	sd	a4,32(s0)
 878:	f41c                	sd	a5,40(s0)
 87a:	03043823          	sd	a6,48(s0)
 87e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 882:	00840613          	addi	a2,s0,8
 886:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 88a:	85aa                	mv	a1,a0
 88c:	4505                	li	a0,1
 88e:	00000097          	auipc	ra,0x0
 892:	dce080e7          	jalr	-562(ra) # 65c <vprintf>
}
 896:	60e2                	ld	ra,24(sp)
 898:	6442                	ld	s0,16(sp)
 89a:	6125                	addi	sp,sp,96
 89c:	8082                	ret

000000000000089e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 89e:	1141                	addi	sp,sp,-16
 8a0:	e422                	sd	s0,8(sp)
 8a2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8a4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8a8:	00000797          	auipc	a5,0x0
 8ac:	7587b783          	ld	a5,1880(a5) # 1000 <freep>
 8b0:	a805                	j	8e0 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8b2:	4618                	lw	a4,8(a2)
 8b4:	9db9                	addw	a1,a1,a4
 8b6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8ba:	6398                	ld	a4,0(a5)
 8bc:	6318                	ld	a4,0(a4)
 8be:	fee53823          	sd	a4,-16(a0)
 8c2:	a091                	j	906 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8c4:	ff852703          	lw	a4,-8(a0)
 8c8:	9e39                	addw	a2,a2,a4
 8ca:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8cc:	ff053703          	ld	a4,-16(a0)
 8d0:	e398                	sd	a4,0(a5)
 8d2:	a099                	j	918 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8d4:	6398                	ld	a4,0(a5)
 8d6:	00e7e463          	bltu	a5,a4,8de <free+0x40>
 8da:	00e6ea63          	bltu	a3,a4,8ee <free+0x50>
{
 8de:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8e0:	fed7fae3          	bgeu	a5,a3,8d4 <free+0x36>
 8e4:	6398                	ld	a4,0(a5)
 8e6:	00e6e463          	bltu	a3,a4,8ee <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8ea:	fee7eae3          	bltu	a5,a4,8de <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8ee:	ff852583          	lw	a1,-8(a0)
 8f2:	6390                	ld	a2,0(a5)
 8f4:	02059713          	slli	a4,a1,0x20
 8f8:	9301                	srli	a4,a4,0x20
 8fa:	0712                	slli	a4,a4,0x4
 8fc:	9736                	add	a4,a4,a3
 8fe:	fae60ae3          	beq	a2,a4,8b2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 902:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 906:	4790                	lw	a2,8(a5)
 908:	02061713          	slli	a4,a2,0x20
 90c:	9301                	srli	a4,a4,0x20
 90e:	0712                	slli	a4,a4,0x4
 910:	973e                	add	a4,a4,a5
 912:	fae689e3          	beq	a3,a4,8c4 <free+0x26>
  } else
    p->s.ptr = bp;
 916:	e394                	sd	a3,0(a5)
  freep = p;
 918:	00000717          	auipc	a4,0x0
 91c:	6ef73423          	sd	a5,1768(a4) # 1000 <freep>
}
 920:	6422                	ld	s0,8(sp)
 922:	0141                	addi	sp,sp,16
 924:	8082                	ret

0000000000000926 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 926:	7139                	addi	sp,sp,-64
 928:	fc06                	sd	ra,56(sp)
 92a:	f822                	sd	s0,48(sp)
 92c:	f426                	sd	s1,40(sp)
 92e:	f04a                	sd	s2,32(sp)
 930:	ec4e                	sd	s3,24(sp)
 932:	e852                	sd	s4,16(sp)
 934:	e456                	sd	s5,8(sp)
 936:	e05a                	sd	s6,0(sp)
 938:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 93a:	02051493          	slli	s1,a0,0x20
 93e:	9081                	srli	s1,s1,0x20
 940:	04bd                	addi	s1,s1,15
 942:	8091                	srli	s1,s1,0x4
 944:	0014899b          	addiw	s3,s1,1
 948:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 94a:	00000517          	auipc	a0,0x0
 94e:	6b653503          	ld	a0,1718(a0) # 1000 <freep>
 952:	c515                	beqz	a0,97e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 954:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 956:	4798                	lw	a4,8(a5)
 958:	02977f63          	bgeu	a4,s1,996 <malloc+0x70>
 95c:	8a4e                	mv	s4,s3
 95e:	0009871b          	sext.w	a4,s3
 962:	6685                	lui	a3,0x1
 964:	00d77363          	bgeu	a4,a3,96a <malloc+0x44>
 968:	6a05                	lui	s4,0x1
 96a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 96e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 972:	00000917          	auipc	s2,0x0
 976:	68e90913          	addi	s2,s2,1678 # 1000 <freep>
  if(p == (char*)-1)
 97a:	5afd                	li	s5,-1
 97c:	a88d                	j	9ee <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 97e:	00000797          	auipc	a5,0x0
 982:	69278793          	addi	a5,a5,1682 # 1010 <base>
 986:	00000717          	auipc	a4,0x0
 98a:	66f73d23          	sd	a5,1658(a4) # 1000 <freep>
 98e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 990:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 994:	b7e1                	j	95c <malloc+0x36>
      if(p->s.size == nunits)
 996:	02e48b63          	beq	s1,a4,9cc <malloc+0xa6>
        p->s.size -= nunits;
 99a:	4137073b          	subw	a4,a4,s3
 99e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9a0:	1702                	slli	a4,a4,0x20
 9a2:	9301                	srli	a4,a4,0x20
 9a4:	0712                	slli	a4,a4,0x4
 9a6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9a8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9ac:	00000717          	auipc	a4,0x0
 9b0:	64a73a23          	sd	a0,1620(a4) # 1000 <freep>
      return (void*)(p + 1);
 9b4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9b8:	70e2                	ld	ra,56(sp)
 9ba:	7442                	ld	s0,48(sp)
 9bc:	74a2                	ld	s1,40(sp)
 9be:	7902                	ld	s2,32(sp)
 9c0:	69e2                	ld	s3,24(sp)
 9c2:	6a42                	ld	s4,16(sp)
 9c4:	6aa2                	ld	s5,8(sp)
 9c6:	6b02                	ld	s6,0(sp)
 9c8:	6121                	addi	sp,sp,64
 9ca:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9cc:	6398                	ld	a4,0(a5)
 9ce:	e118                	sd	a4,0(a0)
 9d0:	bff1                	j	9ac <malloc+0x86>
  hp->s.size = nu;
 9d2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9d6:	0541                	addi	a0,a0,16
 9d8:	00000097          	auipc	ra,0x0
 9dc:	ec6080e7          	jalr	-314(ra) # 89e <free>
  return freep;
 9e0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9e4:	d971                	beqz	a0,9b8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9e6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9e8:	4798                	lw	a4,8(a5)
 9ea:	fa9776e3          	bgeu	a4,s1,996 <malloc+0x70>
    if(p == freep)
 9ee:	00093703          	ld	a4,0(s2)
 9f2:	853e                	mv	a0,a5
 9f4:	fef719e3          	bne	a4,a5,9e6 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9f8:	8552                	mv	a0,s4
 9fa:	00000097          	auipc	ra,0x0
 9fe:	b6e080e7          	jalr	-1170(ra) # 568 <sbrk>
  if(p == (char*)-1)
 a02:	fd5518e3          	bne	a0,s5,9d2 <malloc+0xac>
        return 0;
 a06:	4501                	li	a0,0
 a08:	bf45                	j	9b8 <malloc+0x92>
