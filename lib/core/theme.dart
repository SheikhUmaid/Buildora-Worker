import 'package:material_ui/material_ui.dart';

class AppColors {
  static const black = Color(0xFF111111);
  static const orange = Color(0xFFF26B1D);
  static const orangeSoft = Color(0xFFFDEBDD);
  static const surface = Color(0xFFF5F5F3);
  static const surfaceDark = Color(0xFFECECEA);
  static const border = Color(0xFFE6E6E3);
  static const text = Color(0xFF111111);
  static const textMuted = Color(0xFF8A8A87);
  static const textFaint = Color(0xFFB4B4B0);
  static const green = Color(0xFF1E9E4A);
  static const greenSoft = Color(0xFFE3F5E9);
  static const red = Color(0xFFE53935);
  static const redSoft = Color(0xFFFFE4E4);
  static const white = Colors.white;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter', // bundled in assets/fonts (works offline)
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.black,
        primary: AppColors.black,
        secondary: AppColors.orange,
        surface: AppColors.white,
        error: AppColors.red,
      ),
      scaffoldBackgroundColor: AppColors.white,
    );
    final textTheme = base.textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.text,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.black,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.black : AppColors.surfaceDark,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.orange,
        inactiveTrackColor: AppColors.surfaceDark,
        thumbColor: AppColors.orange,
        trackHeight: 4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.black),
    );
  }
}

/// Common text styles used across screens.
class AppText {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.text);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.text);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text);
  static const title = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text);
  static const body = TextStyle(fontSize: 14, color: AppColors.text, height: 1.4);
  static const muted = TextStyle(fontSize: 13, color: AppColors.textMuted);
  static const small = TextStyle(fontSize: 12, color: AppColors.textMuted);
  static const label = TextStyle(fontSize: 12, color: AppColors.textMuted);
}
