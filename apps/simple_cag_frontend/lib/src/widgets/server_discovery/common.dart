import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class JoinGameAction({
  required final String gameId,
  required final Uri host,
  required final bool spectate,
});

class const GameListWidget({
  required final Uri address,
  required final ValueChanged<CagGameListing> onJoinGame,
  required final ValueChanged<CagGameListing> onSpectateGame,
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
            child: const Text("Create game"),
          ),
          const SizedBox(height: 12),
          if (value.games.isEmpty) ...[
            const Text("No games active on this server"),
          ] else
            for (final game in value.games) ...[
              _GameTile(game: game, onJoinGame: onJoinGame, onSpectateGame: onSpectateGame),
            ],
        ],
      ),
    };
  }
}

class const _GameTile({
  required final CagGameListing game,
  required final ValueChanged<CagGameListing> onJoinGame,
  required final ValueChanged<CagGameListing> onSpectateGame,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => InkWell(
      onDoubleTap: () {
        onJoinGame(game);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: .start,
          spacing: 12,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                spacing: 4,
                crossAxisAlignment: .stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      onJoinGame(game);
                    },
                    icon: const Icon(Icons.gamepad),
                    label: const Text("Join"),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      onSpectateGame(game);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text("Spectate"),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: .start,
                crossAxisAlignment: .start,
                spacing: 8,
                children: [
                  Text(
                    "Players: ${game.players}",
                    style: const TextStyle(
                      fontWeight: .w900,
                    ),
                  ),
                  Text("Sets(${game.sets.length}): ${game.sets.take(3).join(", ")}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
