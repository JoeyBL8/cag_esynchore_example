import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/service/game_connection.dart";
import "package:simple_cag_frontend/src/widgets/show_error.dart";
import "package:stretch_wrap/stretch_wrap.dart";

class const GenericPlayerControls({
  required final CagCredentials credentials,
  required final CagGameConnected connectedState,
  required final CagGame gameState,
  required final CagPlayer player,
  required final List<CagIdentifier> selectedCards,
  super.key,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final commands = <_GenericCommand>[
      .new(label: "Start round", command: StartNewRoundCommand()),
      .new(label: "Reveal cards", command: ProgressToVotingCommand()),
      .new(
        label: "Play cards",
        command: PlayCardsCommand(playerIdentifier: player.id, cardsToPlay: selectedCards),
      ),
    ];

    final principal = CagAuthPrincipal(
      playerIdentifier: player.id,
      role: player.role,
      key: "",
      sessionId: "",
    );

    final validatedCommandsFuture = useMemoized(
      () => Future.wait(
        commands.map(
          (command) async => (
            command,
            await command.canBeExecuted(gameState, principal).run(),
            await command.canBeExecutedWithoutAdmin(gameState, principal).run(),
          ),
        ),
      ),
      [...selectedCards, gameState, 1],
    );

    final future = useFuture(validatedCommandsFuture);

    final verifiedCommands = switch (future) {
      AsyncSnapshot(:final data?) => data,
      _ => <(_GenericCommand, bool, bool)>[],
    };

    final isBusy = useState(false);

    Future<void> applyCommand(CagCommand command) async {
      if (isBusy.value) return;
      isBusy.value = true;
      try {
        final result = await connectedState.sendCommand(command);
        if (result case Left(value: final error) when context.mounted) {
          context.showError("Code: ${error.code}. ${error.message}");
        }
      } finally {
        if (context.mounted) {
          isBusy.value = false;
        }
      }
    }

    final adminCommands = verifiedCommands.where((command) => command.isAdminCommand).map((command) => command.command);
    final playerCommands = verifiedCommands
        .where((command) => command.isValid && !command.isAdminCommand)
        .map((command) => command.command);

    final playerCommandList = StretchWrap(
      runSpacing: 8,
      children: [
        ...playerCommands.map(
          (command) => GenericPlayerControl(
            name: command.label,
            onPressed: isBusy.value
                ? null
                : () async {
                    await applyCommand(command.command);
                  },
          ),
        ),
        if (playerCommands.isEmpty) ...[
          const Text("Nothing for you to do"),
        ],
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
      ),
      padding: const .all(12),
      child: Row(
        children: [
          Expanded(
            child: playerCommandList,
          ),
          if (adminCommands.isNotEmpty) ...[
            PopupMenuButton(
              tooltip: "Admin Commands",
              itemBuilder: (context) => adminCommands
                  .map(
                    (command) => PopupMenuItem(
                      onTap: isBusy.value
                          ? null
                          : () async {
                              await applyCommand(command.command);
                            },
                      child: Text(command.label),
                    ),
                  )
                  .toList(),
              child: const Icon(Icons.more_vert),
            ),
          ],
        ],
      ),
    );
  }
}

class const GenericPlayerControl({
  required final String name,
  required final VoidCallback? onPressed,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stretch(
    child: Container(
      padding: const .symmetric(horizontal: 8),
      decoration: const BoxDecoration(),
      child: FilledButton(onPressed: onPressed, child: Text(name)),
    ),
  );
}

extension on (_GenericCommand, bool, bool) {
  bool get isValid => $2;
  bool get isAdminCommand => $2 && !$3;
  _GenericCommand get command => $1;
}

class _GenericCommand({
  required final String label,
  required final CagCommand command,
}) {
  Task<bool> canBeExecuted(CagGame state, CagAuthPrincipal principal) =>
      command.authorize(state, principal).map((_) => true).getOrElse((l) => false);

  Task<bool> canBeExecutedWithoutAdmin(CagGame state, CagAuthPrincipal principal) => command
      .authorize(
        state,
        CagAuthPrincipal(
          playerIdentifier: principal.playerIdentifier,
          role: .player,
          key: principal.key,
          sessionId: principal.sessionId,
        ),
      )
      .map((_) => true)
      .getOrElse((_) => false);
}
