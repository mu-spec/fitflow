// Optional build-time tool. Extracts the approved squat athlete's component
// vectors as transparent PNGs; no player/runtime dependency on this script.
// Usage: node extract_character.cjs /tmp/fitflow-character
const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');
const lottieWeb = require.resolve('lottie-web/build/player/lottie.min.js');
const app = path.resolve(__dirname, '../..');
const out = path.resolve(process.argv[2] || path.join(__dirname, 'character_parts'));
const source = fs.readFileSync(path.join(app, 'assets/animations/bodyweight_squat.json'), 'utf8');

// The names and layer positions are taken from the existing app animation;
// frame 8 is a stable, grounded frame. Limbs retain their original shapes,
// colours, outlines, clothes and footwear, rather than recolouring a mannequin.
const groups = {
  torso: [21, 19, 17, 13, 12, 11], neck: [20], head: [18],
  upper_far: [10, 9], fore_far: [8], hand_far: [4],
  thigh_far: [6, 2], shin_far: [7],
  upper_near: [24, 23], fore_near: [22], hand_near: [27, 28, 29],
  thigh_near: [14, 25], shin_near: [15], shoe: [0],
};

(async () => {
  fs.mkdirSync(out, {recursive: true});
  const browser = await puppeteer.launch({headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']});
  try {
    const page = await browser.newPage();
    await page.setViewport({width: 480, height: 480, deviceScaleFactor: 1});
    await page.setContent('<style>*{margin:0;padding:0}body{background:transparent}#canvas{width:480px;height:480px}</style><div id="canvas"></div>');
    await page.addScriptTag({path: lottieWeb});
    async function load(data) {
      await page.evaluate(async d => {
        if (window.animation) window.animation.destroy();
        window.animation = lottie.loadAnimation({container: document.getElementById('canvas'),
          renderer: 'svg', loop: false, autoplay: false, animationData: d});
        await new Promise(resolve => window.animation.addEventListener('DOMLoaded', resolve));
      }, data);
    }
    async function snapshot(frame, filename) {
      await page.evaluate(frame => new Promise(resolve => {
        window.animation.goToAndStop(frame, true);
        requestAnimationFrame(() => requestAnimationFrame(resolve));
      }), frame);
      await page.screenshot({path: path.join(out, filename), omitBackground: true});
    }
    for (const [name, selected] of Object.entries(groups)) {
      const data = JSON.parse(source);
      const comp = data.assets.find(asset => asset.id === 'comp_0');
      if (!comp || comp.layers.length < 31 || comp.layers[30].nm !== 'White Solid 1') {
        throw new Error('The approved squat source layer structure has changed.');
      }
      comp.layers.forEach((layer, index) => { layer.hd = !selected.includes(index); });
      await load(data);
      await snapshot(8, `${name}.png`);
    }
    // Full transparent grounded squat frames, used to place the chair behind
    // the original athlete for the sit-to-stand. All other layers stay intact.
    const data = JSON.parse(source);
    const comp = data.assets.find(asset => asset.id === 'comp_0');
    comp.layers.find(layer => layer.nm === 'White Solid 1').hd = true;
    await load(data);
    for (let step = 36; step <= 120; step++) await snapshot(step / 4, `squat_${step}.png`);
    console.log(`Extracted ${Object.keys(groups).length} body parts and 85 squat frames to ${out}`);
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
