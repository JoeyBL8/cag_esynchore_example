import "package:material_ui/material_ui.dart";

ThemeData getTheme() {
  final colorScheme = ColorScheme(
    brightness: .dark,
    primary: Colors.black,
    onPrimary: Colors.white,
    secondary: Colors.grey.shade800,
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onError: Colors.black,
    surface: Colors.grey.shade900,
    onSurface: Colors.white,
  );

  return ThemeData(
    fontFamily: "monospace",
    colorScheme: colorScheme,
    progressIndicatorTheme: .new(
      color: colorScheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const .all(8),
      fillColor: colorScheme.secondary,
      isDense: false,
      filled: true,
      border: .none,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        shape: const BeveledRectangleBorder(borderRadius: .all(.circular(4))),
        elevation: 2,
        shadowColor: colorScheme.secondary,
      ),
    ),
  );
}
