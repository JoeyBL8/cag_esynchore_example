import "package:esynchore_backend/esynchore_backend.dart";
import "package:shelf/shelf.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

Handler websocketHandler({
  required CagSessionService sessionService,
  required CagGameSerializer gameSerializer,
  required String sessionId,
}) => sessionWebSocketHandler(
  id: sessionId,
  sessions: sessionService,
  credentialsSerializer: CagCredentials.serializer,
  stateSerializer: gameSerializer.serializer,
  projectState: (state, principal) => CagProjection(principal: principal, game: state),
  projectPublicState: (state) => CagProjection(principal: null, game: state),
);
