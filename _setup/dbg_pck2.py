import re, struct

A = r"F:\诡异事务局\deploy\game\index.pck"
data = open(A, "rb").read()
n = len(data)
tail = data[-300000:]
ms = list(re.finditer(rb"res://", tail))
print("尾部 300KB 内 res:// 次数:", len(ms))
for m in ms[:3]:
    pos = m.start() + n - 300000
    plen = struct.unpack_from("<I", data, pos - 4)[0]
    print("\n@0x%08X plen=%d" % (pos, plen))
    print("  hex:", data[pos - 4:pos + 70].hex())
    print("  txt:", "".join(chr(c) if 32 <= c < 127 else "." for c in data[pos - 4:pos + 70]))
    raw = data[pos:pos + plen].split(b"\x00")[0]
    print("  name:", raw.decode("utf-8", "replace"))
    end = pos + len(raw) + 1
    rec = (end + 3) & ~3
    print("  rec=0x%08X  pad=%d" % (rec, rec - end))
    off, size, md5, flags = struct.unpack_from("<QQ16sI", data, rec)
    print("  off=%d size=%d md5=%s flags=%d  (文件总长 %d)" % (off, size, md5.hex(), flags, n))
    print("  内容开头:", data[off:off + 16].hex())
