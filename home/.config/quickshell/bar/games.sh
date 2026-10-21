#!/usr/bin/env bash
# Installed Steam games as JSON (newest played first), with cover art paths. Made by Claude.
python3 -I - <<'PY'
import glob,os,re,json
H=os.path.expanduser('~'); LC=H+'/.local/share/Steam/appcache/librarycache'
libs=[H+'/.local/share/Steam/steamapps']
try:
    t=open(H+'/.local/share/Steam/steamapps/libraryfolders.vdf').read()
    libs+= [p+'/steamapps' for p in re.findall(r'"path"\s+"([^"]+)"',t)]
except Exception: pass
skip=re.compile(r'Proton|Steam Linux Runtime|Steamworks|Redistributable|SteamVR|Soundtrack|Dedicated Server|SDK',re.I)
games={}
for lib in set(libs):
    for f in glob.glob(lib+'/appmanifest_*.acf'):
        t=open(f,errors='ignore').read()
        g=lambda k: (re.search(r'"%s"\s+"([^"]*)"'%k,t) or [None,''])[1]
        aid,name=g('appid'),g('name')
        if not aid or not name or skip.search(name): continue
        cover=next((p for p in [f'{LC}/{aid}/library_600x900.jpg',*glob.glob(f'{LC}/{aid}/*/library_600x900.jpg'),*glob.glob(f'{LC}/{aid}/*/library_capsule.jpg'),f'{LC}/{aid}/header.jpg',*glob.glob(f'{LC}/{aid}/*/library_header.jpg')] if os.path.exists(p)),'')
        games[aid]={'id':aid,'name':name,'cover':cover,'last':int(g('LastPlayed') or 0)}
print(json.dumps(sorted(games.values(),key=lambda x:-x['last'])))
PY
