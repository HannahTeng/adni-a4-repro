# Compare a rendered vignette HTML against the prebuilt reference HTML.
# Compares: HTML table cells, "#>" printed-output lines, and DT widget data.
# Prints only aggregate cells (vignette outputs are aggregate tables / model summaries).
import sys, re, json, html
from html.parser import HTMLParser

class Tables(HTMLParser):
    def __init__(s):
        super().__init__(); s.tables = []; s.cell = None; s.row = None; s.skip = 0
    def handle_starttag(s, t, a):
        if t in ('script', 'style'): s.skip += 1
        if t == 'table': s.tables.append([])
        if t == 'tr' and s.tables: s.row = []; s.tables[-1].append(s.row)
        if t in ('td', 'th'): s.cell = []
    def handle_endtag(s, t):
        if t in ('script', 'style'): s.skip -= 1
        if t in ('td', 'th') and s.cell is not None and s.row is not None:
            s.row.append(re.sub(r'\s+', ' ', ''.join(s.cell)).strip()); s.cell = None
    def handle_data(s, d):
        if s.cell is not None and not s.skip: s.cell.append(d)

def load(path):
    h = open(path, encoding='utf-8').read()
    p = Tables(); p.feed(h)
    # Printed R output: strip tags (code spans split lines), unescape, keep "#>" lines
    plain = html.unescape(re.sub(r'<[^>]+>', '', re.sub(r'<script.*?</script>', '', h, flags=re.S)))
    printed = [re.sub(r'\s+', ' ', l).strip() for l in plain.splitlines() if l.lstrip().startswith('#>')]
    dts = []
    for m in re.finditer(r'<script type="application/json" data-for="[^"]+">(.*?)</script>', h, re.S):
        try: x = json.loads(m.group(1)).get('x', {})
        except Exception: continue
        if isinstance(x.get('data'), list):
            dts.append((re.sub('<[^>]+>', '', str(x.get('caption', ''))), list(zip(*x['data']))))
    return p.tables, printed, dts

ref, new = load(sys.argv[1]), load(sys.argv[2])
skip_printed = re.compile(r'Warning|deprecated|Ignoring unknown|•')
ncmp = ndiff = 0
print(f"tables: ref={len(ref[0])} new={len(new[0])}")
for ti, (a, b) in enumerate(zip(ref[0], new[0])):
    for ri in range(max(len(a), len(b))):
        ra = a[ri] if ri < len(a) else []; rb = b[ri] if ri < len(b) else []
        for ci in range(max(len(ra), len(rb))):
            ca = ra[ci] if ci < len(ra) else None; cb = rb[ci] if ci < len(rb) else None
            ncmp += 1
            if ca != cb:
                ndiff += 1
                if ndiff <= 40:
                    label = ra[0] if ra else (rb[0] if rb else '')
                    print(f"  DIFF table{ti+1} row{ri} '{label}' col{ci}: ref={ca!r} new={cb!r}")
pa = [l for l in ref[1] if not skip_printed.search(l)]
pb = [l for l in new[1] if not skip_printed.search(l)]
print(f"printed lines: ref={len(pa)} new={len(pb)}")
for i in range(max(len(pa), len(pb))):
    la = pa[i] if i < len(pa) else None; lb = pb[i] if i < len(pb) else None
    ncmp += 1
    if la != lb:
        ndiff += 1; print(f"  DIFF printed[{i}]: ref={la!r} new={lb!r}")
# DT widgets: compare only aggregate-summary widgets (caption contains 'Summary')
for (ca, ra), (cb, rb) in zip(ref[2], new[2]):
    if 'Summary' not in ca: continue
    for i in range(max(len(ra), len(rb))):
        x = ra[i] if i < len(ra) else None; y = rb[i] if i < len(rb) else None
        ncmp += 1
        if x != y:
            ndiff += 1; print(f"  DIFF DT '{ca}' row{i}: ref={x} new={y}")
print(f"RESULT: {ncmp} values compared, {ndiff} differ")
