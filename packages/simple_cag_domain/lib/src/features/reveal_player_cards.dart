import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/features/copying.dart";

extension RevealPlayerCards on CagGame {
  CagGame revealPlayerCards() => copyWith(
    players: players
        .map(
          (player) => player.copyWith(
            played: player.played.map((card) => card.copyWith(visible: true)).toList(),
          ),
        )
        .toList(),
  );
}
