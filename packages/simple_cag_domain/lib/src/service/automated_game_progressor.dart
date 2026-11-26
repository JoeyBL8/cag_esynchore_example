import "dart:async";

import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class AutomatedGameProgressor({
  required final CagCredentials systemCredentials,
  required final Task<Unit> Function(String id) onRemove,
}) {
  final _taskManager = _TaskManager();

  void onCommandApplied(CagCommand command, CagGame game, CagHandler handler) {
    switch (command) {
      case PlayCardsCommand():
        continueToVotingWhenAllPlayersVoted(game, handler);
      case final UpdatePlayerConnectionStatusCommand command:
        unawaited(handleStalePlayers(command, game, handler));
    }
  }

  static const _idleTimeout = Duration(seconds: 10);

  Future<void> handleStalePlayers(UpdatePlayerConnectionStatusCommand command, CagGame game, CagHandler handler) async {
    if (command.status == .disconnected) {
      final timer = Timer(_idleTimeout, () async {
        await handler
            .submit(
              UpdatePlayerConnectionStatusCommand(playerIdentifier: command.playerIdentifier, status: .stale),
              .of(systemCredentials),
            )
            .run();
      });

      _taskManager.registerPlayerTask(
        game.id.id,
        command.playerIdentifier,
        .staleConnection,
        timer,
      );
    } else {
      _taskManager.cancelPlayerTask(game.id.id, command.playerIdentifier, .staleConnection);
    }

    if (command.status == .stale) {
      if (game.players.every((player) => !player.isInGame())) {
        await onRemove(game.id.id).run();
        return;
      }

      if (game.currentJudge case Some(value: final judge) when judge == command.playerIdentifier) {
        await handler
            .submit(
              StartNewRoundCommand(),
              .of(systemCredentials),
            )
            .run();
      }
    }
  }

  void continueToVotingWhenAllPlayersVoted(CagGame game, CagHandler handler) {
    if (game.players.every((player) => player.hasPlayedCards() || player.isJudge(game))) {
      unawaited(_submit(handler, ProgressToVotingCommand()).run());
    }
  }

  TaskEither<EsynchoreError, CagGame> _submit(CagHandler handler, CagCommand command) =>
      handler.submit(command, .right(systemCredentials));
}

typedef CagHandler = StateHandler<CagGame, Either<CagSerializationFailure, CagCredentials>, CagAuthPrincipal>;

extension on CagPlayer {
  bool hasPlayedCards() => played.isNotEmpty;

  bool isJudge(CagGame game) => game.currentJudge.map((id) => id == this.id).getOrElse(() => false);

  bool isInGame() => status == .active || status == .disconnected;
}

enum _PlayerTask { staleConnection }

class _TaskManager() {
  final Map<String, Map<CagIdentifier, Map<_PlayerTask, Timer>>> _playerConnectionTimers = {};

  void registerPlayerTask(String sessionId, CagIdentifier playerIdentifier, _PlayerTask task, Timer timer) {
    cancelPlayerTask(sessionId, playerIdentifier, task);
    _playerConnectionTimers
        .putIfAbsent(sessionId, () => {})
        .putIfAbsent(playerIdentifier, () => {})
        .putIfAbsent(task, () => timer);
  }

  void cancelPlayerTask(String sessionId, CagIdentifier playerIdentifier, _PlayerTask task) {
    _playerConnectionTimers[sessionId]?[playerIdentifier]?[task]?.cancel();
  }
}
