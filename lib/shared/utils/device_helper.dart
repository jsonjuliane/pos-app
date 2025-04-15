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

  static int getCrossAxisCount(DeviceType type, bool wide) {
    switch (type) {
      case DeviceType.web:
        return 5;
      case DeviceType.tabletLandscape:
        if (wide) {
          return 4;
        } else {
          return 3;
        }
      case DeviceType.tabletPortrait:
        return 3;
      case DeviceType.mobileLandscape:
        return 3;
      case DeviceType.mobilePortrait:
      default:
        return 2;
    }
  }

  static double getChildAspectRatio(DeviceType type, String screen) {
    switch (type) {
      case DeviceType.web:
        return 1.1;
      case DeviceType.tabletLandscape:
        if (screen == "ord") {
          return 0.9;
        } else if (screen == "rep") {
          return 2.5;
        } else {
          return 1.3;
        }
      case DeviceType.tabletPortrait:
        if (screen == "inv") {
          return 0.9;
        } else if (screen == "ord") {
          return 0.75;
        } else if (screen == "rep") {
          return 1.5;
        } else {
          return 1.0;
        }
      case DeviceType.mobileLandscape:
        if (screen == "inv") {
          return 1.1;
        } else if (screen == "rep") {
          return 2.35;
        } else if (screen == "ord") {
          return 0.80;
        }else {
          return 1.2;
        }
      case DeviceType.mobilePortrait:
      default:
        if (screen == "inv") {
          return 0.80;
        } else if (screen == "ord") {
          return 0.55;
        } else if (screen == "rep") {
          return 1.5;
        } else {
          return 0.85;
        }
    }
  }
}
