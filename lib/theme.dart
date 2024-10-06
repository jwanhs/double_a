import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData lightThemeData = FlexThemeData.light(
  scheme: FlexScheme.gold,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 7,
  swapColors: true,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 40,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);

ThemeData darkThemeData = FlexThemeData.dark(
  scheme: FlexScheme.gold,
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 13,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 20,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);
