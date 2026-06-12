
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
  40:	9e458593          	addi	a1,a1,-1564 # a20 <malloc+0xf0>
  44:	4509                	li	a0,2
  46:	00000097          	auipc	ra,0x0
  4a:	7fe080e7          	jalr	2046(ra) # 844 <fprintf>
        exit(1);
  4e:	4505                	li	a0,1
  50:	00000097          	auipc	ra,0x0
  54:	49a080e7          	jalr	1178(ra) # 4ea <exit>
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
  ac:	4ca080e7          	jalr	1226(ra) # 572 <sbrk>
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
  d2:	220080e7          	jalr	544(ra) # 2ee <memset>

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
  fc:	980d8d93          	addi	s11,s11,-1664 # a78 <font8x8>
 100:	000247b7          	lui	a5,0x24
 104:	a0078793          	addi	a5,a5,-1536 # 23a00 <base+0x229f0>
 108:	e8f43423          	sd	a5,-376(s0)
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 10c:	010002b7          	lui	t0,0x1000
 110:	12fd                	addi	t0,t0,-1
 112:	4311                	li	t1,4
            for (int dy = 0; dy < SCALE; dy++)
 114:	6805                	lui	a6,0x1
 116:	a0080813          	addi	a6,a6,-1536 # a00 <malloc+0xd0>
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
 140:	436080e7          	jalr	1078(ra) # 572 <sbrk>
 144:	84aa                	mv	s1,a0
    if (fb == (uint32 *)-1)
 146:	57fd                	li	a5,-1
 148:	0ef51463          	bne	a0,a5,230 <main+0x230>
        fprintf(2, "show_flip: sbrk failed\n");
 14c:	00001597          	auipc	a1,0x1
 150:	8f458593          	addi	a1,a1,-1804 # a40 <malloc+0x110>
 154:	4509                	li	a0,2
 156:	00000097          	auipc	ra,0x0
 15a:	6ee080e7          	jalr	1774(ra) # 844 <fprintf>
        exit(1);
 15e:	4505                	li	a0,1
 160:	00000097          	auipc	ra,0x0
 164:	38a080e7          	jalr	906(ra) # 4ea <exit>
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
 1f8:	396080e7          	jalr	918(ra) # 58a <flip_display>
 1fc:	00054c63          	bltz	a0,214 <main+0x214>
    }

    // Keep the process alive long enough for the display daemon to flush
    // the image.  Without this, exit() frees the buffer pages immediately
    // and the device reads garbage (visible as a corrupted display).
    sleep(30);
 200:	4579                	li	a0,30
 202:	00000097          	auipc	ra,0x0
 206:	378080e7          	jalr	888(ra) # 57a <sleep>
    exit(0);
 20a:	4501                	li	a0,0
 20c:	00000097          	auipc	ra,0x0
 210:	2de080e7          	jalr	734(ra) # 4ea <exit>
        fprintf(2, "show_flip: flip_display failed\n");
 214:	00001597          	auipc	a1,0x1
 218:	84458593          	addi	a1,a1,-1980 # a58 <malloc+0x128>
 21c:	4509                	li	a0,2
 21e:	00000097          	auipc	ra,0x0
 222:	626080e7          	jalr	1574(ra) # 844 <fprintf>
        exit(1);
 226:	4505                	li	a0,1
 228:	00000097          	auipc	ra,0x0
 22c:	2c2080e7          	jalr	706(ra) # 4ea <exit>
 230:	8a4e                	mv	s4,s3
 232:	47d1                	li	a5,20
 234:	0137d363          	bge	a5,s3,23a <main+0x23a>
 238:	4a51                	li	s4,20
 23a:	000a091b          	sext.w	s2,s4
    memset(fb, 0, FB_BYTES);
 23e:	0012c637          	lui	a2,0x12c
 242:	4581                	li	a1,0
 244:	8526                	mv	a0,s1
 246:	00000097          	auipc	ra,0x0
 24a:	0a8080e7          	jalr	168(ra) # 2ee <memset>
    int text_w = pos * char_w;
 24e:	005a179b          	slliw	a5,s4,0x5
    int x0 = (SCREEN_W - text_w) / 2;
 252:	28000a13          	li	s4,640
 256:	40fa0a3b          	subw	s4,s4,a5
 25a:	4789                	li	a5,2
 25c:	02fa4a3b          	divw	s4,s4,a5
    for (int i = 0; i < pos; i++)
 260:	b571                	j	ec <main+0xec>

0000000000000262 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 262:	1141                	addi	sp,sp,-16
 264:	e406                	sd	ra,8(sp)
 266:	e022                	sd	s0,0(sp)
 268:	0800                	addi	s0,sp,16
  extern int main();
  main();
 26a:	00000097          	auipc	ra,0x0
 26e:	d96080e7          	jalr	-618(ra) # 0 <main>
  exit(0);
 272:	4501                	li	a0,0
 274:	00000097          	auipc	ra,0x0
 278:	276080e7          	jalr	630(ra) # 4ea <exit>

000000000000027c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 27c:	1141                	addi	sp,sp,-16
 27e:	e422                	sd	s0,8(sp)
 280:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 282:	87aa                	mv	a5,a0
 284:	0585                	addi	a1,a1,1
 286:	0785                	addi	a5,a5,1
 288:	fff5c703          	lbu	a4,-1(a1)
 28c:	fee78fa3          	sb	a4,-1(a5)
 290:	fb75                	bnez	a4,284 <strcpy+0x8>
    ;
  return os;
}
 292:	6422                	ld	s0,8(sp)
 294:	0141                	addi	sp,sp,16
 296:	8082                	ret

0000000000000298 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 29e:	00054783          	lbu	a5,0(a0) # 12c000 <base+0x12aff0>
 2a2:	cb91                	beqz	a5,2b6 <strcmp+0x1e>
 2a4:	0005c703          	lbu	a4,0(a1)
 2a8:	00f71763          	bne	a4,a5,2b6 <strcmp+0x1e>
    p++, q++;
 2ac:	0505                	addi	a0,a0,1
 2ae:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2b0:	00054783          	lbu	a5,0(a0)
 2b4:	fbe5                	bnez	a5,2a4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2b6:	0005c503          	lbu	a0,0(a1)
}
 2ba:	40a7853b          	subw	a0,a5,a0
 2be:	6422                	ld	s0,8(sp)
 2c0:	0141                	addi	sp,sp,16
 2c2:	8082                	ret

00000000000002c4 <strlen>:

uint
strlen(const char *s)
{
 2c4:	1141                	addi	sp,sp,-16
 2c6:	e422                	sd	s0,8(sp)
 2c8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2ca:	00054783          	lbu	a5,0(a0)
 2ce:	cf91                	beqz	a5,2ea <strlen+0x26>
 2d0:	0505                	addi	a0,a0,1
 2d2:	87aa                	mv	a5,a0
 2d4:	4685                	li	a3,1
 2d6:	9e89                	subw	a3,a3,a0
 2d8:	00f6853b          	addw	a0,a3,a5
 2dc:	0785                	addi	a5,a5,1
 2de:	fff7c703          	lbu	a4,-1(a5)
 2e2:	fb7d                	bnez	a4,2d8 <strlen+0x14>
    ;
  return n;
}
 2e4:	6422                	ld	s0,8(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret
  for(n = 0; s[n]; n++)
 2ea:	4501                	li	a0,0
 2ec:	bfe5                	j	2e4 <strlen+0x20>

00000000000002ee <memset>:

void*
memset(void *dst, int c, uint n)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2f4:	ca19                	beqz	a2,30a <memset+0x1c>
 2f6:	87aa                	mv	a5,a0
 2f8:	1602                	slli	a2,a2,0x20
 2fa:	9201                	srli	a2,a2,0x20
 2fc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 300:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 304:	0785                	addi	a5,a5,1
 306:	fee79de3          	bne	a5,a4,300 <memset+0x12>
  }
  return dst;
}
 30a:	6422                	ld	s0,8(sp)
 30c:	0141                	addi	sp,sp,16
 30e:	8082                	ret

0000000000000310 <strchr>:

char*
strchr(const char *s, char c)
{
 310:	1141                	addi	sp,sp,-16
 312:	e422                	sd	s0,8(sp)
 314:	0800                	addi	s0,sp,16
  for(; *s; s++)
 316:	00054783          	lbu	a5,0(a0)
 31a:	cb99                	beqz	a5,330 <strchr+0x20>
    if(*s == c)
 31c:	00f58763          	beq	a1,a5,32a <strchr+0x1a>
  for(; *s; s++)
 320:	0505                	addi	a0,a0,1
 322:	00054783          	lbu	a5,0(a0)
 326:	fbfd                	bnez	a5,31c <strchr+0xc>
      return (char*)s;
  return 0;
 328:	4501                	li	a0,0
}
 32a:	6422                	ld	s0,8(sp)
 32c:	0141                	addi	sp,sp,16
 32e:	8082                	ret
  return 0;
 330:	4501                	li	a0,0
 332:	bfe5                	j	32a <strchr+0x1a>

0000000000000334 <gets>:

char*
gets(char *buf, int max)
{
 334:	711d                	addi	sp,sp,-96
 336:	ec86                	sd	ra,88(sp)
 338:	e8a2                	sd	s0,80(sp)
 33a:	e4a6                	sd	s1,72(sp)
 33c:	e0ca                	sd	s2,64(sp)
 33e:	fc4e                	sd	s3,56(sp)
 340:	f852                	sd	s4,48(sp)
 342:	f456                	sd	s5,40(sp)
 344:	f05a                	sd	s6,32(sp)
 346:	ec5e                	sd	s7,24(sp)
 348:	1080                	addi	s0,sp,96
 34a:	8baa                	mv	s7,a0
 34c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 34e:	892a                	mv	s2,a0
 350:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 352:	4aa9                	li	s5,10
 354:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 356:	89a6                	mv	s3,s1
 358:	2485                	addiw	s1,s1,1
 35a:	0344d863          	bge	s1,s4,38a <gets+0x56>
    cc = read(0, &c, 1);
 35e:	4605                	li	a2,1
 360:	faf40593          	addi	a1,s0,-81
 364:	4501                	li	a0,0
 366:	00000097          	auipc	ra,0x0
 36a:	19c080e7          	jalr	412(ra) # 502 <read>
    if(cc < 1)
 36e:	00a05e63          	blez	a0,38a <gets+0x56>
    buf[i++] = c;
 372:	faf44783          	lbu	a5,-81(s0)
 376:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 37a:	01578763          	beq	a5,s5,388 <gets+0x54>
 37e:	0905                	addi	s2,s2,1
 380:	fd679be3          	bne	a5,s6,356 <gets+0x22>
  for(i=0; i+1 < max; ){
 384:	89a6                	mv	s3,s1
 386:	a011                	j	38a <gets+0x56>
 388:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 38a:	99de                	add	s3,s3,s7
 38c:	00098023          	sb	zero,0(s3) # 23000 <base+0x21ff0>
  return buf;
}
 390:	855e                	mv	a0,s7
 392:	60e6                	ld	ra,88(sp)
 394:	6446                	ld	s0,80(sp)
 396:	64a6                	ld	s1,72(sp)
 398:	6906                	ld	s2,64(sp)
 39a:	79e2                	ld	s3,56(sp)
 39c:	7a42                	ld	s4,48(sp)
 39e:	7aa2                	ld	s5,40(sp)
 3a0:	7b02                	ld	s6,32(sp)
 3a2:	6be2                	ld	s7,24(sp)
 3a4:	6125                	addi	sp,sp,96
 3a6:	8082                	ret

00000000000003a8 <stat>:

int
stat(const char *n, struct stat *st)
{
 3a8:	1101                	addi	sp,sp,-32
 3aa:	ec06                	sd	ra,24(sp)
 3ac:	e822                	sd	s0,16(sp)
 3ae:	e426                	sd	s1,8(sp)
 3b0:	e04a                	sd	s2,0(sp)
 3b2:	1000                	addi	s0,sp,32
 3b4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3b6:	4581                	li	a1,0
 3b8:	00000097          	auipc	ra,0x0
 3bc:	172080e7          	jalr	370(ra) # 52a <open>
  if(fd < 0)
 3c0:	02054563          	bltz	a0,3ea <stat+0x42>
 3c4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3c6:	85ca                	mv	a1,s2
 3c8:	00000097          	auipc	ra,0x0
 3cc:	17a080e7          	jalr	378(ra) # 542 <fstat>
 3d0:	892a                	mv	s2,a0
  close(fd);
 3d2:	8526                	mv	a0,s1
 3d4:	00000097          	auipc	ra,0x0
 3d8:	13e080e7          	jalr	318(ra) # 512 <close>
  return r;
}
 3dc:	854a                	mv	a0,s2
 3de:	60e2                	ld	ra,24(sp)
 3e0:	6442                	ld	s0,16(sp)
 3e2:	64a2                	ld	s1,8(sp)
 3e4:	6902                	ld	s2,0(sp)
 3e6:	6105                	addi	sp,sp,32
 3e8:	8082                	ret
    return -1;
 3ea:	597d                	li	s2,-1
 3ec:	bfc5                	j	3dc <stat+0x34>

00000000000003ee <atoi>:

int
atoi(const char *s)
{
 3ee:	1141                	addi	sp,sp,-16
 3f0:	e422                	sd	s0,8(sp)
 3f2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3f4:	00054603          	lbu	a2,0(a0)
 3f8:	fd06079b          	addiw	a5,a2,-48
 3fc:	0ff7f793          	andi	a5,a5,255
 400:	4725                	li	a4,9
 402:	02f76963          	bltu	a4,a5,434 <atoi+0x46>
 406:	86aa                	mv	a3,a0
  n = 0;
 408:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 40a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 40c:	0685                	addi	a3,a3,1
 40e:	0025179b          	slliw	a5,a0,0x2
 412:	9fa9                	addw	a5,a5,a0
 414:	0017979b          	slliw	a5,a5,0x1
 418:	9fb1                	addw	a5,a5,a2
 41a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 41e:	0006c603          	lbu	a2,0(a3)
 422:	fd06071b          	addiw	a4,a2,-48
 426:	0ff77713          	andi	a4,a4,255
 42a:	fee5f1e3          	bgeu	a1,a4,40c <atoi+0x1e>
  return n;
}
 42e:	6422                	ld	s0,8(sp)
 430:	0141                	addi	sp,sp,16
 432:	8082                	ret
  n = 0;
 434:	4501                	li	a0,0
 436:	bfe5                	j	42e <atoi+0x40>

0000000000000438 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 438:	1141                	addi	sp,sp,-16
 43a:	e422                	sd	s0,8(sp)
 43c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 43e:	02b57463          	bgeu	a0,a1,466 <memmove+0x2e>
    while(n-- > 0)
 442:	00c05f63          	blez	a2,460 <memmove+0x28>
 446:	1602                	slli	a2,a2,0x20
 448:	9201                	srli	a2,a2,0x20
 44a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 44e:	872a                	mv	a4,a0
      *dst++ = *src++;
 450:	0585                	addi	a1,a1,1
 452:	0705                	addi	a4,a4,1
 454:	fff5c683          	lbu	a3,-1(a1)
 458:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 45c:	fee79ae3          	bne	a5,a4,450 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 460:	6422                	ld	s0,8(sp)
 462:	0141                	addi	sp,sp,16
 464:	8082                	ret
    dst += n;
 466:	00c50733          	add	a4,a0,a2
    src += n;
 46a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 46c:	fec05ae3          	blez	a2,460 <memmove+0x28>
 470:	fff6079b          	addiw	a5,a2,-1
 474:	1782                	slli	a5,a5,0x20
 476:	9381                	srli	a5,a5,0x20
 478:	fff7c793          	not	a5,a5
 47c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 47e:	15fd                	addi	a1,a1,-1
 480:	177d                	addi	a4,a4,-1
 482:	0005c683          	lbu	a3,0(a1)
 486:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 48a:	fee79ae3          	bne	a5,a4,47e <memmove+0x46>
 48e:	bfc9                	j	460 <memmove+0x28>

0000000000000490 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 490:	1141                	addi	sp,sp,-16
 492:	e422                	sd	s0,8(sp)
 494:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 496:	ca05                	beqz	a2,4c6 <memcmp+0x36>
 498:	fff6069b          	addiw	a3,a2,-1
 49c:	1682                	slli	a3,a3,0x20
 49e:	9281                	srli	a3,a3,0x20
 4a0:	0685                	addi	a3,a3,1
 4a2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4a4:	00054783          	lbu	a5,0(a0)
 4a8:	0005c703          	lbu	a4,0(a1)
 4ac:	00e79863          	bne	a5,a4,4bc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4b0:	0505                	addi	a0,a0,1
    p2++;
 4b2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4b4:	fed518e3          	bne	a0,a3,4a4 <memcmp+0x14>
  }
  return 0;
 4b8:	4501                	li	a0,0
 4ba:	a019                	j	4c0 <memcmp+0x30>
      return *p1 - *p2;
 4bc:	40e7853b          	subw	a0,a5,a4
}
 4c0:	6422                	ld	s0,8(sp)
 4c2:	0141                	addi	sp,sp,16
 4c4:	8082                	ret
  return 0;
 4c6:	4501                	li	a0,0
 4c8:	bfe5                	j	4c0 <memcmp+0x30>

00000000000004ca <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4ca:	1141                	addi	sp,sp,-16
 4cc:	e406                	sd	ra,8(sp)
 4ce:	e022                	sd	s0,0(sp)
 4d0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4d2:	00000097          	auipc	ra,0x0
 4d6:	f66080e7          	jalr	-154(ra) # 438 <memmove>
}
 4da:	60a2                	ld	ra,8(sp)
 4dc:	6402                	ld	s0,0(sp)
 4de:	0141                	addi	sp,sp,16
 4e0:	8082                	ret

00000000000004e2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4e2:	4885                	li	a7,1
 ecall
 4e4:	00000073          	ecall
 ret
 4e8:	8082                	ret

00000000000004ea <exit>:
.global exit
exit:
 li a7, SYS_exit
 4ea:	4889                	li	a7,2
 ecall
 4ec:	00000073          	ecall
 ret
 4f0:	8082                	ret

00000000000004f2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4f2:	488d                	li	a7,3
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4fa:	4891                	li	a7,4
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <read>:
.global read
read:
 li a7, SYS_read
 502:	4895                	li	a7,5
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <write>:
.global write
write:
 li a7, SYS_write
 50a:	48c1                	li	a7,16
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <close>:
.global close
close:
 li a7, SYS_close
 512:	48d5                	li	a7,21
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <kill>:
.global kill
kill:
 li a7, SYS_kill
 51a:	4899                	li	a7,6
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <exec>:
.global exec
exec:
 li a7, SYS_exec
 522:	489d                	li	a7,7
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <open>:
.global open
open:
 li a7, SYS_open
 52a:	48bd                	li	a7,15
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 532:	48c5                	li	a7,17
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 53a:	48c9                	li	a7,18
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 542:	48a1                	li	a7,8
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <link>:
.global link
link:
 li a7, SYS_link
 54a:	48cd                	li	a7,19
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 552:	48d1                	li	a7,20
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 55a:	48a5                	li	a7,9
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <dup>:
.global dup
dup:
 li a7, SYS_dup
 562:	48a9                	li	a7,10
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 56a:	48ad                	li	a7,11
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 572:	48b1                	li	a7,12
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 57a:	48b5                	li	a7,13
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 582:	48b9                	li	a7,14
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <flip_display>:
.global flip_display
flip_display:
 li a7, SYS_flip_display
 58a:	48d9                	li	a7,22
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <map_display>:
.global map_display
map_display:
 li a7, SYS_map_display
 592:	48dd                	li	a7,23
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 59a:	1101                	addi	sp,sp,-32
 59c:	ec06                	sd	ra,24(sp)
 59e:	e822                	sd	s0,16(sp)
 5a0:	1000                	addi	s0,sp,32
 5a2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5a6:	4605                	li	a2,1
 5a8:	fef40593          	addi	a1,s0,-17
 5ac:	00000097          	auipc	ra,0x0
 5b0:	f5e080e7          	jalr	-162(ra) # 50a <write>
}
 5b4:	60e2                	ld	ra,24(sp)
 5b6:	6442                	ld	s0,16(sp)
 5b8:	6105                	addi	sp,sp,32
 5ba:	8082                	ret

00000000000005bc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5bc:	7139                	addi	sp,sp,-64
 5be:	fc06                	sd	ra,56(sp)
 5c0:	f822                	sd	s0,48(sp)
 5c2:	f426                	sd	s1,40(sp)
 5c4:	f04a                	sd	s2,32(sp)
 5c6:	ec4e                	sd	s3,24(sp)
 5c8:	0080                	addi	s0,sp,64
 5ca:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5cc:	c299                	beqz	a3,5d2 <printint+0x16>
 5ce:	0805c863          	bltz	a1,65e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5d2:	2581                	sext.w	a1,a1
  neg = 0;
 5d4:	4881                	li	a7,0
 5d6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5da:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5dc:	2601                	sext.w	a2,a2
 5de:	00001517          	auipc	a0,0x1
 5e2:	8a250513          	addi	a0,a0,-1886 # e80 <digits>
 5e6:	883a                	mv	a6,a4
 5e8:	2705                	addiw	a4,a4,1
 5ea:	02c5f7bb          	remuw	a5,a1,a2
 5ee:	1782                	slli	a5,a5,0x20
 5f0:	9381                	srli	a5,a5,0x20
 5f2:	97aa                	add	a5,a5,a0
 5f4:	0007c783          	lbu	a5,0(a5)
 5f8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5fc:	0005879b          	sext.w	a5,a1
 600:	02c5d5bb          	divuw	a1,a1,a2
 604:	0685                	addi	a3,a3,1
 606:	fec7f0e3          	bgeu	a5,a2,5e6 <printint+0x2a>
  if(neg)
 60a:	00088b63          	beqz	a7,620 <printint+0x64>
    buf[i++] = '-';
 60e:	fd040793          	addi	a5,s0,-48
 612:	973e                	add	a4,a4,a5
 614:	02d00793          	li	a5,45
 618:	fef70823          	sb	a5,-16(a4)
 61c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 620:	02e05863          	blez	a4,650 <printint+0x94>
 624:	fc040793          	addi	a5,s0,-64
 628:	00e78933          	add	s2,a5,a4
 62c:	fff78993          	addi	s3,a5,-1
 630:	99ba                	add	s3,s3,a4
 632:	377d                	addiw	a4,a4,-1
 634:	1702                	slli	a4,a4,0x20
 636:	9301                	srli	a4,a4,0x20
 638:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 63c:	fff94583          	lbu	a1,-1(s2)
 640:	8526                	mv	a0,s1
 642:	00000097          	auipc	ra,0x0
 646:	f58080e7          	jalr	-168(ra) # 59a <putc>
  while(--i >= 0)
 64a:	197d                	addi	s2,s2,-1
 64c:	ff3918e3          	bne	s2,s3,63c <printint+0x80>
}
 650:	70e2                	ld	ra,56(sp)
 652:	7442                	ld	s0,48(sp)
 654:	74a2                	ld	s1,40(sp)
 656:	7902                	ld	s2,32(sp)
 658:	69e2                	ld	s3,24(sp)
 65a:	6121                	addi	sp,sp,64
 65c:	8082                	ret
    x = -xx;
 65e:	40b005bb          	negw	a1,a1
    neg = 1;
 662:	4885                	li	a7,1
    x = -xx;
 664:	bf8d                	j	5d6 <printint+0x1a>

0000000000000666 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 666:	7119                	addi	sp,sp,-128
 668:	fc86                	sd	ra,120(sp)
 66a:	f8a2                	sd	s0,112(sp)
 66c:	f4a6                	sd	s1,104(sp)
 66e:	f0ca                	sd	s2,96(sp)
 670:	ecce                	sd	s3,88(sp)
 672:	e8d2                	sd	s4,80(sp)
 674:	e4d6                	sd	s5,72(sp)
 676:	e0da                	sd	s6,64(sp)
 678:	fc5e                	sd	s7,56(sp)
 67a:	f862                	sd	s8,48(sp)
 67c:	f466                	sd	s9,40(sp)
 67e:	f06a                	sd	s10,32(sp)
 680:	ec6e                	sd	s11,24(sp)
 682:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 684:	0005c903          	lbu	s2,0(a1)
 688:	18090f63          	beqz	s2,826 <vprintf+0x1c0>
 68c:	8aaa                	mv	s5,a0
 68e:	8b32                	mv	s6,a2
 690:	00158493          	addi	s1,a1,1
  state = 0;
 694:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 696:	02500a13          	li	s4,37
      if(c == 'd'){
 69a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 69e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6a2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6a6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6aa:	00000b97          	auipc	s7,0x0
 6ae:	7d6b8b93          	addi	s7,s7,2006 # e80 <digits>
 6b2:	a839                	j	6d0 <vprintf+0x6a>
        putc(fd, c);
 6b4:	85ca                	mv	a1,s2
 6b6:	8556                	mv	a0,s5
 6b8:	00000097          	auipc	ra,0x0
 6bc:	ee2080e7          	jalr	-286(ra) # 59a <putc>
 6c0:	a019                	j	6c6 <vprintf+0x60>
    } else if(state == '%'){
 6c2:	01498f63          	beq	s3,s4,6e0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6c6:	0485                	addi	s1,s1,1
 6c8:	fff4c903          	lbu	s2,-1(s1)
 6cc:	14090d63          	beqz	s2,826 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6d0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6d4:	fe0997e3          	bnez	s3,6c2 <vprintf+0x5c>
      if(c == '%'){
 6d8:	fd479ee3          	bne	a5,s4,6b4 <vprintf+0x4e>
        state = '%';
 6dc:	89be                	mv	s3,a5
 6de:	b7e5                	j	6c6 <vprintf+0x60>
      if(c == 'd'){
 6e0:	05878063          	beq	a5,s8,720 <vprintf+0xba>
      } else if(c == 'l') {
 6e4:	05978c63          	beq	a5,s9,73c <vprintf+0xd6>
      } else if(c == 'x') {
 6e8:	07a78863          	beq	a5,s10,758 <vprintf+0xf2>
      } else if(c == 'p') {
 6ec:	09b78463          	beq	a5,s11,774 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6f0:	07300713          	li	a4,115
 6f4:	0ce78663          	beq	a5,a4,7c0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6f8:	06300713          	li	a4,99
 6fc:	0ee78e63          	beq	a5,a4,7f8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 700:	11478863          	beq	a5,s4,810 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 704:	85d2                	mv	a1,s4
 706:	8556                	mv	a0,s5
 708:	00000097          	auipc	ra,0x0
 70c:	e92080e7          	jalr	-366(ra) # 59a <putc>
        putc(fd, c);
 710:	85ca                	mv	a1,s2
 712:	8556                	mv	a0,s5
 714:	00000097          	auipc	ra,0x0
 718:	e86080e7          	jalr	-378(ra) # 59a <putc>
      }
      state = 0;
 71c:	4981                	li	s3,0
 71e:	b765                	j	6c6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 720:	008b0913          	addi	s2,s6,8 # 1008 <freep+0x8>
 724:	4685                	li	a3,1
 726:	4629                	li	a2,10
 728:	000b2583          	lw	a1,0(s6)
 72c:	8556                	mv	a0,s5
 72e:	00000097          	auipc	ra,0x0
 732:	e8e080e7          	jalr	-370(ra) # 5bc <printint>
 736:	8b4a                	mv	s6,s2
      state = 0;
 738:	4981                	li	s3,0
 73a:	b771                	j	6c6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 73c:	008b0913          	addi	s2,s6,8
 740:	4681                	li	a3,0
 742:	4629                	li	a2,10
 744:	000b2583          	lw	a1,0(s6)
 748:	8556                	mv	a0,s5
 74a:	00000097          	auipc	ra,0x0
 74e:	e72080e7          	jalr	-398(ra) # 5bc <printint>
 752:	8b4a                	mv	s6,s2
      state = 0;
 754:	4981                	li	s3,0
 756:	bf85                	j	6c6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 758:	008b0913          	addi	s2,s6,8
 75c:	4681                	li	a3,0
 75e:	4641                	li	a2,16
 760:	000b2583          	lw	a1,0(s6)
 764:	8556                	mv	a0,s5
 766:	00000097          	auipc	ra,0x0
 76a:	e56080e7          	jalr	-426(ra) # 5bc <printint>
 76e:	8b4a                	mv	s6,s2
      state = 0;
 770:	4981                	li	s3,0
 772:	bf91                	j	6c6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 774:	008b0793          	addi	a5,s6,8
 778:	f8f43423          	sd	a5,-120(s0)
 77c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 780:	03000593          	li	a1,48
 784:	8556                	mv	a0,s5
 786:	00000097          	auipc	ra,0x0
 78a:	e14080e7          	jalr	-492(ra) # 59a <putc>
  putc(fd, 'x');
 78e:	85ea                	mv	a1,s10
 790:	8556                	mv	a0,s5
 792:	00000097          	auipc	ra,0x0
 796:	e08080e7          	jalr	-504(ra) # 59a <putc>
 79a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 79c:	03c9d793          	srli	a5,s3,0x3c
 7a0:	97de                	add	a5,a5,s7
 7a2:	0007c583          	lbu	a1,0(a5)
 7a6:	8556                	mv	a0,s5
 7a8:	00000097          	auipc	ra,0x0
 7ac:	df2080e7          	jalr	-526(ra) # 59a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7b0:	0992                	slli	s3,s3,0x4
 7b2:	397d                	addiw	s2,s2,-1
 7b4:	fe0914e3          	bnez	s2,79c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7b8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7bc:	4981                	li	s3,0
 7be:	b721                	j	6c6 <vprintf+0x60>
        s = va_arg(ap, char*);
 7c0:	008b0993          	addi	s3,s6,8
 7c4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7c8:	02090163          	beqz	s2,7ea <vprintf+0x184>
        while(*s != 0){
 7cc:	00094583          	lbu	a1,0(s2)
 7d0:	c9a1                	beqz	a1,820 <vprintf+0x1ba>
          putc(fd, *s);
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	dc6080e7          	jalr	-570(ra) # 59a <putc>
          s++;
 7dc:	0905                	addi	s2,s2,1
        while(*s != 0){
 7de:	00094583          	lbu	a1,0(s2)
 7e2:	f9e5                	bnez	a1,7d2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7e4:	8b4e                	mv	s6,s3
      state = 0;
 7e6:	4981                	li	s3,0
 7e8:	bdf9                	j	6c6 <vprintf+0x60>
          s = "(null)";
 7ea:	00000917          	auipc	s2,0x0
 7ee:	68e90913          	addi	s2,s2,1678 # e78 <font8x8+0x400>
        while(*s != 0){
 7f2:	02800593          	li	a1,40
 7f6:	bff1                	j	7d2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7f8:	008b0913          	addi	s2,s6,8
 7fc:	000b4583          	lbu	a1,0(s6)
 800:	8556                	mv	a0,s5
 802:	00000097          	auipc	ra,0x0
 806:	d98080e7          	jalr	-616(ra) # 59a <putc>
 80a:	8b4a                	mv	s6,s2
      state = 0;
 80c:	4981                	li	s3,0
 80e:	bd65                	j	6c6 <vprintf+0x60>
        putc(fd, c);
 810:	85d2                	mv	a1,s4
 812:	8556                	mv	a0,s5
 814:	00000097          	auipc	ra,0x0
 818:	d86080e7          	jalr	-634(ra) # 59a <putc>
      state = 0;
 81c:	4981                	li	s3,0
 81e:	b565                	j	6c6 <vprintf+0x60>
        s = va_arg(ap, char*);
 820:	8b4e                	mv	s6,s3
      state = 0;
 822:	4981                	li	s3,0
 824:	b54d                	j	6c6 <vprintf+0x60>
    }
  }
}
 826:	70e6                	ld	ra,120(sp)
 828:	7446                	ld	s0,112(sp)
 82a:	74a6                	ld	s1,104(sp)
 82c:	7906                	ld	s2,96(sp)
 82e:	69e6                	ld	s3,88(sp)
 830:	6a46                	ld	s4,80(sp)
 832:	6aa6                	ld	s5,72(sp)
 834:	6b06                	ld	s6,64(sp)
 836:	7be2                	ld	s7,56(sp)
 838:	7c42                	ld	s8,48(sp)
 83a:	7ca2                	ld	s9,40(sp)
 83c:	7d02                	ld	s10,32(sp)
 83e:	6de2                	ld	s11,24(sp)
 840:	6109                	addi	sp,sp,128
 842:	8082                	ret

0000000000000844 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 844:	715d                	addi	sp,sp,-80
 846:	ec06                	sd	ra,24(sp)
 848:	e822                	sd	s0,16(sp)
 84a:	1000                	addi	s0,sp,32
 84c:	e010                	sd	a2,0(s0)
 84e:	e414                	sd	a3,8(s0)
 850:	e818                	sd	a4,16(s0)
 852:	ec1c                	sd	a5,24(s0)
 854:	03043023          	sd	a6,32(s0)
 858:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 85c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 860:	8622                	mv	a2,s0
 862:	00000097          	auipc	ra,0x0
 866:	e04080e7          	jalr	-508(ra) # 666 <vprintf>
}
 86a:	60e2                	ld	ra,24(sp)
 86c:	6442                	ld	s0,16(sp)
 86e:	6161                	addi	sp,sp,80
 870:	8082                	ret

0000000000000872 <printf>:

void
printf(const char *fmt, ...)
{
 872:	711d                	addi	sp,sp,-96
 874:	ec06                	sd	ra,24(sp)
 876:	e822                	sd	s0,16(sp)
 878:	1000                	addi	s0,sp,32
 87a:	e40c                	sd	a1,8(s0)
 87c:	e810                	sd	a2,16(s0)
 87e:	ec14                	sd	a3,24(s0)
 880:	f018                	sd	a4,32(s0)
 882:	f41c                	sd	a5,40(s0)
 884:	03043823          	sd	a6,48(s0)
 888:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 88c:	00840613          	addi	a2,s0,8
 890:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 894:	85aa                	mv	a1,a0
 896:	4505                	li	a0,1
 898:	00000097          	auipc	ra,0x0
 89c:	dce080e7          	jalr	-562(ra) # 666 <vprintf>
}
 8a0:	60e2                	ld	ra,24(sp)
 8a2:	6442                	ld	s0,16(sp)
 8a4:	6125                	addi	sp,sp,96
 8a6:	8082                	ret

00000000000008a8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8a8:	1141                	addi	sp,sp,-16
 8aa:	e422                	sd	s0,8(sp)
 8ac:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8ae:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8b2:	00000797          	auipc	a5,0x0
 8b6:	74e7b783          	ld	a5,1870(a5) # 1000 <freep>
 8ba:	a805                	j	8ea <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8bc:	4618                	lw	a4,8(a2)
 8be:	9db9                	addw	a1,a1,a4
 8c0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8c4:	6398                	ld	a4,0(a5)
 8c6:	6318                	ld	a4,0(a4)
 8c8:	fee53823          	sd	a4,-16(a0)
 8cc:	a091                	j	910 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8ce:	ff852703          	lw	a4,-8(a0)
 8d2:	9e39                	addw	a2,a2,a4
 8d4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8d6:	ff053703          	ld	a4,-16(a0)
 8da:	e398                	sd	a4,0(a5)
 8dc:	a099                	j	922 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8de:	6398                	ld	a4,0(a5)
 8e0:	00e7e463          	bltu	a5,a4,8e8 <free+0x40>
 8e4:	00e6ea63          	bltu	a3,a4,8f8 <free+0x50>
{
 8e8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8ea:	fed7fae3          	bgeu	a5,a3,8de <free+0x36>
 8ee:	6398                	ld	a4,0(a5)
 8f0:	00e6e463          	bltu	a3,a4,8f8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8f4:	fee7eae3          	bltu	a5,a4,8e8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8f8:	ff852583          	lw	a1,-8(a0)
 8fc:	6390                	ld	a2,0(a5)
 8fe:	02059713          	slli	a4,a1,0x20
 902:	9301                	srli	a4,a4,0x20
 904:	0712                	slli	a4,a4,0x4
 906:	9736                	add	a4,a4,a3
 908:	fae60ae3          	beq	a2,a4,8bc <free+0x14>
    bp->s.ptr = p->s.ptr;
 90c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 910:	4790                	lw	a2,8(a5)
 912:	02061713          	slli	a4,a2,0x20
 916:	9301                	srli	a4,a4,0x20
 918:	0712                	slli	a4,a4,0x4
 91a:	973e                	add	a4,a4,a5
 91c:	fae689e3          	beq	a3,a4,8ce <free+0x26>
  } else
    p->s.ptr = bp;
 920:	e394                	sd	a3,0(a5)
  freep = p;
 922:	00000717          	auipc	a4,0x0
 926:	6cf73f23          	sd	a5,1758(a4) # 1000 <freep>
}
 92a:	6422                	ld	s0,8(sp)
 92c:	0141                	addi	sp,sp,16
 92e:	8082                	ret

0000000000000930 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 930:	7139                	addi	sp,sp,-64
 932:	fc06                	sd	ra,56(sp)
 934:	f822                	sd	s0,48(sp)
 936:	f426                	sd	s1,40(sp)
 938:	f04a                	sd	s2,32(sp)
 93a:	ec4e                	sd	s3,24(sp)
 93c:	e852                	sd	s4,16(sp)
 93e:	e456                	sd	s5,8(sp)
 940:	e05a                	sd	s6,0(sp)
 942:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 944:	02051493          	slli	s1,a0,0x20
 948:	9081                	srli	s1,s1,0x20
 94a:	04bd                	addi	s1,s1,15
 94c:	8091                	srli	s1,s1,0x4
 94e:	0014899b          	addiw	s3,s1,1
 952:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 954:	00000517          	auipc	a0,0x0
 958:	6ac53503          	ld	a0,1708(a0) # 1000 <freep>
 95c:	c515                	beqz	a0,988 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 95e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 960:	4798                	lw	a4,8(a5)
 962:	02977f63          	bgeu	a4,s1,9a0 <malloc+0x70>
 966:	8a4e                	mv	s4,s3
 968:	0009871b          	sext.w	a4,s3
 96c:	6685                	lui	a3,0x1
 96e:	00d77363          	bgeu	a4,a3,974 <malloc+0x44>
 972:	6a05                	lui	s4,0x1
 974:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 978:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 97c:	00000917          	auipc	s2,0x0
 980:	68490913          	addi	s2,s2,1668 # 1000 <freep>
  if(p == (char*)-1)
 984:	5afd                	li	s5,-1
 986:	a88d                	j	9f8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 988:	00000797          	auipc	a5,0x0
 98c:	68878793          	addi	a5,a5,1672 # 1010 <base>
 990:	00000717          	auipc	a4,0x0
 994:	66f73823          	sd	a5,1648(a4) # 1000 <freep>
 998:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 99a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 99e:	b7e1                	j	966 <malloc+0x36>
      if(p->s.size == nunits)
 9a0:	02e48b63          	beq	s1,a4,9d6 <malloc+0xa6>
        p->s.size -= nunits;
 9a4:	4137073b          	subw	a4,a4,s3
 9a8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9aa:	1702                	slli	a4,a4,0x20
 9ac:	9301                	srli	a4,a4,0x20
 9ae:	0712                	slli	a4,a4,0x4
 9b0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9b2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9b6:	00000717          	auipc	a4,0x0
 9ba:	64a73523          	sd	a0,1610(a4) # 1000 <freep>
      return (void*)(p + 1);
 9be:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9c2:	70e2                	ld	ra,56(sp)
 9c4:	7442                	ld	s0,48(sp)
 9c6:	74a2                	ld	s1,40(sp)
 9c8:	7902                	ld	s2,32(sp)
 9ca:	69e2                	ld	s3,24(sp)
 9cc:	6a42                	ld	s4,16(sp)
 9ce:	6aa2                	ld	s5,8(sp)
 9d0:	6b02                	ld	s6,0(sp)
 9d2:	6121                	addi	sp,sp,64
 9d4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9d6:	6398                	ld	a4,0(a5)
 9d8:	e118                	sd	a4,0(a0)
 9da:	bff1                	j	9b6 <malloc+0x86>
  hp->s.size = nu;
 9dc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9e0:	0541                	addi	a0,a0,16
 9e2:	00000097          	auipc	ra,0x0
 9e6:	ec6080e7          	jalr	-314(ra) # 8a8 <free>
  return freep;
 9ea:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9ee:	d971                	beqz	a0,9c2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9f0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9f2:	4798                	lw	a4,8(a5)
 9f4:	fa9776e3          	bgeu	a4,s1,9a0 <malloc+0x70>
    if(p == freep)
 9f8:	00093703          	ld	a4,0(s2)
 9fc:	853e                	mv	a0,a5
 9fe:	fef719e3          	bne	a4,a5,9f0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a02:	8552                	mv	a0,s4
 a04:	00000097          	auipc	ra,0x0
 a08:	b6e080e7          	jalr	-1170(ra) # 572 <sbrk>
  if(p == (char*)-1)
 a0c:	fd5518e3          	bne	a0,s5,9dc <malloc+0xac>
        return 0;
 a10:	4501                	li	a0,0
 a12:	bf45                	j	9c2 <malloc+0x92>
