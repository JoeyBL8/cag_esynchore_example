import "package:esynchore_core/esynchore_core.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/cag_game_state_view.dart";
import "package:simple_cag_frontend/src/screens/screen_state.dart";
import "package:simple_cag_frontend/src/service/game_connection.dart";

class const GameScreen({
  required final GameCagScreenState state,
  required final ValueChanged<CagScreenState> onStateChanged,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final connection = useCagGameConnection(state);

    return Stack(
      children: [
        GameConnectionView(
          connectionState: connection,
          credentials: state.credentials,
        ),
        Align(
          alignment: .topLeft,
          child: Padding(
            padding: const .all(12),
            child: FilledButton.icon(
              onPressed: () async => onStateChanged(await state.disconnect().run()),
              label: const Text("Disconnect"),
              icon: const Icon(Icons.signal_cellular_0_bar),
            ),
          ),
        ),
      ],
    );
  }
}

class const GameConnectionView({
  required final CagGameConnectionState connectionState,
  required final CagCredentials credentials,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (connectionState) {
    CagGameDisconnected() => const DisconnectedView(),
    CagGameConnecting() => const _ConnectingView(),
    CagGameConnected state => switch (state.gameState) {
      Right<String, CagGame>(value: final gameState) => CagGameStateView(
        credentials: credentials,
        connectedState: state,
        gameState: gameState,
      ),
      Left<String, CagGame>(:final value) => _ConnectionFailedView(
        error: EsynchoreConnectionFailure(
          message: ErrorMessage(category: .protocol, code: "state_loading_failed", message: value),
        ),
        connectionState: connectionState,
      ),
    },
    CagGameConnectionFailed(
      error: final error,
    ) =>
      _ConnectionFailedView(error: error, connectionState: connectionState),
  };
}

class const _ConnectingView() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: .min,
      spacing: 20,
      children: [
        Text(
          "Connecting...",
          style: .new(fontSize: 40, fontWeight: .w900),
        ),
        CircularProgressIndicator(),
      ],
    ),
  );
}

class const DisconnectedView({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: .min,
      spacing: 20,
      children: [
        Text(
          "Disconnected!",
          style: .new(fontSize: 40, fontWeight: .w900),
        ),
        Text("Press disconnect at the top and select a game to join"),
      ],
    ),
  );
}

class const _ConnectionFailedView({
  required final CagConnectionFailure error,
  required final CagGameConnectionState connectionState,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: .min,
      spacing: 20,
      children: [
        const Text(
          "Connection Failure!",
          style: .new(fontSize: 40, fontWeight: .w900),
        ),
        switch (error) {
          EsynchoreConnectionFailure(message: final details) => Text(
            "Category: ${details.category.name}\nErrorcode: ${details.code}\nErrormessage: ${details.message}",
          ),
          UnknownConnectionFailure() => const Text("Unknown error"),
        },
        const Text("Press disconnect at the top and select a different game to join"),
        const Text("or"),
        FilledButton(onPressed: connectionState.controller.reconnect, child: const Text("Reconnect")),
      ],
    ),
  );
}
