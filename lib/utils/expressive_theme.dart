import 'package:flutter/material.dart';

/// Miuix-inspired Flutter styling. Keeps the existing theme preferences.
ThemeData applyExpressiveTheme(ThemeData theme) {
  final dark = theme.brightness == Brightness.dark;
  final background = dark ? Colors.black : const Color(0xfff5f5f5);
  final panel = dark ? const Color(0xff222222) : Colors.white;
  final colors = theme.colorScheme.copyWith(
    surface: background,
    onSurface: dark ? const Color(0xffeeeeee) : const Color(0xff191919),
    onSurfaceVariant: dark ? const Color(0xff999999) : const Color(0xff777777),
    surfaceContainerLow: panel,
    surfaceContainer: panel,
    surfaceContainerHigh:
        dark ? const Color(0xff303030) : const Color(0xffeeeeee),
    surfaceContainerHighest:
        dark ? const Color(0xff2a2a2a) : const Color(0xffe9e9e9),
    secondaryContainer:
        dark ? const Color(0xff303030) : const Color(0xffeeeeee),
    onSecondaryContainer:
        dark ? const Color(0xffeeeeee) : const Color(0xff191919),
    outlineVariant: dark ? const Color(0xff333333) : const Color(0xffe8e8e8),
  );
  final roundedPanel = ContinuousRectangleBorder(
    borderRadius: BorderRadius.circular(40),
  );
  final buttonStyle = ButtonStyle(
    shape: WidgetStatePropertyAll(
        ContinuousRectangleBorder(borderRadius: BorderRadius.circular(32))),
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
      titleTextStyle: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 17, fontWeight: FontWeight.w400, color: colors.onSurface),
      subtitleTextStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13, height: 1.45, color: colors.onSurfaceVariant),
    ),
    dividerTheme: DividerThemeData(
        color: colors.outlineVariant.withOpacity(.35),
        thickness: 0.5,
        space: 1),
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
      bodyLarge:
          theme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium:
          theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      headlineSmall: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w400,
      ),
      titleLarge: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
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
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      dataRowColor: WidgetStatePropertyAll(colors.surfaceContainerLow),
      headingTextStyle: theme.textTheme.bodyMedium
          ?.copyWith(fontSize: 13, color: colors.onSurfaceVariant),
      dataTextStyle: theme.textTheme.bodyMedium
          ?.copyWith(fontSize: 14, color: colors.onSurface),
      columnSpacing: 24,
      horizontalMargin: 20,
      dividerThickness: .4,
      dataRowMinHeight: 52,
      dataRowMaxHeight: 84,
    ),
    popupMenuTheme: PopupMenuThemeData(
        color: panel,
        elevation: 3,
        shape: roundedPanel,
        textStyle: TextStyle(fontSize: 15, color: colors.onSurface)),
    chipTheme: theme.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide.none,
      backgroundColor: colors.surfaceContainerLow,
      selectedColor: colors.primary.withOpacity(.14),
      labelStyle: TextStyle(fontSize: 13, color: colors.onSurface),
    ),
    tabBarTheme: TabBarTheme(
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16)),
        dividerColor: Colors.transparent),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: buttonStyle.copyWith(
            elevation: const WidgetStatePropertyAll(0),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(
        style: buttonStyle.copyWith(
      foregroundColor: WidgetStatePropertyAll(colors.onSurface),
    )),
    drawerTheme: DrawerThemeData(backgroundColor: panel, shape: roundedPanel),
    navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: panel,
        indicatorColor: colors.surfaceContainerHigh,
        indicatorShape: const StadiumBorder()),
    navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.surfaceContainerHigh,
        selectedIconTheme: IconThemeData(color: colors.onSurface),
        unselectedIconTheme: IconThemeData(color: colors.onSurfaceVariant)),
    dialogTheme: DialogTheme(
      backgroundColor: panel,
      shape: roundedPanel,
      titleTextStyle: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w500, color: colors.onSurface),
      contentTextStyle:
          TextStyle(fontSize: 15, height: 1.5, color: colors.onSurfaceVariant),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: panel,
      shape: roundedPanel,
      headerBackgroundColor: panel,
      headerForegroundColor: colors.onSurface,
      headerHeadlineStyle:
          const TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
      dividerColor: Colors.transparent,
    ),
    timePickerTheme: TimePickerThemeData(
        backgroundColor: panel,
        shape: roundedPanel,
        dialBackgroundColor: colors.surfaceContainerHigh,
        hourMinuteColor: colors.surfaceContainerHigh),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: TextStyle(fontSize: 15, color: colors.onSurface),
      menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(panel),
          shape: WidgetStatePropertyAll(roundedPanel)),
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
