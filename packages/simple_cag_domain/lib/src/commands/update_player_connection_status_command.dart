import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";

class UpdatePlayerConnectionStatusCommand({
  required final CagIdentifier playerIdentifier,
  required final PlayerActivityStatus status,
}) extends CagCommand {
  @override
  TaskEither<ApplicationError, CagGame> apply(CagGame state, CagAuthPrincipal principal) => .of(
    state
        .modifyPlayer(
          playerIdentifier,
          (player) => player.copyWith(status: status),
        )
        .getOrElse((_) => state),
  );

  @override
  TaskEither<AuthorizationError, Unit> authorize(CagGame state, CagAuthPrincipal principal) {
    if (principal.role != .system) {
      return .left(CagEsynchoreErrorCodes.operationNotAllowed.getError());
    }

    return .of(unit);
  }

  @override
  String get type => CagCommands.updatePlayerConnectionStatus.commandType;
}
