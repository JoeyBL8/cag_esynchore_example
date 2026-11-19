import "dart:convert";

import "package:esynchore_backend/esynchore_backend.dart";
import "package:shelf/shelf.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

Handler commandsHandler({
  required String sessionId,
  required CagSessionService sessionService,
}) => sessionCommandHandler(
  sessions: sessionService,
  id: sessionId,
  commandSerializer: cagCommandSerializer,
  readCredentials: (request) =>
      CagCredentials.serializer.withData(jsonDecode(request.headers["authorization"]!)).deserialize(),
);
