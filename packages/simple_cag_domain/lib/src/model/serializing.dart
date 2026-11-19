import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

final class const CagSerializationFailure({required final String message});

class CagGameSerializer {
  /// Serialize the game for a player
  Map<String, dynamic> serializeForPlayer(CagGame game, CagIdentifier playerIdentifier) => {
    "id": game.id,
    "stage": game.stage.name,
    "players": game.players
        .map(
          (player) => _serializePlayer(
            player,
            showHand: playerIdentifier == player.id,
            showPlayed: playerIdentifier == player.id || game.stage != .playCards,
          ),
        )
        .toList(),
    "promptCardDeck": game.promptCardDeck.map(_anonymizePromptCard).map(_serializePromptCard).toList(),
    "roundResults": game.roundResults.map(_serializeRoundResult).toList(),
    "responseCardDeck": game.responseCardDeck.map(_anonymizeResponseCard).map(_serializeResponseCard).toList(),
    "playedResponseCards": game.playedResponseCards.map(_serializeResponseCard).toList(),
    "currentJudge": game.currentJudge.toJson((id) => id),
    "currentPrompt": game.currentPrompt.toJson(_serializePromptCard),
  };

  Map<String, dynamic> serializeForSpectator(CagGame game) => serializeForPlayer(game, .new("spectator"));

  Either<CagSerializationFailure, CagGame> deserialize(Map<String, dynamic> map) => .Do(($) {
    final rawPlayers = $(_parseType<List<dynamic>>(map, "players", "List of Players"));
    final players = rawPlayers
        .map(
          (rawPlayer) => switch (rawPlayer) {
            Map<String, dynamic> rawPlayer => $(_deserializePlayer(rawPlayer)),
            _ => $(Failure(_wrongValueFoundFailure("players", "List of players"))),
          },
        )
        .whereType<CagPlayer>()
        .toList();

    return CagGame(
      id: $(_parseId(map)),
      stage: $(
        _parseType<String>(
          map,
          "stage",
          "String",
        ).flatMap((name) => _deserializeEnum("stage", name, GameStage.values, "GameStage")),
      ),
      players: players,
      responseCardDeck: $(_deserializeResponseCardList(map, "responseCardDeck")),
      playedResponseCards: $(_deserializeResponseCardList(map, "playedResponseCards")),
      promptCardDeck: $(_deserializePromptCardList(map, "promptCardDeck")),
      roundResults: $(_deserializeRoundResultList(map, "roundResults")),
      currentPrompt: $(
        _parseType<Map<String, dynamic>?>(
          map,
          "currentPrompt",
          "Prompt Card",
        ).map((x) => .fromJson(x, (x) => $(_deserializePromptCard(x)))),
      ),
      currentJudge: $(
        _parseType<String?>(map, "currentJudge", "String").map((id) => .fromJson(id, (id) => CagIdentifier(id))),
      ),
    );
  });

  // #######################################################################
  // Deserialization Helpers
  // #######################################################################

  CagSerializationFailure _keyNotFoundFailure(String key) =>
      CagSerializationFailure(message: "Missing key: $key in json object");
  CagSerializationFailure _wrongValueFoundFailure(String key, String expectedType) =>
      CagSerializationFailure(message: "Value for $key was expected to be of type $expectedType");

  Either<CagSerializationFailure, T> _parseType<T>(Map<String, dynamic> map, String key, String expectedType) =>
      .Do(($) {
        final rawValue = $(.fromPredicate(map[key], (_) => map.containsKey(key), (_) => _keyNotFoundFailure(key)));
        final value =
            $(.fromPredicate(rawValue, (value) => value is T, (_) => _wrongValueFoundFailure(key, expectedType))) as T;
        return value;
      });

  Either<CagSerializationFailure, CagIdentifier> _parseId(Map<String, dynamic> map, [String key = "id"]) =>
      _parseType<String>(map, key, "String").map(CagIdentifier.new);

  Either<CagSerializationFailure, CagPlayer> _deserializePlayer(Map<String, dynamic> map) => .Do(
    ($) => CagPlayer(
      id: $(_parseId(map)),
      score: $(_parseType(map, "score", "Integer")),
      name: $(_parseType(map, "name", "String")),
      hand: $(_deserializeResponseCardList(map, "hand")),
      played: $(_deserializeResponseCardList(map, "played")),
      role: $(
        _parseType<String>(
          map,
          "role",
          "String",
        ).flatMap((name) => _deserializeEnum("role", name, CagPlayerRole.values, "PlayerRole")),
      ),
      // always set to -1, turnorderIdentifier is never in the map, the player does not need to know it.
      turnOrderIdentifier: -1,
    ),
  );

  Either<CagSerializationFailure, List<CagResponseCard>> _deserializeResponseCardList(
    Map<String, dynamic> map,
    String key,
  ) => _deserializeGenericList(map, key, _deserializeResponseCard);

  Either<CagSerializationFailure, List<CagPromptCard>> _deserializePromptCardList(
    Map<String, dynamic> map,
    String key,
  ) => _deserializeGenericList(map, key, _deserializePromptCard);

  Either<CagSerializationFailure, List<CagRoundResult>> _deserializeRoundResultList(
    Map<String, dynamic> map,
    String key,
  ) => _deserializeGenericList(map, key, _deserializeRoundResult);

  Either<CagSerializationFailure, List<T>> _deserializeGenericList<T>(
    Map<String, dynamic> map,
    String key,
    Either<CagSerializationFailure, T> Function(Map<String, dynamic>) deserializer,
  ) => .Do(($) {
    final list = $(_parseType<List<dynamic>>(map, key, "List"));

    T parseRawResponse(rawResponse) =>
        $(deserializer($(_ensureType<Map<String, dynamic>>(rawResponse, key, "List of PromptCard"))));

    return list.map(parseRawResponse).toList();
  });

  Either<CagSerializationFailure, CagRoundResult> _deserializeRoundResult(Map<String, dynamic> map) => .Do(
    ($) => CagRoundResult(
      playerIdentifier: $(_parseId(map, "playerIdentifier")),
      relatedPrompt: $(_deserializePromptCard($(_parseType<Map<String, dynamic>>(map, "relatedPrompt", "PromptCard")))),
      winningResponses: $(_deserializeResponseCardList(map, "winningResponses")),
    ),
  );

  Either<CagSerializationFailure, CagPromptCard> _deserializePromptCard(Map<String, dynamic> map) => .Do(
    ($) => CagPromptCard(
      id: $(_parseId(map)),
      prompt: $(_parseType(map, "prompt", "String")),
      picks: $(_parseType(map, "picks", "Integer")),
      visible: $(_parseType(map, "visible", "Boolean")),
    ),
  );

  Either<CagSerializationFailure, CagResponseCard> _deserializeResponseCard(Map<String, dynamic> map) => .Do(
    ($) => CagResponseCard(
      id: $(_parseId(map)),
      text: $(_parseType(map, "text", "String")),
      visible: $(_parseType(map, "visible", "Boolean")),
    ),
  );

  // ignored because json by default uses dynamic values
  // ignore: avoid_annotating_with_dynamic
  Either<CagSerializationFailure, T> _ensureType<T>(dynamic value, String key, String expectedType) {
    if (value is T) return Success(value);

    return Failure(_wrongValueFoundFailure(key, expectedType));
  }

  Either<CagSerializationFailure, R> _deserializeEnum<R extends Enum>(
    String key,
    String name,
    List<R> enumerable,
    String type,
  ) => .fromOption(enumerable.where((role) => role.name == name).firstOption, () => _wrongValueFoundFailure(key, name));

  // #######################################################################
  // Serialization Helpers
  // #######################################################################

  Map<String, dynamic> _serializePlayer(CagPlayer player, {required bool showHand, required bool showPlayed}) => {
    "id": player.id,
    "name": player.name,
    "score": player.score,
    "hand": switch (showHand) {
      true => player.hand,
      false => player.hand.map(_anonymizeResponseCard),
    }.map(_serializeResponseCard).toList(),
    "played": switch (showPlayed) {
      true => player.played,
      false => player.played.map(_anonymizeResponseCard),
    }.map(_serializeResponseCard).toList(),
    "role": player.role.name,
  };

  Map<String, dynamic> _serializeRoundResult(CagRoundResult result) => {
    "playerIdentifier": result.playerIdentifier,
    "relatedPrompt": _serializePromptCard(result.relatedPrompt),
    "winningResponses": result.winningResponses.map(_serializeResponseCard).toList(),
  };

  Map<String, dynamic> _serializeResponseCard(CagResponseCard card) => {
    "text": card.text,
    "id": card.id,
    "visible": card.visible,
  };

  Map<String, dynamic> _serializePromptCard(CagPromptCard card) => {
    "id": card.id,
    "prompt": card.prompt,
    "picks": card.picks,
    "visible": card.visible,
  };

  String _anonymize(String value) => "*" * (value.length % 7 + 4);

  CagPromptCard _anonymizePromptCard(CagPromptCard card) => card.copyWith(
    visible: false,
    prompt: _anonymize(card.prompt),
  );

  CagResponseCard _anonymizeResponseCard(CagResponseCard card) => card.copyWith(
    visible: false,
    text: _anonymize(card.text),
  );
}
