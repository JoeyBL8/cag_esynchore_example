import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";

extension AddPlayer on CagGame {
  CagGame createPlayer(CagPlayer player) => copyWith(
    players: [
      ...players,
      player,
    ],
  );
}
