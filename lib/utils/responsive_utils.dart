import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper utilities for device classification, responsive layout breakpoints,
/// and adaptive orientation locking.
class ResponsiveUtils {
  // Breakpoints
  static const double mobileMaxWidth = 768.0;
  static const double dualPaneMinWidth = 992.0;
  static const double tabletShortestSide = 600.0;

  /// Returns true if the device is a tablet/iPad (shortest side >= 600dp).
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= tabletShortestSide;
  }

  /// Returns true if running on a desktop/laptop operating system.
  static bool isDesktopOrLaptop() {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  /// Returns true if the current viewport is in landscape orientation.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Returns true if the screen is wider than a standard phone (e.g. tablet or laptop).
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= mobileMaxWidth;
  }

  /// Returns true if the screen is large enough for a two-pane tablet assistant layout.
  static bool isDualPane(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= dualPaneMinWidth;
  }

  /// Computes dynamic grid column count based on available container width.
  static int getGridColumnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  /// Applies orientation constraints: locks phones to portrait, unlocks landscape for tablets & laptops.
  static void updateOrientationsForContext(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final canUseLandscape = shortest >= tabletShortestSide || isDesktopOrLaptop();

    if (canUseLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }
}
