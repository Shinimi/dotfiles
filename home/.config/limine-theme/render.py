import sys,math,random
from PIL import Image,ImageDraw,ImageFont,ImageFilter
src,fontp,out=sys.argv[1:]
W,H=2560,1440; cw,ch=12,22
cols,rows=W//cw+1,H//ch+1
full=Image.open(src).convert("L")
img=full.resize((cols,rows),Image.LANCZOS)
edge=full.filter(ImageFilter.GaussianBlur(3)).filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(9)).resize((cols,rows),Image.BOX)
font=ImageFont.truetype(fontp,17)
ramp=" .·:-=+*x%#@"
o=Image.new("RGB",(W,H),(5,5,5)); d=ImageDraw.Draw(o)
random.seed(7)
for y in range(rows):
    for x in range(cols):
        l=img.getpixel((x,y))/255
        e=0 if x<3 or y<3 or x>cols-4 or y>rows-4 else min(1,edge.getpixel((x,y))/40)
        river=max(0,(l-0.6)*2.5) if y>rows*0.45 else 0      # the river below the ridge gets its own glow
        v=max(0,min(1,0.45*l**2.2+0.7*e+0.6*river))
        c=ramp[min(len(ramp)-1,int(v*(len(ramp)-1)+random.random()*0.5))]
        if c==" ": continue
        dx=(x/cols-0.5)*2; dy=(y/rows-0.5)*2
        f=1-0.35*math.exp(-(dx*dx*1.4+dy*dy*2.0))
        g=int(30+225*v*f)
        d.text((x*cw,y*ch),c,font=font,fill=(g,g,g))
vg=Image.new("L",(W,H),0); vd=ImageDraw.Draw(vg)
for i in range(60): vd.rectangle([i*8,i*5,W-i*8,H-i*5],fill=int(255*min(1,i/40)))
vg=vg.filter(ImageFilter.GaussianBlur(60))
Image.composite(o,Image.new("RGB",(W,H),(4,4,4)),vg).save(out,optimize=True)
