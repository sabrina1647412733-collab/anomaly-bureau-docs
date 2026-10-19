import re, struct

A = r"F:\诡异事务局\deploy\game\index.pck"
data = open(A, "rb").read()
ms = list(re.finditer(rb"res://", data))
print("res:// 出现次数:", len(ms))
for m in ms[:5]:
    pos = m.start()
    plen = struct.unpack_from("<I", data, pos - 4)[0]
    print("\n@0x%08X plen=%d" % (pos, plen))
    print("  pos-8..pos+80:", data[pos - 8:pos + 80].hex())
    print("  ascii:", "".join(chr(c) if 32 <= c < 127 else "." for c in data[pos - 8:pos + 80]))
