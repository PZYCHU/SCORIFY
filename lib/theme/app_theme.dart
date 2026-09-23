import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary palette — dari mockup (teal gelap + sage green)
  static const Color primary = Color(0xFF1B4B5A);       // dark teal (tombol, header)
  static const Color primaryLight = Color(0xFF2D7D8E);  // medium teal
  static const Color accent = Color(0xFF10B981);        // green emerald (benefit / sukses)
  static const Color danger = Color(0xFFDC2626);        // red (cost / remedi / hapus)
  static const Color warning = Color(0xFFD97706);       // amber warning
  static const Color warningDark = Color(0xFF92400E);   // amber dark text kontras tinggi
  static const Color warningBg = Color(0xFFFEF3C7);     // amber soft bg
  static const Color warningBorder = Color(0xFFFCD34D); // amber border
  static const Color background = Color(0xFFE8EDE6);    // sage background
  static const Color surface = Color(0xFFF5F7F3);       // card putih keabuan
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A);   // slate dark untuk ketegasan
  static const Color textSecondary = Color(0xFF334155); // slate secondary lebih terbaca
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFCBD5E1);

  static const Color benefitChip = Color(0xFFECFDF5);
  static const Color benefitChipText = Color(0xFF065F46);
  static const Color costChip = Color(0xFFFEF2F2);
  static const Color costChipText = Color(0xFF991B1B);

  static const Color scoreCard = Color(0xFF1B4B5A);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
        primary: AppColors.primary,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14.5, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColors.textHint,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
    );
  }
}
