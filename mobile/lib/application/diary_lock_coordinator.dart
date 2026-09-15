import 'package:flutter/foundation.dart';

/// Coordinates short-lived platform activities such as the photo picker.
///
/// Android reports opening a picker as an app lifecycle transition. The diary
/// must not interpret that transition as the user leaving the app, otherwise
/// returning from a photo picker would immediately trigger the privacy lock.
class DiaryLockCoordinator extends ChangeNotifier {
  int _externalActivityDepth = 0;

  bool get isExternalActivityActive => _externalActivityDepth > 0;

  void beginExternalActivity() {
    _externalActivityDepth += 1;
    notifyListeners();
  }

  void endExternalActivity() {
    if (_externalActivityDepth == 0) return;
    _externalActivityDepth -= 1;
    notifyListeners();
  }
}
