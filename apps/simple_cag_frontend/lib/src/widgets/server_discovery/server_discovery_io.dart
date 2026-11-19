import "dart:async";

import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:network_discovery/network_discovery.dart";
import "package:simple_cag_frontend/src/widgets/server_discovery/common.dart";

TaskEither<String, List<NetworkAddress>> _discoverServers() => .Do(($) async {
  final address = await $(
    .fromNullable(await NetworkDiscovery.discoverDeviceIpAddress(), () => "Failed to retrieve local IP address"),
  );

  final subnet = address.substring(0, address.lastIndexOf("."));

  return NetworkDiscovery.discoverMultiplePorts(subnet, [
    43234,
  ]).fold(<NetworkAddress>[], (previous, data) => [...previous, data]);
});

class const ServerDiscovery({
  required final ValueChanged<JoinGameAction> onJoinGame,
  required final Future<void> Function(Uri host) onCreateGame,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final reloadAttempts = useState(1);

    final serverDiscovery = useMemoized(_discoverServers().run, [reloadAttempts.value]);

    final serverDiscoverySnapshot = useFuture(serverDiscovery, preserveState: false);

    return switch (serverDiscoverySnapshot) {
      AsyncSnapshot(data: Right(value: final data)) => _ServerList(
        onCreateGame: onCreateGame,
        addresses: data,
        onJoinGame: onJoinGame,
        refresh: () {
          reloadAttempts.value = reloadAttempts.value + 1;
        },
      ),
      AsyncSnapshot(data: Left(value: final error)) => Text(error),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class const _ServerList({
  required final List<NetworkAddress> addresses,
  required final VoidCallback refresh,
  required final ValueChanged<JoinGameAction> onJoinGame,
  required final Future<void> Function(Uri host) onCreateGame,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final refreshButton = FilledButton(onPressed: refresh, child: const Text("refresh"));
    if (addresses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: .min,
            spacing: 40,
            children: [const Text("Nothing found, refresh to find more"), refreshButton],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: addresses.length + 1,
      itemBuilder: (context, index) {
        if (index == addresses.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: refreshButton,
            ),
          );
        }
        final address = addresses[index];

        return GameListWidget(
          address: address.uri,
          onCreateGame: () => onCreateGame(address.uri),
          onJoinGame: (game) {
            onJoinGame(JoinGameAction(gameId: game.id, host: address.uri));
          },
        );
      },
    );
  }
}

extension on NetworkAddress {
  Uri get uri => Uri(
    scheme: "http",
    host: ip,
    port: openPorts.first,
  );
}
