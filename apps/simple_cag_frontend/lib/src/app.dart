import "dart:ui";

import "package:material_ui/material_ui.dart";
import "package:simple_cag_frontend/src/screens/cag_screen.dart";
import "package:simple_cag_frontend/src/theme.dart";

class const CagApp({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    scrollBehavior: _CagScrollBehaviour(),
    theme: getTheme(),
    home: const CagScreen(),
  );
}

class _CagScrollBehaviour extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
