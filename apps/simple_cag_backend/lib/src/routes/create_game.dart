import "dart:convert";

import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:shelf/shelf.dart";
import "package:simple_cag_backend/src/errors/response_errors.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

Handler createGameHandler({
  required CagSessionService sessionService,
}) => (request) async {
  final result = await _createGame(request: request, sessionService: sessionService).run();

  return handleResponseFailure(result, onSuccess: (joinedGame) => joinedGame.objectSerializer.serialize());
};

TaskEither<RequestFailure, JoinGameIntentResponse> _createGame({
  required Request request,
  required CagSessionService sessionService,
}) => .Do(($) async {
  final error = InvalidRequestBodyFormatFailure(details: {"message": "Invalid json body found"});
  final body = await $(.tryCatch(() async => jsonDecode(await request.readAsString()), (_, _) => error));
  if (body is! Map<String, dynamic>) await $(.left(error));

  final serializer = CreateGameIntentSerializer.serializer.withData(body);
  final createGameIntent = await $(
    .fromEither(
      serializer.fDeserializeValidated().mapLeft(
        (error) => InvalidRequestBodyFormatFailure(details: error.validationMessages),
      ),
    ),
  );

  final createGameAttempt = sessionService.createGame(createGameIntent);

  final errorHandledGameCreationAttempt = createGameAttempt.mapLeft(
    (error) => switch (error) {
      AuthenticationError() => ServerFailure(
        message: "Authentication is not expected during game creation",
        code: "unexpected_authentication",
      ),
      ApplicationError error => ServerFailure(message: "Failed to create game", code: error.code),
      AuthorizationError error => ServerFailure(message: "Failed to create game", code: error.code),
    },
  );

  return $(errorHandledGameCreationAttempt);
});
