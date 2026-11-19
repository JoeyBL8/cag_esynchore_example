import "dart:convert";

import "package:shelf/shelf.dart";
import "package:shelf_router/shelf_router.dart";
import "package:simple_cag_backend/src/config/request.dart";
import "package:simple_cag_backend/src/routes/commands.dart";
import "package:simple_cag_backend/src/routes/create_game.dart";
import "package:simple_cag_backend/src/routes/join_game.dart";
import "package:simple_cag_backend/src/routes/list_games.dart";
import "package:simple_cag_backend/src/routes/middleware/cors.dart";
import "package:simple_cag_backend/src/routes/websocket.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

Router createRouter({
  required CagSessionService sessionService,
  required CagGameSerializer gameSerializer,
  required CagSetProvider setProvider,
}) => Router()
  ..post("/games", createGameHandler(sessionService: sessionService))
  ..get("/games", listGamesHandler(sessionService: sessionService))
  ..post(
    "/games/<sessionId>/join",
    (Request request, String sessionId) =>
        joinGameHandler(sessionId: sessionId, sessionService: sessionService)(request),
  )
  ..get(
    "/games/<sessionId>/states",
    (Request request, String sessionId) =>
        websocketHandler(gameSerializer: gameSerializer, sessionId: sessionId, sessionService: sessionService)(request),
  )
  ..post(
    "/games/<sessionId>/commands",
    (Request request, String sessionId) =>
        commandsHandler(sessionId: sessionId, sessionService: sessionService)(request),
  )
  ..get("/sets", (_) async {
    final setsResult = await setProvider.getCagSetIdentifiers().run();
    final sets = setsResult.getOrElse((_) => []);

    return Response.ok(
      headers: jsonDefaultHeaders,
      jsonEncode({
        "sets": sets,
      }),
    );
  });

Handler createPipeline({
  required Router router,
}) => const Pipeline().addMiddleware(corsMiddleware()).addMiddleware(logRequests()).addHandler(router.call);
