import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Restrained luxury: mostly neutral surfaces; orange is accent-only.
abstract final class LuxuryAppTheme {
  /// Primary brand orange — use for CTAs, key selection, focus states only.
  static const Color orange = Color(0xFFE65100);

  /// Subtle gold for rare highlights (status dot, etc.).
  static const Color amberGold = Color(0xFFFFB300);

  /// Light mode: cool neutral canvas (no peach / orange wash).
  static const Color canvasLight = Color(0xFFF8F8F9);

  static const Color canvasLightElevated = Color(0xFFFFFFFF);

  /// Dark mode near-black (slightly cool).
  static const Color canvasDark = Color(0xFF0F0F10);

  static const Color canvasDarkElevated = Color(0xFF1C1C1E);

  static const Color _neutralContainerLight = Color(0xFFEEF0F3);
  static const Color _neutralSurfaceLowLight = Color(0xFFF3F3F5);
  static const Color _neutralSurfaceMidLight = Color(0xFFEBECF0);

  static ThemeData theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: brightness,
    );

    final onSurface = isDark ? const Color(0xFFF5F2EE) : const Color(0xFF1A1512);
    final onSurfaceVariant =
        isDark ? const Color(0xFFB8B0A8) : const Color(0xFF5C534A);

    final colorScheme = baseScheme.copyWith(
      primary: orange,
      onPrimary: Colors.white,
      // Tonal surfaces stay neutral — orange is not baked into backgrounds.
      primaryContainer: isDark
          ? const Color(0xFF2A2826)
          : _neutralContainerLight,
      onPrimaryContainer:
          isDark ? const Color(0xFFE8E6E3) : const Color(0xFF1C1B1F),
      // Secondary = refined slate (not gold wash across UI).
      secondary: isDark ? const Color(0xFF9AA0A6) : const Color(0xFF5C6370),
      onSecondary: Colors.white,
      secondaryContainer: isDark
          ? const Color(0xFF2D3136)
          : const Color(0xFFE4E6EA),
      onSecondaryContainer:
          isDark ? const Color(0xFFDCE1E8) : const Color(0xFF1C1F24),
      tertiary: const Color(0xFFB85C38),
      onTertiary: Colors.white,
      surface: isDark ? canvasDark : Colors.white,
      surfaceContainerLowest:
          isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          isDark ? const Color(0xFF18181A) : _neutralSurfaceLowLight,
      surfaceContainer:
          isDark ? canvasDarkElevated : const Color(0xFFEEEFF2),
      surfaceContainerHigh:
          isDark ? const Color(0xFF252528) : _neutralSurfaceMidLight,
      surfaceContainerHighest:
          isDark ? const Color(0xFF2E2E32) : const Color(0xFFE2E3E8),
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: isDark
          ? const Color(0xFF44444A)
          : const Color(0xFFC8CAD0),
      outlineVariant: isDark
          ? const Color(0xFF333338)
          : const Color(0xFFE0E1E6),
      shadow: Colors.black.withValues(alpha: isDark ? 0.55 : 0.08),
      scrim: Colors.black.withValues(alpha: 0.5),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    final titleStyle = GoogleFonts.plusJakartaSans(
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      // Slightly tighter defaults to fit better on phones.
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      iconTheme: IconThemeData(color: onSurface, size: 24),
      textTheme: textTheme.copyWith(
        headlineLarge: titleStyle.copyWith(fontSize: 36),
        headlineMedium: titleStyle.copyWith(fontSize: 30),
        headlineSmall: titleStyle.copyWith(fontSize: 26),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          height: 1.45,
          letterSpacing: 0.1,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          height: 1.45,
          letterSpacing: 0.15,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          height: 1.35,
          letterSpacing: 0.2,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 4,
        shadowColor: colorScheme.shadow,
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: orange.withValues(alpha: isDark ? 0.22 : 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: orange, size: 26);
          }
          return IconThemeData(color: onSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.plusJakartaSans(fontSize: 11.5);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
              color: orange,
              fontWeight: FontWeight.w700,
            );
          }
          return base.copyWith(
            color: onSurfaceVariant,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide.none,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: orange,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: orange.withValues(alpha: isDark ? 0.2 : 0.09),
        disabledColor: colorScheme.surfaceContainerHighest,
        checkmarkColor: orange,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
        color: isDark ? colorScheme.surfaceContainerHigh : canvasLightElevated,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        backgroundColor: colorScheme.surfaceContainerHigh,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: Colors.transparent,
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        dragHandleColor: onSurfaceVariant.withValues(alpha: 0.35),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? colorScheme.surfaceContainerHighest : onSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: isDark ? onSurface : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: orange.withValues(alpha: 0.55), width: 1.25),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.75)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: orange,
        linearTrackColor: orange.withValues(alpha: 0.15),
        circularTrackColor: orange.withValues(alpha: 0.12),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return orange;
          return null;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return orange;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return orange.withValues(alpha: 0.45);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: orange,
        thumbColor: orange,
        overlayColor: orange.withValues(alpha: 0.18),
        inactiveTrackColor: orange.withValues(alpha: 0.15),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: orange,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: orange,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: orange,
        textColor: Colors.white,
      ),
    );
  }
}
