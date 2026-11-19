import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:meta/meta.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

export "join_game_command.dart";
export "play_cards_command.dart";
export "progress_to_voting_command.dart";
export "serializer.dart";
export "start_new_round_command.dart";
export "vote_pick_command.dart";

enum CagCommands(final String commandType) {
  joinGame("cag_join_game"),
  playCards("play_cards"),
  votePick("pick_votes"),
  startNewRound("start_new_round"),
  progressToVoting("progress_to_voting"),
}

extension CagCommandError on CagCommand {
  @useResult
  TaskEither<AuthorizationError, Unit> guard(CagEsynchoreErrorCodes<AuthorizationError> errorCode) =>
      .left(errorCode.getError());
}
