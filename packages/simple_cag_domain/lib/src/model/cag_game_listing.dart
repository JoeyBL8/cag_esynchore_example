import "package:dart_iconica_utilities/dart_iconica_utilities.dart";

const _keyId = "id";
const _keyPlayers = "players";
const _keySets = "sets";
const _keyGames = "games";

class CagGameListing({
  required final String id,
  required final int players,
  required final List<String> sets,
});

extension CagGameListingSerializer on CagGameListing {
  static Serializer<CagGameListing> get serializer => _cagGameListingSerializer;

  Serializer<CagGameListing> get objectSerializer => serializer.withObject(this);
}

final Serializer<CagGameListing> _cagGameListingSerializer = Serializer(
  validators: {
    _keyId: .string(),
    _keyPlayers: .int(),
    _keySets: .list(childValidator: .string()),
  },
  fromMap: (map) => switch (map) {
    {_keyId: final String id, _keyPlayers: final int players, _keySets: final List sets} => CagGameListing(
      id: id,
      players: players,
      sets: sets.whereType<String>().toList(),
    ),
    _ => throw StateError(
      "Tried to serialize an unvalidated map, validate the object first",
    ),
  },
  toMap: (game) => {_keyId: game.id, _keyPlayers: game.players, _keySets: game.sets},
);

class CagGameList({required final List<CagGameListing> games});

extension CagGameListSerializer on CagGameList {
  static Serializer<CagGameList> get serializer => _cagGameListSerializer;

  Serializer<CagGameList> get objectSerializer => serializer.withObject(this);
}

final Serializer<CagGameList> _cagGameListSerializer = Serializer(
  validators: {
    _keyGames: .list(),
  },
  fromMap: (map) => switch (map) {
    {_keyGames: final List games} => CagGameList(
      games: games.map((game) {
        if (game is! Map<String, dynamic>) {
          throw StateError("Expected each game listing to be a map");
        }

        return CagGameListingSerializer.serializer.fromMap(game);
      }).toList(),
    ),
    _ => throw StateError(
      "Tried to serialize an unvalidated map, validate the object first",
    ),
  },
  toMap: (result) => {
    _keyGames: result.games.map((game) => game.objectSerializer.serialize()).toList(),
  },
);
