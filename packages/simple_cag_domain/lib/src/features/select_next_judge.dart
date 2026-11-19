import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/features/copying.dart";
import "package:simple_cag_domain/src/features/modify_players.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";

extension SelectNextJudge on CagGame {
  CagGame selectNextJudge() {
    final previousJudge = currentJudge.flatMap((id) => getPlayer(id).toOption());
    final previousJudgeId = previousJudge.toNullable()?.id;
    final previousIndex = previousJudge.map((player) => player.turnOrderIdentifier).getOrElse(() => -1);

    // this has O(n) complexity, but it does not require more optimisation
    // A better solution would be to have a cached sorted list and use a binary search,
    // but who has the time for that.
    final nextPlayer = players.reduce((playerA, playerB) {
      if (playerA.id == previousJudgeId) return playerB;
      if (playerB.id == previousJudgeId) return playerA;

      final diffA = playerA.turnOrderIdentifier - previousIndex;
      final diffB = playerB.turnOrderIdentifier - previousIndex;

      // b already had a turn
      if (diffB.isNegative) return playerA;

      // A can be the first player we encounter, which also can have a negative turn
      if (diffA.isNegative) return playerB;

      // player a is a more logical next choice
      if (diffA > diffB) return playerB;

      return playerA;
    });

    return copyWith(
      currentJudge: Some(nextPlayer.id),
    );
  }
}
