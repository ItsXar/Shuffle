// Draws the card art (cards.html) into transparent PNGs:  node tools/cardart/render.mjs
// Output: assets/cards/<Back|Common|...>.png, 800x1040 = the 600x840 card plus a 100 px margin on
// every side for the crest, wings and glow that stick out. Upload them to Roblox and put the ids
// in src/ReplicatedStorage/Shared/Config/CardArt.luau.

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
let chromium;
try {
	({ chromium } = require("playwright"));
} catch {
	({ chromium } = require("/opt/node22/lib/node_modules/playwright"));
}

const here = path.dirname(fileURLToPath(import.meta.url));
const out = path.resolve(here, "../../assets/cards");
const MARGIN = 100;
fs.mkdirSync(out, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 4800, height: 2600 }, deviceScaleFactor: 1 });
await page.goto("file://" + path.join(here, "cards.html"));
await page.waitForFunction(() => window.ready);
await page.evaluate(() => document.fonts.ready);
const ids = await page.evaluate(() => window.cards);
for (const id of ids) {
	const box = await page.locator(`#${id}`).boundingBox();
	const clip = { x: box.x - MARGIN, y: box.y - MARGIN, width: box.width + MARGIN * 2, height: box.height + MARGIN * 2 };
	await page.screenshot({ path: path.join(out, `${id}.png`), clip, omitBackground: true });
}
if (process.argv.includes("--sheet")) {
	await page.setViewportSize({ width: 4800, height: 2600 });
	await page.evaluate(() => (document.body.style.background = "#2a2f3a"));
	await page.screenshot({ path: path.join(here, "sheet.png"), fullPage: true });
}
await browser.close();
console.log(`${ids.length} cards -> ${out}`);
