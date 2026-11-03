import sys, re, json
h=open(sys.argv[1],encoding='utf-8').read()
for i,m in enumerate(re.finditer(r'<script type="application/json" data-for="[^"]+">(.*?)</script>',h,re.S)):
    try: w=json.loads(m.group(1))
    except Exception: continue
    x=w.get('x',{}); d=x.get('data')
    if not isinstance(d,list): continue
    cap=re.sub('<[^>]+>','',str(x.get('caption','')))
    cols=re.findall(r'<th>(.*?)</th>',x.get('container',''))
    print(i, '|', cap, '| cols:', cols, '| nrow:', len(d[0]) if d else 0)
    if len(sys.argv)>2 and str(i) in sys.argv[2].split(','):
        for r in zip(*d): print('   ', r)
