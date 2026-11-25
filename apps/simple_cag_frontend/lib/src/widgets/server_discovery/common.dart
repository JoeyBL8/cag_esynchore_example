import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class JoinGameAction({
  required final String gameId,
  required final Uri host,
});

class const GameListWidget({
  required final Uri address,
  required final ValueChanged<CagGameListing> onJoinGame,
  required final Future<void> Function() onCreateGame,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiService = useMemoized(
      () => CagApiService.unsecure(
        baseUrl: Uri(
          scheme: "https",
          port: address.port,
          host: address.host,
        ),
      ),
      [address],
    );

    final refreshIndicator = useState(0);

    final gamesFuture = useMemoized(apiService.getGames().run, [apiService, refreshIndicator.value]);

    final gamesSnapshot = useFuture(gamesFuture, preserveState: true);

    useEffect(
      () => Timer.periodic(const Duration(seconds: 10), (timer) {
        refreshIndicator.value++;
      }).cancel,
      [apiService],
    );

    final urlAsString = apiService.baseUrl.toString();

    final data = gamesSnapshot.data;
    if (data == null) {
      return ExpansionTile(
        title: Text(urlAsString),
        subtitle: const Text("loading"),
      );
    }

    return switch (data) {
      Left() => ListTile(
        title: Text("$urlAsString: Not a valid or reachable Game server"),
      ),
      Right(:final value) => ExpansionTile(
        title: Text(urlAsString),
        subtitle: Text("${value.games.length} games found"),
        collapsedBackgroundColor: theme.colorScheme.secondary,
        iconColor: theme.colorScheme.onPrimary,
        maintainState: true,
        childrenPadding: const .all(12),
        children: [
          FilledButton(
            onPressed: () async {
              await onCreateGame();
              refreshIndicator.value++;
            },
            child: const Text("Create temp game"),
          ),
          if (value.games.isEmpty) ...[
            const Text("No games active on this server"),
          ] else
            for (final game in value.games) ...[
              ListTile(
                title: Text(game.id),
                subtitle: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text("Players: ${game.players}"),
                    Text("Sets: ${game.sets.join(", ")}"),
                  ],
                ),
                leading: FilledButton.icon(
                  onPressed: () {
                    onJoinGame(game);
                  },
                  icon: const Icon(Icons.gamepad),
                  label: const Text("Join"),
                ),
              ),
            ],
        ],
      ),
    };
  }
}
