"""Package rendered candidates for visual review, without touching app assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT=Path(__file__).resolve().parents[2]/'build/squat-family-review'
font=ImageFont.truetype('C:/Windows/Fonts/seguisb.ttf',21)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',16)
frames=[]
for frame in range(144):
    canvas=Image.new('RGB',(840,482),'#f5f5f5')
    draw=ImageDraw.Draw(canvas)
    draw.rectangle((0,0,840,61),fill='white')
    for col,(name,title,count,subtitle) in enumerate([
        ('squat_partial','Partial Squat',48,'Shallower bend · hands at chest'),
        ('squat_chair','Chair Sit-to-Stand',72,'Seated start · controlled rise and return')]):
        draw.text((col*420+18,8),title,font=font,fill='#202124')
        draw.text((col*420+18,36),subtitle,font=small,fill='#66717b')
        with Image.open(OUT/'frames'/f'{name}_{frame%count}.png') as im:
            canvas.paste(im.convert('RGB'),(col*420,62))
    draw.line((420,0,420,482),fill='#dce1e5')
    frames.append(canvas)
frames[0].save(OUT/'partial-and-chair-review.gif',save_all=True,
               append_images=frames[1:],duration=[83,83,84]*48,loop=0,disposal=2)

for name,indices in [('squat_chair',[0,20,35,58]),('squat_partial',[0,12,24,36])]:
    sheet=Image.new('RGB',(840,884),'#f5f5f5')
    for slot,i in enumerate(indices):
        x,y=slot%2*420,slot//2*442
        with Image.open(OUT/'frames'/f'{name}_{i}.png') as im:
            sheet.paste(im.convert('RGB'),(x,y+22))
        ImageDraw.Draw(sheet).text((x+14,y),f'{i/12:.1f} seconds',font=small,fill='#202124')
    sheet.save(OUT/f'{name}-poses.png')
print(OUT/'partial-and-chair-review.gif')
