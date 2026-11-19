import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";
import "package:simple_cag_domain/src/features/voting.dart";

class VotePickCommand({required final CagIdentifier playerIdentifier, required final CagIdentifier playerToVoteFor})
    extends CagCommand {
  @override
  TaskEither<ApplicationError, CagGame> apply(CagGame state, CagAuthPrincipal principal) => .Do(($) async {
    final votedState = await $(state.voteForPlayer(playerToVoteFor).toEsynchoreTask());
    return votedState.copyWith(stage: .endOfRound);
  });

  @override
  TaskEither<AuthorizationError, Unit> authorize(CagGame state, CagAuthPrincipal principal) => .Do(($) async {
    if (principal.playerIdentifier != playerIdentifier && principal.role != .system) {
      await $(guard(.operationNotAllowed));
    }

    final prompt = await $(.fromOption(state.currentPrompt, CagEsynchoreErrorCodes.operationNotAllowed.getError));

    final player = await $(state.getPlayer(playerToVoteFor).toEsynchoreOf(.operationNotAllowed).toTaskEither());

    if (state.stage != .voteBestOption) await $(guard(.operationNotAllowed));

    if (state.currentJudge case Some(value: final judge) when judge != playerIdentifier) {
      await $(guard(.voteAsNonJudge));
    }

    if (player.played.length != prompt.picks) await $(guard(.operationNotAllowed));

    return unit;
  });

  @override
  String get type => CagCommands.votePick.commandType;

  static Serializer<CagCommand> get serializer => _serializer;
}

const _keyPlayer = "playerIdentifier";
const _keyPlayerToVoteFor = "playerToVoteFor";

Serializer<CagCommand> _serializer = Serializer(
  fromMap: (data) => switch (data) {
    {_keyPlayer: final String player, _keyPlayerToVoteFor: final String toVoteFor} => VotePickCommand(
      playerIdentifier: CagIdentifier(player),
      playerToVoteFor: CagIdentifier(toVoteFor),
    ),
    _ => VotePickCommand(playerIdentifier: .create(), playerToVoteFor: .create()),
  },
  toMap: (command) {
    assert(
      command is VotePickCommand,
      "This command can only ever be a PlayCardsCommand, "
      "but this serializer needs to be generically appliable",
    );
    command as VotePickCommand;
    return {
      _keyPlayer: command.playerIdentifier,
      _keyPlayerToVoteFor: command.playerToVoteFor,
    };
  },
);
