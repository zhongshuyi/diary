import 'package:flutter/material.dart';

/// Small motion primitives shared by the mobile surfaces.
///
/// The app keeps transitions short and tactile, while honoring the platform's
/// reduced-motion preference in widget tests and on accessibility-focused
/// devices.
abstract final class DiaryMotion {
  static const standard = Duration(milliseconds: 180);
  static const emphasized = Duration(milliseconds: 260);

  static Duration duration(BuildContext context, Duration value) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Duration.zero
        : value;
  }

  static Curve curve(BuildContext context, Curve value) {
    return MediaQuery.maybeOf(context)?.disableAnimations == true
        ? Curves.linear
        : value;
  }
}
