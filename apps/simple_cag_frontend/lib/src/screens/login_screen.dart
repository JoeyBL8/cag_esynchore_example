import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_frontend/main.dart";
import "package:simple_cag_frontend/src/screens/screen_state.dart";
import "package:simple_cag_frontend/src/widgets/cag_text_field.dart";

class const LoginScreen({
  required final InitialCagScreenState state,
  required final ValueChanged<CagScreenState> onStateChanged,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final keyController = useTextEditingController(text: globalPersistence.getKey());
    final nameController = useTextEditingController(text: globalPersistence.getName());

    final isLoading = useState(false);

    Future<void> login() async {
      if (isLoading.value) return;
      isLoading.value = true;
      try {
        final displayName = nameController.text;
        final key = keyController.text;

        final result = await state.login(key: key, playerName: displayName).run();

        switch (result) {
          case Right(:final value):
            onStateChanged(value);
          case Left(:final value):
            {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
            }
        }
      } finally {
        if (context.mounted) isLoading.value = false;
      }
    }

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 20,
      children: [
        const Spacer(),
        const Center(
          child: Text(
            "Join the game",
            style: .new(fontSize: 40),
          ),
        ),
        const SizedBox(height: 20),
        CagInputField(
          controller: nameController,
          hint: "Display name",
        ),
        CagInputField(
          controller: keyController,
          hint: "Unique key",
        ),
        Center(
          child: FilledButton(onPressed: isLoading.value ? null : login, child: const Text("Login")),
        ),
        const Spacer(
          flex: 3,
        ),
      ],
    );
  }
}
