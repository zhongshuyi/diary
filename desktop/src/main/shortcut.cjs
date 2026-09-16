const DEFAULT_QUICK_CAPTURE_ACCELERATOR = 'CommandOrControl+Shift+Space';

const MODIFIER_ALIASES = new Map([
  ['ctrl', 'CommandOrControl'],
  ['control', 'CommandOrControl'],
  ['cmd', 'CommandOrControl'],
  ['command', 'CommandOrControl'],
  ['commandorcontrol', 'CommandOrControl'],
  ['shift', 'Shift'],
  ['alt', 'Alt'],
  ['option', 'Alt'],
]);

function normalizeAccelerator(value) {
  const tokens = String(value || '').split('+').map((token) => token.trim()).filter(Boolean);
  if (tokens.length < 2) throw new Error('A shortcut accelerator needs a modifier and a key');

  const key = tokens.at(-1);
  const modifiers = [...new Set(tokens.slice(0, -1).map((token) => MODIFIER_ALIASES.get(token.toLowerCase())))];
  if (modifiers.includes(undefined) || !modifiers.includes('CommandOrControl')) {
    throw new Error('Unsupported shortcut accelerator');
  }
  if (!/^[A-Za-z0-9]$/.test(key) && !/^(Space|Enter|Escape|Tab|Backspace|Delete|F(?:[1-9]|1[0-2]))$/i.test(key)) {
    throw new Error('Unsupported shortcut accelerator key');
  }
  return [...modifiers.sort((left, right) => ['CommandOrControl', 'Alt', 'Shift'].indexOf(left) - ['CommandOrControl', 'Alt', 'Shift'].indexOf(right)), key.length === 1 ? key.toUpperCase() : key[0].toUpperCase() + key.slice(1).toLowerCase()].join('+');
}

function formatAccelerator(value, platform = process.platform) {
  const normalized = normalizeAccelerator(value);
  return normalized.split('+').map((token) => token === 'CommandOrControl' ? (platform === 'darwin' ? '⌘' : 'Ctrl') : token).join(' + ');
}

module.exports = {
  DEFAULT_QUICK_CAPTURE_ACCELERATOR,
  normalizeAccelerator,
  formatAccelerator,
};
