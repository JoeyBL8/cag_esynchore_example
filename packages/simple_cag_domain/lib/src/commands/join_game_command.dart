import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/commands/commands.dart";
import "package:simple_cag_domain/src/errors/esynchore_error_codes.dart";
import "package:simple_cag_domain/src/features/create_player.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/service/authentication.dart";
import "package:simple_cag_domain/src/service/session_service.dart";

class JoinGameCommand({required final CagPlayer player}) extends CagCommand {
  @override
  TaskEither<ApplicationError, CagGame> apply(CagGame state, CagAuthPrincipal principal) =>
      .right(state.createPlayer(player));

  @override
  TaskEither<AuthorizationError, Unit> authorize(CagGame state, CagAuthPrincipal principal) {
    if (principal.role != .system) return .left(CagEsynchoreErrorCodes.operationNotAllowed.getError());

    return .right(unit);
  }

  @override
  String get type => CagCommands.joinGame.commandType;
}
