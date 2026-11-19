import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/reveal_player_cards.dart";

class ProgressToVotingCommand() extends CagCommand {
  @override
  TaskEither<ApplicationError, CagGame> apply(CagGame state, CagAuthPrincipal principal) =>
      .Do(($) async => state.revealPlayerCards().copyWith(stage: .voteBestOption));

  @override
  TaskEither<AuthorizationError, Unit> authorize(CagGame state, CagAuthPrincipal principal) => .Do(($) async {
    if (state.stage != .playCards) await $(guard(.operationNotAllowed));
    // anyone but players should be able to progress the round
    if (principal.role != .player) return unit;
    // only a judge can progress the round as a player
    if (state.currentJudge case Some(value: final judge) when judge != principal.playerIdentifier) {
      await $(guard(.operationNotAllowed));
    }

    return unit;
  });

  @override
  String get type => CagCommands.progressToVoting.commandType;

  static Serializer<CagCommand> get serializer => emptySerializer(ProgressToVotingCommand.new);
}
