import re
from collections import Counter

A = r"F:\诡异事务局\deploy\game\index.pck"
B = r"C:\Users\Sabrina\Documents\ChatGPT\最后的地铁：0017\deploy\game\index.pck"

pat = re.compile(rb"res://[\x21-\x7e]*")

def paths(p):
    data = open(p, "rb").read()
    c = Counter()
    for m in pat.finditer(data):
        s = m.group(0).decode("utf-8", "replace").rstrip('.",);')
        c[s] += 1
    return c

a = paths(A)
b = paths(B)
print("新包路径种类:", len(a), " 总出现:", sum(a.values()))
print("旧包路径种类:", len(b), " 总出现:", sum(b.values()))

onlya = a - b
onlyb = b - a
print("\n只在新包出现:", sum(onlya.values()), "次 /", len(onlya), "种")
for k, v in list(onlya.items())[:25]:
    print("   +", k, "x", v)
print("只在旧包出现:", sum(onlyb.values()), "次 /", len(onlyb), "种")
for k, v in list(onlyb.items())[:25]:
    print("   -", k, "x", v)
print("\n结论: 路径集合", "完全一致" if not onlya and not onlyb else "存在差异")
