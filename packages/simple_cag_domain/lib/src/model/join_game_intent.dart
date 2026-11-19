import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

const _keyPlayerName = "playerName";
const _keyKey = "key";
const _keyPlayerIdentifier = "playerIdentifier";
const _keyGameId = "gameId";

class JoinGameIntent({
  required final String playerName,
  required final String key,
});

extension JoinGameIntentSerializer on JoinGameIntent {
  static Serializer<JoinGameIntent> get serializer => _serializer;

  Serializer<JoinGameIntent> get objectSerializer => serializer.withObject(this);
}

Serializer<JoinGameIntent> _serializer = Serializer(
  validators: {
    _keyPlayerName: .string(),
    _keyKey: .string(),
  },
  fromMap: (map) => switch (map) {
    {_keyKey: final String key, _keyPlayerName: final String playerName} => JoinGameIntent(
      playerName: playerName,
      key: key,
    ),
    _ => throw StateError("Tried to serialize an unvalidated map, validate the object first"),
  },
  toMap: (intent) => {
    _keyPlayerName: intent.playerName,
    _keyKey: intent.key,
  },
);

class JoinGameIntentResponse({
  required final String gameId,
  required final CagIdentifier playerId,
});

extension JoinGameIntentResponseSerializer on JoinGameIntentResponse {
  static Serializer<JoinGameIntentResponse> get serializer => _joinGameIntentResponseSerializer;

  Serializer<JoinGameIntentResponse> get objectSerializer => serializer.withObject(this);
}

final Serializer<JoinGameIntentResponse> _joinGameIntentResponseSerializer = Serializer(
  validators: {
    _keyGameId: .string(),
    _keyPlayerIdentifier: .string(),
  },
  fromMap: (map) => switch (map) {
    {
      _keyGameId: final String gameId,
      _keyPlayerIdentifier: final String playerIdentifier,
    } =>
      JoinGameIntentResponse(
        gameId: gameId,
        playerId: CagIdentifier(playerIdentifier),
      ),
    _ => throw StateError(
      "Tried to serialize an unvalidated map, validate the object first",
    ),
  },
  toMap: (response) => {
    _keyGameId: response.gameId,
    _keyPlayerIdentifier: response.playerId,
  },
);
