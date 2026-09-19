const QUICK_CAPTURE_WIDTH = 760;
const QUICK_CAPTURE_HEIGHT = 680;
const QUICK_CAPTURE_MIN_WIDTH = 560;
const QUICK_CAPTURE_MIN_HEIGHT = 500;
const MIN_VISIBLE_EDGE = 80;

function numeric(value, fallback) {
  return Number.isFinite(Number(value)) ? Number(value) : fallback;
}

function intersectsDisplay(bounds, displayBounds) {
  const width = Math.min(bounds.x + bounds.width, displayBounds.x + displayBounds.width) - Math.max(bounds.x, displayBounds.x);
  const height = Math.min(bounds.y + bounds.height, displayBounds.y + displayBounds.height) - Math.max(bounds.y, displayBounds.y);
  return width >= MIN_VISIBLE_EDGE && height >= MIN_VISIBLE_EDGE;
}

function restoreQuickCaptureBounds(saved, displays = [], width = QUICK_CAPTURE_WIDTH, height = QUICK_CAPTURE_HEIGHT) {
  const primary = displays[0]?.bounds || { x: 0, y: 0, width: 1920, height: 1080 };
  const fallback = { x: Math.round(primary.x + (primary.width - width) / 2), y: Math.round(primary.y + (primary.height - height) / 2), width, height };
  if (!saved || !Array.isArray(displays) || !displays.length) return fallback;
  const bounds = { x: numeric(saved.x, fallback.x), y: numeric(saved.y, fallback.y), width: Math.max(QUICK_CAPTURE_MIN_WIDTH, numeric(saved.width, width)), height: Math.max(QUICK_CAPTURE_MIN_HEIGHT, numeric(saved.height, height)) };
  return displays.some((display) => display?.bounds && intersectsDisplay(bounds, display.bounds)) ? bounds : fallback;
}

module.exports = {
  QUICK_CAPTURE_HEIGHT,
  QUICK_CAPTURE_MIN_HEIGHT,
  QUICK_CAPTURE_MIN_WIDTH,
  QUICK_CAPTURE_WIDTH,
  restoreQuickCaptureBounds,
};
