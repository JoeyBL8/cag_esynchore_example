import "package:dart_iconica_utilities/dart_iconica_utilities.dart";

const _keyPlayerName = "playerName";
const _keyKey = "key";
const _keyCardSets = "cardSets";

class const CreateGameIntent({
  required final String playerName,
  required final String key,
  required final List<String> cardSets,
});

extension CreateGameIntentSerializer on CreateGameIntent {
  static Serializer<CreateGameIntent> get serializer => _serializer;

  Serializer<CreateGameIntent> get objectSerializer => serializer.withObject(this);
}

final Serializer<CreateGameIntent> _serializer = Serializer(
  validators: {
    _keyPlayerName: .string(),
    _keyKey: .string(),
    _keyCardSets: .list(childValidator: .string()),
  },
  fromMap: (map) => switch (map) {
    {
      _keyPlayerName: final String playerName,
      _keyKey: final String key,
      _keyCardSets: final List cardSets,
    } =>
      CreateGameIntent(
        playerName: playerName,
        key: key,
        cardSets: cardSets.whereType<String>().toList(),
      ),
    _ => throw StateError(
      "Tried to serialize an unvalidated map, validate the object first",
    ),
  },
  toMap: (intent) => {
    _keyPlayerName: intent.playerName,
    _keyKey: intent.key,
    _keyCardSets: intent.cardSets,
  },
);
