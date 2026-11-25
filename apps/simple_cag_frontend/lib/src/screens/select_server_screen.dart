import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/screens/screen_state.dart";
import "package:simple_cag_frontend/src/widgets/cag_text_field.dart";
import "package:simple_cag_frontend/src/widgets/server_discovery.dart";
import "package:simple_cag_frontend/src/widgets/server_manage.dart";
import "package:simple_cag_frontend/src/widgets/show_error.dart";

class const SelectServerScreen({
  required final SelectServerCagScreenState state,
  required final ValueChanged<CagScreenState> onStateChanged,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future<void> logout() async {
      onStateChanged(await state.logout().run());
    }

    Future<void> onJoinGame(JoinGameAction action) async {
      final result = await state.join(action.host, action.gameId).run();

      switch (result) {
        case Right(value: final state):
          onStateChanged(state);
        case Left(value: final error):
          if (context.mounted) {
            context.showError(error);
          }
      }
    }

    Future<void> onCreateGame(Uri host) async {
      final sets = await _CreateGameDialog.selectSets(context, host);
      if (sets == null || sets.isEmpty) {
        if (context.mounted) {
          context.showError("You need to select at least 1 set before starting a game");
        }
        return;
      }

      final result = await state.createGame(host, sets).run();

      switch (result) {
        case Right(value: final state):
          onStateChanged(state);
        case Left(value: final error):
          if (context.mounted) {
            context.showError(error);
          }
      }
    }

    return Stack(
      children: [
        Column(
          spacing: 20,
          children: [
            const SizedBox(height: 64),
            const Center(
              child: Text(
                "Join the game",
                style: .new(fontSize: 40),
                textAlign: .center,
              ),
            ),
            const ServerManager(),
            Expanded(
              child: ServerDiscovery(
                onCreateGame: onCreateGame,
                onJoinGame: onJoinGame,
              ),
            ),
          ],
        ),
        Align(
          alignment: .topLeft,
          child: Padding(
            padding: const .all(12),
            child: FilledButton.icon(
              onPressed: logout,
              label: const Text("Logout"),
              icon: const Icon(Icons.logout),
            ),
          ),
        ),
      ],
    );
  }
}

class const _CreateGameDialog(final Uri host) extends HookWidget {
  static Future<List<String>?> selectSets(BuildContext context, Uri host) async => showDialog<List<String>>(
    context: context,
    builder: (context) => _CreateGameDialog(host),
  );

  @override
  Widget build(BuildContext context) {
    final apiService = useMemoized(() => CagApiService.unsecure(baseUrl: host), [host]);

    final setsFuture = useMemoized(apiService.getSets().run, [apiService]);

    final setsSnapshot = useFuture(setsFuture);

    final sets = switch (setsSnapshot) {
      AsyncSnapshot(data: Right(value: final sets)) => sets,
      _ => <String>[],
    };

    final controller = useTextEditingController();

    final filter = useState("");

    final filterExpression = RegExp(".*${filter.value.split("").join(".*")}.*");

    final selectedSets = useState(<String>[]);

    final theme = Theme.of(context);

    return Center(
      child: Dialog(
        child: Column(
          mainAxisSize: .min,
          spacing: 20,
          children: [
            Stack(
              children: [
                Container(
                  color: theme.colorScheme.primary,
                  padding: const .all(20),
                  alignment: .center,
                  child: Text("Select sets (${selectedSets.value.length} sets selected)"),
                ),
                Positioned(
                  top: 8,
                  right: 0,
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            if (sets.isEmpty && setsSnapshot.connectionState == .waiting) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (sets.isEmpty) ...[
              const Text("This server has no sets available for you to play"),
            ] else ...[
              CagInputField(
                controller: controller,
                icon: Icons.search,
                onSubmit: () {
                  filter.value = controller.text;
                },
              ),
              SizedBox(
                height: 400,
                child: ListView(
                  children: [
                    for (final set in sets.where(filterExpression.hasMatch)) ...[
                      CheckboxListTile(
                        title: Text(set),
                        subtitle: const Text("Tap to select this set"),
                        value: selectedSets.value.contains(set),
                        onChanged: (value) {
                          if (value ?? false) {
                            selectedSets.value = [
                              ...selectedSets.value,
                              set,
                            ];
                          } else {
                            selectedSets.value = List.from(selectedSets.value)..remove(set);
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: .center,
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(selectedSets.value);
                    },
                    child: const Text("Create game"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
