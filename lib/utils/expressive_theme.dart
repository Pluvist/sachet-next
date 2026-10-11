import 'package:flutter/material.dart';

/// Miuix-inspired Flutter styling. Keeps the existing theme preferences.
ThemeData applyExpressiveTheme(ThemeData theme) {
  if (!theme.useMaterial3) return theme;

  final dark = theme.brightness == Brightness.dark;
  final background = dark ? const Color(0xff101010) : const Color(0xfff5f5f5);
  final panel = dark ? const Color(0xff202020) : Colors.white;
  final colors = theme.colorScheme.copyWith(
    surface: background,
    onSurface: dark ? const Color(0xffeeeeee) : const Color(0xff191919),
    onSurfaceVariant: dark ? const Color(0xff999999) : const Color(0xff777777),
    surfaceContainerLow: panel,
    surfaceContainer: panel,
    surfaceContainerHigh:
        dark ? const Color(0xff292929) : const Color(0xffeeeeee),
    outlineVariant: dark ? const Color(0xff333333) : const Color(0xffe8e8e8),
  );
  final roundedPanel = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  final buttonStyle = ButtonStyle(
    shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    textStyle: WidgetStatePropertyAll(
      theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  return theme.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    splashFactory: NoSplash.splashFactory,
    highlightColor: colors.onSurface.withOpacity(0.05),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      minVerticalPadding: 12,
      iconColor: colors.onSurfaceVariant,
      textColor: colors.onSurface,
      titleTextStyle: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w500, color: colors.onSurface),
      subtitleTextStyle:
          TextStyle(fontSize: 13, height: 1.4, color: colors.onSurfaceVariant),
    ),
    dividerTheme: DividerThemeData(
        color: colors.outlineVariant, thickness: 0.5, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surfaceContainerHigh),
    ),
    textTheme: theme.textTheme.copyWith(
      headlineSmall: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: theme.appBarTheme.copyWith(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardTheme(
      color: colors.surfaceContainerLow,
      elevation: 0,
      shape: roundedPanel,
    ),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
    dialogTheme: DialogTheme(
      backgroundColor: panel,
      shape: roundedPanel,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceContainerLow,
      modalBackgroundColor: colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surfaceContainerHigh,
      indicatorColor: colors.primaryContainer,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onPrimaryContainer
                : colors.onSurfaceVariant,
            size: 24,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          )),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
