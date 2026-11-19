import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/commands/commands.dart";
import "package:simple_cag_domain/src/errors/esynchore_error_codes.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";
import "package:simple_cag_domain/src/features/play_cards.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/service/authentication.dart";
import "package:simple_cag_domain/src/service/session_service.dart";

class PlayCardsCommand({
  required final CagIdentifier playerIdentifier,
  required final List<CagIdentifier> cardsToPlay,
}) extends CagCommand {
  @override
  TaskEither<ApplicationError, CagGame> apply(CagGame state, CagAuthPrincipal principal) =>
      state.playCards(playerIdentifier, cardsToPlay).toEsynchore().toTaskEither();

  @override
  TaskEither<AuthorizationError, Unit> authorize(CagGame state, CagAuthPrincipal principal) => .Do(($) async {
    if (principal.playerIdentifier != playerIdentifier && principal.role != .system)
      await $(guard(.operationNotAllowed));

    final player = await $(state.getPlayer(playerIdentifier).toEsynchoreOf(.operationNotAllowed).toTaskEither());

    final prompt = await $(.fromOption(state.currentPrompt, CagEsynchoreErrorCodes.operationNotAllowed.getError));

    if (state.stage != .playCards) await $(guard(.operationNotAllowed));

    if (state.currentJudge case Some(value: final judge) when judge == playerIdentifier) {
      await $(guard(.playCardsAsJudge));
    }

    if (player.played.isNotEmpty) await $(guard(.playCardsWhenCardsAreAlreadyPlayed));

    if (cardsToPlay.length != prompt.picks) await $(guard(.playIncorrectCardAmount));

    return unit;
  });

  @override
  String get type => CagCommands.playCards.commandType;

  static Serializer<CagCommand> get serializer => _serializer;
}

const _keyPlayer = "player";
const _keyCards = "cards";

Serializer<CagCommand> _serializer = Serializer(
  fromMap: (data) => switch (data) {
    {_keyPlayer: final String player, _keyCards: final List cardIds} => PlayCardsCommand(
      playerIdentifier: CagIdentifier(player),
      cardsToPlay: cardIds.whereType<String>().map(CagIdentifier.new).toList(),
    ),
    _ => PlayCardsCommand(playerIdentifier: .create(), cardsToPlay: []),
  },
  toMap: (command) {
    assert(
      command is PlayCardsCommand,
      "This command can only ever be a PlayCardsCommand, "
      "but this serializer needs to be generically appliable",
    );
    command as PlayCardsCommand;
    return {
      _keyPlayer: command.playerIdentifier,
      _keyCards: command.cardsToPlay,
    };
  },
);
