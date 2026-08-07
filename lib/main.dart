import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/app.dart';

void main() {
  runApp(const ProviderScope(child: ShowlineApp()));
}

ThemeData buildShowlineTheme() {
  const ink = Color(0xFF17221C);
  const cream = Color(0xFFF6F2E9);
  const moss = Color(0xFF4E725C);

  final textTheme = GoogleFonts.dmSansTextTheme().copyWith(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 64,
      height: .98,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 46,
      height: 1,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    headlineLarge: GoogleFonts.playfairDisplay(
      fontSize: 34,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: moss,
      brightness: Brightness.light,
      surface: cream,
    ),
    scaffoldBackgroundColor: cream,
    textTheme: textTheme,
    useMaterial3: true,
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
  );
}
