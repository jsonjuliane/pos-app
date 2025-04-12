import 'package:flutter/material.dart';

enum DeviceType {
  mobilePortrait,
  mobileLandscape,
  tabletPortrait,
  tabletLandscape,
  web,
}

class DeviceHelper {
  static DeviceType getDeviceType(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final shortestSide = size.shortestSide;
    final orientation = MediaQuery.of(context).orientation;

    if (width >= 1400) {
      return DeviceType.web;
    }

    if (shortestSide >= 600) {
      // Tablet device
      return orientation == Orientation.portrait
          ? DeviceType.tabletPortrait
          : DeviceType.tabletLandscape;
    }

    // Mobile device
    return orientation == Orientation.portrait
        ? DeviceType.mobilePortrait
        : DeviceType.mobileLandscape;
  }

  static int getCrossAxisCount(DeviceType type) {
    switch (type) {
      case DeviceType.web:
        return 5;
      case DeviceType.tabletLandscape:
        return 4;
      case DeviceType.tabletPortrait:
        return 3;
      case DeviceType.mobileLandscape:
        return 3;
      case DeviceType.mobilePortrait:
      default:
        return 2;
    }
  }

  static double getChildAspectRatio(DeviceType type) {
    switch (type) {
      case DeviceType.web:
        return 1.1;
      case DeviceType.tabletLandscape:
        return 1.3;
      case DeviceType.tabletPortrait:
        return 0.9;
      case DeviceType.mobileLandscape:
        return 1.0;
      case DeviceType.mobilePortrait:
      default:
        return 0.75;
    }
  }
}