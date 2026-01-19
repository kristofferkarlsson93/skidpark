import 'package:flutter/material.dart';

class AppTheme {
  static const double _borderRadius = 8.0;

  static final ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF8B7CF6),
    onPrimary: Color(0xFF0E0A2B),

    primaryContainer: Color(0xFF2A245E),
    onPrimaryContainer: Color(0xFFE6E1FF),

    secondary: Color(0xFF6FD6C2),
    onSecondary: Color(0xFF06201A),

    secondaryContainer: Color(0xFF1F3A36),
    onSecondaryContainer: Color(0xFFB8EFE6),

    error: Color(0xFFFF6B6B),
    onError: Color(0xFF2B0B0B),

    surface: Color(0xFF101014),
    onSurface: Color(0xFFE6E6EB),

    surfaceContainerLowest: Color(0xFF0C0C10),
    surfaceContainerLow: Color(0xFF18181F),
    surfaceContainer: Color(0xFF1F1F2A),
    surfaceContainerHigh: Color(0xFF262635),
    surfaceContainerHighest: Color(0xFF2E2E42),

    outline: Color(0xFF343447),
    outlineVariant: Color(0xFF45455E),
    onSurfaceVariant: Color(0xFFB0B0C3),
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
      elevation: 0,
      color: _darkColorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _darkColorScheme.outlineVariant.withAlpha((0.3 * 255).toInt()),
          width: 1,
        ),
      ),
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
