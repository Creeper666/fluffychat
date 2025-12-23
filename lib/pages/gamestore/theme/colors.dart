import 'package:flutter/material.dart';

class AppColors {
  static const light = AppScheme(
    background: Color(0xffffffff),
    text: Color(0xff333333),
    textSecondary: Color(0xff888888),
    border: Color(0xffeeeeee),
    primary: Color(0xff007AFF),
    cardBackground: Color(0xffffffff),
    screenBackground: Color(0xfff5f5f5),
    loadingIndicator: Color(0xff0000ff),
  );

  static const dark = AppScheme(
    background: Color(0xff121212),
    text: Color(0xffe0e0e0),
    textSecondary: Color(0xffaaaaaa),
    border: Color(0xff333333),
    primary: Color(0xff0a84ff),
    cardBackground: Color(0xff1e1e1e),
    screenBackground: Color(0xff121212),
    loadingIndicator: Color(0xffffffff),
  );
}

class AppScheme {
  final Color background;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color primary;
  final Color cardBackground;
  final Color screenBackground;
  final Color loadingIndicator;
  const AppScheme({
    required this.background,
    required this.text,
    required this.textSecondary,
    required this.border,
    required this.primary,
    required this.cardBackground,
    required this.screenBackground,
    required this.loadingIndicator,
  });
}

AppScheme schemeOf(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.dark : AppColors.light;
}
