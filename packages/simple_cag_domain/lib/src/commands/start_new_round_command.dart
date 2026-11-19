import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/clear_field.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/prompts.dart";
import "package:simple_cag_domain/src/features/refill_hand.dart";
import "package:simple_cag_domain/src/features/select_next_judge.dart";

class StartNewRoundCommand() extends CagCommand {
  @override
  TaskEither<ApplicationError, CagGame> apply(CagGame state, CagAuthPrincipal principal) => .Do(($) async {
    final refilledHands = await $(state.refillHand().toEsynchoreTask());

    // This is also done at the moment of voting, but this command can be done from any round
    final clearedField = refilledHands.clearField();

    final selectedJudge = clearedField.selectNextJudge();

    final revealedPrompt = await $(selectedJudge.revealPrompt().toEsynchoreTask());

    return revealedPrompt.copyWith(
      stage: .playCards,
    );
  });

  @override
  TaskEither<AuthorizationError, Unit> authorize(CagGame state, CagAuthPrincipal principal) => .Do(($) async {
    // anyone but players should be able to progress the round
    if (principal.role != .player) return unit;

    // Players cannot start a new round unless the previous one finished
    if (state.stage != .endOfRound) await $(guard(.operationNotAllowed));

    // only a judge can progress the round as a player
    if (state.currentJudge case Some(value: final judge) when judge != principal.playerIdentifier) {
      await $(guard(.operationNotAllowed));
    }

    return unit;
  });

  @override
  String get type => CagCommands.startNewRound.commandType;

  static Serializer<CagCommand> get serializer => emptySerializer(StartNewRoundCommand.new);
}
