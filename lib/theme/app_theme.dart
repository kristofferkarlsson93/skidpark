import 'package:flutter/material.dart';

class AppTheme {
  static const double _controlRadius = 14;

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF9281FF),
    onPrimary: Color(0xFF151123),
    primaryContainer: Color(0xFF302958),
    onPrimaryContainer: Color(0xFFF0ECFF),
    secondary: Color(0xFF70DDC5),
    onSecondary: Color(0xFF0A211D),
    secondaryContainer: Color(0xFF173A34),
    onSecondaryContainer: Color(0xFFC2FFF2),
    error: Color(0xFFFF909C),
    onError: Color(0xFF340A10),
    surface: Color(0xFF101116),
    onSurface: Color(0xFFF7F5FF),
    surfaceContainerLowest: Color(0xFF0B0C11),
    surfaceContainerLow: Color(0xFF191A22),
    surfaceContainer: Color(0xFF20212C),
    surfaceContainerHigh: Color(0xFF262735),
    surfaceContainerHighest: Color(0xFF2D2E3D),
    outline: Color(0xFF4A4C5C),
    outlineVariant: Color(0xFF343642),
    onSurfaceVariant: Color(0xFFB2B0C0),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackgroundColor: _darkColorScheme.surface,
    textTheme: ThemeData.dark(useMaterial3: true).textTheme
        .apply(
          bodyColor: _darkColorScheme.onSurface,
          displayColor: _darkColorScheme.onSurface,
        )
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 24,
            height: 1.17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: const TextStyle(fontSize: 15, height: 1.42),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          labelSmall: TextStyle(
            color: _darkColorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          bodySmall: TextStyle(
            color: _darkColorScheme.onSurfaceVariant,
            fontSize: 13,
            height: 1.35,
          ),
        ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF7F5FF),
      toolbarHeight: 64,
      titleSpacing: 16,
      titleTextStyle: TextStyle(
        color: Color(0xFFF7F5FF),
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: Color(0xFF191A22),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFF343642)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: Color(0xFF4A4C5C)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      backgroundColor: Color(0xFF9281FF),
      foregroundColor: Color(0xFF151123),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkColorScheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: _darkColorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: _darkColorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(color: _darkColorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: _darkColorScheme.onSurfaceVariant),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _darkColorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_controlRadius),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      elevation: 0,
      backgroundColor: _darkColorScheme.surfaceContainerLow,
      indicatorColor: _darkColorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final color = states.contains(WidgetState.selected)
            ? _darkColorScheme.primary
            : _darkColorScheme.onSurfaceVariant;
        return IconThemeData(color: color);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected
              ? _darkColorScheme.primary
              : _darkColorScheme.onSurfaceVariant,
        );
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF343642),
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF2D2E3D),
      contentTextStyle: TextStyle(color: Color(0xFFF7F5FF)),
    ),
  );
}
