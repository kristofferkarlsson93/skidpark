// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Din 8px border-radius
  static const double _borderRadius = 8.0;

  static final ColorScheme _darkColorScheme = ColorScheme.dark(
    // Accent Colors
    primary: const Color(0xFFBB86FC),
    // 'primary'
    onPrimary: const Color(0xFF000000),
    // 'primary-foreground'
    secondary: const Color(0xFF03DAC6),
    // 'accent'
    onSecondary: const Color(0xFF000000),
    // 'accent-foreground'

    // Status Colors
    error: const Color(0xFFCF6679),
    onError: const Color(0xFF000000),
    surface: const Color(0xFF121212),
    // 'card'
    onSurface: const Color(0xFFFFFFFF),
    // Borders & Inputs
    outline: const Color(0xFF2C2C2C),
    surfaceContainer: const Color(0xFF1E1E1E),

    surfaceContainerHighest: const Color(0xFF2C2C2C),

    onSurfaceVariant: const Color(0xFFB3B3B3),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    textTheme: ThemeData.dark().textTheme
        .apply(
          bodyColor: _darkColorScheme.onSurface, // #FFFFFF
          displayColor: _darkColorScheme.onSurface, // #FFFFFF
        )
        .copyWith(
          labelSmall: TextStyle(color: _darkColorScheme.onSurfaceVariant),
          // #B3B3B3
          bodySmall: TextStyle(
            color: _darkColorScheme.onSurfaceVariant,
          ), // #B3B3B3
        ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      color: _darkColorScheme.surfaceContainer,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkColorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide.none, // Ingen border som standard
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: _darkColorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: BorderSide(color: _darkColorScheme.primary, width: 2),
      ),
      labelStyle: TextStyle(
        color: _darkColorScheme.onSurfaceVariant, // 'muted-foreground'
      ),
    ),

    // popups/dropdowns
    popupMenuTheme: PopupMenuThemeData(
      color: _darkColorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkColorScheme.surfaceContainer, // #1E1E1E
      // 2. remove background circle from active element
      indicatorColor: Colors.transparent,

      // 3. icon theme
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          // active icon get primary
          return IconThemeData(color: _darkColorScheme.primary); // #BB86FC
        }
        // inactive icon fall back to standard
        return null;
      }),

      // Text theme
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          // Aktiv text: Sätt till 'primary' (lila)
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _darkColorScheme.primary,
          );
        }
        return null;
      }),
    ),
  );
}
