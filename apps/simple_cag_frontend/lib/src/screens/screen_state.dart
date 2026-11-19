import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/main.dart";

sealed class const CagScreenState();

final class const InitialCagScreenState() extends CagScreenState {
  TaskEither<String, SelectServerCagScreenState> login({required String key, required String playerName}) =>
      .Do(($) async {
        if (playerName.length > 32) await $(.left("Playernames can be at most 32 characters"));
        if (playerName.length < 3) await $(.left("Playernames have to be at least 3 characters"));
        if (key.isEmpty) await $(.left("You need a key to log in"));

        await $(.fromTask(globalPersistence.saveKey(key)));
        await $(.fromTask(globalPersistence.saveName(playerName)));

        return SelectServerCagScreenState(key: key, playerName: playerName);
      });
}

final class const SelectServerCagScreenState({
  required final String key,
  required final String playerName,
}) extends CagScreenState {
  Task<InitialCagScreenState> logout() => .of(const InitialCagScreenState());

  TaskEither<String, GameCagScreenState> createGame(Uri host, List<String> cardSets) => .Do(($) async {
    final apiService = CagApiService(baseUrl: host);
    final result = await $(
      apiService
          .createGame(JoinGameIntent(playerName: playerName, key: key), cardSets)
          .mapLeft((_) => "Failed to create a game"),
    );
    await globalPersistence
        .persistCredentials(result.gameId, key, CagCredentials(playerIdentifier: result.playerId, key: key))
        .run();

    return $(join(host, result.gameId));
  });

  TaskEither<String, GameCagScreenState> join(Uri host, String game) => .Do(($) async {
    final history = globalPersistence.getCredentials(game, key);

    final credentials = await $(.fromOption(history, () => "").alt(() => _joinFresh(host, game)));

    return GameCagScreenState(
      credentials: credentials,
      playerName: playerName,
      serverUri: host,
      gameId: game,
    );
  });

  TaskEither<String, CagCredentials> _joinFresh(Uri host, String game) => .Do(($) async {
    await $(.fromTask(globalPersistence.resetCredentials(game, key)));
    final apiService = CagApiService(baseUrl: host);

    final result = await $(
      apiService
          .joinGame(game, JoinGameIntent(playerName: playerName, key: key))
          .mapLeft((_) => "Failed to join game, try again or chose another game"),
    );

    final cagCredentials = CagCredentials(playerIdentifier: result.playerId, key: key);
    await globalPersistence.persistCredentials(game, key, cagCredentials).run();

    return cagCredentials;
  });
}

final class const GameCagScreenState({
  required final CagCredentials credentials,
  required final Uri serverUri,
  required final String gameId,
  required final String playerName,
}) extends CagScreenState {
  Task<SelectServerCagScreenState> disconnect() => .of(
    SelectServerCagScreenState(key: credentials.key, playerName: playerName),
  );
}
