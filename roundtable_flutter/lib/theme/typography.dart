import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Named text styles from `docs/UI-DESIGN.md` §1 (Typography). IBM Plex Sans
/// for UI text, IBM Plex Mono for code/logs/diffs/tokens/model names.
abstract final class AppTypography {
  static TextStyle get screenTitle => GoogleFonts.ibmPlexSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text0,
  );

  static TextStyle get cardTitle => GoogleFonts.ibmPlexSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text0,
  );

  static TextStyle get body => GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text0,
  );

  static TextStyle get bodyStrong => GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text0,
  );

  static TextStyle get label => GoogleFonts.ibmPlexSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.04 * 11,
    color: AppColors.text1,
  );

  static TextStyle get caption => GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.text2,
  );

  static TextStyle get code => GoogleFonts.ibmPlexMono(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.text0,
  );

  static TextTheme get textTheme => TextTheme(
    titleLarge: screenTitle,
    titleMedium: cardTitle,
    bodyMedium: body,
    bodyLarge: bodyStrong,
    labelLarge: label,
    bodySmall: caption,
  );
}
