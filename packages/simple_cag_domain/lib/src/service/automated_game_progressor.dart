import "dart:async";

import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class AutomatedGameProgressor({
  required final CagCredentials systemCredentials,
}) {
  void onCommandApplied(CagCommand command, CagGame game, CagHandler handler) {
    switch (command) {
      case PlayCardsCommand():
        continueToVotingWhenAllPlayersVoted(game, handler);
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
}
