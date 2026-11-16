"""Compare the previous squat pose with the revised arm pose."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[2] / 'build/front-squat-review'
font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 18)
frames=[]
with Image.open(OUT / 'squat-artwork-comparison.gif') as previous:
    assert previous.n_frames == 24
    for i in range(24):
        previous.seek(i)
        canvas=Image.new('RGB',(720,402),'#f5f5f5')
        canvas.paste(previous.convert('RGB').crop((360,42,720,402)),(0,42))
        with Image.open(OUT/'frames'/f'squat_{i}.png') as current:
            canvas.paste(current.convert('RGB'),(360,42))
        draw=ImageDraw.Draw(canvas)
        draw.rectangle((0,0,720,41),fill='white')
        draw.text((16,10),'Before: arms at the sides',font=font,fill='#202124')
        draw.text((376,10),'Updated: hands in front of chest',font=font,fill='#202124')
        draw.line((360,0,360,402),fill='#dddddd')
        frames.append(canvas)
frames[0].save(OUT/'squat-arms-comparison-v2.gif',save_all=True,
               append_images=frames[1:],duration=167,loop=0,disposal=2)
frames[12].save(OUT/'squat-arms-bottom-v2.png')
print(OUT/'squat-arms-comparison-v2.gif')
