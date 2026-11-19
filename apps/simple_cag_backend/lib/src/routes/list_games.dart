import "dart:convert";

import "package:shelf/shelf.dart";
import "package:simple_cag_backend/src/config/request.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

Handler listGamesHandler({
  required CagSessionService sessionService,
}) =>
    (request) async => .ok(
      headers: jsonDefaultHeaders,
      jsonEncode(CagGameList(games: sessionService.getGames()).objectSerializer.serialize()),
    );
