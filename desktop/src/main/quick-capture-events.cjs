function shouldRefreshMainAfterSave({ senderId, quickCaptureWindowId }) {
  return Number.isInteger(senderId) && senderId === quickCaptureWindowId;
}

module.exports = { shouldRefreshMainAfterSave };
