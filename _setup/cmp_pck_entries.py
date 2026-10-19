import re, struct, sys, json

A = r"F:\诡异事务局\deploy\game\index.pck"
B = r"C:\Users\Sabrina\Documents\ChatGPT\最后的地铁：0017\deploy\game\index.pck"

def entries(path):
    data = open(path, "rb").read()
    out = {}
    order = []
    for m in re.finditer(rb"res://", data):
        pos = m.start()
        # 往回读 u32 路径长度
        if pos < 4:
            continue
        plen = struct.unpack_from("<I", data, pos - 4)[0]
        if plen < 6 or plen > 512:
            continue
        raw = data[pos:pos + plen].split(b"\x00")[0]
        try:
            name = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue
        if not name.startswith("res://"):
            continue
        plen = len(data[pos:pos + plen].split(b"\x00")[0]) + 1
        end = pos + plen
        rec = (end + 3) & ~3
        if rec + 8 + 8 + 16 + 4 > len(data):
            continue
        off, size, md5, flags = struct.unpack_from("<QQ16sI", data, rec)
        if off + size > len(data) or size == 0:
            continue
        if name in out:
            continue
        out[name] = (size, md5.hex())
        order.append(name)
    return data, out, order

da, ea, oa = entries(A)
db, eb, ob = entries(B)
print("new pck:", len(da), "bytes,", len(ea), "条目录项")
print("old pck:", len(db), "bytes,", len(eb), "条目录项")

only_new = sorted(set(ea) - set(eb))
only_old = sorted(set(eb) - set(ea))
print("\n只在新包:", len(only_new))
for n in only_new[:20]:
    print("   +", n)
print("只在旧包:", len(only_old))
for n in only_old[:20]:
    print("   -", n)

diff_size, diff_md5 = [], []
for n in sorted(set(ea) & set(eb)):
    if ea[n][0] != eb[n][0]:
        diff_size.append((n, ea[n][0], eb[n][0]))
    elif ea[n][1] != eb[n][1]:
        diff_md5.append((n, ea[n][1], eb[n][1]))
print("\n共有条目:", len(set(ea) & set(eb)))
print("大小不同:", len(diff_size))
for n, x, y in diff_size[:20]:
    print("   %s  new=%d old=%d" % (n, x, y))
print("大小相同但 md5 不同:", len(diff_md5))
for n, x, y in diff_md5[:20]:
    print("   %s\n     new %s\n     old %s" % (n, x, y))

print("\n目录顺序是否相同:", oa == ob)
if oa != ob:
    for i, (x, y) in enumerate(zip(oa, ob)):
        if x != y:
            print("  首个顺序差异 @%d: new=%s  old=%s" % (i, x, y))
            break
