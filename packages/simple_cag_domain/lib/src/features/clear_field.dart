import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/features/copying.dart";

extension ClearField on CagGame {
  CagGame clearField() {
    final playerCards = players.expand((player) => player.played);

    return copyWith(
      playedResponseCards: [
        ...playedResponseCards,
        ...playerCards,
      ],
      currentPrompt: const None(),
      players: players.map((player) => player.copyWith(played: [])).toList(),
    );
  }
}
