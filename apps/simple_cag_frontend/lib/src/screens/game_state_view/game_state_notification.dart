import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

enum _JudgeStatus { judge, player }

class const GameStateNotification({
  required final CagGame game,
  required final CagPlayer player,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isJudge = game.currentJudge
        .map((judge) => judge == player.id ? _JudgeStatus.judge : _JudgeStatus.player)
        .getOrElse(() => .player);

    final message = switch ((isJudge, game.stage)) {
      (.judge, .endOfRound) => "Start the next round when you are done discussing the winner",
      (.judge, .playCards) => "Wait for the players to play their cards, if you want to continue press 'Reveal cards'",
      (.judge, .voteBestOption) => "Pick the best option from the players in the sidebar",
      (.player, .endOfRound) => "Waiting for a judge or host to start the next round",
      (.player, .playCards) when player.played.isNotEmpty => "Waiting for other players to play their cards",
      (.player, .playCards) => "Pick and play your cards from your hand at the bottom",
      (.player, .voteBestOption) => "Waiting for the judge to vote for the best card",
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
      ),
      child: Padding(
        padding: const .all(12),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              fontWeight: .w900,
            ),
          ),
        ),
      ),
    );
  }
}
