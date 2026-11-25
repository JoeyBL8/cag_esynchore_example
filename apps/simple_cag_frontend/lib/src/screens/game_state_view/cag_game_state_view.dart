import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/screens/game_screen.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/game_state_notification.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/generic_player_controls.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/player_hand_visualization.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/player_sidebar.dart";
import "package:simple_cag_frontend/src/screens/game_state_view/winning_prompt.dart";
import "package:simple_cag_frontend/src/service/game_connection.dart";
import "package:simple_cag_frontend/src/widgets/cag_card.dart";

class const CagGameStateView({
  required final CagCredentials credentials,
  required final CagGameConnected connectedState,
  required final CagGame gameState,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final player = gameState.players.where((player) => player.id == credentials.playerIdentifier).firstOrNull;

    if (player == null) return const DisconnectedView();

    return _LoggedInPlayerView(
      credentials: credentials,
      connectedState: connectedState,
      gameState: gameState,
      myPlayer: player,
    );
  }
}

class const _LoggedInPlayerView({
  required final CagCredentials credentials,
  required final CagGameConnected connectedState,
  required final CagGame gameState,
  required final CagPlayer myPlayer,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedCards = useState(<CagIdentifier>[]);

    final canPlayCards = gameState.canPlayCards(myPlayer.id);

    useEffect(() {
      if (!canPlayCards) {
        selectedCards.value = [];
      }
      return null;
    }, [gameState.roundResults.length, gameState.stage]);

    final maxSelectableCards = gameState.currentPrompt.map((prompt) => prompt.picks).getOrElse(() => 0);

    void selectCard(CagResponseCard card) {
      if (selectedCards.value.contains(card.id)) {
        selectedCards.value = List.from(selectedCards.value)..remove(card.id);
      } else if (selectedCards.value.length < maxSelectableCards) {
        selectedCards.value = [
          ...selectedCards.value,
          card.id,
        ];
      }
    }

    final gameControls = Row(
      children: [
        Expanded(
          child: Padding(
            padding: const .all(24.0),
            child: Center(
              child: gameState.currentPrompt
                  .map(
                    (prompt) => CagPromptCardDisplay(card: prompt),
                  )
                  .toNullable(),
            ),
          ),
        ),
        SizedBox(
          width: 160,
          child: PlayerSidebar(
            credentials: credentials,
            connectedState: connectedState,
            gameState: gameState,
            player: myPlayer,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              gameControls,
              if (gameState.stage == .endOfRound) ...[
                Center(child: WinningPrompt(game: gameState)),
              ],
            ],
          ),
        ),
        const Divider(
          height: 4,
          thickness: 4,
        ),
        GameStateNotification(game: gameState, player: myPlayer),
        const Divider(
          height: 4,
          thickness: 4,
        ),
        GenericPlayerControls(
          credentials: credentials,
          connectedState: connectedState,
          gameState: gameState,
          player: myPlayer,
          selectedCards: selectedCards.value,
        ),
        SizedBox(
          height: 240,
          child: PlayerHandDisplay(
            selectedCards: selectedCards.value,
            hand: myPlayer.hand,
            onTapCard: switch (canPlayCards) {
              true => selectCard,
              false => null,
            },
          ),
        ),
      ],
    );
  }
}

extension on CagGame {
  bool canPlayCards(CagIdentifier identifier) {
    if (currentJudge case Some(value: final id) when id == identifier) return false;
    if (stage != .playCards) return false;

    return true;
  }
}
