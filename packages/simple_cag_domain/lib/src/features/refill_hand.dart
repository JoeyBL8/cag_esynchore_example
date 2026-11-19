import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

extension RefillHand on CagGame {
  static const handSize = 10;

  static const responseDeckEmptyFailure = SimpleCagFailure(
    errorMessage: "You cannot draw from the responsedeck if the deck is empty",
  );

  /// Refills the hands of all players using the response card deck
  ///
  /// Can also be used to fill the hand of every player at the start of the game
  Either<SimpleCagFailure, CagGame> refillHand() => .Do(
    ($) => players.fold(this, (game, player) {
      final hand = player.hand;
      final cardsToDraw = handSize - hand.length;

      if (cardsToDraw <= 0) return game;

      final (updatedPlayer, updatedGame) = repeatFold<(CagPlayer, CagGame)>(
        cardsToDraw,
        (player, game),
        (state) {
          final (player, game) = state;
          final (updatedGame, card) = $(game.takeFromPile());
          final updatedPlayer = player.addCard(card.copyWith(visible: true));
          return (updatedPlayer, updatedGame);
        },
      );

      return $(updatedGame.modifyPlayer(updatedPlayer.id, (player) => updatedPlayer));
    }),
  );

  Either<SimpleCagFailure, (CagGame, CagResponseCard)> takeFromPile() => .Do(($) {
    if (responseCardDeck.isEmpty) $(const Failure(responseDeckEmptyFailure));
    final [card, ...remaining] = responseCardDeck;

    return (copyWith(responseCardDeck: remaining), card);
  });
}

extension on CagPlayer {
  CagPlayer addCard(CagResponseCard card) => copyWith(
    hand: [...hand, card],
  );
}
