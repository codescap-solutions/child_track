import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Oswald Font Styles for Headings
  static TextStyle get headlineXL => GoogleFonts.oswald(
    fontSize: 44,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline1 => GoogleFonts.oswald(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline2 => GoogleFonts.oswald(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline3 => GoogleFonts.oswald(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline4 => GoogleFonts.oswald(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline5 => GoogleFonts.oswald(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get headline6 => GoogleFonts.oswald(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Manrope Font Styles for Body, Buttons, and Captions
  static TextStyle get subtitle1 => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get subtitle2 => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Styles
  static TextStyle get body1 => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get body2 => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // Caption Styles
  static TextStyle get caption => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle get textSecondary => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Button Styles
  static TextStyle get button => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.surfaceColor,
  );

  // Overline Styles
  static TextStyle get overline => GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );
}
