import sys, numpy as np

A = r"F:\诡异事务局\deploy\game\index.pck"
B = r"C:\Users\Sabrina\Documents\ChatGPT\最后的地铁：0017\deploy\game\index.pck"

a = np.fromfile(A, dtype=np.uint8)
b = np.fromfile(B, dtype=np.uint8)
print("size new =", a.size)
print("size old =", b.size)
if a.size != b.size:
    print("!! 长度不同，无法逐字节对比")
    sys.exit(0)

d = np.nonzero(a != b)[0]
print("differing bytes =", d.size, " (%.4f%%)" % (100.0 * d.size / a.size))
if d.size == 0:
    sys.exit(0)

# 合并邻近差异，形成区间
gap = 128
ranges = []
start = prev = int(d[0])
count = 1
for x in d[1:]:
    x = int(x)
    if x - prev <= gap:
        prev = x
        count += 1
    else:
        ranges.append((start, prev, count))
        start = prev = x
        count = 1
ranges.append((start, prev, count))

print("合并后的差异区间数 =", len(ranges))

def ctx(buf, off, n=64):
    s = buf[off:off + n].tobytes()
    txt = "".join(chr(c) if 32 <= c < 127 else "." for c in s)
    return s.hex(), txt

for i, (s, e, c) in enumerate(ranges[:40]):
    print("\n--- 区间 %d: 0x%08X..0x%08X  (%d 字节不同, 跨度 %d) ---" % (i, s, e, c, e - s + 1))
    hn, tn = ctx(a, max(0, s - 8))
    ho, to = ctx(b, max(0, s - 8))
    print(" new:", hn)
    print("      ", tn)
    print(" old:", ho)
    print("      ", to)
if len(ranges) > 40:
    print("\n... 还有 %d 个区间未显示" % (len(ranges) - 40))
