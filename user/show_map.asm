
user/_show_map:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
        draw_char(fb, x0 + i * char_w, y0, (unsigned char)text[i]);
}

// ── main ──────────────────────────────────────────────────────────────
int main(void)
{
   0:	7149                	addi	sp,sp,-368
   2:	f686                	sd	ra,360(sp)
   4:	f2a2                	sd	s0,352(sp)
   6:	eea6                	sd	s1,344(sp)
   8:	eaca                	sd	s2,336(sp)
   a:	e6ce                	sd	s3,328(sp)
   c:	e2d2                	sd	s4,320(sp)
   e:	fe56                	sd	s5,312(sp)
  10:	fa5a                	sd	s6,304(sp)
  12:	f65e                	sd	s7,296(sp)
  14:	f262                	sd	s8,288(sp)
  16:	ee66                	sd	s9,280(sp)
  18:	ea6a                	sd	s10,272(sp)
  1a:	e66e                	sd	s11,264(sp)
  1c:	1a80                	addi	s0,sp,368
    // installs PTEs at this VA pointing at the GPU's physical fb[] pages
    // (PTE_U|PTE_R|PTE_W).  No pixel data is moved.
    //
    // Passing 0 instead would let the kernel auto-pick a free VA.
    void *want_addr = (void *)0x10000000;
    uint32 *fb = (uint32 *)map_display(want_addr);
  1e:	10000537          	lui	a0,0x10000
  22:	00000097          	auipc	ra,0x0
  26:	572080e7          	jalr	1394(ra) # 594 <map_display>
    if (fb == (uint32 *)(uint64)-1 || fb == 0)
  2a:	fff50713          	addi	a4,a0,-1 # fffffff <base+0xfffefef>
  2e:	57f5                	li	a5,-3
  30:	02e7f063          	bgeu	a5,a4,50 <main+0x50>
    {
        fprintf(2, "show_map: map_display failed\n");
  34:	00001597          	auipc	a1,0x1
  38:	9ec58593          	addi	a1,a1,-1556 # a20 <malloc+0xee>
  3c:	4509                	li	a0,2
  3e:	00001097          	auipc	ra,0x1
  42:	808080e7          	jalr	-2040(ra) # 846 <fprintf>
        exit(1);
  46:	4505                	li	a0,1
  48:	00000097          	auipc	ra,0x0
  4c:	4a4080e7          	jalr	1188(ra) # 4ec <exit>
  50:	89aa                	mv	s3,a0
    }

    // ── 2. Initial clear ──────────────────────────────────────────────
    memset(fb, 0, FB_BYTES);
  52:	0012c637          	lui	a2,0x12c
  56:	4581                	li	a1,0
  58:	00000097          	auipc	ra,0x0
  5c:	298080e7          	jalr	664(ra) # 2f0 <memset>
    // (daemon will flush within ~16 ms)

    printf("show_map: type text and press Enter to display it.\n");
  60:	00001517          	auipc	a0,0x1
  64:	9e050513          	addi	a0,a0,-1568 # a40 <malloc+0x10e>
  68:	00001097          	auipc	ra,0x1
  6c:	80c080e7          	jalr	-2036(ra) # 874 <printf>
    printf("          Type 'exit' to clear the screen and quit.\n");
  70:	00001517          	auipc	a0,0x1
  74:	a0850513          	addi	a0,a0,-1528 # a78 <malloc+0x146>
  78:	00000097          	auipc	ra,0x0
  7c:	7fc080e7          	jalr	2044(ra) # 874 <printf>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
  80:	01000937          	lui	s2,0x1000
  84:	197d                	addi	s2,s2,-1
            for (int dy = 0; dy < SCALE; dy++)
  86:	6485                	lui	s1,0x1
  88:	a0048493          	addi	s1,s1,-1536 # a00 <malloc+0xce>

    // ── 3. Interactive loop ───────────────────────────────────────────
    char line[256];
    while (1)
    {
        printf("> ");
  8c:	00001517          	auipc	a0,0x1
  90:	a2450513          	addi	a0,a0,-1500 # ab0 <malloc+0x17e>
  94:	00000097          	auipc	ra,0x0
  98:	7e0080e7          	jalr	2016(ra) # 874 <printf>

        // gets() reads from stdin until '\n' or max-1 chars.
        if (gets(line, sizeof(line)) == 0)
  9c:	10000593          	li	a1,256
  a0:	e9040513          	addi	a0,s0,-368
  a4:	00000097          	auipc	ra,0x0
  a8:	292080e7          	jalr	658(ra) # 336 <gets>
  ac:	18050f63          	beqz	a0,24a <main+0x24a>
            break; // EOF (e.g. stdin closed)

        // Strip trailing newline.
        int len = strlen(line);
  b0:	e9040513          	addi	a0,s0,-368
  b4:	00000097          	auipc	ra,0x0
  b8:	212080e7          	jalr	530(ra) # 2c6 <strlen>
  bc:	00050a1b          	sext.w	s4,a0
        if (len > 0 && line[len - 1] == '\n')
  c0:	17405a63          	blez	s4,234 <main+0x234>
  c4:	fffa0b1b          	addiw	s6,s4,-1
  c8:	000b0a9b          	sext.w	s5,s6
  cc:	f9040793          	addi	a5,s0,-112
  d0:	97d6                	add	a5,a5,s5
  d2:	f007c703          	lbu	a4,-256(a5)
  d6:	47a9                	li	a5,10
  d8:	04f70663          	beq	a4,a5,124 <main+0x124>
            line[--len] = '\0';

        if (strcmp(line, "exit") == 0)
  dc:	00001597          	auipc	a1,0x1
  e0:	9dc58593          	addi	a1,a1,-1572 # ab8 <malloc+0x186>
  e4:	e9040513          	addi	a0,s0,-368
  e8:	00000097          	auipc	ra,0x0
  ec:	1b2080e7          	jalr	434(ra) # 29a <strcmp>
  f0:	14050d63          	beqz	a0,24a <main+0x24a>
            break;

        // ── Render entirely in user space ─────────────────────────────
        memset(fb, 0, FB_BYTES);
  f4:	0012c637          	lui	a2,0x12c
  f8:	4581                	li	a1,0
  fa:	854e                	mv	a0,s3
  fc:	00000097          	auipc	ra,0x0
 100:	1f4080e7          	jalr	500(ra) # 2f0 <memset>
    if (len > max_chars)
 104:	87d2                	mv	a5,s4
 106:	4751                	li	a4,20
 108:	01475363          	bge	a4,s4,10e <main+0x10e>
 10c:	47d1                	li	a5,20
 10e:	00078c9b          	sext.w	s9,a5
    int x0 = (SCREEN_W - len * char_w) / 2;
 112:	0057979b          	slliw	a5,a5,0x5
 116:	28000f13          	li	t5,640
 11a:	40ff0f3b          	subw	t5,t5,a5
 11e:	401f5f1b          	sraiw	t5,t5,0x1
    for (int i = 0; i < len; i++)
 122:	a899                	j	178 <main+0x178>
            line[--len] = '\0';
 124:	f9040793          	addi	a5,s0,-112
 128:	97d6                	add	a5,a5,s5
 12a:	f0078023          	sb	zero,-256(a5)
        if (strcmp(line, "exit") == 0)
 12e:	00001597          	auipc	a1,0x1
 132:	98a58593          	addi	a1,a1,-1654 # ab8 <malloc+0x186>
 136:	e9040513          	addi	a0,s0,-368
 13a:	00000097          	auipc	ra,0x0
 13e:	160080e7          	jalr	352(ra) # 29a <strcmp>
 142:	10050463          	beqz	a0,24a <main+0x24a>
        memset(fb, 0, FB_BYTES);
 146:	0012c637          	lui	a2,0x12c
 14a:	4581                	li	a1,0
 14c:	854e                	mv	a0,s3
 14e:	00000097          	auipc	ra,0x0
 152:	1a2080e7          	jalr	418(ra) # 2f0 <memset>
    if (len > max_chars)
 156:	87da                	mv	a5,s6
 158:	4751                	li	a4,20
 15a:	01575363          	bge	a4,s5,160 <main+0x160>
 15e:	47d1                	li	a5,20
 160:	00078c9b          	sext.w	s9,a5
    int x0 = (SCREEN_W - len * char_w) / 2;
 164:	0057979b          	slliw	a5,a5,0x5
 168:	28000f13          	li	t5,640
 16c:	40ff0f3b          	subw	t5,t5,a5
 170:	401f5f1b          	sraiw	t5,t5,0x1
    for (int i = 0; i < len; i++)
 174:	f1505ce3          	blez	s5,8c <main+0x8c>
 178:	e9040c13          	addi	s8,s0,-368
{
 17c:	4b81                	li	s7,0
    if (ch < 0x20 || ch >= 0x7F)
 17e:	05e00d93          	li	s11,94
 182:	0008cb37          	lui	s6,0x8c
 186:	9b4e                	add	s6,s6,s3
    const uint8 *rows = font8x8[ch];
 188:	00001d17          	auipc	s10,0x1
 18c:	938d0d13          	addi	s10,s10,-1736 # ac0 <font8x8>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 190:	4a91                	li	s5,4
        for (int col = 0; col < 8; col++)
 192:	40a1                	li	ra,8
    for (int row = 0; row < 8; row++)
 194:	638d                	lui	t2,0x3
 196:	80038393          	addi	t2,t2,-2048 # 2800 <base+0x17f0>
 19a:	10000a13          	li	s4,256
 19e:	a8a9                	j	1f8 <main+0x1f8>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 1a0:	88fe                	mv	a7,t6
 1a2:	882e                	mv	a6,a1
 1a4:	86c2                	mv	a3,a6
 1a6:	8756                	mv	a4,s5
    fb[y * SCREEN_W + x] = color;
 1a8:	c29c                	sw	a5,0(a3)
                for (int dx = 0; dx < SCALE; dx++)
 1aa:	377d                	addiw	a4,a4,-1
 1ac:	0691                	addi	a3,a3,4
 1ae:	ff6d                	bnez	a4,1a8 <main+0x1a8>
            for (int dy = 0; dy < SCALE; dy++)
 1b0:	9826                	add	a6,a6,s1
 1b2:	2808889b          	addiw	a7,a7,640
 1b6:	ff1297e3          	bne	t0,a7,1a4 <main+0x1a4>
        for (int col = 0; col < 8; col++)
 1ba:	2605                	addiw	a2,a2,1
 1bc:	05c1                	addi	a1,a1,16
 1be:	00160a63          	beq	a2,ra,1d2 <main+0x1d2>
            uint32 color = (rows[row] & (1u << col)) ? COLOR_FG : COLOR_BG;
 1c2:	00054783          	lbu	a5,0(a0)
 1c6:	00c7d7bb          	srlw	a5,a5,a2
 1ca:	8b85                	andi	a5,a5,1
 1cc:	dbf1                	beqz	a5,1a0 <main+0x1a0>
 1ce:	87ca                	mv	a5,s2
 1d0:	bfc1                	j	1a0 <main+0x1a0>
    for (int row = 0; row < 8; row++)
 1d2:	2e91                	addiw	t4,t4,4
 1d4:	9326                	add	t1,t1,s1
 1d6:	9e1e                	add	t3,t3,t2
 1d8:	0505                	addi	a0,a0,1
 1da:	014e8963          	beq	t4,s4,1ec <main+0x1ec>
        ch = '?';
 1de:	85f2                	mv	a1,t3
        for (int col = 0; col < 8; col++)
 1e0:	4601                	li	a2,0
 1e2:	00030f9b          	sext.w	t6,t1
            for (int dy = 0; dy < SCALE; dy++)
 1e6:	009302bb          	addw	t0,t1,s1
 1ea:	bfe1                	j	1c2 <main+0x1c2>
    for (int i = 0; i < len; i++)
 1ec:	2b85                	addiw	s7,s7,1
 1ee:	0c05                	addi	s8,s8,1
 1f0:	020f0f13          	addi	t5,t5,32
 1f4:	e99bdce3          	bge	s7,s9,8c <main+0x8c>
        draw_char(fb, x0 + i * char_w, y0, (unsigned char)text[i]);
 1f8:	000c4783          	lbu	a5,0(s8)
    if (ch < 0x20 || ch >= 0x7F)
 1fc:	fe07871b          	addiw	a4,a5,-32
 200:	0ff77713          	andi	a4,a4,255
 204:	00edf463          	bgeu	s11,a4,20c <main+0x20c>
        ch = '?';
 208:	03f00793          	li	a5,63
    for (int row = 0; row < 8; row++)
 20c:	002f1e13          	slli	t3,t5,0x2
 210:	9e5a                	add	t3,t3,s6
    const uint8 *rows = font8x8[ch];
 212:	078e                	slli	a5,a5,0x3
 214:	00fd0533          	add	a0,s10,a5
 218:	00023337          	lui	t1,0x23
 21c:	0e000e93          	li	t4,224
 220:	bf7d                	j	1de <main+0x1de>
        memset(fb, 0, FB_BYTES);
 222:	0012c637          	lui	a2,0x12c
 226:	4581                	li	a1,0
 228:	854e                	mv	a0,s3
 22a:	00000097          	auipc	ra,0x0
 22e:	0c6080e7          	jalr	198(ra) # 2f0 <memset>
    for (int i = 0; i < len; i++)
 232:	bda9                	j	8c <main+0x8c>
        if (strcmp(line, "exit") == 0)
 234:	00001597          	auipc	a1,0x1
 238:	88458593          	addi	a1,a1,-1916 # ab8 <malloc+0x186>
 23c:	e9040513          	addi	a0,s0,-368
 240:	00000097          	auipc	ra,0x0
 244:	05a080e7          	jalr	90(ra) # 29a <strcmp>
 248:	fd69                	bnez	a0,222 <main+0x222>
        render_centred(fb, line, len);
        // (daemon flushes to display within ~16 ms)
    }

    // ── 4. Clear display before exit ──────────────────────────────────
    memset(fb, 0, FB_BYTES);
 24a:	0012c637          	lui	a2,0x12c
 24e:	4581                	li	a1,0
 250:	854e                	mv	a0,s3
 252:	00000097          	auipc	ra,0x0
 256:	09e080e7          	jalr	158(ra) # 2f0 <memset>

    exit(0);
 25a:	4501                	li	a0,0
 25c:	00000097          	auipc	ra,0x0
 260:	290080e7          	jalr	656(ra) # 4ec <exit>

0000000000000264 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 264:	1141                	addi	sp,sp,-16
 266:	e406                	sd	ra,8(sp)
 268:	e022                	sd	s0,0(sp)
 26a:	0800                	addi	s0,sp,16
  extern int main();
  main();
 26c:	00000097          	auipc	ra,0x0
 270:	d94080e7          	jalr	-620(ra) # 0 <main>
  exit(0);
 274:	4501                	li	a0,0
 276:	00000097          	auipc	ra,0x0
 27a:	276080e7          	jalr	630(ra) # 4ec <exit>

000000000000027e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 27e:	1141                	addi	sp,sp,-16
 280:	e422                	sd	s0,8(sp)
 282:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 284:	87aa                	mv	a5,a0
 286:	0585                	addi	a1,a1,1
 288:	0785                	addi	a5,a5,1
 28a:	fff5c703          	lbu	a4,-1(a1)
 28e:	fee78fa3          	sb	a4,-1(a5)
 292:	fb75                	bnez	a4,286 <strcpy+0x8>
    ;
  return os;
}
 294:	6422                	ld	s0,8(sp)
 296:	0141                	addi	sp,sp,16
 298:	8082                	ret

000000000000029a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 29a:	1141                	addi	sp,sp,-16
 29c:	e422                	sd	s0,8(sp)
 29e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2a0:	00054783          	lbu	a5,0(a0)
 2a4:	cb91                	beqz	a5,2b8 <strcmp+0x1e>
 2a6:	0005c703          	lbu	a4,0(a1)
 2aa:	00f71763          	bne	a4,a5,2b8 <strcmp+0x1e>
    p++, q++;
 2ae:	0505                	addi	a0,a0,1
 2b0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2b2:	00054783          	lbu	a5,0(a0)
 2b6:	fbe5                	bnez	a5,2a6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2b8:	0005c503          	lbu	a0,0(a1)
}
 2bc:	40a7853b          	subw	a0,a5,a0
 2c0:	6422                	ld	s0,8(sp)
 2c2:	0141                	addi	sp,sp,16
 2c4:	8082                	ret

00000000000002c6 <strlen>:

uint
strlen(const char *s)
{
 2c6:	1141                	addi	sp,sp,-16
 2c8:	e422                	sd	s0,8(sp)
 2ca:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2cc:	00054783          	lbu	a5,0(a0)
 2d0:	cf91                	beqz	a5,2ec <strlen+0x26>
 2d2:	0505                	addi	a0,a0,1
 2d4:	87aa                	mv	a5,a0
 2d6:	4685                	li	a3,1
 2d8:	9e89                	subw	a3,a3,a0
 2da:	00f6853b          	addw	a0,a3,a5
 2de:	0785                	addi	a5,a5,1
 2e0:	fff7c703          	lbu	a4,-1(a5)
 2e4:	fb7d                	bnez	a4,2da <strlen+0x14>
    ;
  return n;
}
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret
  for(n = 0; s[n]; n++)
 2ec:	4501                	li	a0,0
 2ee:	bfe5                	j	2e6 <strlen+0x20>

00000000000002f0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2f0:	1141                	addi	sp,sp,-16
 2f2:	e422                	sd	s0,8(sp)
 2f4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2f6:	ca19                	beqz	a2,30c <memset+0x1c>
 2f8:	87aa                	mv	a5,a0
 2fa:	1602                	slli	a2,a2,0x20
 2fc:	9201                	srli	a2,a2,0x20
 2fe:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 302:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 306:	0785                	addi	a5,a5,1
 308:	fee79de3          	bne	a5,a4,302 <memset+0x12>
  }
  return dst;
}
 30c:	6422                	ld	s0,8(sp)
 30e:	0141                	addi	sp,sp,16
 310:	8082                	ret

0000000000000312 <strchr>:

char*
strchr(const char *s, char c)
{
 312:	1141                	addi	sp,sp,-16
 314:	e422                	sd	s0,8(sp)
 316:	0800                	addi	s0,sp,16
  for(; *s; s++)
 318:	00054783          	lbu	a5,0(a0)
 31c:	cb99                	beqz	a5,332 <strchr+0x20>
    if(*s == c)
 31e:	00f58763          	beq	a1,a5,32c <strchr+0x1a>
  for(; *s; s++)
 322:	0505                	addi	a0,a0,1
 324:	00054783          	lbu	a5,0(a0)
 328:	fbfd                	bnez	a5,31e <strchr+0xc>
      return (char*)s;
  return 0;
 32a:	4501                	li	a0,0
}
 32c:	6422                	ld	s0,8(sp)
 32e:	0141                	addi	sp,sp,16
 330:	8082                	ret
  return 0;
 332:	4501                	li	a0,0
 334:	bfe5                	j	32c <strchr+0x1a>

0000000000000336 <gets>:

char*
gets(char *buf, int max)
{
 336:	711d                	addi	sp,sp,-96
 338:	ec86                	sd	ra,88(sp)
 33a:	e8a2                	sd	s0,80(sp)
 33c:	e4a6                	sd	s1,72(sp)
 33e:	e0ca                	sd	s2,64(sp)
 340:	fc4e                	sd	s3,56(sp)
 342:	f852                	sd	s4,48(sp)
 344:	f456                	sd	s5,40(sp)
 346:	f05a                	sd	s6,32(sp)
 348:	ec5e                	sd	s7,24(sp)
 34a:	1080                	addi	s0,sp,96
 34c:	8baa                	mv	s7,a0
 34e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 350:	892a                	mv	s2,a0
 352:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 354:	4aa9                	li	s5,10
 356:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 358:	89a6                	mv	s3,s1
 35a:	2485                	addiw	s1,s1,1
 35c:	0344d863          	bge	s1,s4,38c <gets+0x56>
    cc = read(0, &c, 1);
 360:	4605                	li	a2,1
 362:	faf40593          	addi	a1,s0,-81
 366:	4501                	li	a0,0
 368:	00000097          	auipc	ra,0x0
 36c:	19c080e7          	jalr	412(ra) # 504 <read>
    if(cc < 1)
 370:	00a05e63          	blez	a0,38c <gets+0x56>
    buf[i++] = c;
 374:	faf44783          	lbu	a5,-81(s0)
 378:	00f90023          	sb	a5,0(s2) # 1000000 <base+0xffeff0>
    if(c == '\n' || c == '\r')
 37c:	01578763          	beq	a5,s5,38a <gets+0x54>
 380:	0905                	addi	s2,s2,1
 382:	fd679be3          	bne	a5,s6,358 <gets+0x22>
  for(i=0; i+1 < max; ){
 386:	89a6                	mv	s3,s1
 388:	a011                	j	38c <gets+0x56>
 38a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 38c:	99de                	add	s3,s3,s7
 38e:	00098023          	sb	zero,0(s3)
  return buf;
}
 392:	855e                	mv	a0,s7
 394:	60e6                	ld	ra,88(sp)
 396:	6446                	ld	s0,80(sp)
 398:	64a6                	ld	s1,72(sp)
 39a:	6906                	ld	s2,64(sp)
 39c:	79e2                	ld	s3,56(sp)
 39e:	7a42                	ld	s4,48(sp)
 3a0:	7aa2                	ld	s5,40(sp)
 3a2:	7b02                	ld	s6,32(sp)
 3a4:	6be2                	ld	s7,24(sp)
 3a6:	6125                	addi	sp,sp,96
 3a8:	8082                	ret

00000000000003aa <stat>:

int
stat(const char *n, struct stat *st)
{
 3aa:	1101                	addi	sp,sp,-32
 3ac:	ec06                	sd	ra,24(sp)
 3ae:	e822                	sd	s0,16(sp)
 3b0:	e426                	sd	s1,8(sp)
 3b2:	e04a                	sd	s2,0(sp)
 3b4:	1000                	addi	s0,sp,32
 3b6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3b8:	4581                	li	a1,0
 3ba:	00000097          	auipc	ra,0x0
 3be:	172080e7          	jalr	370(ra) # 52c <open>
  if(fd < 0)
 3c2:	02054563          	bltz	a0,3ec <stat+0x42>
 3c6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3c8:	85ca                	mv	a1,s2
 3ca:	00000097          	auipc	ra,0x0
 3ce:	17a080e7          	jalr	378(ra) # 544 <fstat>
 3d2:	892a                	mv	s2,a0
  close(fd);
 3d4:	8526                	mv	a0,s1
 3d6:	00000097          	auipc	ra,0x0
 3da:	13e080e7          	jalr	318(ra) # 514 <close>
  return r;
}
 3de:	854a                	mv	a0,s2
 3e0:	60e2                	ld	ra,24(sp)
 3e2:	6442                	ld	s0,16(sp)
 3e4:	64a2                	ld	s1,8(sp)
 3e6:	6902                	ld	s2,0(sp)
 3e8:	6105                	addi	sp,sp,32
 3ea:	8082                	ret
    return -1;
 3ec:	597d                	li	s2,-1
 3ee:	bfc5                	j	3de <stat+0x34>

00000000000003f0 <atoi>:

int
atoi(const char *s)
{
 3f0:	1141                	addi	sp,sp,-16
 3f2:	e422                	sd	s0,8(sp)
 3f4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3f6:	00054603          	lbu	a2,0(a0)
 3fa:	fd06079b          	addiw	a5,a2,-48
 3fe:	0ff7f793          	andi	a5,a5,255
 402:	4725                	li	a4,9
 404:	02f76963          	bltu	a4,a5,436 <atoi+0x46>
 408:	86aa                	mv	a3,a0
  n = 0;
 40a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 40c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 40e:	0685                	addi	a3,a3,1
 410:	0025179b          	slliw	a5,a0,0x2
 414:	9fa9                	addw	a5,a5,a0
 416:	0017979b          	slliw	a5,a5,0x1
 41a:	9fb1                	addw	a5,a5,a2
 41c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 420:	0006c603          	lbu	a2,0(a3)
 424:	fd06071b          	addiw	a4,a2,-48
 428:	0ff77713          	andi	a4,a4,255
 42c:	fee5f1e3          	bgeu	a1,a4,40e <atoi+0x1e>
  return n;
}
 430:	6422                	ld	s0,8(sp)
 432:	0141                	addi	sp,sp,16
 434:	8082                	ret
  n = 0;
 436:	4501                	li	a0,0
 438:	bfe5                	j	430 <atoi+0x40>

000000000000043a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 43a:	1141                	addi	sp,sp,-16
 43c:	e422                	sd	s0,8(sp)
 43e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 440:	02b57463          	bgeu	a0,a1,468 <memmove+0x2e>
    while(n-- > 0)
 444:	00c05f63          	blez	a2,462 <memmove+0x28>
 448:	1602                	slli	a2,a2,0x20
 44a:	9201                	srli	a2,a2,0x20
 44c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 450:	872a                	mv	a4,a0
      *dst++ = *src++;
 452:	0585                	addi	a1,a1,1
 454:	0705                	addi	a4,a4,1
 456:	fff5c683          	lbu	a3,-1(a1)
 45a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 45e:	fee79ae3          	bne	a5,a4,452 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 462:	6422                	ld	s0,8(sp)
 464:	0141                	addi	sp,sp,16
 466:	8082                	ret
    dst += n;
 468:	00c50733          	add	a4,a0,a2
    src += n;
 46c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 46e:	fec05ae3          	blez	a2,462 <memmove+0x28>
 472:	fff6079b          	addiw	a5,a2,-1
 476:	1782                	slli	a5,a5,0x20
 478:	9381                	srli	a5,a5,0x20
 47a:	fff7c793          	not	a5,a5
 47e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 480:	15fd                	addi	a1,a1,-1
 482:	177d                	addi	a4,a4,-1
 484:	0005c683          	lbu	a3,0(a1)
 488:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 48c:	fee79ae3          	bne	a5,a4,480 <memmove+0x46>
 490:	bfc9                	j	462 <memmove+0x28>

0000000000000492 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 492:	1141                	addi	sp,sp,-16
 494:	e422                	sd	s0,8(sp)
 496:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 498:	ca05                	beqz	a2,4c8 <memcmp+0x36>
 49a:	fff6069b          	addiw	a3,a2,-1
 49e:	1682                	slli	a3,a3,0x20
 4a0:	9281                	srli	a3,a3,0x20
 4a2:	0685                	addi	a3,a3,1
 4a4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4a6:	00054783          	lbu	a5,0(a0)
 4aa:	0005c703          	lbu	a4,0(a1)
 4ae:	00e79863          	bne	a5,a4,4be <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4b2:	0505                	addi	a0,a0,1
    p2++;
 4b4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4b6:	fed518e3          	bne	a0,a3,4a6 <memcmp+0x14>
  }
  return 0;
 4ba:	4501                	li	a0,0
 4bc:	a019                	j	4c2 <memcmp+0x30>
      return *p1 - *p2;
 4be:	40e7853b          	subw	a0,a5,a4
}
 4c2:	6422                	ld	s0,8(sp)
 4c4:	0141                	addi	sp,sp,16
 4c6:	8082                	ret
  return 0;
 4c8:	4501                	li	a0,0
 4ca:	bfe5                	j	4c2 <memcmp+0x30>

00000000000004cc <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4cc:	1141                	addi	sp,sp,-16
 4ce:	e406                	sd	ra,8(sp)
 4d0:	e022                	sd	s0,0(sp)
 4d2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4d4:	00000097          	auipc	ra,0x0
 4d8:	f66080e7          	jalr	-154(ra) # 43a <memmove>
}
 4dc:	60a2                	ld	ra,8(sp)
 4de:	6402                	ld	s0,0(sp)
 4e0:	0141                	addi	sp,sp,16
 4e2:	8082                	ret

00000000000004e4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4e4:	4885                	li	a7,1
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <exit>:
.global exit
exit:
 li a7, SYS_exit
 4ec:	4889                	li	a7,2
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4f4:	488d                	li	a7,3
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4fc:	4891                	li	a7,4
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <read>:
.global read
read:
 li a7, SYS_read
 504:	4895                	li	a7,5
 ecall
 506:	00000073          	ecall
 ret
 50a:	8082                	ret

000000000000050c <write>:
.global write
write:
 li a7, SYS_write
 50c:	48c1                	li	a7,16
 ecall
 50e:	00000073          	ecall
 ret
 512:	8082                	ret

0000000000000514 <close>:
.global close
close:
 li a7, SYS_close
 514:	48d5                	li	a7,21
 ecall
 516:	00000073          	ecall
 ret
 51a:	8082                	ret

000000000000051c <kill>:
.global kill
kill:
 li a7, SYS_kill
 51c:	4899                	li	a7,6
 ecall
 51e:	00000073          	ecall
 ret
 522:	8082                	ret

0000000000000524 <exec>:
.global exec
exec:
 li a7, SYS_exec
 524:	489d                	li	a7,7
 ecall
 526:	00000073          	ecall
 ret
 52a:	8082                	ret

000000000000052c <open>:
.global open
open:
 li a7, SYS_open
 52c:	48bd                	li	a7,15
 ecall
 52e:	00000073          	ecall
 ret
 532:	8082                	ret

0000000000000534 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 534:	48c5                	li	a7,17
 ecall
 536:	00000073          	ecall
 ret
 53a:	8082                	ret

000000000000053c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 53c:	48c9                	li	a7,18
 ecall
 53e:	00000073          	ecall
 ret
 542:	8082                	ret

0000000000000544 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 544:	48a1                	li	a7,8
 ecall
 546:	00000073          	ecall
 ret
 54a:	8082                	ret

000000000000054c <link>:
.global link
link:
 li a7, SYS_link
 54c:	48cd                	li	a7,19
 ecall
 54e:	00000073          	ecall
 ret
 552:	8082                	ret

0000000000000554 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 554:	48d1                	li	a7,20
 ecall
 556:	00000073          	ecall
 ret
 55a:	8082                	ret

000000000000055c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 55c:	48a5                	li	a7,9
 ecall
 55e:	00000073          	ecall
 ret
 562:	8082                	ret

0000000000000564 <dup>:
.global dup
dup:
 li a7, SYS_dup
 564:	48a9                	li	a7,10
 ecall
 566:	00000073          	ecall
 ret
 56a:	8082                	ret

000000000000056c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 56c:	48ad                	li	a7,11
 ecall
 56e:	00000073          	ecall
 ret
 572:	8082                	ret

0000000000000574 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 574:	48b1                	li	a7,12
 ecall
 576:	00000073          	ecall
 ret
 57a:	8082                	ret

000000000000057c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 57c:	48b5                	li	a7,13
 ecall
 57e:	00000073          	ecall
 ret
 582:	8082                	ret

0000000000000584 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 584:	48b9                	li	a7,14
 ecall
 586:	00000073          	ecall
 ret
 58a:	8082                	ret

000000000000058c <flip_display>:
.global flip_display
flip_display:
 li a7, SYS_flip_display
 58c:	48d9                	li	a7,22
 ecall
 58e:	00000073          	ecall
 ret
 592:	8082                	ret

0000000000000594 <map_display>:
.global map_display
map_display:
 li a7, SYS_map_display
 594:	48dd                	li	a7,23
 ecall
 596:	00000073          	ecall
 ret
 59a:	8082                	ret

000000000000059c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 59c:	1101                	addi	sp,sp,-32
 59e:	ec06                	sd	ra,24(sp)
 5a0:	e822                	sd	s0,16(sp)
 5a2:	1000                	addi	s0,sp,32
 5a4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5a8:	4605                	li	a2,1
 5aa:	fef40593          	addi	a1,s0,-17
 5ae:	00000097          	auipc	ra,0x0
 5b2:	f5e080e7          	jalr	-162(ra) # 50c <write>
}
 5b6:	60e2                	ld	ra,24(sp)
 5b8:	6442                	ld	s0,16(sp)
 5ba:	6105                	addi	sp,sp,32
 5bc:	8082                	ret

00000000000005be <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5be:	7139                	addi	sp,sp,-64
 5c0:	fc06                	sd	ra,56(sp)
 5c2:	f822                	sd	s0,48(sp)
 5c4:	f426                	sd	s1,40(sp)
 5c6:	f04a                	sd	s2,32(sp)
 5c8:	ec4e                	sd	s3,24(sp)
 5ca:	0080                	addi	s0,sp,64
 5cc:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5ce:	c299                	beqz	a3,5d4 <printint+0x16>
 5d0:	0805c863          	bltz	a1,660 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5d4:	2581                	sext.w	a1,a1
  neg = 0;
 5d6:	4881                	li	a7,0
 5d8:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5dc:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5de:	2601                	sext.w	a2,a2
 5e0:	00001517          	auipc	a0,0x1
 5e4:	8e850513          	addi	a0,a0,-1816 # ec8 <digits>
 5e8:	883a                	mv	a6,a4
 5ea:	2705                	addiw	a4,a4,1
 5ec:	02c5f7bb          	remuw	a5,a1,a2
 5f0:	1782                	slli	a5,a5,0x20
 5f2:	9381                	srli	a5,a5,0x20
 5f4:	97aa                	add	a5,a5,a0
 5f6:	0007c783          	lbu	a5,0(a5)
 5fa:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5fe:	0005879b          	sext.w	a5,a1
 602:	02c5d5bb          	divuw	a1,a1,a2
 606:	0685                	addi	a3,a3,1
 608:	fec7f0e3          	bgeu	a5,a2,5e8 <printint+0x2a>
  if(neg)
 60c:	00088b63          	beqz	a7,622 <printint+0x64>
    buf[i++] = '-';
 610:	fd040793          	addi	a5,s0,-48
 614:	973e                	add	a4,a4,a5
 616:	02d00793          	li	a5,45
 61a:	fef70823          	sb	a5,-16(a4)
 61e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 622:	02e05863          	blez	a4,652 <printint+0x94>
 626:	fc040793          	addi	a5,s0,-64
 62a:	00e78933          	add	s2,a5,a4
 62e:	fff78993          	addi	s3,a5,-1
 632:	99ba                	add	s3,s3,a4
 634:	377d                	addiw	a4,a4,-1
 636:	1702                	slli	a4,a4,0x20
 638:	9301                	srli	a4,a4,0x20
 63a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 63e:	fff94583          	lbu	a1,-1(s2)
 642:	8526                	mv	a0,s1
 644:	00000097          	auipc	ra,0x0
 648:	f58080e7          	jalr	-168(ra) # 59c <putc>
  while(--i >= 0)
 64c:	197d                	addi	s2,s2,-1
 64e:	ff3918e3          	bne	s2,s3,63e <printint+0x80>
}
 652:	70e2                	ld	ra,56(sp)
 654:	7442                	ld	s0,48(sp)
 656:	74a2                	ld	s1,40(sp)
 658:	7902                	ld	s2,32(sp)
 65a:	69e2                	ld	s3,24(sp)
 65c:	6121                	addi	sp,sp,64
 65e:	8082                	ret
    x = -xx;
 660:	40b005bb          	negw	a1,a1
    neg = 1;
 664:	4885                	li	a7,1
    x = -xx;
 666:	bf8d                	j	5d8 <printint+0x1a>

0000000000000668 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 668:	7119                	addi	sp,sp,-128
 66a:	fc86                	sd	ra,120(sp)
 66c:	f8a2                	sd	s0,112(sp)
 66e:	f4a6                	sd	s1,104(sp)
 670:	f0ca                	sd	s2,96(sp)
 672:	ecce                	sd	s3,88(sp)
 674:	e8d2                	sd	s4,80(sp)
 676:	e4d6                	sd	s5,72(sp)
 678:	e0da                	sd	s6,64(sp)
 67a:	fc5e                	sd	s7,56(sp)
 67c:	f862                	sd	s8,48(sp)
 67e:	f466                	sd	s9,40(sp)
 680:	f06a                	sd	s10,32(sp)
 682:	ec6e                	sd	s11,24(sp)
 684:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 686:	0005c903          	lbu	s2,0(a1)
 68a:	18090f63          	beqz	s2,828 <vprintf+0x1c0>
 68e:	8aaa                	mv	s5,a0
 690:	8b32                	mv	s6,a2
 692:	00158493          	addi	s1,a1,1
  state = 0;
 696:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 698:	02500a13          	li	s4,37
      if(c == 'd'){
 69c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6a0:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6a4:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6a8:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6ac:	00001b97          	auipc	s7,0x1
 6b0:	81cb8b93          	addi	s7,s7,-2020 # ec8 <digits>
 6b4:	a839                	j	6d2 <vprintf+0x6a>
        putc(fd, c);
 6b6:	85ca                	mv	a1,s2
 6b8:	8556                	mv	a0,s5
 6ba:	00000097          	auipc	ra,0x0
 6be:	ee2080e7          	jalr	-286(ra) # 59c <putc>
 6c2:	a019                	j	6c8 <vprintf+0x60>
    } else if(state == '%'){
 6c4:	01498f63          	beq	s3,s4,6e2 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6c8:	0485                	addi	s1,s1,1
 6ca:	fff4c903          	lbu	s2,-1(s1)
 6ce:	14090d63          	beqz	s2,828 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6d2:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6d6:	fe0997e3          	bnez	s3,6c4 <vprintf+0x5c>
      if(c == '%'){
 6da:	fd479ee3          	bne	a5,s4,6b6 <vprintf+0x4e>
        state = '%';
 6de:	89be                	mv	s3,a5
 6e0:	b7e5                	j	6c8 <vprintf+0x60>
      if(c == 'd'){
 6e2:	05878063          	beq	a5,s8,722 <vprintf+0xba>
      } else if(c == 'l') {
 6e6:	05978c63          	beq	a5,s9,73e <vprintf+0xd6>
      } else if(c == 'x') {
 6ea:	07a78863          	beq	a5,s10,75a <vprintf+0xf2>
      } else if(c == 'p') {
 6ee:	09b78463          	beq	a5,s11,776 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6f2:	07300713          	li	a4,115
 6f6:	0ce78663          	beq	a5,a4,7c2 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6fa:	06300713          	li	a4,99
 6fe:	0ee78e63          	beq	a5,a4,7fa <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 702:	11478863          	beq	a5,s4,812 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 706:	85d2                	mv	a1,s4
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	e92080e7          	jalr	-366(ra) # 59c <putc>
        putc(fd, c);
 712:	85ca                	mv	a1,s2
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	e86080e7          	jalr	-378(ra) # 59c <putc>
      }
      state = 0;
 71e:	4981                	li	s3,0
 720:	b765                	j	6c8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 722:	008b0913          	addi	s2,s6,8 # 8c008 <base+0x8aff8>
 726:	4685                	li	a3,1
 728:	4629                	li	a2,10
 72a:	000b2583          	lw	a1,0(s6)
 72e:	8556                	mv	a0,s5
 730:	00000097          	auipc	ra,0x0
 734:	e8e080e7          	jalr	-370(ra) # 5be <printint>
 738:	8b4a                	mv	s6,s2
      state = 0;
 73a:	4981                	li	s3,0
 73c:	b771                	j	6c8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 73e:	008b0913          	addi	s2,s6,8
 742:	4681                	li	a3,0
 744:	4629                	li	a2,10
 746:	000b2583          	lw	a1,0(s6)
 74a:	8556                	mv	a0,s5
 74c:	00000097          	auipc	ra,0x0
 750:	e72080e7          	jalr	-398(ra) # 5be <printint>
 754:	8b4a                	mv	s6,s2
      state = 0;
 756:	4981                	li	s3,0
 758:	bf85                	j	6c8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 75a:	008b0913          	addi	s2,s6,8
 75e:	4681                	li	a3,0
 760:	4641                	li	a2,16
 762:	000b2583          	lw	a1,0(s6)
 766:	8556                	mv	a0,s5
 768:	00000097          	auipc	ra,0x0
 76c:	e56080e7          	jalr	-426(ra) # 5be <printint>
 770:	8b4a                	mv	s6,s2
      state = 0;
 772:	4981                	li	s3,0
 774:	bf91                	j	6c8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 776:	008b0793          	addi	a5,s6,8
 77a:	f8f43423          	sd	a5,-120(s0)
 77e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 782:	03000593          	li	a1,48
 786:	8556                	mv	a0,s5
 788:	00000097          	auipc	ra,0x0
 78c:	e14080e7          	jalr	-492(ra) # 59c <putc>
  putc(fd, 'x');
 790:	85ea                	mv	a1,s10
 792:	8556                	mv	a0,s5
 794:	00000097          	auipc	ra,0x0
 798:	e08080e7          	jalr	-504(ra) # 59c <putc>
 79c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 79e:	03c9d793          	srli	a5,s3,0x3c
 7a2:	97de                	add	a5,a5,s7
 7a4:	0007c583          	lbu	a1,0(a5)
 7a8:	8556                	mv	a0,s5
 7aa:	00000097          	auipc	ra,0x0
 7ae:	df2080e7          	jalr	-526(ra) # 59c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7b2:	0992                	slli	s3,s3,0x4
 7b4:	397d                	addiw	s2,s2,-1
 7b6:	fe0914e3          	bnez	s2,79e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7ba:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7be:	4981                	li	s3,0
 7c0:	b721                	j	6c8 <vprintf+0x60>
        s = va_arg(ap, char*);
 7c2:	008b0993          	addi	s3,s6,8
 7c6:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7ca:	02090163          	beqz	s2,7ec <vprintf+0x184>
        while(*s != 0){
 7ce:	00094583          	lbu	a1,0(s2)
 7d2:	c9a1                	beqz	a1,822 <vprintf+0x1ba>
          putc(fd, *s);
 7d4:	8556                	mv	a0,s5
 7d6:	00000097          	auipc	ra,0x0
 7da:	dc6080e7          	jalr	-570(ra) # 59c <putc>
          s++;
 7de:	0905                	addi	s2,s2,1
        while(*s != 0){
 7e0:	00094583          	lbu	a1,0(s2)
 7e4:	f9e5                	bnez	a1,7d4 <vprintf+0x16c>
        s = va_arg(ap, char*);
 7e6:	8b4e                	mv	s6,s3
      state = 0;
 7e8:	4981                	li	s3,0
 7ea:	bdf9                	j	6c8 <vprintf+0x60>
          s = "(null)";
 7ec:	00000917          	auipc	s2,0x0
 7f0:	6d490913          	addi	s2,s2,1748 # ec0 <font8x8+0x400>
        while(*s != 0){
 7f4:	02800593          	li	a1,40
 7f8:	bff1                	j	7d4 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7fa:	008b0913          	addi	s2,s6,8
 7fe:	000b4583          	lbu	a1,0(s6)
 802:	8556                	mv	a0,s5
 804:	00000097          	auipc	ra,0x0
 808:	d98080e7          	jalr	-616(ra) # 59c <putc>
 80c:	8b4a                	mv	s6,s2
      state = 0;
 80e:	4981                	li	s3,0
 810:	bd65                	j	6c8 <vprintf+0x60>
        putc(fd, c);
 812:	85d2                	mv	a1,s4
 814:	8556                	mv	a0,s5
 816:	00000097          	auipc	ra,0x0
 81a:	d86080e7          	jalr	-634(ra) # 59c <putc>
      state = 0;
 81e:	4981                	li	s3,0
 820:	b565                	j	6c8 <vprintf+0x60>
        s = va_arg(ap, char*);
 822:	8b4e                	mv	s6,s3
      state = 0;
 824:	4981                	li	s3,0
 826:	b54d                	j	6c8 <vprintf+0x60>
    }
  }
}
 828:	70e6                	ld	ra,120(sp)
 82a:	7446                	ld	s0,112(sp)
 82c:	74a6                	ld	s1,104(sp)
 82e:	7906                	ld	s2,96(sp)
 830:	69e6                	ld	s3,88(sp)
 832:	6a46                	ld	s4,80(sp)
 834:	6aa6                	ld	s5,72(sp)
 836:	6b06                	ld	s6,64(sp)
 838:	7be2                	ld	s7,56(sp)
 83a:	7c42                	ld	s8,48(sp)
 83c:	7ca2                	ld	s9,40(sp)
 83e:	7d02                	ld	s10,32(sp)
 840:	6de2                	ld	s11,24(sp)
 842:	6109                	addi	sp,sp,128
 844:	8082                	ret

0000000000000846 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 846:	715d                	addi	sp,sp,-80
 848:	ec06                	sd	ra,24(sp)
 84a:	e822                	sd	s0,16(sp)
 84c:	1000                	addi	s0,sp,32
 84e:	e010                	sd	a2,0(s0)
 850:	e414                	sd	a3,8(s0)
 852:	e818                	sd	a4,16(s0)
 854:	ec1c                	sd	a5,24(s0)
 856:	03043023          	sd	a6,32(s0)
 85a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 85e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 862:	8622                	mv	a2,s0
 864:	00000097          	auipc	ra,0x0
 868:	e04080e7          	jalr	-508(ra) # 668 <vprintf>
}
 86c:	60e2                	ld	ra,24(sp)
 86e:	6442                	ld	s0,16(sp)
 870:	6161                	addi	sp,sp,80
 872:	8082                	ret

0000000000000874 <printf>:

void
printf(const char *fmt, ...)
{
 874:	711d                	addi	sp,sp,-96
 876:	ec06                	sd	ra,24(sp)
 878:	e822                	sd	s0,16(sp)
 87a:	1000                	addi	s0,sp,32
 87c:	e40c                	sd	a1,8(s0)
 87e:	e810                	sd	a2,16(s0)
 880:	ec14                	sd	a3,24(s0)
 882:	f018                	sd	a4,32(s0)
 884:	f41c                	sd	a5,40(s0)
 886:	03043823          	sd	a6,48(s0)
 88a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 88e:	00840613          	addi	a2,s0,8
 892:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 896:	85aa                	mv	a1,a0
 898:	4505                	li	a0,1
 89a:	00000097          	auipc	ra,0x0
 89e:	dce080e7          	jalr	-562(ra) # 668 <vprintf>
}
 8a2:	60e2                	ld	ra,24(sp)
 8a4:	6442                	ld	s0,16(sp)
 8a6:	6125                	addi	sp,sp,96
 8a8:	8082                	ret

00000000000008aa <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8aa:	1141                	addi	sp,sp,-16
 8ac:	e422                	sd	s0,8(sp)
 8ae:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8b0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8b4:	00000797          	auipc	a5,0x0
 8b8:	74c7b783          	ld	a5,1868(a5) # 1000 <freep>
 8bc:	a805                	j	8ec <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8be:	4618                	lw	a4,8(a2)
 8c0:	9db9                	addw	a1,a1,a4
 8c2:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8c6:	6398                	ld	a4,0(a5)
 8c8:	6318                	ld	a4,0(a4)
 8ca:	fee53823          	sd	a4,-16(a0)
 8ce:	a091                	j	912 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8d0:	ff852703          	lw	a4,-8(a0)
 8d4:	9e39                	addw	a2,a2,a4
 8d6:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8d8:	ff053703          	ld	a4,-16(a0)
 8dc:	e398                	sd	a4,0(a5)
 8de:	a099                	j	924 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8e0:	6398                	ld	a4,0(a5)
 8e2:	00e7e463          	bltu	a5,a4,8ea <free+0x40>
 8e6:	00e6ea63          	bltu	a3,a4,8fa <free+0x50>
{
 8ea:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8ec:	fed7fae3          	bgeu	a5,a3,8e0 <free+0x36>
 8f0:	6398                	ld	a4,0(a5)
 8f2:	00e6e463          	bltu	a3,a4,8fa <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8f6:	fee7eae3          	bltu	a5,a4,8ea <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8fa:	ff852583          	lw	a1,-8(a0)
 8fe:	6390                	ld	a2,0(a5)
 900:	02059713          	slli	a4,a1,0x20
 904:	9301                	srli	a4,a4,0x20
 906:	0712                	slli	a4,a4,0x4
 908:	9736                	add	a4,a4,a3
 90a:	fae60ae3          	beq	a2,a4,8be <free+0x14>
    bp->s.ptr = p->s.ptr;
 90e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 912:	4790                	lw	a2,8(a5)
 914:	02061713          	slli	a4,a2,0x20
 918:	9301                	srli	a4,a4,0x20
 91a:	0712                	slli	a4,a4,0x4
 91c:	973e                	add	a4,a4,a5
 91e:	fae689e3          	beq	a3,a4,8d0 <free+0x26>
  } else
    p->s.ptr = bp;
 922:	e394                	sd	a3,0(a5)
  freep = p;
 924:	00000717          	auipc	a4,0x0
 928:	6cf73e23          	sd	a5,1756(a4) # 1000 <freep>
}
 92c:	6422                	ld	s0,8(sp)
 92e:	0141                	addi	sp,sp,16
 930:	8082                	ret

0000000000000932 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 932:	7139                	addi	sp,sp,-64
 934:	fc06                	sd	ra,56(sp)
 936:	f822                	sd	s0,48(sp)
 938:	f426                	sd	s1,40(sp)
 93a:	f04a                	sd	s2,32(sp)
 93c:	ec4e                	sd	s3,24(sp)
 93e:	e852                	sd	s4,16(sp)
 940:	e456                	sd	s5,8(sp)
 942:	e05a                	sd	s6,0(sp)
 944:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 946:	02051493          	slli	s1,a0,0x20
 94a:	9081                	srli	s1,s1,0x20
 94c:	04bd                	addi	s1,s1,15
 94e:	8091                	srli	s1,s1,0x4
 950:	0014899b          	addiw	s3,s1,1
 954:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 956:	00000517          	auipc	a0,0x0
 95a:	6aa53503          	ld	a0,1706(a0) # 1000 <freep>
 95e:	c515                	beqz	a0,98a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 960:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 962:	4798                	lw	a4,8(a5)
 964:	02977f63          	bgeu	a4,s1,9a2 <malloc+0x70>
 968:	8a4e                	mv	s4,s3
 96a:	0009871b          	sext.w	a4,s3
 96e:	6685                	lui	a3,0x1
 970:	00d77363          	bgeu	a4,a3,976 <malloc+0x44>
 974:	6a05                	lui	s4,0x1
 976:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 97a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 97e:	00000917          	auipc	s2,0x0
 982:	68290913          	addi	s2,s2,1666 # 1000 <freep>
  if(p == (char*)-1)
 986:	5afd                	li	s5,-1
 988:	a88d                	j	9fa <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 98a:	00000797          	auipc	a5,0x0
 98e:	68678793          	addi	a5,a5,1670 # 1010 <base>
 992:	00000717          	auipc	a4,0x0
 996:	66f73723          	sd	a5,1646(a4) # 1000 <freep>
 99a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 99c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9a0:	b7e1                	j	968 <malloc+0x36>
      if(p->s.size == nunits)
 9a2:	02e48b63          	beq	s1,a4,9d8 <malloc+0xa6>
        p->s.size -= nunits;
 9a6:	4137073b          	subw	a4,a4,s3
 9aa:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9ac:	1702                	slli	a4,a4,0x20
 9ae:	9301                	srli	a4,a4,0x20
 9b0:	0712                	slli	a4,a4,0x4
 9b2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9b4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9b8:	00000717          	auipc	a4,0x0
 9bc:	64a73423          	sd	a0,1608(a4) # 1000 <freep>
      return (void*)(p + 1);
 9c0:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9c4:	70e2                	ld	ra,56(sp)
 9c6:	7442                	ld	s0,48(sp)
 9c8:	74a2                	ld	s1,40(sp)
 9ca:	7902                	ld	s2,32(sp)
 9cc:	69e2                	ld	s3,24(sp)
 9ce:	6a42                	ld	s4,16(sp)
 9d0:	6aa2                	ld	s5,8(sp)
 9d2:	6b02                	ld	s6,0(sp)
 9d4:	6121                	addi	sp,sp,64
 9d6:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9d8:	6398                	ld	a4,0(a5)
 9da:	e118                	sd	a4,0(a0)
 9dc:	bff1                	j	9b8 <malloc+0x86>
  hp->s.size = nu;
 9de:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9e2:	0541                	addi	a0,a0,16
 9e4:	00000097          	auipc	ra,0x0
 9e8:	ec6080e7          	jalr	-314(ra) # 8aa <free>
  return freep;
 9ec:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9f0:	d971                	beqz	a0,9c4 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9f2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9f4:	4798                	lw	a4,8(a5)
 9f6:	fa9776e3          	bgeu	a4,s1,9a2 <malloc+0x70>
    if(p == freep)
 9fa:	00093703          	ld	a4,0(s2)
 9fe:	853e                	mv	a0,a5
 a00:	fef719e3          	bne	a4,a5,9f2 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a04:	8552                	mv	a0,s4
 a06:	00000097          	auipc	ra,0x0
 a0a:	b6e080e7          	jalr	-1170(ra) # 574 <sbrk>
  if(p == (char*)-1)
 a0e:	fd5518e3          	bne	a0,s5,9de <malloc+0xac>
        return 0;
 a12:	4501                	li	a0,0
 a14:	bf45                	j	9c4 <malloc+0x92>
