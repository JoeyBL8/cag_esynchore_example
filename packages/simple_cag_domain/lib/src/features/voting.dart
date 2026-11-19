import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/errors/simple_cag_error.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

extension VoteForPlayer on CagGame {
  static const cannotVoteForPlayerIfNoPromptExists = SimpleCagFailure(
    errorMessage: "Voting for a player inbetween rounds is not allowed",
  );

  static const cannotVoteForPlayerWithIncompleteAnswers = SimpleCagFailure(
    errorMessage: "Voting for a player inbetween rounds is not allowed",
  );

  /// Vote for the player
  ///
  /// Increases the score of the player voted for
  /// Also moves all played cards to the discard pile
  /// Adds winning cards to the roundWinner list
  Either<SimpleCagFailure, CagGame> voteForPlayer(CagIdentifier playerIdentifier) => .Do(($) {
    final player = $(getPlayer(playerIdentifier));

    final prompt = $(.fromOption(currentPrompt, () => cannotVoteForPlayerIfNoPromptExists));

    if (player.played.length != prompt.picks) $(const Failure(cannotVoteForPlayerWithIncompleteAnswers));

    final result = CagRoundResult(
      winningResponses: player.played,
      relatedPrompt: prompt,
      playerIdentifier: player.id,
    );

    final remainingCards = players
        .where((player) => player.id != playerIdentifier)
        .expand((player) => player.played)
        .toList();

    final scoreUpdatedGame = $(modifyPlayer(playerIdentifier, (player) => player.incrementScore()));

    return scoreUpdatedGame.copyWith(
      roundResults: [
        ...roundResults,
        result,
      ],
      playedResponseCards: [
        ...playedResponseCards,
        ...remainingCards,
      ],
      currentPrompt: const None(),
      players: scoreUpdatedGame.players.map((player) => player.copyWith(played: [])).toList(),
    );
  });
}

extension on CagPlayer {
  CagPlayer incrementScore() => copyWith(score: score + 1);
}
