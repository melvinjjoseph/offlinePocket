import 'package:flutter/material.dart';

/// Raw palette pulled directly from the Google Stitch "cyber" design tokens.
/// These are the exact hex values from the mockup's Tailwind config so that
/// gradients, glows, and one-off surfaces can reference them without going
/// through [ColorScheme] (which only carries a subset of roles).
abstract final class AppColors {
  // Surfaces (dark)
  static const background = Color(0xFF0D1518);
  static const surface = Color(0xFF0D1518);
  static const surfaceContainerLowest = Color(0xFF070F12);
  static const surfaceContainerLow = Color(0xFF151D20);
  static const surfaceContainer = Color(0xFF192124);
  static const surfaceContainerHigh = Color(0xFF232B2E);
  static const surfaceContainerHighest = Color(0xFF2E3639);
  static const surfaceBright = Color(0xFF323A3E);

  // Content
  static const onSurface = Color(0xFFDBE4E8);
  static const onSurfaceVariant = Color(0xFFB9CACA);
  static const outline = Color(0xFF849495);
  static const outlineVariant = Color(0xFF3A494A);

  // Cyan accent family
  static const accent = Color(0xFF00DCE5); // primary-fixed-dim — main neon
  static const accentBright = Color(0xFF00F5FF); // primary-container
  static const accentSoft = Color(0xFF63F7FF); // primary-fixed
  static const onAccent = Color(0xFF003739); // on-primary
  static const onAccentContainer = Color(0xFF00363A); // dark ink on bright cyan

  // Secondary / neutral chips
  static const secondary = Color(0xFFB6CAD1);
  static const secondaryContainer = Color(0xFF374A50);
  static const onSecondaryContainer = Color(0xFFA5B8C0);

  // Error / destructive
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const inversePrimary = Color(0xFF00696E);
}

/// Neon-specific design tokens that Material's [ThemeData] has no slot for.
/// Screens read these via `Theme.of(context).extension<NeonTheme>()!` (or the
/// [NeonThemeX] helper) so the same widget renders correctly in light + dark.
@immutable
class NeonTheme extends ThemeExtension<NeonTheme> {
  const NeonTheme({
    required this.accent,
    required this.accentBright,
    required this.glow,
    required this.panelBorder,
    required this.mono,
    required this.cardGradient,
  });

  /// Primary neon accent — headings, active nav, key icons.
  final Color accent;

  /// Brighter cyan for the FAB / high-emphasis fills.
  final Color accentBright;

  /// Shadow color used for the "cyber glow" box-shadow.
  final Color glow;

  /// Hairline border used on glass panels and cards.
  final Color panelBorder;

  /// Muted color for JetBrains-Mono micro labels.
  final Color mono;

  /// Gradient used for the credit-card visual on the detail screen.
  final List<Color> cardGradient;

  /// Standard cyber-glow shadow. [strength] scales the blur + spread.
  List<BoxShadow> glowShadow({double strength = 1}) => [
        BoxShadow(
          color: glow.withValues(alpha: 0.40 * strength),
          blurRadius: 16 * strength,
          spreadRadius: 0,
        ),
      ];

  @override
  NeonTheme copyWith({
    Color? accent,
    Color? accentBright,
    Color? glow,
    Color? panelBorder,
    Color? mono,
    List<Color>? cardGradient,
  }) =>
      NeonTheme(
        accent: accent ?? this.accent,
        accentBright: accentBright ?? this.accentBright,
        glow: glow ?? this.glow,
        panelBorder: panelBorder ?? this.panelBorder,
        mono: mono ?? this.mono,
        cardGradient: cardGradient ?? this.cardGradient,
      );

  @override
  NeonTheme lerp(NeonTheme? other, double t) {
    if (other == null) return this;
    return NeonTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      mono: Color.lerp(mono, other.mono, t)!,
      cardGradient: [
        Color.lerp(cardGradient.first, other.cardGradient.first, t)!,
        Color.lerp(cardGradient.last, other.cardGradient.last, t)!,
      ],
    );
  }

  static const dark = NeonTheme(
    accent: AppColors.accent,
    accentBright: AppColors.accentBright,
    glow: AppColors.accentBright,
    panelBorder: AppColors.outlineVariant,
    mono: AppColors.onSurfaceVariant,
    cardGradient: [Color(0xFF1B2A2E), Color(0xFF0D1518)],
  );

  static const light = NeonTheme(
    accent: Color(0xFF00777E),
    accentBright: Color(0xFF00A5AE),
    glow: Color(0xFF00A5AE),
    panelBorder: Color(0xFFC5D4D5),
    mono: Color(0xFF4A5B5C),
    cardGradient: [Color(0xFF0E7A80), Color(0xFF0A5A5F)],
  );
}

extension NeonThemeX on BuildContext {
  NeonTheme get neon => Theme.of(this).extension<NeonTheme>()!;
}

abstract final class AppTheme {
  static const _sans = 'Geist';
  static const _mono = 'JetBrainsMono';

  /// Text theme shared by both brightnesses (colors come from [ColorScheme]).
  /// Geist for display/headline/title/body, JetBrains Mono for labels — this
  /// mono/sans split is core to the design's identity.
  static TextTheme _textTheme(Color onSurface, Color variant) {
    TextStyle sans(double size, double height, FontWeight w,
            {double spacing = 0, Color? color}) =>
        TextStyle(
          fontFamily: _sans,
          fontSize: size,
          height: height / size,
          fontWeight: w,
          letterSpacing: spacing,
          color: color ?? onSurface,
        );

    TextStyle mono(double size, double height, double spacing) => TextStyle(
          fontFamily: _mono,
          fontSize: size,
          height: height / size,
          fontWeight: FontWeight.w500,
          letterSpacing: spacing,
          color: variant,
        );

    return TextTheme(
      displayLarge: sans(40, 48, FontWeight.w600, spacing: -0.8),
      displayMedium: sans(34, 42, FontWeight.w600, spacing: -0.6),
      headlineLarge: sans(32, 40, FontWeight.w600, spacing: -0.64),
      headlineMedium: sans(24, 32, FontWeight.w600, spacing: -0.24),
      headlineSmall: sans(20, 28, FontWeight.w600, spacing: -0.2),
      titleLarge: sans(22, 28, FontWeight.w600),
      titleMedium: sans(16, 24, FontWeight.w600),
      titleSmall: sans(14, 20, FontWeight.w600),
      bodyLarge: sans(18, 28, FontWeight.w400),
      bodyMedium: sans(16, 24, FontWeight.w400),
      bodySmall: sans(14, 20, FontWeight.w400, color: variant),
      labelLarge: mono(14, 20, 0.7),
      labelMedium: mono(14, 20, 0.7),
      labelSmall: mono(12, 16, 0.96),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      primaryContainer: AppColors.accentBright,
      onPrimaryContainer: AppColors.onAccentContainer,
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF213339),
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.accentSoft,
      onTertiary: Color(0xFF00363A),
      tertiaryContainer: Color(0xFF004F53),
      onTertiaryContainer: Color(0xFF9EF0F5),
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceBright: AppColors.surfaceBright,
      surfaceDim: AppColors.background,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.onSurface,
      onInverseSurface: Color(0xFF2A3235),
      inversePrimary: AppColors.inversePrimary,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    return _build(scheme, NeonTheme.dark);
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00777E),
      brightness: Brightness.light,
    );
    return _build(scheme, NeonTheme.light);
  }

  static ThemeData _build(ColorScheme scheme, NeonTheme neon) {
    final text = _textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: AppTheme._sans,
      textTheme: text,
      extensions: [neon],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neon.panelBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: neon.panelBorder, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer.withValues(alpha: 0.92),
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? neon.accent
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? neon.accent
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: neon.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: neon.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: neon.accent, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        modalBackgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: neon.panelBorder,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.labelSmall,
        iconColor: neon.accent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neon.panelBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Color.alphaBlend(
            neon.accent.withValues(alpha: 0.12), scheme.surfaceContainerHigh),
        contentTextStyle: text.bodyMedium?.copyWith(color: neon.accent),
        actionTextColor: neon.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: neon.accent.withValues(alpha: 0.5)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: neon.accentBright,
        foregroundColor: AppColors.onAccentContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: neon.accentBright,
          foregroundColor: AppColors.onAccentContainer,
          textStyle: text.titleMedium,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
