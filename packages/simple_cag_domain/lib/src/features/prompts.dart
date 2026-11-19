import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

extension HandlePrompts on CagGame {
  static const promptAlreadyRevealedFailure = SimpleCagFailure(
    errorMessage: "You cannot reveal a prompt if another is still on the field",
  );
  static const noPromptToDiscardFailure = SimpleCagFailure(
    errorMessage: "You cannot discard a prompt if none is availabel on the field",
  );
  static const promptDeckEmptyFailure = SimpleCagFailure(
    errorMessage: "You cannot reveal a prompt if the deck is empty",
  );

  Either<SimpleCagFailure, CagGame> revealPrompt() => .Do(($) {
    if (currentPrompt is Some) $(const Failure(promptAlreadyRevealedFailure));

    final (game, prompt) = $(takeFromPile());
    return game.copyWith(currentPrompt: Some(prompt.copyWith(visible: true)));
  });

  Either<SimpleCagFailure, (CagGame, CagPromptCard)> takeFromPile() => .Do(($) {
    if (promptCardDeck.isEmpty) $(const Failure(promptDeckEmptyFailure));
    final [card, ...remaining] = promptCardDeck;

    return (copyWith(promptCardDeck: remaining), card);
  });
}
