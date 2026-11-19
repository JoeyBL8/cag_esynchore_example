import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

extension PlayCards on CagGame {
  static const playCardsWithoutPromptFailure = SimpleCagFailure(
    errorMessage: "Cards can only be played if there is a current prompt",
  );

  static const playInequalAmountOfCardsThenPromptFailure = SimpleCagFailure(
    errorMessage: "Cards played should match the prompt",
  );

  static const playerNeedsEmptyFieldToPlay = SimpleCagFailure(errorMessage: "Player needs an empty field to play");

  static const playerNeedsToOwnCardsToPlay = SimpleCagFailure(
    errorMessage: "Player needs to have the cards in their hand to play them",
  );

  Either<SimpleCagFailure, CagGame> playCards(CagIdentifier playerToPlay, List<CagIdentifier> cardsToPlay) => .Do(($) {
    final prompt = $(.fromOption(currentPrompt, () => playCardsWithoutPromptFailure));

    $(
      .fromPredicate(unit, (_) => prompt.picks == cardsToPlay.length, (_) => playInequalAmountOfCardsThenPromptFailure),
    );

    return $(modifyPlayer(playerToPlay, (player) => $(player._playCards(cardsToPlay))));
  });
}

extension on CagPlayer {
  Either<SimpleCagFailure, CagPlayer> _playCards(List<CagIdentifier> cardsToPlay) => .Do(($) {
    if (played.isNotEmpty) $(const Failure(PlayCards.playerNeedsEmptyFieldToPlay));

    final cards = cardsToPlay.map(
      (identifier) => $(
        .fromOption(
          hand.where((card) => card.id == identifier).firstOption,
          () => PlayCards.playerNeedsToOwnCardsToPlay,
        ),
      ),
    );

    return copyWith(
      hand: hand.where((card) => !cardsToPlay.contains(card.id)).toList(),
      played: cards.toList(),
    );
  });
}
