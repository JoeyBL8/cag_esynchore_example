import "package:dart_api_service/dart_api_service.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

final class const CagApiFailure();

class CagApiService({
  required super.baseUrl,
  super.client,
}) extends HttpApiService<Object> {
  factory CagApiService.unsecure({
    required Uri baseUrl,
  }) => CagApiService(
    baseUrl: baseUrl,
    client: createApiClient(allowedHost: baseUrl.host, allowedPort: baseUrl.port),
  );

  TaskEither<CagApiFailure, List<String>> getSets() {
    final result = endpoint("/sets").withConverter(const MapJsonResponseConverter()).get();

    return result
        .mapLeft((_) => const CagApiFailure())
        .flatMap((response) => .fromNullable(response.result, CagApiFailure.new))
        .map(
          (data) => switch (data) {
            {"sets": final List sets} => sets.whereType<String>().toList(),
            _ => <String>[],
          },
        );
  }

  TaskEither<CagApiFailure, CagGameList> getGames() {
    final serializer = CagGameListSerializer.serializer;
    final result = endpoint("/games")
        .withConverter(.model(serialize: serializer.toMap, deserialize: serializer.fromMap))
        .get();

    return result
        .mapLeft((_) => const CagApiFailure())
        .flatMap((response) => .fromNullable(response.result, CagApiFailure.new));
  }

  TaskEither<CagApiFailure, JoinGameIntentResponse> createGame(JoinGameIntent joinGameIntent, List<String> cardSets) {
    final game = CreateGameIntent(playerName: joinGameIntent.playerName, key: joinGameIntent.key, cardSets: cardSets);
    final result = endpoint("/games")
        .withConverter(const MapJsonResponseConverter())
        .post(
          requestModel: game.objectSerializer.serialize(),
        );

    return result
        .mapLeft((_) => const CagApiFailure())
        .map((data) => JoinGameIntentResponseSerializer.serializer.withData(data.result!).deserialize());
  }

  TaskEither<CagApiFailure, JoinGameIntentResponse> joinGame(String game, JoinGameIntent joinGameIntent) =>
      .Do(($) async {
        final result = await $(
          endpoint("/games/$game/join")
              .withConverter(const MapJsonResponseConverter())
              .post(
                requestModel: joinGameIntent.objectSerializer.serialize(),
              )
              .mapLeft((_) => const CagApiFailure()),
        );

        return $(
          .tryCatch(() async {
            final serializer = JoinGameIntentResponseSerializer.serializer.withData(result.result!);
            serializer.validate(raiseException: true);
            return serializer.deserialize();
          }, (_, _) => const CagApiFailure()),
        );
      });
}
