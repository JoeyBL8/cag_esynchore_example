import "dart:async";
import "dart:io";

import "package:bcrypt/bcrypt.dart";
import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/service/automated_game_progressor.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

final _systemAccessKey = Platform.environment["CAG_SYSTEM_ACCESS_KEY"] ?? "unsafe_system_access_key";
final _systemAccessIdentifier = CagIdentifier("system_access");

typedef CagCommand = StateCommand<CagGame, CagAuthPrincipal>;

final _systemPrincipal = CagAuthPrincipal(
  playerIdentifier: _systemAccessIdentifier,
  role: .system,
  key: BCrypt.hashpw(_systemAccessKey, BCrypt.gensalt()),
  // never used for any session, this principal is a one time eternally available key
  sessionId: "",
);

class GameRegistration({
  required final String gameId,
  required final List<String> cardSets,
});

class CagSessionService({
  required final CagSetProvider _setProvider,
  AutomatedGameProgressor? progressor,
}) extends StateSessionService<CagGame, SerializableCredentials, CagAuthPrincipal> {
  this : super(authenticate: (_, _) => .fromEither(Failure(CagEsynchoreErrorCodes.authUnimplemented.getError()))) {
    _progressor =
        progressor ??
        AutomatedGameProgressor(
          systemCredentials: _systemCredentials,
          onRemove: (id) => .Do(($) async {
            await remove(id);
            return unit;
          }),
        );
  }

  static CagCredentials get _systemCredentials =>
      CagCredentials(playerIdentifier: _systemAccessIdentifier, key: _systemAccessKey);

  late final List<GameRegistration> _knownGameIds = [];

  late final AutomatedGameProgressor _progressor;

  /// The principals that are allowed to communicate
  late final AuthCredentialsSubscription _principals = AuthCredentialsSubscription({})..addPrincipal(_systemPrincipal);

  TaskEither<EsynchoreError, CagIdentifier> registerPlayer(
    String sessionId,
    JoinGameIntent joinGameIntent, {
    CagPlayerRole? role,
  }) => .Do(($) async {
    final session = await $(
      .fromOption(.fromNullable(get(sessionId)), () => CagEsynchoreErrorCodes.gameNotFound.getError()),
    );

    final player = CagPlayer.fresh(joinGameIntent.playerName, role);

    final principal = CagAuthPrincipal(
      playerIdentifier: player.id,
      role: player.role,
      key: BCrypt.hashpw(joinGameIntent.key, BCrypt.gensalt()),
      sessionId: sessionId,
    );

    await $(.fromEither(_principals.addPrincipal(principal)));

    await $(
      session.submit(JoinGameCommand(player: player), Success(_systemCredentials)).mapLeft((left) {
        _principals.removeCredential(principal);
        return left;
      }),
    );

    return principal.playerIdentifier;
  });

  List<CagGameListing> getGames() {
    final games = _knownGameIds.map((registration) => (registration, get(registration.gameId))).toList();

    games.where((gwid) => gwid.$2 == null).map((gwid) => gwid.$1).forEach(_knownGameIds.remove);

    return games.where((gwid) => gwid.$2 != null).map((gwid) {
      final (registration, game!) = gwid;

      return CagGameListing(
        id: registration.gameId,
        players: game.state.players.where((player) => player.status == .active).length,
        sets: registration.cardSets,
      );
    }).toList();
  }

  /// Creates a new game and adds the player to it as a host
  TaskEither<EsynchoreError, JoinGameIntentResponse> createGame(CreateGameIntent intent) => .Do(($) async {
    final sets = await Future.wait(
      intent.cardSets.map((setId) => $(_setProvider.getCagSet(setId).capture(.createGameWithUnknownSet))),
    );

    final game = createCagGameFromSets(sets);

    create(
      game.id.id,
      game,
      onApplied: (command, principal, state) => _notifyAutomation(game.id.id, command, state),
    );

    final joinGameIntent = JoinGameIntent(playerName: intent.playerName, key: intent.key);

    final identifier = await $(
      registerPlayer(game.id.id, joinGameIntent, role: .host).mapLeft((error) {
        unawaited(remove(game.id.id)); // this is not causing a failure, its simply cleanup that must happen
        return error;
      }),
    );

    _knownGameIds.add(GameRegistration(gameId: game.id.id, cardSets: sets.map((set) => set.name).toList()));

    return JoinGameIntentResponse(gameId: game.id.id, playerId: identifier);
  });

  Future<void> handlePlayerJoinGame(String id, CagIdentifier playerId) async {
    final handler = get(id);
    if (handler == null) return;

    await handler
        .submit(
          UpdatePlayerConnectionStatusCommand(playerIdentifier: playerId, status: .active),
          .of(_systemCredentials),
        )
        .run();
  }

  Future<void> handlePlayerLeaveGame(String id, CagIdentifier playerId) async {
    final handler = get(id);
    if (handler == null) return;

    await handler
        .submit(
          UpdatePlayerConnectionStatusCommand(playerIdentifier: playerId, status: .disconnected),
          .of(_systemCredentials),
        )
        .run();
  }

  void _notifyAutomation(String id, CagCommand command, CagGame state) {
    final handler = get(id);

    if (handler == null) return;

    _progressor.onCommandApplied(command, state, handler);
  }

  @override
  TaskEither<AuthenticationError, CagAuthPrincipal> Function(CagGame state, SerializableCredentials credentials)
  get authenticate => _principals.verifyPrincipal;
}

class CagProjection({
  required final CagAuthPrincipal? principal,
  required final CagGame game,
});

extension SerializationBinding on CagGameSerializer {
  Serializer<CagProjection> get serializer => Serializer(
    fromMap: (map) => CagProjection(
      principal: null,
      game: deserialize(map).getOrElse((failure) => throw CagSerializationError(failure)),
    ),
    toMap: (projection) => switch (projection.principal) {
      CagAuthPrincipal principal => serializeForPlayer(projection.game, principal.playerIdentifier),
      null => serializeForSpectator(projection.game),
    },
  );
}

class CagSerializationError(final CagSerializationFailure failure) extends Error;

extension<T> on TaskEither<CagSetFailure, T> {
  TaskEither<EsynchoreError, T> capture(CagEsynchoreErrorCodes code) => mapLeft((_) => code.getError());
}

CagGame createCagGameFromSets(List<CagSet> sets) {
  final (promptCards, responseCards) = sets.fold((<CagPromptCard>[], <CagResponseCard>[]), (previous, set) {
    final (promptCards, responseCards) = previous;
    return ([...promptCards, ...set.promptCards], [...responseCards, ...set.responseCards]);
  });

  return CagGame(
    stage: .endOfRound,
    id: .create(),
    players: [],
    responseCardDeck: List.from(responseCards..shuffle()),
    playedResponseCards: [],
    promptCardDeck: List.from(promptCards..shuffle()),
    roundResults: [],
    currentPrompt: const None(),
    currentJudge: const None(),
  );
}
