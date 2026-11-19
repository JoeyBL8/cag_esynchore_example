import "dart:convert";

import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:shelf/shelf.dart";
import "package:simple_cag_backend/src/errors/response_errors.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

Handler joinGameHandler({
  required String sessionId,
  required CagSessionService sessionService,
}) => (request) async {
  final result = await _joinGame(sessionId: sessionId, sessionService: sessionService, request: request).run();

  return handleResponseFailure(result, onSuccess: (joinedGame) => joinedGame.objectSerializer.serialize());
};

TaskEither<RequestFailure, JoinGameIntentResponse> _joinGame({
  required String sessionId,
  required CagSessionService sessionService,
  required Request request,
}) => .Do(($) async {
  final error = InvalidRequestBodyFormatFailure(details: {"message": "Invalid json body found"});
  final body = await $(.tryCatch(() async => jsonDecode(await request.readAsString()), (_, _) => error));
  if (body is! Map<String, dynamic>) await $(.left(error));

  final serializer = JoinGameIntentSerializer.serializer.withData(body);
  final joinGameIntent = await $(
    .fromEither(
      serializer.fDeserializeValidated().mapLeft(
        (error) => InvalidRequestBodyFormatFailure(details: error.validationMessages),
      ),
    ),
  );

  final registrationAttempt = await sessionService.registerPlayer(sessionId, joinGameIntent).run();

  final errorHandledRegistrationAttempt = registrationAttempt.mapLeft(
    (error) => switch (error) {
      EsynchoreError error when error.code == CagEsynchoreErrorCodes.gameNotFound.errorCode =>
        TargetResourceNotFoundFailure(identifier: sessionId, target: "Game"),
      AuthenticationError() => ServerFailure(
        message: "Authentication is not expected before joining",
        code: "unexpected_authentication",
      ),
      ApplicationError error => ServerFailure(message: "Failed to join the game", code: error.code),
      AuthorizationError error => ServerFailure(message: "Failed to join the game", code: error.code),
    },
  );
  final registration = await $(.fromEither(errorHandledRegistrationAttempt));

  return JoinGameIntentResponse(gameId: sessionId, playerId: registration);
});
