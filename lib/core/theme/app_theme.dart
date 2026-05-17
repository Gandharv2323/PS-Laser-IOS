import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ios_design_system.dart';

// ══════════════════════════════════════════════════════════════════
// PS LASER App Theme — v2.0 iOS-First
// ══════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // Expose PSColors for backward compatibility with existing screens
  static const Color primaryBlue = PSColors.brand;
  static const Color primaryLight = PSColors.brandLight;
  static const Color accentOrange = PSColors.neonOrange;
  static const Color accentGreen = PSColors.neonGreen;
  static const Color accentRed = PSColors.neonRed;
  static const Color accentYellow = PSColors.neonYellow;

  static const Color darkBg = PSColors.darkBg;
  static const Color darkSurface = PSColors.darkSurface;
  static const Color darkCard = PSColors.darkCard;
  static const Color darkBorder = PSColors.darkBorder;

  static const Color lightBg = PSColors.lightBg;
  static const Color lightSurface = PSColors.lightSurface;
  static const Color lightCard = PSColors.lightCard;

  static const Color statusRunning = PSColors.statusOnline;
  static const Color statusIdle = PSColors.statusWarning;
  static const Color statusMaintenance = PSColors.neonOrange;
  static const Color statusCritical = PSColors.statusCritical;

  // ── Dark Theme (Primary — iOS-native precision dark) ─────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.dark(
        primary: PSColors.brand,
        secondary: PSColors.neonCyan,
        surface: PSColors.darkSurface,
        error: PSColors.neonRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: PSColors.textDark1,
        surfaceContainerHighest: PSColors.darkCard,
      ),
      scaffoldBackgroundColor: PSColors.darkBg,
      cardTheme: CardThemeData(
        color: PSColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PSRadius.md),
          side: const BorderSide(color: PSColors.darkBorder, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PSColors.darkBg,
        foregroundColor: PSColors.textDark1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: PSColors.textDark1,
        ),
        iconTheme: const IconThemeData(color: PSColors.textDark1, size: 22),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: PSText.display(color: PSColors.textDark1),
        headlineLarge: PSText.headline(color: PSColors.textDark1),
        headlineMedium: PSText.title(color: PSColors.textDark1),
        titleLarge: PSText.titleSmall(color: PSColors.textDark1),
        titleMedium: PSText.body(color: PSColors.textDark2, weight: FontWeight.w600),
        bodyLarge: PSText.body(color: PSColors.textDark2),
        bodyMedium: PSText.bodySmall(color: PSColors.textDark2),
        bodySmall: PSText.caption(color: PSColors.textDark3),
        labelLarge: PSText.label(color: PSColors.brand),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PSColors.darkSurface,
        selectedItemColor: PSColors.brand,
        unselectedItemColor: PSColors.textDark3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PSColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.darkBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.darkBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.neonRed, width: 1),
        ),
        hintStyle: GoogleFonts.inter(color: PSColors.textDark3, fontSize: 15),
        labelStyle: GoogleFonts.inter(color: PSColors.textDark2, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PSColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PSRadius.sm),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PSColors.brand,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.full)),
        backgroundColor: PSColors.darkCard,
        selectedColor: PSColors.brand.withOpacity(0.25),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        side: const BorderSide(color: PSColors.darkBorder, width: 0.5),
      ),
      dividerTheme: const DividerThemeData(
        color: PSColors.darkBorder,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: PSColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PSColors.darkElevated,
        contentTextStyle: GoogleFonts.inter(color: PSColors.textDark1, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.sm)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PSColors.darkElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.lg)),
        titleTextStyle: GoogleFonts.inter(
          color: PSColors.textDark1,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: PSColors.textDark2,
          fontSize: 14,
        ),
      ),
    );
  }

  // ── Light Theme (Secondary) ───────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.light(
        primary: PSColors.brand,
        secondary: PSColors.brandLight,
        surface: PSColors.lightSurface,
        error: PSColors.neonRed,
        onPrimary: Colors.white,
        onSurface: PSColors.textLight1,
        surfaceContainerHighest: const Color(0xFFF2F2F7),
      ),
      scaffoldBackgroundColor: PSColors.lightBg,
      cardTheme: CardThemeData(
        color: PSColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PSRadius.md),
          side: const BorderSide(color: PSColors.lightBorder, width: 0.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PSColors.lightBg,
        foregroundColor: PSColors.textLight1,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: PSColors.textLight1,
        ),
        iconTheme: const IconThemeData(color: PSColors.textLight1, size: 22),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: PSText.display(color: PSColors.textLight1),
        headlineLarge: PSText.headline(color: PSColors.textLight1),
        headlineMedium: PSText.title(color: PSColors.textLight1),
        titleLarge: PSText.titleSmall(color: PSColors.textLight1),
        titleMedium: PSText.body(color: PSColors.textLight2, weight: FontWeight.w600),
        bodyLarge: PSText.body(color: PSColors.textLight2),
        bodyMedium: PSText.bodySmall(color: PSColors.textLight2),
        bodySmall: PSText.caption(color: PSColors.textLight3),
        labelLarge: PSText.label(color: PSColors.brand),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PSColors.lightSurface,
        selectedItemColor: PSColors.brand,
        unselectedItemColor: PSColors.textLight3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.lightBorder, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.lightBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PSRadius.sm),
          borderSide: const BorderSide(color: PSColors.brand, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: PSColors.textLight3, fontSize: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PSColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PSRadius.sm),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.full)),
        selectedColor: PSColors.brand.withOpacity(0.1),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        side: const BorderSide(color: PSColors.lightBorder, width: 0.5),
      ),
      dividerTheme: const DividerThemeData(
        color: PSColors.lightBorder,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PSColors.textLight1,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.sm)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: PSColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PSRadius.lg)),
        titleTextStyle: GoogleFonts.inter(
          color: PSColors.textLight1,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(color: PSColors.textLight2, fontSize: 14),
      ),
    );
  }

  // ── Static helpers (backward compat with existing screens) ─────────

  static Color statusColor(String status) => PSColors.forStatus(status);
  static Color statusBg(String status) => PSColors.bgForStatus(status);
  static Color priorityColor(String priority) => PSColors.forPriority(priority);
}
