import 'package:material_ui/material_ui.dart';

/// "Broadcast control room" palette: petrol-teal surfaces with a single
/// amber tally accent. Red is reserved for the live badge.
abstract final class SlayerColors {
  static const canvas = Color(0xFF0F1E22);
  static const surface = Color(0xFF16292E);
  static const raised = Color(0xFF1F363C);
  static const border = Color(0xFF223D44);
  static const tally = Color(0xFFF2B544);
  static const onTally = Color(0xFF1A1405);
  static const live = Color(0xFFE5484D);
  static const text = Color(0xFFE8EEEC);
  static const muted = Color(0xFF8FA5A3);
}

/// Variable fonts need an explicit weight axis.
TextStyle _font(String family, double size, FontWeight weight, {double? height, double? spacing}) =>
    TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
    );

const tabular = [FontFeature.tabularFigures()];

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: SlayerColors.tally,
    onPrimary: SlayerColors.onTally,
    secondary: SlayerColors.tally,
    onSecondary: SlayerColors.onTally,
    error: SlayerColors.live,
    surface: SlayerColors.canvas,
    onSurface: SlayerColors.text,
    onSurfaceVariant: SlayerColors.muted,
    surfaceContainerLowest: SlayerColors.canvas,
    surfaceContainerLow: SlayerColors.surface,
    surfaceContainer: SlayerColors.surface,
    surfaceContainerHigh: SlayerColors.raised,
    surfaceContainerHighest: SlayerColors.raised,
    outline: SlayerColors.border,
    outlineVariant: SlayerColors.border,
  );

  final text = TextTheme(
    headlineLarge: _font('Figtree', 30, FontWeight.w700, height: 1.15, spacing: -0.4),
    headlineMedium: _font('Figtree', 24, FontWeight.w700, height: 1.2, spacing: -0.2),
    headlineSmall: _font('Figtree', 20, FontWeight.w600, height: 1.25),
    titleLarge: _font('Figtree', 18, FontWeight.w600, height: 1.3),
    titleMedium: _font('Figtree', 16, FontWeight.w600, height: 1.35),
    titleSmall: _font('Figtree', 14, FontWeight.w600, height: 1.35),
    bodyLarge: _font('Figtree', 15, FontWeight.w400, height: 1.5),
    bodyMedium: _font('Figtree', 14, FontWeight.w400, height: 1.45),
    bodySmall: _font('Figtree', 12.5, FontWeight.w400, height: 1.4),
    labelLarge: _font('Figtree', 14, FontWeight.w600),
    labelMedium: _font('Figtree', 13, FontWeight.w500),
    labelSmall: _font('Figtree', 11.5, FontWeight.w500),
  ).apply(bodyColor: SlayerColors.text, displayColor: SlayerColors.text);

  final radius = BorderRadius.circular(8);
  const side = BorderSide(color: SlayerColors.border);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: SlayerColors.canvas,
    fontFamily: 'Figtree',
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: SlayerColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.headlineSmall,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SlayerColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: SlayerColors.tally.withValues(alpha: 0.16),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected) ? SlayerColors.tally : SlayerColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? SlayerColors.tally : SlayerColors.muted,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: SlayerColors.surface,
      indicatorColor: SlayerColors.tally.withValues(alpha: 0.16),
      selectedIconTheme: const IconThemeData(color: SlayerColors.tally),
      unselectedIconTheme: const IconThemeData(color: SlayerColors.muted),
      selectedLabelTextStyle: text.labelSmall!.copyWith(color: SlayerColors.tally),
      unselectedLabelTextStyle: text.labelSmall!.copyWith(color: SlayerColors.muted),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: SlayerColors.surface,
      selectedColor: SlayerColors.tally,
      side: side,
      shape: const StadiumBorder(side: side),
      labelStyle: text.labelMedium!.copyWith(color: SlayerColors.text),
      secondaryLabelStyle: text.labelMedium!.copyWith(color: SlayerColors.onTally),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SlayerColors.surface,
      hintStyle: text.bodyMedium!.copyWith(color: SlayerColors.muted),
      labelStyle: text.bodyMedium!.copyWith(color: SlayerColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: SlayerColors.tally, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: SlayerColors.live),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SlayerColors.tally,
        foregroundColor: SlayerColors.onTally,
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SlayerColors.text,
        backgroundColor: SlayerColors.raised,
        side: side,
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: SlayerColors.tally, textStyle: text.labelLarge),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: SlayerColors.surface,
        foregroundColor: SlayerColors.muted,
        selectedBackgroundColor: SlayerColors.raised,
        selectedForegroundColor: SlayerColors.tally,
        side: side,
        textStyle: text.labelMedium,
      ),
    ),
    cardTheme: CardThemeData(
      color: SlayerColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: radius, side: side),
    ),
    dividerTheme: const DividerThemeData(color: SlayerColors.border, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: SlayerColors.muted,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodySmall!.copyWith(color: SlayerColors.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SlayerColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: SlayerColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: side),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SlayerColors.raised,
      contentTextStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: radius, side: side),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: SlayerColors.tally,
      linearTrackColor: SlayerColors.border,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? SlayerColors.onTally : SlayerColors.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? SlayerColors.tally : SlayerColors.raised),
    ),
  );
}
