from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[3]
folder=root/'.dart_tool/bodyweight_squat_review'
frames=[Image.open(folder/f'frame_{i}.png').convert('RGB') for i in range(60)]
samples=Image.new('RGB',(1080,360))
for n,i in enumerate([0,15,30]):samples.paste(frames[i],(360*n,0))
palette=samples.quantize(colors=256)
frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
frames[0].save(Path(__file__).parent/'bodyweight_preview.gif',save_all=True,append_images=frames[1:],duration=[40,40,40,40,40,50]*10,loop=0,optimize=False,disposal=2)
