import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display({
    double size = 32,
    Color color = AppColors.white,
    double spacing = 1.5,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: spacing,
      );

  static TextStyle heading({
    double size = 18,
    Color color = AppColors.white,
    double spacing = 0.8,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: spacing,
      );

  static TextStyle subheading({
    double size = 15,
    Color color = AppColors.grey,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );

  static TextStyle label({
    double size = 11,
    Color color = AppColors.muted,
    double spacing = 1.5,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: spacing,
      );

  static TextStyle body({
    double size = 14,
    Color color = AppColors.white,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle number({
    double size = 24,
    Color color = AppColors.yellow,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.0,
      );
}
