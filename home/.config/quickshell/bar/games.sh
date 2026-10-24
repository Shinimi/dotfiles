#!/usr/bin/env bash
# Installed Steam games as JSON (newest played first): cover, wide banner, logo, hours played, size on disk.
# Made by Claude.
python3 -I - <<'PY'
import glob,os,re,json
H=os.path.expanduser('~'); S=H+'/.local/share/Steam'; LC=S+'/appcache/librarycache'
libs=[S+'/steamapps']
try:
    t=open(S+'/steamapps/libraryfolders.vdf').read()
    libs+= [p+'/steamapps' for p in re.findall(r'"path"\s+"([^"]+)"',t)]
except Exception: pass
# minutes played, from Steam's own per-user config (blocks are matched by brace depth)
play={}
for f in glob.glob(S+'/userdata/*/config/localconfig.vdf'):
    cur=None; depth=0; start=None
    for line in open(f,errors='ignore'):
        s=line.strip()
        if s=='{': depth+=1; continue
        if s=='}':
            depth-=1
            if start is not None and depth<start: cur=None; start=None
            continue
        m=re.fullmatch(r'"(\d+)"',s)
        if m: cur=m.group(1); start=depth+1; continue
        m=re.match(r'"Playtime"\s+"(\d+)"',s)
        if m and cur and start==depth: play[cur]=max(play.get(cur,0),int(m.group(1)))
skip=re.compile(r'Proton|Steam Linux Runtime|Steamworks|Redistributable|SteamVR|Soundtrack|Dedicated Server|SDK',re.I)
def first(*pats):
    for p in pats:
        for x in glob.glob(p):
            if os.path.exists(x): return x
    return ''
games={}
for lib in set(libs):
    for f in glob.glob(lib+'/appmanifest_*.acf'):
        t=open(f,errors='ignore').read()
        g=lambda k: (re.search(r'"%s"\s+"([^"]*)"'%k,t) or [None,''])[1]
        aid,name=g('appid'),g('name')
        if not aid or not name or skip.search(name): continue
        d=f'{LC}/{aid}'
        games[aid]={'id':aid,'name':name,
            'cover':first(f'{d}/library_600x900.jpg',f'{d}/*/library_600x900.jpg',f'{d}/*/library_capsule.jpg',f'{d}/header.jpg',f'{d}/*/library_header.jpg'),
            'hero':first(f'{d}/library_hero.jpg',f'{d}/*/library_hero.jpg',f'{d}/*/library_header.jpg'),
            'logo':first(f'{d}/logo.png',f'{d}/*/logo.png'),
            'last':int(g('LastPlayed') or 0),'minutes':play.get(aid,0),'size':int(g('SizeOnDisk') or 0)}
print(json.dumps(sorted(games.values(),key=lambda x:-x['last'])))
PY
