// Optional authoring tool; not used by the Flutter application.
// Run from tools/illustrated_athletes after `npm install`.
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');
const lottieWeb = require.resolve('lottie-web/build/player/lottie.min.js');

(async () => {
  const app = path.resolve(__dirname, '../..');
  const output = path.resolve(process.argv[2] || path.join(__dirname, 'frames'));
  fs.mkdirSync(output, {recursive: true});
  const source = fs.readFileSync(path.join(app, 'assets/animations/bodyweight_squat.json'), 'utf8');
  const browser = await puppeteer.launch({headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']});
  try {
    const page = await browser.newPage();
    await page.setViewport({width: 480, height: 480, deviceScaleFactor: 1});
    await page.setContent('<style>*{margin:0;padding:0}body{background:transparent}#canvas{width:480px;height:480px}</style><div id="canvas"></div>');
    await page.addScriptTag({path: lottieWeb});
    const data = JSON.parse(source);
    const comp = data.assets.find(asset => asset.id === 'comp_0');
    const background = comp && comp.layers.find(layer => layer.nm === 'White Solid 1');
    if (!background) throw new Error('Cannot identify the source background layer');
    background.hd = true;
    await page.evaluate(async (data) => {
      window.animation = lottie.loadAnimation({container: document.getElementById('canvas'),
        renderer: 'svg', loop: false, autoplay: false, animationData: data});
      await new Promise(resolve => window.animation.addEventListener('DOMLoaded', resolve));
    }, data);
    // Frames 9..30 are the grounded, standing-to-squat part of the existing
    // licensed vector adaptation. Quarter-frame sampling avoids jitter.
    for (let step = 36; step <= 120; step++) {
      await page.evaluate(frame => new Promise(resolve => {
        window.animation.goToAndStop(frame, true);
        requestAnimationFrame(() => requestAnimationFrame(resolve));
      }), step / 4);
      await page.screenshot({path: path.join(output, `squat_${step}.png`), omitBackground: true});
    }
    console.log(`Rendered 85 source poses to ${output}`);
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
