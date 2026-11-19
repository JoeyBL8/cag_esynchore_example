import "package:material_ui/material_ui.dart";

extension ShowError on BuildContext {
  void showError(String message) {
    final messenger = ScaffoldMessenger.of(this);
    final theme = Theme.of(this);

    messenger.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(
          color: theme.colorScheme.error,
        ),),
        backgroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
