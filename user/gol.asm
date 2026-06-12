
user/_gol:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <cell_get>:
}

// Toroidal (wrapping) get/set
static int
cell_get(const uint8 *g, int x, int y)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
    x = (x % GRID_W + GRID_W) % GRID_W;
   6:	05000713          	li	a4,80
   a:	02e5e5bb          	remw	a1,a1,a4
   e:	0505859b          	addiw	a1,a1,80
    y = (y % GRID_H + GRID_H) % GRID_H;
  12:	03c00793          	li	a5,60
  16:	02f6663b          	remw	a2,a2,a5
  1a:	03c6061b          	addiw	a2,a2,60
  1e:	02f6663b          	remw	a2,a2,a5
    return g[y * GRID_W + x];
  22:	0026179b          	slliw	a5,a2,0x2
  26:	9e3d                	addw	a2,a2,a5
  28:	0046161b          	slliw	a2,a2,0x4
    x = (x % GRID_W + GRID_W) % GRID_W;
  2c:	02e5e5bb          	remw	a1,a1,a4
    return g[y * GRID_W + x];
  30:	9e2d                	addw	a2,a2,a1
  32:	9532                	add	a0,a0,a2
}
  34:	00054503          	lbu	a0,0(a0)
  38:	6422                	ld	s0,8(sp)
  3a:	0141                	addi	sp,sp,16
  3c:	8082                	ret

000000000000003e <cell_set>:

static void
cell_set(uint8 *g, int x, int y)
{
  3e:	1141                	addi	sp,sp,-16
  40:	e422                	sd	s0,8(sp)
  42:	0800                	addi	s0,sp,16
    x = (x % GRID_W + GRID_W) % GRID_W;
  44:	05000713          	li	a4,80
  48:	02e5e5bb          	remw	a1,a1,a4
  4c:	0505859b          	addiw	a1,a1,80
    y = (y % GRID_H + GRID_H) % GRID_H;
  50:	03c00793          	li	a5,60
  54:	02f6663b          	remw	a2,a2,a5
  58:	03c6061b          	addiw	a2,a2,60
  5c:	02f6663b          	remw	a2,a2,a5
    g[y * GRID_W + x] = 1;
  60:	0026179b          	slliw	a5,a2,0x2
  64:	9e3d                	addw	a2,a2,a5
  66:	0046161b          	slliw	a2,a2,0x4
    x = (x % GRID_W + GRID_W) % GRID_W;
  6a:	02e5e5bb          	remw	a1,a1,a4
    g[y * GRID_W + x] = 1;
  6e:	9e2d                	addw	a2,a2,a1
  70:	9532                	add	a0,a0,a2
  72:	4785                	li	a5,1
  74:	00f50023          	sb	a5,0(a0)
}
  78:	6422                	ld	s0,8(sp)
  7a:	0141                	addi	sp,sp,16
  7c:	8082                	ret

000000000000007e <gol_step>:

// Advance one GOL generation: cur → nxt
static void
gol_step(const uint8 *cur, uint8 *nxt)
{
  7e:	7175                	addi	sp,sp,-144
  80:	e506                	sd	ra,136(sp)
  82:	e122                	sd	s0,128(sp)
  84:	fca6                	sd	s1,120(sp)
  86:	f8ca                	sd	s2,112(sp)
  88:	f4ce                	sd	s3,104(sp)
  8a:	f0d2                	sd	s4,96(sp)
  8c:	ecd6                	sd	s5,88(sp)
  8e:	e8da                	sd	s6,80(sp)
  90:	e4de                	sd	s7,72(sp)
  92:	e0e2                	sd	s8,64(sp)
  94:	fc66                	sd	s9,56(sp)
  96:	f86a                	sd	s10,48(sp)
  98:	f46e                	sd	s11,40(sp)
  9a:	0900                	addi	s0,sp,144
  9c:	892a                	mv	s2,a0
  9e:	f6b43823          	sd	a1,-144(s0)
    for (int y = 0; y < GRID_H; y++)
    {
        for (int x = 0; x < GRID_W; x++)
  a2:	f6043c23          	sd	zero,-136(s0)
  a6:	57fd                	li	a5,-1
  a8:	f8f43023          	sd	a5,-128(s0)
  ac:	4785                	li	a5,1
  ae:	f8f43423          	sd	a5,-120(s0)
  b2:	05000d93          	li	s11,80
  b6:	a0dd                	j	19c <gol_step+0x11e>
        {
            int n = cell_get(cur, x - 1, y - 1) + cell_get(cur, x, y - 1) + cell_get(cur, x + 1, y - 1) + cell_get(cur, x - 1, y) + cell_get(cur, x + 1, y) + cell_get(cur, x - 1, y + 1) + cell_get(cur, x, y + 1) + cell_get(cur, x + 1, y + 1);
            int alive = cur[y * GRID_W + x];
            nxt[y * GRID_W + x] = alive ? (n == 2 || n == 3) : (n == 3);
  b8:	ffd78993          	addi	s3,a5,-3
  bc:	0019b993          	seqz	s3,s3
  c0:	013b8023          	sb	s3,0(s7)
        for (int x = 0; x < GRID_W; x++)
  c4:	0c05                	addi	s8,s8,1
  c6:	0b85                	addi	s7,s7,1
  c8:	0bb48663          	beq	s1,s11,174 <gol_step+0xf6>
            int n = cell_get(cur, x - 1, y - 1) + cell_get(cur, x, y - 1) + cell_get(cur, x + 1, y - 1) + cell_get(cur, x - 1, y) + cell_get(cur, x + 1, y) + cell_get(cur, x - 1, y + 1) + cell_get(cur, x, y + 1) + cell_get(cur, x + 1, y + 1);
  cc:	fff48a1b          	addiw	s4,s1,-1
  d0:	865a                	mv	a2,s6
  d2:	85d2                	mv	a1,s4
  d4:	854a                	mv	a0,s2
  d6:	00000097          	auipc	ra,0x0
  da:	f2a080e7          	jalr	-214(ra) # 0 <cell_get>
  de:	89aa                	mv	s3,a0
  e0:	865a                	mv	a2,s6
  e2:	85a6                	mv	a1,s1
  e4:	854a                	mv	a0,s2
  e6:	00000097          	auipc	ra,0x0
  ea:	f1a080e7          	jalr	-230(ra) # 0 <cell_get>
  ee:	00a989bb          	addw	s3,s3,a0
  f2:	8d26                	mv	s10,s1
  f4:	2485                	addiw	s1,s1,1
  f6:	865a                	mv	a2,s6
  f8:	85a6                	mv	a1,s1
  fa:	854a                	mv	a0,s2
  fc:	00000097          	auipc	ra,0x0
 100:	f04080e7          	jalr	-252(ra) # 0 <cell_get>
 104:	00a989bb          	addw	s3,s3,a0
 108:	8666                	mv	a2,s9
 10a:	85d2                	mv	a1,s4
 10c:	854a                	mv	a0,s2
 10e:	00000097          	auipc	ra,0x0
 112:	ef2080e7          	jalr	-270(ra) # 0 <cell_get>
 116:	00a989bb          	addw	s3,s3,a0
 11a:	8666                	mv	a2,s9
 11c:	85a6                	mv	a1,s1
 11e:	854a                	mv	a0,s2
 120:	00000097          	auipc	ra,0x0
 124:	ee0080e7          	jalr	-288(ra) # 0 <cell_get>
 128:	00a989bb          	addw	s3,s3,a0
 12c:	8656                	mv	a2,s5
 12e:	85d2                	mv	a1,s4
 130:	854a                	mv	a0,s2
 132:	00000097          	auipc	ra,0x0
 136:	ece080e7          	jalr	-306(ra) # 0 <cell_get>
 13a:	00a989bb          	addw	s3,s3,a0
 13e:	8656                	mv	a2,s5
 140:	85ea                	mv	a1,s10
 142:	854a                	mv	a0,s2
 144:	00000097          	auipc	ra,0x0
 148:	ebc080e7          	jalr	-324(ra) # 0 <cell_get>
 14c:	00a989bb          	addw	s3,s3,a0
 150:	8656                	mv	a2,s5
 152:	85a6                	mv	a1,s1
 154:	854a                	mv	a0,s2
 156:	00000097          	auipc	ra,0x0
 15a:	eaa080e7          	jalr	-342(ra) # 0 <cell_get>
 15e:	00a989bb          	addw	s3,s3,a0
 162:	0009879b          	sext.w	a5,s3
            nxt[y * GRID_W + x] = alive ? (n == 2 || n == 3) : (n == 3);
 166:	000c4703          	lbu	a4,0(s8)
 16a:	d739                	beqz	a4,b8 <gol_step+0x3a>
 16c:	39f9                	addiw	s3,s3,-2
 16e:	0029b993          	sltiu	s3,s3,2
 172:	b7b9                	j	c0 <gol_step+0x42>
    for (int y = 0; y < GRID_H; y++)
 174:	f8843783          	ld	a5,-120(s0)
 178:	2785                	addiw	a5,a5,1
 17a:	f8f43423          	sd	a5,-120(s0)
 17e:	f8043703          	ld	a4,-128(s0)
 182:	2705                	addiw	a4,a4,1
 184:	f8e43023          	sd	a4,-128(s0)
 188:	f7843703          	ld	a4,-136(s0)
 18c:	05070713          	addi	a4,a4,80
 190:	f6e43c23          	sd	a4,-136(s0)
 194:	03d00713          	li	a4,61
 198:	02e78463          	beq	a5,a4,1c0 <gol_step+0x142>
 19c:	f8843783          	ld	a5,-120(s0)
 1a0:	fff78c9b          	addiw	s9,a5,-1
        for (int x = 0; x < GRID_W; x++)
 1a4:	f7843703          	ld	a4,-136(s0)
 1a8:	00e90c33          	add	s8,s2,a4
 1ac:	f7043683          	ld	a3,-144(s0)
 1b0:	00e68bb3          	add	s7,a3,a4
 1b4:	4481                	li	s1,0
            int n = cell_get(cur, x - 1, y - 1) + cell_get(cur, x, y - 1) + cell_get(cur, x + 1, y - 1) + cell_get(cur, x - 1, y) + cell_get(cur, x + 1, y) + cell_get(cur, x - 1, y + 1) + cell_get(cur, x, y + 1) + cell_get(cur, x + 1, y + 1);
 1b6:	f8042b03          	lw	s6,-128(s0)
 1ba:	00078a9b          	sext.w	s5,a5
 1be:	b739                	j	cc <gol_step+0x4e>
        }
    }
}
 1c0:	60aa                	ld	ra,136(sp)
 1c2:	640a                	ld	s0,128(sp)
 1c4:	74e6                	ld	s1,120(sp)
 1c6:	7946                	ld	s2,112(sp)
 1c8:	79a6                	ld	s3,104(sp)
 1ca:	7a06                	ld	s4,96(sp)
 1cc:	6ae6                	ld	s5,88(sp)
 1ce:	6b46                	ld	s6,80(sp)
 1d0:	6ba6                	ld	s7,72(sp)
 1d2:	6c06                	ld	s8,64(sp)
 1d4:	7ce2                	ld	s9,56(sp)
 1d6:	7d42                	ld	s10,48(sp)
 1d8:	7da2                	ld	s11,40(sp)
 1da:	6149                	addi	sp,sp,144
 1dc:	8082                	ret

00000000000001de <render>:

// Render grid into a 32-bit BGRX pixel buffer
static void
render(const uint8 *g, uint32 *fb, uint32 alive_color, uint32 dead_color)
{
 1de:	7139                	addi	sp,sp,-64
 1e0:	fc22                	sd	s0,56(sp)
 1e2:	f826                	sd	s1,48(sp)
 1e4:	f44a                	sd	s2,40(sp)
 1e6:	f04e                	sd	s3,32(sp)
 1e8:	ec52                	sd	s4,24(sp)
 1ea:	e856                	sd	s5,16(sp)
 1ec:	e45a                	sd	s6,8(sp)
 1ee:	0080                	addi	s0,sp,64
 1f0:	8b2a                	mv	s6,a0
 1f2:	8eb2                	mv	t4,a2
 1f4:	8fb6                	mv	t6,a3
    for (int cy = 0; cy < GRID_H; cy++)
 1f6:	02058393          	addi	t2,a1,32
{
 1fa:	4981                	li	s3,0
 1fc:	6285                	lui	t0,0x1
 1fe:	40028293          	addi	t0,t0,1024 # 1400 <digits+0x1f0>
 202:	4481                	li	s1,0
 204:	7e7d                	lui	t3,0xfffff
 206:	c00e0e1b          	addiw	t3,t3,-1024
    {
        uint32 c = g[cy * GRID_W] ? alive_color : dead_color; // dummy init
        for (int cx = 0; cx < GRID_W; cx++)
        {
            c = g[cy * GRID_W + cx] ? alive_color : dead_color;
            for (int py = 0; py < CELL_H; py++)
 20a:	6785                	lui	a5,0x1
 20c:	a0078513          	addi	a0,a5,-1536 # a00 <memmove+0x2e>
        for (int cx = 0; cx < GRID_W; cx++)
 210:	05000f13          	li	t5,80
    for (int cy = 0; cy < GRID_H; cy++)
 214:	6905                	lui	s2,0x1
 216:	4009091b          	addiw	s2,s2,1024
 21a:	6a15                	lui	s4,0x5
 21c:	2c078a93          	addi	s5,a5,704
 220:	a0a9                	j	26a <render+0x8c>
            for (int py = 0; py < CELL_H; py++)
 222:	00be063b          	addw	a2,t3,a1
            c = g[cy * GRID_W + cx] ? alive_color : dead_color;
 226:	8746                	mv	a4,a7
            {
                int base = ((cy * CELL_H + py) * SCREEN_W) + cx * CELL_W;
                for (int px = 0; px < CELL_W; px++)
 228:	fe070793          	addi	a5,a4,-32
                    fb[base + px] = c;
 22c:	c394                	sw	a3,0(a5)
                for (int px = 0; px < CELL_W; px++)
 22e:	0791                	addi	a5,a5,4
 230:	fee79ee3          	bne	a5,a4,22c <render+0x4e>
            for (int py = 0; py < CELL_H; py++)
 234:	2806061b          	addiw	a2,a2,640
 238:	972a                	add	a4,a4,a0
 23a:	feb617e3          	bne	a2,a1,228 <render+0x4a>
        for (int cx = 0; cx < GRID_W; cx++)
 23e:	0805                	addi	a6,a6,1
 240:	25a1                	addiw	a1,a1,8
 242:	02088893          	addi	a7,a7,32
 246:	01e80a63          	beq	a6,t5,25a <render+0x7c>
            c = g[cy * GRID_W + cx] ? alive_color : dead_color;
 24a:	010307b3          	add	a5,t1,a6
 24e:	0007c783          	lbu	a5,0(a5)
 252:	86f6                	mv	a3,t4
 254:	f7f9                	bnez	a5,222 <render+0x44>
 256:	86fe                	mv	a3,t6
 258:	b7e9                	j	222 <render+0x44>
    for (int cy = 0; cy < GRID_H; cy++)
 25a:	0485                	addi	s1,s1,1
 25c:	005902bb          	addw	t0,s2,t0
 260:	93d2                	add	t2,t2,s4
 262:	0509899b          	addiw	s3,s3,80
 266:	01598b63          	beq	s3,s5,27c <render+0x9e>
        for (int cx = 0; cx < GRID_W; cx++)
 26a:	00249313          	slli	t1,s1,0x2
 26e:	9326                	add	t1,t1,s1
 270:	0312                	slli	t1,t1,0x4
 272:	935a                	add	t1,t1,s6
{
 274:	889e                	mv	a7,t2
 276:	8596                	mv	a1,t0
 278:	4801                	li	a6,0
 27a:	bfc1                	j	24a <render+0x6c>
            }
        }
    }
}
 27c:	7462                	ld	s0,56(sp)
 27e:	74c2                	ld	s1,48(sp)
 280:	7922                	ld	s2,40(sp)
 282:	7982                	ld	s3,32(sp)
 284:	6a62                	ld	s4,24(sp)
 286:	6ac2                	ld	s5,16(sp)
 288:	6b22                	ld	s6,8(sp)
 28a:	6121                	addi	sp,sp,64
 28c:	8082                	ret

000000000000028e <init_gliders>:
// Classic NE-moving glider:  . X .
//                            . . X
//                            X X X
static void
init_gliders(uint8 *g)
{
 28e:	7135                	addi	sp,sp,-160
 290:	ed06                	sd	ra,152(sp)
 292:	e922                	sd	s0,144(sp)
 294:	e526                	sd	s1,136(sp)
 296:	e14a                	sd	s2,128(sp)
 298:	fcce                	sd	s3,120(sp)
 29a:	f8d2                	sd	s4,112(sp)
 29c:	f4d6                	sd	s5,104(sp)
 29e:	f0da                	sd	s6,96(sp)
 2a0:	ecde                	sd	s7,88(sp)
 2a2:	1100                	addi	s0,sp,160
 2a4:	892a                	mv	s2,a0
    // 9 gliders spread across the grid
    int origins[][2] = {
 2a6:	00001797          	auipc	a5,0x1
 2aa:	da278793          	addi	a5,a5,-606 # 1048 <malloc+0x17e>
 2ae:	0007b303          	ld	t1,0(a5)
 2b2:	0087b883          	ld	a7,8(a5)
 2b6:	0107b803          	ld	a6,16(a5)
 2ba:	6f88                	ld	a0,24(a5)
 2bc:	738c                	ld	a1,32(a5)
 2be:	7790                	ld	a2,40(a5)
 2c0:	7b94                	ld	a3,48(a5)
 2c2:	7f98                	ld	a4,56(a5)
 2c4:	63bc                	ld	a5,64(a5)
 2c6:	f6643423          	sd	t1,-152(s0)
 2ca:	f7143823          	sd	a7,-144(s0)
 2ce:	f7043c23          	sd	a6,-136(s0)
 2d2:	f8a43023          	sd	a0,-128(s0)
 2d6:	f8b43423          	sd	a1,-120(s0)
 2da:	f8c43823          	sd	a2,-112(s0)
 2de:	f8d43c23          	sd	a3,-104(s0)
 2e2:	fae43023          	sd	a4,-96(s0)
 2e6:	faf43423          	sd	a5,-88(s0)
        {57, 25},
        {3, 48},
        {30, 48},
        {57, 48},
    };
    for (int k = 0; k < 9; k++)
 2ea:	f6840993          	addi	s3,s0,-152
 2ee:	fb040b93          	addi	s7,s0,-80
    {
        int cx = origins[k][0], cy = origins[k][1];
 2f2:	0009aa03          	lw	s4,0(s3)
 2f6:	0049a483          	lw	s1,4(s3)
        cell_set(g, cx + 1, cy + 0);
 2fa:	001a0b1b          	addiw	s6,s4,1
 2fe:	8626                	mv	a2,s1
 300:	85da                	mv	a1,s6
 302:	854a                	mv	a0,s2
 304:	00000097          	auipc	ra,0x0
 308:	d3a080e7          	jalr	-710(ra) # 3e <cell_set>
        cell_set(g, cx + 2, cy + 1);
 30c:	002a0a9b          	addiw	s5,s4,2
 310:	0014861b          	addiw	a2,s1,1
 314:	85d6                	mv	a1,s5
 316:	854a                	mv	a0,s2
 318:	00000097          	auipc	ra,0x0
 31c:	d26080e7          	jalr	-730(ra) # 3e <cell_set>
        cell_set(g, cx + 0, cy + 2);
 320:	2489                	addiw	s1,s1,2
 322:	8626                	mv	a2,s1
 324:	85d2                	mv	a1,s4
 326:	854a                	mv	a0,s2
 328:	00000097          	auipc	ra,0x0
 32c:	d16080e7          	jalr	-746(ra) # 3e <cell_set>
        cell_set(g, cx + 1, cy + 2);
 330:	8626                	mv	a2,s1
 332:	85da                	mv	a1,s6
 334:	854a                	mv	a0,s2
 336:	00000097          	auipc	ra,0x0
 33a:	d08080e7          	jalr	-760(ra) # 3e <cell_set>
        cell_set(g, cx + 2, cy + 2);
 33e:	8626                	mv	a2,s1
 340:	85d6                	mv	a1,s5
 342:	854a                	mv	a0,s2
 344:	00000097          	auipc	ra,0x0
 348:	cfa080e7          	jalr	-774(ra) # 3e <cell_set>
    for (int k = 0; k < 9; k++)
 34c:	09a1                	addi	s3,s3,8
 34e:	fb7992e3          	bne	s3,s7,2f2 <init_gliders+0x64>
    }
}
 352:	60ea                	ld	ra,152(sp)
 354:	644a                	ld	s0,144(sp)
 356:	64aa                	ld	s1,136(sp)
 358:	690a                	ld	s2,128(sp)
 35a:	79e6                	ld	s3,120(sp)
 35c:	7a46                	ld	s4,112(sp)
 35e:	7aa6                	ld	s5,104(sp)
 360:	7b06                	ld	s6,96(sp)
 362:	6be6                	ld	s7,88(sp)
 364:	610d                	addi	sp,sp,160
 366:	8082                	ret

0000000000000368 <init_rpentominos>:
//               X X .
//               . X .
// Five copies scattered — each evolves chaotically for ~1100 steps.
static void
init_rpentominos(uint8 *g)
{
 368:	7119                	addi	sp,sp,-128
 36a:	fc86                	sd	ra,120(sp)
 36c:	f8a2                	sd	s0,112(sp)
 36e:	f4a6                	sd	s1,104(sp)
 370:	f0ca                	sd	s2,96(sp)
 372:	ecce                	sd	s3,88(sp)
 374:	e8d2                	sd	s4,80(sp)
 376:	e4d6                	sd	s5,72(sp)
 378:	e0da                	sd	s6,64(sp)
 37a:	fc5e                	sd	s7,56(sp)
 37c:	0100                	addi	s0,sp,128
 37e:	84aa                	mv	s1,a0
    int origins[][2] = {{15, 10}, {55, 10}, {35, 30}, {15, 48}, {55, 48}};
 380:	00001797          	auipc	a5,0x1
 384:	cc878793          	addi	a5,a5,-824 # 1048 <malloc+0x17e>
 388:	67ac                	ld	a1,72(a5)
 38a:	6bb0                	ld	a2,80(a5)
 38c:	6fb4                	ld	a3,88(a5)
 38e:	73b8                	ld	a4,96(a5)
 390:	77bc                	ld	a5,104(a5)
 392:	f8b43423          	sd	a1,-120(s0)
 396:	f8c43823          	sd	a2,-112(s0)
 39a:	f8d43c23          	sd	a3,-104(s0)
 39e:	fae43023          	sd	a4,-96(s0)
 3a2:	faf43423          	sd	a5,-88(s0)
    for (int k = 0; k < 5; k++)
 3a6:	f8840913          	addi	s2,s0,-120
 3aa:	fb040b93          	addi	s7,s0,-80
    {
        int cx = origins[k][0], cy = origins[k][1];
 3ae:	00092a83          	lw	s5,0(s2) # 1000 <malloc+0x136>
 3b2:	00492983          	lw	s3,4(s2)
        cell_set(g, cx + 1, cy + 0);
 3b6:	001a8a1b          	addiw	s4,s5,1
 3ba:	864e                	mv	a2,s3
 3bc:	85d2                	mv	a1,s4
 3be:	8526                	mv	a0,s1
 3c0:	00000097          	auipc	ra,0x0
 3c4:	c7e080e7          	jalr	-898(ra) # 3e <cell_set>
        cell_set(g, cx + 2, cy + 0);
 3c8:	864e                	mv	a2,s3
 3ca:	002a859b          	addiw	a1,s5,2
 3ce:	8526                	mv	a0,s1
 3d0:	00000097          	auipc	ra,0x0
 3d4:	c6e080e7          	jalr	-914(ra) # 3e <cell_set>
        cell_set(g, cx + 0, cy + 1);
 3d8:	00198b1b          	addiw	s6,s3,1
 3dc:	865a                	mv	a2,s6
 3de:	85d6                	mv	a1,s5
 3e0:	8526                	mv	a0,s1
 3e2:	00000097          	auipc	ra,0x0
 3e6:	c5c080e7          	jalr	-932(ra) # 3e <cell_set>
        cell_set(g, cx + 1, cy + 1);
 3ea:	865a                	mv	a2,s6
 3ec:	85d2                	mv	a1,s4
 3ee:	8526                	mv	a0,s1
 3f0:	00000097          	auipc	ra,0x0
 3f4:	c4e080e7          	jalr	-946(ra) # 3e <cell_set>
        cell_set(g, cx + 1, cy + 2);
 3f8:	0029861b          	addiw	a2,s3,2
 3fc:	85d2                	mv	a1,s4
 3fe:	8526                	mv	a0,s1
 400:	00000097          	auipc	ra,0x0
 404:	c3e080e7          	jalr	-962(ra) # 3e <cell_set>
    for (int k = 0; k < 5; k++)
 408:	0921                	addi	s2,s2,8
 40a:	fb7912e3          	bne	s2,s7,3ae <init_rpentominos+0x46>
    }
}
 40e:	70e6                	ld	ra,120(sp)
 410:	7446                	ld	s0,112(sp)
 412:	74a6                	ld	s1,104(sp)
 414:	7906                	ld	s2,96(sp)
 416:	69e6                	ld	s3,88(sp)
 418:	6a46                	ld	s4,80(sp)
 41a:	6aa6                	ld	s5,72(sp)
 41c:	6b06                	ld	s6,64(sp)
 41e:	7be2                	ld	s7,56(sp)
 420:	6109                	addi	sp,sp,128
 422:	8082                	ret

0000000000000424 <init_glider_gun>:
// ── Pattern 3: Gosper Glider Gun ─────────────────────────────────────
// Emits a new NE-glider every 30 generations.
// Placed in the upper-left quadrant; gliders travel SE.
static void
init_glider_gun(uint8 *g)
{
 424:	7179                	addi	sp,sp,-48
 426:	f406                	sd	ra,40(sp)
 428:	f022                	sd	s0,32(sp)
 42a:	ec26                	sd	s1,24(sp)
 42c:	e84a                	sd	s2,16(sp)
 42e:	e44e                	sd	s3,8(sp)
 430:	1800                	addi	s0,sp,48
 432:	892a                	mv	s2,a0
    static const int cells[][2] = {
        {24, 0}, {25, 0}, {22, 1}, {26, 1}, {12, 2}, {13, 2}, {20, 2}, {21, 2}, {34, 2}, {35, 2}, {11, 3}, {15, 3}, {20, 3}, {21, 3}, {34, 3}, {35, 3}, {0, 4}, {1, 4}, {10, 4}, {16, 4}, {20, 4}, {21, 4}, {0, 5}, {1, 5}, {10, 5}, {14, 5}, {15, 5}, {22, 5}, {26, 5}, {10, 6}, {16, 6}, {23, 6}, {24, 6}, {25, 6}, {11, 7}, {15, 7}, {26, 7}, {12, 8}, {13, 8}, {24, 9}, {25, 9}, {-1, -1} // sentinel
    };
    // Offset so the gun sits in the upper-left with a small margin.
    int ox = 2, oy = 12;
    for (int i = 0; cells[i][0] != -1; i++)
 434:	00001497          	auipc	s1,0x1
 438:	c8848493          	addi	s1,s1,-888 # 10bc <cells.0+0x4>
 43c:	45e1                	li	a1,24
 43e:	59fd                	li	s3,-1
        cell_set(g, ox + cells[i][0], oy + cells[i][1]);
 440:	4090                	lw	a2,0(s1)
 442:	2631                	addiw	a2,a2,12
 444:	2589                	addiw	a1,a1,2
 446:	854a                	mv	a0,s2
 448:	00000097          	auipc	ra,0x0
 44c:	bf6080e7          	jalr	-1034(ra) # 3e <cell_set>
    for (int i = 0; cells[i][0] != -1; i++)
 450:	04a1                	addi	s1,s1,8
 452:	ffc4a583          	lw	a1,-4(s1)
 456:	ff3595e3          	bne	a1,s3,440 <init_glider_gun+0x1c>
}
 45a:	70a2                	ld	ra,40(sp)
 45c:	7402                	ld	s0,32(sp)
 45e:	64e2                	ld	s1,24(sp)
 460:	6942                	ld	s2,16(sp)
 462:	69a2                	ld	s3,8(sp)
 464:	6145                	addi	sp,sp,48
 466:	8082                	ret

0000000000000468 <grid_clear>:
{
 468:	1141                	addi	sp,sp,-16
 46a:	e406                	sd	ra,8(sp)
 46c:	e022                	sd	s0,0(sp)
 46e:	0800                	addi	s0,sp,16
    memset(g, 0, GRID_W * GRID_H);
 470:	6605                	lui	a2,0x1
 472:	2c060613          	addi	a2,a2,704 # 12c0 <digits+0xb0>
 476:	4581                	li	a1,0
 478:	00000097          	auipc	ra,0x0
 47c:	410080e7          	jalr	1040(ra) # 888 <memset>
}
 480:	60a2                	ld	ra,8(sp)
 482:	6402                	ld	s0,0(sp)
 484:	0141                	addi	sp,sp,16
 486:	8082                	ret

0000000000000488 <alloc_fb>:
{
 488:	1141                	addi	sp,sp,-16
 48a:	e406                	sd	ra,8(sp)
 48c:	e022                	sd	s0,0(sp)
 48e:	0800                	addi	s0,sp,16
    char *p = sbrk(FB_BYTES);
 490:	0012c537          	lui	a0,0x12c
 494:	00000097          	auipc	ra,0x0
 498:	678080e7          	jalr	1656(ra) # b0c <sbrk>
    if (p == (char *)-1)
 49c:	57fd                	li	a5,-1
 49e:	00f50663          	beq	a0,a5,4aa <alloc_fb+0x22>
}
 4a2:	60a2                	ld	ra,8(sp)
 4a4:	6402                	ld	s0,0(sp)
 4a6:	0141                	addi	sp,sp,16
 4a8:	8082                	ret
        fprintf(2, "gol: sbrk failed\n");
 4aa:	00001597          	auipc	a1,0x1
 4ae:	b0658593          	addi	a1,a1,-1274 # fb0 <malloc+0xe6>
 4b2:	4509                	li	a0,2
 4b4:	00001097          	auipc	ra,0x1
 4b8:	92a080e7          	jalr	-1750(ra) # dde <fprintf>
        exit(1);
 4bc:	4505                	li	a0,1
 4be:	00000097          	auipc	ra,0x0
 4c2:	5c6080e7          	jalr	1478(ra) # a84 <exit>

00000000000004c6 <main>:

// ── main ──────────────────────────────────────────────────────────────
int main(int argc, char *argv[])
{
 4c6:	7131                	addi	sp,sp,-192
 4c8:	fd06                	sd	ra,184(sp)
 4ca:	f922                	sd	s0,176(sp)
 4cc:	f526                	sd	s1,168(sp)
 4ce:	f14a                	sd	s2,160(sp)
 4d0:	ed4e                	sd	s3,152(sp)
 4d2:	e952                	sd	s4,144(sp)
 4d4:	e556                	sd	s5,136(sp)
 4d6:	e15a                	sd	s6,128(sp)
 4d8:	fcde                	sd	s7,120(sp)
 4da:	f8e2                	sd	s8,112(sp)
 4dc:	f4e6                	sd	s9,104(sp)
 4de:	f0ea                	sd	s10,96(sp)
 4e0:	0180                	addi	s0,sp,192
    // Pick display mode: default "flip", or "map" if requested.
    int use_map = 0;
    if (argc > 1)
 4e2:	4785                	li	a5,1
    int use_map = 0;
 4e4:	4981                	li	s3,0
    if (argc > 1)
 4e6:	0aa7c563          	blt	a5,a0,590 <main+0xca>
            exit(1);
        }
    }

    // Pattern colours (BGRX little-endian: value = R<<16 | G<<8 | B)
    uint32 colors_alive[3] = {
 4ea:	67c1                	lui	a5,0x10
 4ec:	f0078793          	addi	a5,a5,-256 # ff00 <base+0xb970>
 4f0:	f8f42823          	sw	a5,-112(s0)
 4f4:	00ffd7b7          	lui	a5,0xffd
 4f8:	80078793          	addi	a5,a5,-2048 # ffc800 <base+0xff8270>
 4fc:	f8f42a23          	sw	a5,-108(s0)
 500:	67b5                	lui	a5,0xd
 502:	8ff78793          	addi	a5,a5,-1793 # c8ff <base+0x836f>
 506:	f8f42c23          	sw	a5,-104(s0)
        rgb(0, 255, 0),   // green  – gliders
        rgb(255, 200, 0), // amber  – R-pentominoes
        rgb(0, 200, 255), // cyan   – glider gun
    };
    uint32 colors_dead[3] = {
 50a:	000a17b7          	lui	a5,0xa1
 50e:	40a78793          	addi	a5,a5,1034 # a140a <base+0x9ce7a>
 512:	f8f42023          	sw	a5,-128(s0)
 516:	001417b7          	lui	a5,0x141
 51a:	f0578793          	addi	a5,a5,-251 # 140f05 <base+0x13c975>
 51e:	f8f42223          	sw	a5,-124(s0)
 522:	000517b7          	lui	a5,0x51
 526:	f1978793          	addi	a5,a5,-231 # 50f19 <base+0x4c989>
 52a:	f8f42423          	sw	a5,-120(s0)
        rgb(10, 20, 10), // dark green tint background
        rgb(20, 15, 5),  // dark amber tint
        rgb(5, 15, 25),  // dark cyan tint
    };
    void (*inits[3])(uint8 *) = {
 52e:	00000797          	auipc	a5,0x0
 532:	d6078793          	addi	a5,a5,-672 # 28e <init_gliders>
 536:	f6f43423          	sd	a5,-152(s0)
 53a:	00000797          	auipc	a5,0x0
 53e:	e2e78793          	addi	a5,a5,-466 # 368 <init_rpentominos>
 542:	f6f43823          	sd	a5,-144(s0)
 546:	00000797          	auipc	a5,0x0
 54a:	ede78793          	addi	a5,a5,-290 # 424 <init_glider_gun>
 54e:	f6f43c23          	sd	a5,-136(s0)
        init_gliders,
        init_rpentominos,
        init_glider_gun,
    };
    int gens[3] = {100, 100, 100};
 552:	06400793          	li	a5,100
 556:	f4f42c23          	sw	a5,-168(s0)
 55a:	f4f42e23          	sw	a5,-164(s0)
 55e:	f6f42023          	sw	a5,-160(s0)

    for (int i = 0; i < 3; i++)
 562:	4901                	li	s2,0
 564:	4a0d                	li	s4,3
    {
        int pid = fork();
 566:	00000097          	auipc	ra,0x0
 56a:	516080e7          	jalr	1302(ra) # a7c <fork>
 56e:	84aa                	mv	s1,a0
        if (pid < 0)
 570:	06054663          	bltz	a0,5dc <main+0x116>
        {
            fprintf(2, "gol: fork failed\n");
            exit(1);
        }
        if (pid == 0)
 574:	c151                	beqz	a0,5f8 <main+0x132>
            else
                run_pattern_flip(inits[i], colors_alive[i], colors_dead[i], gens[i]);
            exit(0);
        }
        // Parent: wait for child before starting the next pattern.
        wait(0);
 576:	4501                	li	a0,0
 578:	00000097          	auipc	ra,0x0
 57c:	514080e7          	jalr	1300(ra) # a8c <wait>
    for (int i = 0; i < 3; i++)
 580:	2905                	addiw	s2,s2,1
 582:	ff4912e3          	bne	s2,s4,566 <main+0xa0>
    }

    exit(0);
 586:	4501                	li	a0,0
 588:	00000097          	auipc	ra,0x0
 58c:	4fc080e7          	jalr	1276(ra) # a84 <exit>
 590:	84ae                	mv	s1,a1
        if (strcmp(argv[1], "map") == 0)
 592:	00001597          	auipc	a1,0x1
 596:	a3658593          	addi	a1,a1,-1482 # fc8 <malloc+0xfe>
 59a:	6488                	ld	a0,8(s1)
 59c:	00000097          	auipc	ra,0x0
 5a0:	296080e7          	jalr	662(ra) # 832 <strcmp>
            use_map = 1;
 5a4:	4985                	li	s3,1
        if (strcmp(argv[1], "map") == 0)
 5a6:	d131                	beqz	a0,4ea <main+0x24>
        else if (strcmp(argv[1], "flip") == 0)
 5a8:	00001597          	auipc	a1,0x1
 5ac:	a2858593          	addi	a1,a1,-1496 # fd0 <malloc+0x106>
 5b0:	6488                	ld	a0,8(s1)
 5b2:	00000097          	auipc	ra,0x0
 5b6:	280080e7          	jalr	640(ra) # 832 <strcmp>
 5ba:	89aa                	mv	s3,a0
 5bc:	d51d                	beqz	a0,4ea <main+0x24>
            fprintf(2, "usage: %s [flip|map]\n", argv[0]);
 5be:	6090                	ld	a2,0(s1)
 5c0:	00001597          	auipc	a1,0x1
 5c4:	a1858593          	addi	a1,a1,-1512 # fd8 <malloc+0x10e>
 5c8:	4509                	li	a0,2
 5ca:	00001097          	auipc	ra,0x1
 5ce:	814080e7          	jalr	-2028(ra) # dde <fprintf>
            exit(1);
 5d2:	4505                	li	a0,1
 5d4:	00000097          	auipc	ra,0x0
 5d8:	4b0080e7          	jalr	1200(ra) # a84 <exit>
            fprintf(2, "gol: fork failed\n");
 5dc:	00001597          	auipc	a1,0x1
 5e0:	a1458593          	addi	a1,a1,-1516 # ff0 <malloc+0x126>
 5e4:	4509                	li	a0,2
 5e6:	00000097          	auipc	ra,0x0
 5ea:	7f8080e7          	jalr	2040(ra) # dde <fprintf>
            exit(1);
 5ee:	4505                	li	a0,1
 5f0:	00000097          	auipc	ra,0x0
 5f4:	494080e7          	jalr	1172(ra) # a84 <exit>
            if (use_map)
 5f8:	0e098263          	beqz	s3,6dc <main+0x216>
                run_pattern_map(inits[i], colors_alive[i], colors_dead[i], gens[i]);
 5fc:	00391793          	slli	a5,s2,0x3
 600:	fa040713          	addi	a4,s0,-96
 604:	97ba                	add	a5,a5,a4
 606:	fc87b983          	ld	s3,-56(a5)
 60a:	00291793          	slli	a5,s2,0x2
 60e:	97ba                	add	a5,a5,a4
 610:	ff07ab83          	lw	s7,-16(a5)
 614:	fe07ac03          	lw	s8,-32(a5)
 618:	fb87ac83          	lw	s9,-72(a5)
    uint32 *fb = (uint32 *)map_display(0);
 61c:	4501                	li	a0,0
 61e:	00000097          	auipc	ra,0x0
 622:	50e080e7          	jalr	1294(ra) # b2c <map_display>
 626:	8b2a                	mv	s6,a0
    if (fb == (uint32 *)-1)
 628:	57fd                	li	a5,-1
 62a:	04f50063          	beq	a0,a5,66a <main+0x1a4>
    grid_clear(grid[0]);
 62e:	00002517          	auipc	a0,0x2
 632:	9e250513          	addi	a0,a0,-1566 # 2010 <grid>
 636:	00000097          	auipc	ra,0x0
 63a:	e32080e7          	jalr	-462(ra) # 468 <grid_clear>
    grid_clear(grid[1]);
 63e:	00003517          	auipc	a0,0x3
 642:	c9250513          	addi	a0,a0,-878 # 32d0 <grid+0x12c0>
 646:	00000097          	auipc	ra,0x0
 64a:	e22080e7          	jalr	-478(ra) # 468 <grid_clear>
    init_fn(grid[0]);
 64e:	00002517          	auipc	a0,0x2
 652:	9c250513          	addi	a0,a0,-1598 # 2010 <grid>
 656:	9982                	jalr	s3
    for (int gen = 0; gen < generations; gen++)
 658:	89a6                	mv	s3,s1
        render(grid[cur], fb, alive_color, dead_color);
 65a:	6a05                	lui	s4,0x1
 65c:	2c0a0a13          	addi	s4,s4,704 # 12c0 <digits+0xb0>
 660:	00002a97          	auipc	s5,0x2
 664:	9b0a8a93          	addi	s5,s5,-1616 # 2010 <grid>
    for (int gen = 0; gen < generations; gen++)
 668:	a899                	j	6be <main+0x1f8>
        fprintf(2, "gol: map_display failed\n");
 66a:	00001597          	auipc	a1,0x1
 66e:	99e58593          	addi	a1,a1,-1634 # 1008 <malloc+0x13e>
 672:	4509                	li	a0,2
 674:	00000097          	auipc	ra,0x0
 678:	76a080e7          	jalr	1898(ra) # dde <fprintf>
        exit(1);
 67c:	4505                	li	a0,1
 67e:	00000097          	auipc	ra,0x0
 682:	406080e7          	jalr	1030(ra) # a84 <exit>
        render(grid[cur], fb, alive_color, dead_color);
 686:	03448933          	mul	s2,s1,s4
 68a:	9956                	add	s2,s2,s5
 68c:	86e2                	mv	a3,s8
 68e:	865e                	mv	a2,s7
 690:	85da                	mv	a1,s6
 692:	854a                	mv	a0,s2
 694:	00000097          	auipc	ra,0x0
 698:	b4a080e7          	jalr	-1206(ra) # 1de <render>
        sleep(1); // wait for the daemon tick to flush
 69c:	4505                	li	a0,1
 69e:	00000097          	auipc	ra,0x0
 6a2:	476080e7          	jalr	1142(ra) # b14 <sleep>
        gol_step(grid[cur], grid[cur ^ 1]);
 6a6:	0014c493          	xori	s1,s1,1
 6aa:	2481                	sext.w	s1,s1
 6ac:	034485b3          	mul	a1,s1,s4
 6b0:	95d6                	add	a1,a1,s5
 6b2:	854a                	mv	a0,s2
 6b4:	00000097          	auipc	ra,0x0
 6b8:	9ca080e7          	jalr	-1590(ra) # 7e <gol_step>
    for (int gen = 0; gen < generations; gen++)
 6bc:	2985                	addiw	s3,s3,1
 6be:	fd99c4e3          	blt	s3,s9,686 <main+0x1c0>
    memset(fb, 0, FB_BYTES);
 6c2:	0012c637          	lui	a2,0x12c
 6c6:	4581                	li	a1,0
 6c8:	855a                	mv	a0,s6
 6ca:	00000097          	auipc	ra,0x0
 6ce:	1be080e7          	jalr	446(ra) # 888 <memset>
            exit(0);
 6d2:	4501                	li	a0,0
 6d4:	00000097          	auipc	ra,0x0
 6d8:	3b0080e7          	jalr	944(ra) # a84 <exit>
                run_pattern_flip(inits[i], colors_alive[i], colors_dead[i], gens[i]);
 6dc:	00391793          	slli	a5,s2,0x3
 6e0:	fa040713          	addi	a4,s0,-96
 6e4:	97ba                	add	a5,a5,a4
 6e6:	fc87b483          	ld	s1,-56(a5)
 6ea:	00291793          	slli	a5,s2,0x2
 6ee:	97ba                	add	a5,a5,a4
 6f0:	ff07ab83          	lw	s7,-16(a5)
 6f4:	fe07ac03          	lw	s8,-32(a5)
 6f8:	fb87ac83          	lw	s9,-72(a5)
    buf[0] = alloc_fb();
 6fc:	00000097          	auipc	ra,0x0
 700:	d8c080e7          	jalr	-628(ra) # 488 <alloc_fb>
 704:	f4a43423          	sd	a0,-184(s0)
    buf[1] = alloc_fb();
 708:	00000097          	auipc	ra,0x0
 70c:	d80080e7          	jalr	-640(ra) # 488 <alloc_fb>
 710:	f4a43823          	sd	a0,-176(s0)
    grid_clear(grid[0]);
 714:	00002517          	auipc	a0,0x2
 718:	8fc50513          	addi	a0,a0,-1796 # 2010 <grid>
 71c:	00000097          	auipc	ra,0x0
 720:	d4c080e7          	jalr	-692(ra) # 468 <grid_clear>
    grid_clear(grid[1]);
 724:	00003517          	auipc	a0,0x3
 728:	bac50513          	addi	a0,a0,-1108 # 32d0 <grid+0x12c0>
 72c:	00000097          	auipc	ra,0x0
 730:	d3c080e7          	jalr	-708(ra) # 468 <grid_clear>
    init_fn(grid[0]);
 734:	00002517          	auipc	a0,0x2
 738:	8dc50513          	addi	a0,a0,-1828 # 2010 <grid>
 73c:	9482                	jalr	s1
    for (int gen = 0; gen < generations; gen++)
 73e:	0b905d63          	blez	s9,7f8 <main+0x332>
 742:	8a4e                	mv	s4,s3
    int draw = 0; // index into buf[] for the next draw target
 744:	84ce                	mv	s1,s3
        render(grid[cur], buf[draw], alive_color, dead_color);
 746:	6a85                	lui	s5,0x1
 748:	2c0a8a93          	addi	s5,s5,704 # 12c0 <digits+0xb0>
 74c:	00002b17          	auipc	s6,0x2
 750:	8c4b0b13          	addi	s6,s6,-1852 # 2010 <grid>
 754:	03598933          	mul	s2,s3,s5
 758:	995a                	add	s2,s2,s6
 75a:	00349793          	slli	a5,s1,0x3
 75e:	fa040713          	addi	a4,s0,-96
 762:	97ba                	add	a5,a5,a4
 764:	fa87bd03          	ld	s10,-88(a5)
 768:	86e2                	mv	a3,s8
 76a:	865e                	mv	a2,s7
 76c:	85ea                	mv	a1,s10
 76e:	854a                	mv	a0,s2
 770:	00000097          	auipc	ra,0x0
 774:	a6e080e7          	jalr	-1426(ra) # 1de <render>
        if (flip_display(buf[draw]) < 0)
 778:	856a                	mv	a0,s10
 77a:	00000097          	auipc	ra,0x0
 77e:	3aa080e7          	jalr	938(ra) # b24 <flip_display>
 782:	04054d63          	bltz	a0,7dc <main+0x316>
        sleep(1);
 786:	4505                	li	a0,1
 788:	00000097          	auipc	ra,0x0
 78c:	38c080e7          	jalr	908(ra) # b14 <sleep>
        gol_step(grid[cur], grid[cur ^ 1]);
 790:	0019c993          	xori	s3,s3,1
 794:	2981                	sext.w	s3,s3
 796:	035985b3          	mul	a1,s3,s5
 79a:	95da                	add	a1,a1,s6
 79c:	854a                	mv	a0,s2
 79e:	00000097          	auipc	ra,0x0
 7a2:	8e0080e7          	jalr	-1824(ra) # 7e <gol_step>
        draw ^= 1;
 7a6:	0014c493          	xori	s1,s1,1
 7aa:	2481                	sext.w	s1,s1
    for (int gen = 0; gen < generations; gen++)
 7ac:	2a05                	addiw	s4,s4,1
 7ae:	fb4c93e3          	bne	s9,s4,754 <main+0x28e>
    memset(buf[draw], 0, FB_BYTES);
 7b2:	00349793          	slli	a5,s1,0x3
 7b6:	fa040713          	addi	a4,s0,-96
 7ba:	97ba                	add	a5,a5,a4
 7bc:	fa87b483          	ld	s1,-88(a5)
 7c0:	0012c637          	lui	a2,0x12c
 7c4:	4581                	li	a1,0
 7c6:	8526                	mv	a0,s1
 7c8:	00000097          	auipc	ra,0x0
 7cc:	0c0080e7          	jalr	192(ra) # 888 <memset>
    flip_display(buf[draw]);
 7d0:	8526                	mv	a0,s1
 7d2:	00000097          	auipc	ra,0x0
 7d6:	352080e7          	jalr	850(ra) # b24 <flip_display>
}
 7da:	bde5                	j	6d2 <main+0x20c>
            fprintf(2, "gol: flip_display failed\n");
 7dc:	00001597          	auipc	a1,0x1
 7e0:	84c58593          	addi	a1,a1,-1972 # 1028 <malloc+0x15e>
 7e4:	4509                	li	a0,2
 7e6:	00000097          	auipc	ra,0x0
 7ea:	5f8080e7          	jalr	1528(ra) # dde <fprintf>
            exit(1);
 7ee:	4505                	li	a0,1
 7f0:	00000097          	auipc	ra,0x0
 7f4:	294080e7          	jalr	660(ra) # a84 <exit>
    int draw = 0; // index into buf[] for the next draw target
 7f8:	84ce                	mv	s1,s3
 7fa:	bf65                	j	7b2 <main+0x2ec>

00000000000007fc <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 7fc:	1141                	addi	sp,sp,-16
 7fe:	e406                	sd	ra,8(sp)
 800:	e022                	sd	s0,0(sp)
 802:	0800                	addi	s0,sp,16
  extern int main();
  main();
 804:	00000097          	auipc	ra,0x0
 808:	cc2080e7          	jalr	-830(ra) # 4c6 <main>
  exit(0);
 80c:	4501                	li	a0,0
 80e:	00000097          	auipc	ra,0x0
 812:	276080e7          	jalr	630(ra) # a84 <exit>

0000000000000816 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 816:	1141                	addi	sp,sp,-16
 818:	e422                	sd	s0,8(sp)
 81a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 81c:	87aa                	mv	a5,a0
 81e:	0585                	addi	a1,a1,1
 820:	0785                	addi	a5,a5,1
 822:	fff5c703          	lbu	a4,-1(a1)
 826:	fee78fa3          	sb	a4,-1(a5)
 82a:	fb75                	bnez	a4,81e <strcpy+0x8>
    ;
  return os;
}
 82c:	6422                	ld	s0,8(sp)
 82e:	0141                	addi	sp,sp,16
 830:	8082                	ret

0000000000000832 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 832:	1141                	addi	sp,sp,-16
 834:	e422                	sd	s0,8(sp)
 836:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 838:	00054783          	lbu	a5,0(a0)
 83c:	cb91                	beqz	a5,850 <strcmp+0x1e>
 83e:	0005c703          	lbu	a4,0(a1)
 842:	00f71763          	bne	a4,a5,850 <strcmp+0x1e>
    p++, q++;
 846:	0505                	addi	a0,a0,1
 848:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 84a:	00054783          	lbu	a5,0(a0)
 84e:	fbe5                	bnez	a5,83e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 850:	0005c503          	lbu	a0,0(a1)
}
 854:	40a7853b          	subw	a0,a5,a0
 858:	6422                	ld	s0,8(sp)
 85a:	0141                	addi	sp,sp,16
 85c:	8082                	ret

000000000000085e <strlen>:

uint
strlen(const char *s)
{
 85e:	1141                	addi	sp,sp,-16
 860:	e422                	sd	s0,8(sp)
 862:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 864:	00054783          	lbu	a5,0(a0)
 868:	cf91                	beqz	a5,884 <strlen+0x26>
 86a:	0505                	addi	a0,a0,1
 86c:	87aa                	mv	a5,a0
 86e:	4685                	li	a3,1
 870:	9e89                	subw	a3,a3,a0
 872:	00f6853b          	addw	a0,a3,a5
 876:	0785                	addi	a5,a5,1
 878:	fff7c703          	lbu	a4,-1(a5)
 87c:	fb7d                	bnez	a4,872 <strlen+0x14>
    ;
  return n;
}
 87e:	6422                	ld	s0,8(sp)
 880:	0141                	addi	sp,sp,16
 882:	8082                	ret
  for(n = 0; s[n]; n++)
 884:	4501                	li	a0,0
 886:	bfe5                	j	87e <strlen+0x20>

0000000000000888 <memset>:

void*
memset(void *dst, int c, uint n)
{
 888:	1141                	addi	sp,sp,-16
 88a:	e422                	sd	s0,8(sp)
 88c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 88e:	ca19                	beqz	a2,8a4 <memset+0x1c>
 890:	87aa                	mv	a5,a0
 892:	1602                	slli	a2,a2,0x20
 894:	9201                	srli	a2,a2,0x20
 896:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 89a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 89e:	0785                	addi	a5,a5,1
 8a0:	fee79de3          	bne	a5,a4,89a <memset+0x12>
  }
  return dst;
}
 8a4:	6422                	ld	s0,8(sp)
 8a6:	0141                	addi	sp,sp,16
 8a8:	8082                	ret

00000000000008aa <strchr>:

char*
strchr(const char *s, char c)
{
 8aa:	1141                	addi	sp,sp,-16
 8ac:	e422                	sd	s0,8(sp)
 8ae:	0800                	addi	s0,sp,16
  for(; *s; s++)
 8b0:	00054783          	lbu	a5,0(a0)
 8b4:	cb99                	beqz	a5,8ca <strchr+0x20>
    if(*s == c)
 8b6:	00f58763          	beq	a1,a5,8c4 <strchr+0x1a>
  for(; *s; s++)
 8ba:	0505                	addi	a0,a0,1
 8bc:	00054783          	lbu	a5,0(a0)
 8c0:	fbfd                	bnez	a5,8b6 <strchr+0xc>
      return (char*)s;
  return 0;
 8c2:	4501                	li	a0,0
}
 8c4:	6422                	ld	s0,8(sp)
 8c6:	0141                	addi	sp,sp,16
 8c8:	8082                	ret
  return 0;
 8ca:	4501                	li	a0,0
 8cc:	bfe5                	j	8c4 <strchr+0x1a>

00000000000008ce <gets>:

char*
gets(char *buf, int max)
{
 8ce:	711d                	addi	sp,sp,-96
 8d0:	ec86                	sd	ra,88(sp)
 8d2:	e8a2                	sd	s0,80(sp)
 8d4:	e4a6                	sd	s1,72(sp)
 8d6:	e0ca                	sd	s2,64(sp)
 8d8:	fc4e                	sd	s3,56(sp)
 8da:	f852                	sd	s4,48(sp)
 8dc:	f456                	sd	s5,40(sp)
 8de:	f05a                	sd	s6,32(sp)
 8e0:	ec5e                	sd	s7,24(sp)
 8e2:	1080                	addi	s0,sp,96
 8e4:	8baa                	mv	s7,a0
 8e6:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 8e8:	892a                	mv	s2,a0
 8ea:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 8ec:	4aa9                	li	s5,10
 8ee:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 8f0:	89a6                	mv	s3,s1
 8f2:	2485                	addiw	s1,s1,1
 8f4:	0344d863          	bge	s1,s4,924 <gets+0x56>
    cc = read(0, &c, 1);
 8f8:	4605                	li	a2,1
 8fa:	faf40593          	addi	a1,s0,-81
 8fe:	4501                	li	a0,0
 900:	00000097          	auipc	ra,0x0
 904:	19c080e7          	jalr	412(ra) # a9c <read>
    if(cc < 1)
 908:	00a05e63          	blez	a0,924 <gets+0x56>
    buf[i++] = c;
 90c:	faf44783          	lbu	a5,-81(s0)
 910:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 914:	01578763          	beq	a5,s5,922 <gets+0x54>
 918:	0905                	addi	s2,s2,1
 91a:	fd679be3          	bne	a5,s6,8f0 <gets+0x22>
  for(i=0; i+1 < max; ){
 91e:	89a6                	mv	s3,s1
 920:	a011                	j	924 <gets+0x56>
 922:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 924:	99de                	add	s3,s3,s7
 926:	00098023          	sb	zero,0(s3)
  return buf;
}
 92a:	855e                	mv	a0,s7
 92c:	60e6                	ld	ra,88(sp)
 92e:	6446                	ld	s0,80(sp)
 930:	64a6                	ld	s1,72(sp)
 932:	6906                	ld	s2,64(sp)
 934:	79e2                	ld	s3,56(sp)
 936:	7a42                	ld	s4,48(sp)
 938:	7aa2                	ld	s5,40(sp)
 93a:	7b02                	ld	s6,32(sp)
 93c:	6be2                	ld	s7,24(sp)
 93e:	6125                	addi	sp,sp,96
 940:	8082                	ret

0000000000000942 <stat>:

int
stat(const char *n, struct stat *st)
{
 942:	1101                	addi	sp,sp,-32
 944:	ec06                	sd	ra,24(sp)
 946:	e822                	sd	s0,16(sp)
 948:	e426                	sd	s1,8(sp)
 94a:	e04a                	sd	s2,0(sp)
 94c:	1000                	addi	s0,sp,32
 94e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 950:	4581                	li	a1,0
 952:	00000097          	auipc	ra,0x0
 956:	172080e7          	jalr	370(ra) # ac4 <open>
  if(fd < 0)
 95a:	02054563          	bltz	a0,984 <stat+0x42>
 95e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 960:	85ca                	mv	a1,s2
 962:	00000097          	auipc	ra,0x0
 966:	17a080e7          	jalr	378(ra) # adc <fstat>
 96a:	892a                	mv	s2,a0
  close(fd);
 96c:	8526                	mv	a0,s1
 96e:	00000097          	auipc	ra,0x0
 972:	13e080e7          	jalr	318(ra) # aac <close>
  return r;
}
 976:	854a                	mv	a0,s2
 978:	60e2                	ld	ra,24(sp)
 97a:	6442                	ld	s0,16(sp)
 97c:	64a2                	ld	s1,8(sp)
 97e:	6902                	ld	s2,0(sp)
 980:	6105                	addi	sp,sp,32
 982:	8082                	ret
    return -1;
 984:	597d                	li	s2,-1
 986:	bfc5                	j	976 <stat+0x34>

0000000000000988 <atoi>:

int
atoi(const char *s)
{
 988:	1141                	addi	sp,sp,-16
 98a:	e422                	sd	s0,8(sp)
 98c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 98e:	00054603          	lbu	a2,0(a0)
 992:	fd06079b          	addiw	a5,a2,-48
 996:	0ff7f793          	andi	a5,a5,255
 99a:	4725                	li	a4,9
 99c:	02f76963          	bltu	a4,a5,9ce <atoi+0x46>
 9a0:	86aa                	mv	a3,a0
  n = 0;
 9a2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 9a4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 9a6:	0685                	addi	a3,a3,1
 9a8:	0025179b          	slliw	a5,a0,0x2
 9ac:	9fa9                	addw	a5,a5,a0
 9ae:	0017979b          	slliw	a5,a5,0x1
 9b2:	9fb1                	addw	a5,a5,a2
 9b4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 9b8:	0006c603          	lbu	a2,0(a3)
 9bc:	fd06071b          	addiw	a4,a2,-48
 9c0:	0ff77713          	andi	a4,a4,255
 9c4:	fee5f1e3          	bgeu	a1,a4,9a6 <atoi+0x1e>
  return n;
}
 9c8:	6422                	ld	s0,8(sp)
 9ca:	0141                	addi	sp,sp,16
 9cc:	8082                	ret
  n = 0;
 9ce:	4501                	li	a0,0
 9d0:	bfe5                	j	9c8 <atoi+0x40>

00000000000009d2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 9d2:	1141                	addi	sp,sp,-16
 9d4:	e422                	sd	s0,8(sp)
 9d6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 9d8:	02b57463          	bgeu	a0,a1,a00 <memmove+0x2e>
    while(n-- > 0)
 9dc:	00c05f63          	blez	a2,9fa <memmove+0x28>
 9e0:	1602                	slli	a2,a2,0x20
 9e2:	9201                	srli	a2,a2,0x20
 9e4:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 9e8:	872a                	mv	a4,a0
      *dst++ = *src++;
 9ea:	0585                	addi	a1,a1,1
 9ec:	0705                	addi	a4,a4,1
 9ee:	fff5c683          	lbu	a3,-1(a1)
 9f2:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 9f6:	fee79ae3          	bne	a5,a4,9ea <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 9fa:	6422                	ld	s0,8(sp)
 9fc:	0141                	addi	sp,sp,16
 9fe:	8082                	ret
    dst += n;
 a00:	00c50733          	add	a4,a0,a2
    src += n;
 a04:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 a06:	fec05ae3          	blez	a2,9fa <memmove+0x28>
 a0a:	fff6079b          	addiw	a5,a2,-1
 a0e:	1782                	slli	a5,a5,0x20
 a10:	9381                	srli	a5,a5,0x20
 a12:	fff7c793          	not	a5,a5
 a16:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 a18:	15fd                	addi	a1,a1,-1
 a1a:	177d                	addi	a4,a4,-1
 a1c:	0005c683          	lbu	a3,0(a1)
 a20:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 a24:	fee79ae3          	bne	a5,a4,a18 <memmove+0x46>
 a28:	bfc9                	j	9fa <memmove+0x28>

0000000000000a2a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 a2a:	1141                	addi	sp,sp,-16
 a2c:	e422                	sd	s0,8(sp)
 a2e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 a30:	ca05                	beqz	a2,a60 <memcmp+0x36>
 a32:	fff6069b          	addiw	a3,a2,-1
 a36:	1682                	slli	a3,a3,0x20
 a38:	9281                	srli	a3,a3,0x20
 a3a:	0685                	addi	a3,a3,1
 a3c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 a3e:	00054783          	lbu	a5,0(a0)
 a42:	0005c703          	lbu	a4,0(a1)
 a46:	00e79863          	bne	a5,a4,a56 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 a4a:	0505                	addi	a0,a0,1
    p2++;
 a4c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 a4e:	fed518e3          	bne	a0,a3,a3e <memcmp+0x14>
  }
  return 0;
 a52:	4501                	li	a0,0
 a54:	a019                	j	a5a <memcmp+0x30>
      return *p1 - *p2;
 a56:	40e7853b          	subw	a0,a5,a4
}
 a5a:	6422                	ld	s0,8(sp)
 a5c:	0141                	addi	sp,sp,16
 a5e:	8082                	ret
  return 0;
 a60:	4501                	li	a0,0
 a62:	bfe5                	j	a5a <memcmp+0x30>

0000000000000a64 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 a64:	1141                	addi	sp,sp,-16
 a66:	e406                	sd	ra,8(sp)
 a68:	e022                	sd	s0,0(sp)
 a6a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 a6c:	00000097          	auipc	ra,0x0
 a70:	f66080e7          	jalr	-154(ra) # 9d2 <memmove>
}
 a74:	60a2                	ld	ra,8(sp)
 a76:	6402                	ld	s0,0(sp)
 a78:	0141                	addi	sp,sp,16
 a7a:	8082                	ret

0000000000000a7c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 a7c:	4885                	li	a7,1
 ecall
 a7e:	00000073          	ecall
 ret
 a82:	8082                	ret

0000000000000a84 <exit>:
.global exit
exit:
 li a7, SYS_exit
 a84:	4889                	li	a7,2
 ecall
 a86:	00000073          	ecall
 ret
 a8a:	8082                	ret

0000000000000a8c <wait>:
.global wait
wait:
 li a7, SYS_wait
 a8c:	488d                	li	a7,3
 ecall
 a8e:	00000073          	ecall
 ret
 a92:	8082                	ret

0000000000000a94 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 a94:	4891                	li	a7,4
 ecall
 a96:	00000073          	ecall
 ret
 a9a:	8082                	ret

0000000000000a9c <read>:
.global read
read:
 li a7, SYS_read
 a9c:	4895                	li	a7,5
 ecall
 a9e:	00000073          	ecall
 ret
 aa2:	8082                	ret

0000000000000aa4 <write>:
.global write
write:
 li a7, SYS_write
 aa4:	48c1                	li	a7,16
 ecall
 aa6:	00000073          	ecall
 ret
 aaa:	8082                	ret

0000000000000aac <close>:
.global close
close:
 li a7, SYS_close
 aac:	48d5                	li	a7,21
 ecall
 aae:	00000073          	ecall
 ret
 ab2:	8082                	ret

0000000000000ab4 <kill>:
.global kill
kill:
 li a7, SYS_kill
 ab4:	4899                	li	a7,6
 ecall
 ab6:	00000073          	ecall
 ret
 aba:	8082                	ret

0000000000000abc <exec>:
.global exec
exec:
 li a7, SYS_exec
 abc:	489d                	li	a7,7
 ecall
 abe:	00000073          	ecall
 ret
 ac2:	8082                	ret

0000000000000ac4 <open>:
.global open
open:
 li a7, SYS_open
 ac4:	48bd                	li	a7,15
 ecall
 ac6:	00000073          	ecall
 ret
 aca:	8082                	ret

0000000000000acc <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 acc:	48c5                	li	a7,17
 ecall
 ace:	00000073          	ecall
 ret
 ad2:	8082                	ret

0000000000000ad4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 ad4:	48c9                	li	a7,18
 ecall
 ad6:	00000073          	ecall
 ret
 ada:	8082                	ret

0000000000000adc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 adc:	48a1                	li	a7,8
 ecall
 ade:	00000073          	ecall
 ret
 ae2:	8082                	ret

0000000000000ae4 <link>:
.global link
link:
 li a7, SYS_link
 ae4:	48cd                	li	a7,19
 ecall
 ae6:	00000073          	ecall
 ret
 aea:	8082                	ret

0000000000000aec <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 aec:	48d1                	li	a7,20
 ecall
 aee:	00000073          	ecall
 ret
 af2:	8082                	ret

0000000000000af4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 af4:	48a5                	li	a7,9
 ecall
 af6:	00000073          	ecall
 ret
 afa:	8082                	ret

0000000000000afc <dup>:
.global dup
dup:
 li a7, SYS_dup
 afc:	48a9                	li	a7,10
 ecall
 afe:	00000073          	ecall
 ret
 b02:	8082                	ret

0000000000000b04 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 b04:	48ad                	li	a7,11
 ecall
 b06:	00000073          	ecall
 ret
 b0a:	8082                	ret

0000000000000b0c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 b0c:	48b1                	li	a7,12
 ecall
 b0e:	00000073          	ecall
 ret
 b12:	8082                	ret

0000000000000b14 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 b14:	48b5                	li	a7,13
 ecall
 b16:	00000073          	ecall
 ret
 b1a:	8082                	ret

0000000000000b1c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 b1c:	48b9                	li	a7,14
 ecall
 b1e:	00000073          	ecall
 ret
 b22:	8082                	ret

0000000000000b24 <flip_display>:
.global flip_display
flip_display:
 li a7, SYS_flip_display
 b24:	48d9                	li	a7,22
 ecall
 b26:	00000073          	ecall
 ret
 b2a:	8082                	ret

0000000000000b2c <map_display>:
.global map_display
map_display:
 li a7, SYS_map_display
 b2c:	48dd                	li	a7,23
 ecall
 b2e:	00000073          	ecall
 ret
 b32:	8082                	ret

0000000000000b34 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 b34:	1101                	addi	sp,sp,-32
 b36:	ec06                	sd	ra,24(sp)
 b38:	e822                	sd	s0,16(sp)
 b3a:	1000                	addi	s0,sp,32
 b3c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 b40:	4605                	li	a2,1
 b42:	fef40593          	addi	a1,s0,-17
 b46:	00000097          	auipc	ra,0x0
 b4a:	f5e080e7          	jalr	-162(ra) # aa4 <write>
}
 b4e:	60e2                	ld	ra,24(sp)
 b50:	6442                	ld	s0,16(sp)
 b52:	6105                	addi	sp,sp,32
 b54:	8082                	ret

0000000000000b56 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 b56:	7139                	addi	sp,sp,-64
 b58:	fc06                	sd	ra,56(sp)
 b5a:	f822                	sd	s0,48(sp)
 b5c:	f426                	sd	s1,40(sp)
 b5e:	f04a                	sd	s2,32(sp)
 b60:	ec4e                	sd	s3,24(sp)
 b62:	0080                	addi	s0,sp,64
 b64:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 b66:	c299                	beqz	a3,b6c <printint+0x16>
 b68:	0805c863          	bltz	a1,bf8 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 b6c:	2581                	sext.w	a1,a1
  neg = 0;
 b6e:	4881                	li	a7,0
 b70:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 b74:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 b76:	2601                	sext.w	a2,a2
 b78:	00000517          	auipc	a0,0x0
 b7c:	69850513          	addi	a0,a0,1688 # 1210 <digits>
 b80:	883a                	mv	a6,a4
 b82:	2705                	addiw	a4,a4,1
 b84:	02c5f7bb          	remuw	a5,a1,a2
 b88:	1782                	slli	a5,a5,0x20
 b8a:	9381                	srli	a5,a5,0x20
 b8c:	97aa                	add	a5,a5,a0
 b8e:	0007c783          	lbu	a5,0(a5)
 b92:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 b96:	0005879b          	sext.w	a5,a1
 b9a:	02c5d5bb          	divuw	a1,a1,a2
 b9e:	0685                	addi	a3,a3,1
 ba0:	fec7f0e3          	bgeu	a5,a2,b80 <printint+0x2a>
  if(neg)
 ba4:	00088b63          	beqz	a7,bba <printint+0x64>
    buf[i++] = '-';
 ba8:	fd040793          	addi	a5,s0,-48
 bac:	973e                	add	a4,a4,a5
 bae:	02d00793          	li	a5,45
 bb2:	fef70823          	sb	a5,-16(a4)
 bb6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 bba:	02e05863          	blez	a4,bea <printint+0x94>
 bbe:	fc040793          	addi	a5,s0,-64
 bc2:	00e78933          	add	s2,a5,a4
 bc6:	fff78993          	addi	s3,a5,-1
 bca:	99ba                	add	s3,s3,a4
 bcc:	377d                	addiw	a4,a4,-1
 bce:	1702                	slli	a4,a4,0x20
 bd0:	9301                	srli	a4,a4,0x20
 bd2:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 bd6:	fff94583          	lbu	a1,-1(s2)
 bda:	8526                	mv	a0,s1
 bdc:	00000097          	auipc	ra,0x0
 be0:	f58080e7          	jalr	-168(ra) # b34 <putc>
  while(--i >= 0)
 be4:	197d                	addi	s2,s2,-1
 be6:	ff3918e3          	bne	s2,s3,bd6 <printint+0x80>
}
 bea:	70e2                	ld	ra,56(sp)
 bec:	7442                	ld	s0,48(sp)
 bee:	74a2                	ld	s1,40(sp)
 bf0:	7902                	ld	s2,32(sp)
 bf2:	69e2                	ld	s3,24(sp)
 bf4:	6121                	addi	sp,sp,64
 bf6:	8082                	ret
    x = -xx;
 bf8:	40b005bb          	negw	a1,a1
    neg = 1;
 bfc:	4885                	li	a7,1
    x = -xx;
 bfe:	bf8d                	j	b70 <printint+0x1a>

0000000000000c00 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 c00:	7119                	addi	sp,sp,-128
 c02:	fc86                	sd	ra,120(sp)
 c04:	f8a2                	sd	s0,112(sp)
 c06:	f4a6                	sd	s1,104(sp)
 c08:	f0ca                	sd	s2,96(sp)
 c0a:	ecce                	sd	s3,88(sp)
 c0c:	e8d2                	sd	s4,80(sp)
 c0e:	e4d6                	sd	s5,72(sp)
 c10:	e0da                	sd	s6,64(sp)
 c12:	fc5e                	sd	s7,56(sp)
 c14:	f862                	sd	s8,48(sp)
 c16:	f466                	sd	s9,40(sp)
 c18:	f06a                	sd	s10,32(sp)
 c1a:	ec6e                	sd	s11,24(sp)
 c1c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 c1e:	0005c903          	lbu	s2,0(a1)
 c22:	18090f63          	beqz	s2,dc0 <vprintf+0x1c0>
 c26:	8aaa                	mv	s5,a0
 c28:	8b32                	mv	s6,a2
 c2a:	00158493          	addi	s1,a1,1
  state = 0;
 c2e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 c30:	02500a13          	li	s4,37
      if(c == 'd'){
 c34:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 c38:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 c3c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 c40:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 c44:	00000b97          	auipc	s7,0x0
 c48:	5ccb8b93          	addi	s7,s7,1484 # 1210 <digits>
 c4c:	a839                	j	c6a <vprintf+0x6a>
        putc(fd, c);
 c4e:	85ca                	mv	a1,s2
 c50:	8556                	mv	a0,s5
 c52:	00000097          	auipc	ra,0x0
 c56:	ee2080e7          	jalr	-286(ra) # b34 <putc>
 c5a:	a019                	j	c60 <vprintf+0x60>
    } else if(state == '%'){
 c5c:	01498f63          	beq	s3,s4,c7a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 c60:	0485                	addi	s1,s1,1
 c62:	fff4c903          	lbu	s2,-1(s1)
 c66:	14090d63          	beqz	s2,dc0 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 c6a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 c6e:	fe0997e3          	bnez	s3,c5c <vprintf+0x5c>
      if(c == '%'){
 c72:	fd479ee3          	bne	a5,s4,c4e <vprintf+0x4e>
        state = '%';
 c76:	89be                	mv	s3,a5
 c78:	b7e5                	j	c60 <vprintf+0x60>
      if(c == 'd'){
 c7a:	05878063          	beq	a5,s8,cba <vprintf+0xba>
      } else if(c == 'l') {
 c7e:	05978c63          	beq	a5,s9,cd6 <vprintf+0xd6>
      } else if(c == 'x') {
 c82:	07a78863          	beq	a5,s10,cf2 <vprintf+0xf2>
      } else if(c == 'p') {
 c86:	09b78463          	beq	a5,s11,d0e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 c8a:	07300713          	li	a4,115
 c8e:	0ce78663          	beq	a5,a4,d5a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 c92:	06300713          	li	a4,99
 c96:	0ee78e63          	beq	a5,a4,d92 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 c9a:	11478863          	beq	a5,s4,daa <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 c9e:	85d2                	mv	a1,s4
 ca0:	8556                	mv	a0,s5
 ca2:	00000097          	auipc	ra,0x0
 ca6:	e92080e7          	jalr	-366(ra) # b34 <putc>
        putc(fd, c);
 caa:	85ca                	mv	a1,s2
 cac:	8556                	mv	a0,s5
 cae:	00000097          	auipc	ra,0x0
 cb2:	e86080e7          	jalr	-378(ra) # b34 <putc>
      }
      state = 0;
 cb6:	4981                	li	s3,0
 cb8:	b765                	j	c60 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 cba:	008b0913          	addi	s2,s6,8
 cbe:	4685                	li	a3,1
 cc0:	4629                	li	a2,10
 cc2:	000b2583          	lw	a1,0(s6)
 cc6:	8556                	mv	a0,s5
 cc8:	00000097          	auipc	ra,0x0
 ccc:	e8e080e7          	jalr	-370(ra) # b56 <printint>
 cd0:	8b4a                	mv	s6,s2
      state = 0;
 cd2:	4981                	li	s3,0
 cd4:	b771                	j	c60 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 cd6:	008b0913          	addi	s2,s6,8
 cda:	4681                	li	a3,0
 cdc:	4629                	li	a2,10
 cde:	000b2583          	lw	a1,0(s6)
 ce2:	8556                	mv	a0,s5
 ce4:	00000097          	auipc	ra,0x0
 ce8:	e72080e7          	jalr	-398(ra) # b56 <printint>
 cec:	8b4a                	mv	s6,s2
      state = 0;
 cee:	4981                	li	s3,0
 cf0:	bf85                	j	c60 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 cf2:	008b0913          	addi	s2,s6,8
 cf6:	4681                	li	a3,0
 cf8:	4641                	li	a2,16
 cfa:	000b2583          	lw	a1,0(s6)
 cfe:	8556                	mv	a0,s5
 d00:	00000097          	auipc	ra,0x0
 d04:	e56080e7          	jalr	-426(ra) # b56 <printint>
 d08:	8b4a                	mv	s6,s2
      state = 0;
 d0a:	4981                	li	s3,0
 d0c:	bf91                	j	c60 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 d0e:	008b0793          	addi	a5,s6,8
 d12:	f8f43423          	sd	a5,-120(s0)
 d16:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 d1a:	03000593          	li	a1,48
 d1e:	8556                	mv	a0,s5
 d20:	00000097          	auipc	ra,0x0
 d24:	e14080e7          	jalr	-492(ra) # b34 <putc>
  putc(fd, 'x');
 d28:	85ea                	mv	a1,s10
 d2a:	8556                	mv	a0,s5
 d2c:	00000097          	auipc	ra,0x0
 d30:	e08080e7          	jalr	-504(ra) # b34 <putc>
 d34:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 d36:	03c9d793          	srli	a5,s3,0x3c
 d3a:	97de                	add	a5,a5,s7
 d3c:	0007c583          	lbu	a1,0(a5)
 d40:	8556                	mv	a0,s5
 d42:	00000097          	auipc	ra,0x0
 d46:	df2080e7          	jalr	-526(ra) # b34 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 d4a:	0992                	slli	s3,s3,0x4
 d4c:	397d                	addiw	s2,s2,-1
 d4e:	fe0914e3          	bnez	s2,d36 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 d52:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 d56:	4981                	li	s3,0
 d58:	b721                	j	c60 <vprintf+0x60>
        s = va_arg(ap, char*);
 d5a:	008b0993          	addi	s3,s6,8
 d5e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 d62:	02090163          	beqz	s2,d84 <vprintf+0x184>
        while(*s != 0){
 d66:	00094583          	lbu	a1,0(s2)
 d6a:	c9a1                	beqz	a1,dba <vprintf+0x1ba>
          putc(fd, *s);
 d6c:	8556                	mv	a0,s5
 d6e:	00000097          	auipc	ra,0x0
 d72:	dc6080e7          	jalr	-570(ra) # b34 <putc>
          s++;
 d76:	0905                	addi	s2,s2,1
        while(*s != 0){
 d78:	00094583          	lbu	a1,0(s2)
 d7c:	f9e5                	bnez	a1,d6c <vprintf+0x16c>
        s = va_arg(ap, char*);
 d7e:	8b4e                	mv	s6,s3
      state = 0;
 d80:	4981                	li	s3,0
 d82:	bdf9                	j	c60 <vprintf+0x60>
          s = "(null)";
 d84:	00000917          	auipc	s2,0x0
 d88:	48490913          	addi	s2,s2,1156 # 1208 <cells.0+0x150>
        while(*s != 0){
 d8c:	02800593          	li	a1,40
 d90:	bff1                	j	d6c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 d92:	008b0913          	addi	s2,s6,8
 d96:	000b4583          	lbu	a1,0(s6)
 d9a:	8556                	mv	a0,s5
 d9c:	00000097          	auipc	ra,0x0
 da0:	d98080e7          	jalr	-616(ra) # b34 <putc>
 da4:	8b4a                	mv	s6,s2
      state = 0;
 da6:	4981                	li	s3,0
 da8:	bd65                	j	c60 <vprintf+0x60>
        putc(fd, c);
 daa:	85d2                	mv	a1,s4
 dac:	8556                	mv	a0,s5
 dae:	00000097          	auipc	ra,0x0
 db2:	d86080e7          	jalr	-634(ra) # b34 <putc>
      state = 0;
 db6:	4981                	li	s3,0
 db8:	b565                	j	c60 <vprintf+0x60>
        s = va_arg(ap, char*);
 dba:	8b4e                	mv	s6,s3
      state = 0;
 dbc:	4981                	li	s3,0
 dbe:	b54d                	j	c60 <vprintf+0x60>
    }
  }
}
 dc0:	70e6                	ld	ra,120(sp)
 dc2:	7446                	ld	s0,112(sp)
 dc4:	74a6                	ld	s1,104(sp)
 dc6:	7906                	ld	s2,96(sp)
 dc8:	69e6                	ld	s3,88(sp)
 dca:	6a46                	ld	s4,80(sp)
 dcc:	6aa6                	ld	s5,72(sp)
 dce:	6b06                	ld	s6,64(sp)
 dd0:	7be2                	ld	s7,56(sp)
 dd2:	7c42                	ld	s8,48(sp)
 dd4:	7ca2                	ld	s9,40(sp)
 dd6:	7d02                	ld	s10,32(sp)
 dd8:	6de2                	ld	s11,24(sp)
 dda:	6109                	addi	sp,sp,128
 ddc:	8082                	ret

0000000000000dde <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 dde:	715d                	addi	sp,sp,-80
 de0:	ec06                	sd	ra,24(sp)
 de2:	e822                	sd	s0,16(sp)
 de4:	1000                	addi	s0,sp,32
 de6:	e010                	sd	a2,0(s0)
 de8:	e414                	sd	a3,8(s0)
 dea:	e818                	sd	a4,16(s0)
 dec:	ec1c                	sd	a5,24(s0)
 dee:	03043023          	sd	a6,32(s0)
 df2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 df6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 dfa:	8622                	mv	a2,s0
 dfc:	00000097          	auipc	ra,0x0
 e00:	e04080e7          	jalr	-508(ra) # c00 <vprintf>
}
 e04:	60e2                	ld	ra,24(sp)
 e06:	6442                	ld	s0,16(sp)
 e08:	6161                	addi	sp,sp,80
 e0a:	8082                	ret

0000000000000e0c <printf>:

void
printf(const char *fmt, ...)
{
 e0c:	711d                	addi	sp,sp,-96
 e0e:	ec06                	sd	ra,24(sp)
 e10:	e822                	sd	s0,16(sp)
 e12:	1000                	addi	s0,sp,32
 e14:	e40c                	sd	a1,8(s0)
 e16:	e810                	sd	a2,16(s0)
 e18:	ec14                	sd	a3,24(s0)
 e1a:	f018                	sd	a4,32(s0)
 e1c:	f41c                	sd	a5,40(s0)
 e1e:	03043823          	sd	a6,48(s0)
 e22:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 e26:	00840613          	addi	a2,s0,8
 e2a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 e2e:	85aa                	mv	a1,a0
 e30:	4505                	li	a0,1
 e32:	00000097          	auipc	ra,0x0
 e36:	dce080e7          	jalr	-562(ra) # c00 <vprintf>
}
 e3a:	60e2                	ld	ra,24(sp)
 e3c:	6442                	ld	s0,16(sp)
 e3e:	6125                	addi	sp,sp,96
 e40:	8082                	ret

0000000000000e42 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 e42:	1141                	addi	sp,sp,-16
 e44:	e422                	sd	s0,8(sp)
 e46:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 e48:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 e4c:	00001797          	auipc	a5,0x1
 e50:	1b47b783          	ld	a5,436(a5) # 2000 <freep>
 e54:	a805                	j	e84 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 e56:	4618                	lw	a4,8(a2)
 e58:	9db9                	addw	a1,a1,a4
 e5a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 e5e:	6398                	ld	a4,0(a5)
 e60:	6318                	ld	a4,0(a4)
 e62:	fee53823          	sd	a4,-16(a0)
 e66:	a091                	j	eaa <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 e68:	ff852703          	lw	a4,-8(a0)
 e6c:	9e39                	addw	a2,a2,a4
 e6e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 e70:	ff053703          	ld	a4,-16(a0)
 e74:	e398                	sd	a4,0(a5)
 e76:	a099                	j	ebc <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 e78:	6398                	ld	a4,0(a5)
 e7a:	00e7e463          	bltu	a5,a4,e82 <free+0x40>
 e7e:	00e6ea63          	bltu	a3,a4,e92 <free+0x50>
{
 e82:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 e84:	fed7fae3          	bgeu	a5,a3,e78 <free+0x36>
 e88:	6398                	ld	a4,0(a5)
 e8a:	00e6e463          	bltu	a3,a4,e92 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 e8e:	fee7eae3          	bltu	a5,a4,e82 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 e92:	ff852583          	lw	a1,-8(a0)
 e96:	6390                	ld	a2,0(a5)
 e98:	02059713          	slli	a4,a1,0x20
 e9c:	9301                	srli	a4,a4,0x20
 e9e:	0712                	slli	a4,a4,0x4
 ea0:	9736                	add	a4,a4,a3
 ea2:	fae60ae3          	beq	a2,a4,e56 <free+0x14>
    bp->s.ptr = p->s.ptr;
 ea6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 eaa:	4790                	lw	a2,8(a5)
 eac:	02061713          	slli	a4,a2,0x20
 eb0:	9301                	srli	a4,a4,0x20
 eb2:	0712                	slli	a4,a4,0x4
 eb4:	973e                	add	a4,a4,a5
 eb6:	fae689e3          	beq	a3,a4,e68 <free+0x26>
  } else
    p->s.ptr = bp;
 eba:	e394                	sd	a3,0(a5)
  freep = p;
 ebc:	00001717          	auipc	a4,0x1
 ec0:	14f73223          	sd	a5,324(a4) # 2000 <freep>
}
 ec4:	6422                	ld	s0,8(sp)
 ec6:	0141                	addi	sp,sp,16
 ec8:	8082                	ret

0000000000000eca <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 eca:	7139                	addi	sp,sp,-64
 ecc:	fc06                	sd	ra,56(sp)
 ece:	f822                	sd	s0,48(sp)
 ed0:	f426                	sd	s1,40(sp)
 ed2:	f04a                	sd	s2,32(sp)
 ed4:	ec4e                	sd	s3,24(sp)
 ed6:	e852                	sd	s4,16(sp)
 ed8:	e456                	sd	s5,8(sp)
 eda:	e05a                	sd	s6,0(sp)
 edc:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 ede:	02051493          	slli	s1,a0,0x20
 ee2:	9081                	srli	s1,s1,0x20
 ee4:	04bd                	addi	s1,s1,15
 ee6:	8091                	srli	s1,s1,0x4
 ee8:	0014899b          	addiw	s3,s1,1
 eec:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 eee:	00001517          	auipc	a0,0x1
 ef2:	11253503          	ld	a0,274(a0) # 2000 <freep>
 ef6:	c515                	beqz	a0,f22 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ef8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 efa:	4798                	lw	a4,8(a5)
 efc:	02977f63          	bgeu	a4,s1,f3a <malloc+0x70>
 f00:	8a4e                	mv	s4,s3
 f02:	0009871b          	sext.w	a4,s3
 f06:	6685                	lui	a3,0x1
 f08:	00d77363          	bgeu	a4,a3,f0e <malloc+0x44>
 f0c:	6a05                	lui	s4,0x1
 f0e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 f12:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 f16:	00001917          	auipc	s2,0x1
 f1a:	0ea90913          	addi	s2,s2,234 # 2000 <freep>
  if(p == (char*)-1)
 f1e:	5afd                	li	s5,-1
 f20:	a88d                	j	f92 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 f22:	00003797          	auipc	a5,0x3
 f26:	66e78793          	addi	a5,a5,1646 # 4590 <base>
 f2a:	00001717          	auipc	a4,0x1
 f2e:	0cf73b23          	sd	a5,214(a4) # 2000 <freep>
 f32:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 f34:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 f38:	b7e1                	j	f00 <malloc+0x36>
      if(p->s.size == nunits)
 f3a:	02e48b63          	beq	s1,a4,f70 <malloc+0xa6>
        p->s.size -= nunits;
 f3e:	4137073b          	subw	a4,a4,s3
 f42:	c798                	sw	a4,8(a5)
        p += p->s.size;
 f44:	1702                	slli	a4,a4,0x20
 f46:	9301                	srli	a4,a4,0x20
 f48:	0712                	slli	a4,a4,0x4
 f4a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 f4c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 f50:	00001717          	auipc	a4,0x1
 f54:	0aa73823          	sd	a0,176(a4) # 2000 <freep>
      return (void*)(p + 1);
 f58:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 f5c:	70e2                	ld	ra,56(sp)
 f5e:	7442                	ld	s0,48(sp)
 f60:	74a2                	ld	s1,40(sp)
 f62:	7902                	ld	s2,32(sp)
 f64:	69e2                	ld	s3,24(sp)
 f66:	6a42                	ld	s4,16(sp)
 f68:	6aa2                	ld	s5,8(sp)
 f6a:	6b02                	ld	s6,0(sp)
 f6c:	6121                	addi	sp,sp,64
 f6e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 f70:	6398                	ld	a4,0(a5)
 f72:	e118                	sd	a4,0(a0)
 f74:	bff1                	j	f50 <malloc+0x86>
  hp->s.size = nu;
 f76:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 f7a:	0541                	addi	a0,a0,16
 f7c:	00000097          	auipc	ra,0x0
 f80:	ec6080e7          	jalr	-314(ra) # e42 <free>
  return freep;
 f84:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 f88:	d971                	beqz	a0,f5c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 f8a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 f8c:	4798                	lw	a4,8(a5)
 f8e:	fa9776e3          	bgeu	a4,s1,f3a <malloc+0x70>
    if(p == freep)
 f92:	00093703          	ld	a4,0(s2)
 f96:	853e                	mv	a0,a5
 f98:	fef719e3          	bne	a4,a5,f8a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 f9c:	8552                	mv	a0,s4
 f9e:	00000097          	auipc	ra,0x0
 fa2:	b6e080e7          	jalr	-1170(ra) # b0c <sbrk>
  if(p == (char*)-1)
 fa6:	fd5518e3          	bne	a0,s5,f76 <malloc+0xac>
        return 0;
 faa:	4501                	li	a0,0
 fac:	bf45                	j	f5c <malloc+0x92>
