import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData lightThemeData = FlexThemeData.light(
  scheme: FlexScheme.gold,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 7,
  swapColors: true,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 40,
    useMaterial3Typography: true,
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
    useMaterial3Typography: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
  ),
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);

InputDecoration getStandardInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.orangeAccent),
    ),
    border: const OutlineInputBorder(),
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.9,
    ),
  );
}
