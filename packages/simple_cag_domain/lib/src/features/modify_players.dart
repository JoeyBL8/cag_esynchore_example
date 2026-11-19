import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

extension ModifyPlayer on CagGame {
  static const playerDoesNotExistFailure = SimpleCagFailure(errorMessage: "Cannot modify a player that does not exist");

  Either<SimpleCagFailure, CagGame> modifyPlayer(
    CagIdentifier playerIdentifier,
    CagPlayer Function(CagPlayer player) modifier,
  ) => .Do(($) {
    final isPlayerWithId = _isPlayerWithId(playerIdentifier);
    if (!players.any(isPlayerWithId)) $(const Failure(playerDoesNotExistFailure));

    CagPlayer identifyAndModifyPlayer(CagPlayer player) {
      if (isPlayerWithId(player)) {
        return modifier(player);
      }
      return player;
    }

    return copyWith(players: players.map(identifyAndModifyPlayer).toList());
  });

  bool Function(CagPlayer) _isPlayerWithId(CagIdentifier identifier) =>
      (player) => player.id == identifier;

  Either<SimpleCagFailure, CagPlayer> getPlayer(CagIdentifier playerIdentifier) =>
      .fromOption(players.where(_isPlayerWithId(playerIdentifier)).firstOption, () => playerDoesNotExistFailure);
}
