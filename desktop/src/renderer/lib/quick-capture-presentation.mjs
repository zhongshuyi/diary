export function shouldShowEditorClose({ windowed, onClose }) {
  return Boolean(onClose && !windowed);
}

export function shouldResetQuickCaptureScroll({ windowed }) {
  return Boolean(windowed);
}
