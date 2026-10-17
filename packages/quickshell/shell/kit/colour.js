.pragma library

// Colours for the pickers: a hex string (#rrggbb) and its hue (0..1).

// the hue of a hex colour, 0..1; -1 for a grey (no hue) or a text that is no colour
function hueOf(hex) {
  const m = /^#?([0-9a-fA-F]{6})$/.exec((hex || "").trim());
  if (!m) return -1;
  const n = parseInt(m[1], 16);
  const r = ((n >> 16) & 255) / 255, g = ((n >> 8) & 255) / 255, b = (n & 255) / 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
  if (d === 0) return -1;
  let h = max === r ? (g - b) / d : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
  h = ((h % 6) + 6) % 6;
  return h / 6;
}

// hue, saturation, value (each 0..1) to #rrggbb
function hexOf(h, s, v) {
  const f = n => {
    const k = (n + h * 6) % 6;
    return v - v * s * Math.max(0, Math.min(k, 4 - k, 1));
  };
  const part = x => Math.round(x * 255).toString(16).padStart(2, "0");
  return "#" + part(f(5)) + part(f(3)) + part(f(1));
}

// #rrggbb to { h, s, v } (each 0..1); h is -1 for a grey (no hue), null for a bad text
function hsvOf(hex) {
  const m = /^#?([0-9a-fA-F]{6})$/.exec((hex || "").trim());
  if (!m) return null;
  const n = parseInt(m[1], 16);
  const r = ((n >> 16) & 255) / 255, g = ((n >> 8) & 255) / 255, b = (n & 255) / 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
  const v = max;
  const s = max === 0 ? 0 : d / max;
  return { h: hueOf(hex), s: s, v: v };
}

// a Qt colour (rgba, 0..1 each) to #rrggbb
function hexOfColour(c) {
  const part = x => Math.round(x * 255).toString(16).padStart(2, "0");
  return "#" + part(c.r) + part(c.g) + part(c.b);
}
