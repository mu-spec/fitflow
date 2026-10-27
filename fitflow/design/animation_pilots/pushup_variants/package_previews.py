from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
for name,folder in [('knee','knee_pushup'),('incline','pushup_incline'),('decline','pushup_decline')]:
    frames=[Image.open(ROOT/f'.dart_tool/{folder}_frames/frame_{i:03d}.png').convert('RGB') for i in range(100)]
    samples=Image.new('RGB',(1440,480))
    for n,i in enumerate([0,25,50]):samples.paste(frames[i],(480*n,0))
    palette=samples.quantize(colors=256)
    frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    frames[0].save(Path(__file__).parent/f'{name}_preview.gif',save_all=True,append_images=frames[1:],duration=[20,30]*50,loop=0,optimize=False,disposal=2)
