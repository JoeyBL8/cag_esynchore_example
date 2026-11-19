import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";

class const ServerManager({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const .all(20),
      padding: const .all(8),
      decoration: BoxDecoration(
        border: .all(
          width: 2,
          color: theme.colorScheme.onSecondary,
        ),
        color: theme.colorScheme.secondary,
      ),
      child: const Text("Server configuration is not available"),
    );
  }
}
