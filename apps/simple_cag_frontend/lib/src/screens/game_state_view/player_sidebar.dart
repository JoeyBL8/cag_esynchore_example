import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/utils.dart";
import "package:simple_cag_frontend/src/service/game_connection.dart";
import "package:simple_cag_frontend/src/widgets/cag_card.dart";
import "package:simple_cag_frontend/src/widgets/scaled_down_size.dart";
import "package:simple_cag_frontend/src/widgets/show_error.dart";

class const PlayerSidebar({
  super.key,
  required final CagCredentials credentials,
  required final CagGameConnected connectedState,
  required final CagGame gameState,
  required final CagPlayer player,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isJudge = gameState.isJudge(player.id);
    final canJudge = gameState.stage == .voteBestOption && isJudge;

    Future<void> voteForPlayer(CagIdentifier toVoteFor) async {
      final result = await connectedState.sendCommand(
        VotePickCommand(playerIdentifier: player.id, playerToVoteFor: toVoteFor),
      );
      if (result case Left(value: final error) when context.mounted) {
        context.showError("${error.code}: ${error.message}");
      }
    }

    Future<void> viewPlayer(CagPlayer player) async {
      final result = await showDialog<CagIdentifier>(
        context: context,
        builder: (context) => ViewPlayerDialog(
          isSelf: player.id == this.player.id,
          player: player,
          canJudge: canJudge && player.played.isNotEmpty,
          promptCard: gameState.currentPrompt,
        ),
      );
      if (result != null) {
        await voteForPlayer(result);
      }
    }

    return ListView(
      children: [
        for (final player in gameState.players) ...[
          _PlayerTile(
            isSelf: player.id == this.player.id,
            player: player,
            isJudge: gameState.currentJudge.map((judge) => judge == player.id).getOrElse(() => false),
            onViewPlayer: () => viewPlayer(player),
          ),
          if (gameState.players.isNotEmpty && gameState.players.last != player) ...[
            const Divider(height: 4, thickness: 4),
          ],
        ],
      ],
    );
  }
}

class const ViewPlayerDialog({
  required final CagPlayer player,
  required final bool isSelf,
  required final bool canJudge,
  required final Option<CagPromptCard> promptCard,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final playerLabel = switch (player.role) {
      CagPlayerRole.system => "Cag System",
      CagPlayerRole.host => "Player(Host)",
      CagPlayerRole.moderator => "Player(Mod)",
      CagPlayerRole.player => "Player",
    };

    return Center(
      child: Dialog(
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Container(
              color: theme.colorScheme.primary,
              padding: const .all(20),
              alignment: .center,
              child: Text(
                "$playerLabel: ${player.name}",
                style: const TextStyle(
                  fontWeight: .w900,
                  fontSize: 24,
                ),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                "Score: ${player.score}",
                style: .new(
                  fontSize: 20,
                  color: theme.colorScheme.onSecondary,
                  fontWeight: .w900,
                ),
              ),
            ),
            if (player.played.isNotEmpty && player.played.any((card) => card.visible)) ...[
              const Divider(),
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: .horizontal,
                  children: player.played
                      .map(
                        (card) => ScaledDownSize(
                          perceivedSize: const .square(160),
                          actualSize: const .square(128),
                          child: CagResponseCardDisplay(card: card),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
            if (promptCard case Some(:final value) when canJudge) ...[
              const Divider(),
              Padding(
                padding: const .all(12),
                child: Text(FullFillPrompt.fromCards(value, player.played)),
              ),
            ],
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Visibility(
                visible: canJudge,
                maintainAnimation: true,
                maintainSize: true,
                maintainState: true,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(player.id);
                  },
                  child: const Text("Vote for this player"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _PlayerTile({
  required final bool isSelf,
  required final CagPlayer player,
  required final VoidCallback onViewPlayer,
  required final bool isJudge,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final playerIcon = Stack(
      clipBehavior: .none,
      children: [
        Icon(switch (player.role) {
          .host => Icons.computer,
          .player => Icons.person_3,
          .moderator => Icons.shield,
          .system => Icons.settings,
        }),
        Positioned.fill(
          left: -10,
          right: -10,
          bottom: -10,
          child: Align(
            alignment: .bottomCenter,
            child: Text(
              "${player.score}",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: .w700,
                shadows: [
                  .new(
                    color: theme.colorScheme.onPrimary,
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onViewPlayer,
      child: Container(
        padding: const .all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
        ),
        child: Column(
          crossAxisAlignment: .center,
          spacing: 12,
          children: [
            Row(
              spacing: 4,
              children: [
                playerIcon,
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: TextStyle(
                      fontWeight: isSelf ? .w900 : .w400,
                    ),
                  ),
                ),
                if (isJudge) ...[
                  const Icon(Icons.gavel),
                ],
              ],
            ),
            if (player.played.isNotEmpty) ...[
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: .horizontal,
                  children: player.played
                      .map(
                        (card) => ScaledDownSize(
                          perceivedSize: const .square(160),
                          actualSize: const .square(64),
                          child: CagResponseCardDisplay(card: card),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on CagGame {
  bool isJudge(CagIdentifier identifier) {
    if (currentJudge case Some(value: final id) when id == identifier) return true;
    return false;
  }
}
