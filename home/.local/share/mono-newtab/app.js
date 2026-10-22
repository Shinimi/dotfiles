// New tab page: clock, today's line, bookmarks, and the dunes drawn as slowly moving ASCII. Made by Claude.
const LINES = ["a thousand years is just a long walk", "learn one useless spell today", "slow is still moving",
  "the flowers bloom where you walked", "remember the small things", "every journey ends somewhere new",
  "magic is patience, mostly", "the road remembers you", "rest is part of the journey",
  "keep the people you meet", "one more step, then tea", "the stars were here before the map"];
const $ = id => document.getElementById(id);
function tick() {
  const d = new Date();
  $("clock").textContent = d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  $("date").textContent = d.toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" }).toLowerCase();
}
tick(); setInterval(tick, 1000);
{ const d = new Date(), start = new Date(d.getFullYear(), 0, 0); $("line").textContent = "— " + LINES[Math.floor((d - start) / 86400000) % LINES.length]; }
LINKS.forEach(([name, url], i) => {
  const a = document.createElement("a"); a.href = url;
  a.innerHTML = `<span class="n">${String(i + 1).padStart(2, "0")}</span><span class="s">//</span><span class="t">${name.toUpperCase()}</span><span class="u">${url.replace(/^https?:\/\/(www\.)?/, "")}</span>`;
  $("links").appendChild(a);
});
// number keys 1-8 open a bookmark when the search box is empty
addEventListener("keydown", e => {
  if ($("q").value === "" && /^[1-9]$/.test(e.key) && LINKS[e.key - 1]) { e.preventDefault(); location.href = LINKS[e.key - 1][1]; }
});

// ---- ASCII dunes (same characters and light wave as the desktop) ----
const CHARS = " .`:-=+*cox%#@", CW = 9, CH = 16;
const cv = $("ascii"), cx = cv.getContext("2d");
const img = new Image(); img.src = "dunes.jpg";
let lum = null, cols = 0, rows = 0, t = 0, last = 0;
function prepare() {
  const dpr = devicePixelRatio || 1;
  cv.width = innerWidth * dpr; cv.height = innerHeight * dpr; cx.setTransform(dpr, 0, 0, dpr, 0, 0);
  cols = Math.ceil(innerWidth / CW); rows = Math.ceil(innerHeight / CH);
  const off = document.createElement("canvas"); off.width = cols; off.height = rows;
  const o = off.getContext("2d");
  const r = innerWidth / innerHeight, ir = img.width / img.height;          // cover-crop like a wallpaper
  let sw = img.width, sh = img.height, sx = 0, sy = 0;
  if (ir > r) { sw = img.height * r; sx = (img.width - sw) / 2 } else { sh = img.width / r; sy = (img.height - sh) / 2 }
  o.drawImage(img, sx, sy, sw, sh, 0, 0, cols, rows);
  const px = o.getImageData(0, 0, cols, rows).data;
  lum = new Float32Array(cols * rows);
  for (let i = 0; i < cols * rows; i++) lum[i] = (px[i * 4] * .299 + px[i * 4 + 1] * .587 + px[i * 4 + 2] * .114) / 255;
  cx.font = `bold 13px "GeistMono Nerd Font", monospace`; cx.textAlign = "center"; cx.textBaseline = "middle";
}
const ss = (a, b, x) => { const v = Math.min(1, Math.max(0, (x - a) / (b - a))); return v * v * (3 - 2 * v); };
function draw(now) {
  requestAnimationFrame(draw);
  if (!lum || now - last < 66) return;            // ~15 fps is plenty for slow light
  last = now; t += 0.066;
  cx.fillStyle = "#000"; cx.fillRect(0, 0, innerWidth, innerHeight);
  for (let y = 0; y < rows; y++) for (let x = 0; x < cols; x++) {
    const u = x / cols, v = y / rows;
    const wave = Math.sin(u * 7 - t * 0.45 + v * 5) * 0.5 + 0.5;
    let l = Math.min(1, Math.max(0, lum[y * cols + x] + (wave - 0.5) * 0.14));
    l = Math.pow(ss(0.13, 0.97, l), 1.35);
    const gi = Math.round(l * (CHARS.length - 1)); if (!gi) continue;
    const g = Math.round(255 * Math.min(1, 0.1 + 1.1 * l));
    cx.fillStyle = `rgb(${g},${g},${g})`;
    cx.fillText(CHARS[gi], x * CW + CW / 2, y * CH + CH / 2);
  }
}
img.onload = () => { prepare(); requestAnimationFrame(draw); };
addEventListener("resize", () => img.complete && prepare());
