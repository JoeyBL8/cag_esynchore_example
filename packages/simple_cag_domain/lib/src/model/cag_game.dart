import "dart:math";

import "package:fpdart/fpdart.dart";
import "package:uuid/uuid.dart";

// 1. Players get a filled hand
// 2. The judge is selected
// 3. The judge reveals a prompt
// 4. The players play card(s)
// 5. The judge votes for best answer
// 6. The judge moves to the next round

// Edge cases:
// Players who have not played any cards cannot be voted for.
// Players can only play their cards once, they cannot cancel them.
// If a player disconnects, they remain in the game but dormant.
// If a judge disconnects, the round is skipped and the judge is marked as dormant.
// The judge has 90 seconds for each of their actions, refreshed every time there is a state update.

enum GameStage {
  playCards,
  voteBestOption,
  endOfRound,
}

class const CagGame({
  required final CagIdentifier id,
  required final GameStage stage,
  required final List<CagPlayer> _players,
  required final List<CagResponseCard> _responseCardDeck,
  required final List<CagResponseCard> _playedResponseCards,
  required final List<CagPromptCard> _promptCardDeck,
  required final List<CagRoundResult> _roundResults,
  required final Option<CagPromptCard> currentPrompt,
  required final Option<CagIdentifier> currentJudge,
}) {
  List<CagPlayer> get players => .unmodifiable(_players);
  List<CagResponseCard> get responseCardDeck => .unmodifiable(_responseCardDeck);
  List<CagResponseCard> get playedResponseCards => .unmodifiable(_playedResponseCards);
  List<CagPromptCard> get promptCardDeck => .unmodifiable(_promptCardDeck);
  List<CagRoundResult> get roundResults => .unmodifiable(_roundResults);
}

enum CagPlayerRole {
  /// Never given to a player, can be used by the system at any point
  system,

  /// Cannot be kicked, unless they lose connection. Next player in list should take this role, has same rights as moderator
  host,

  /// Can kick players
  moderator,

  /// No rights
  player,
}

enum PlayerActivityStatus {
  active,
  disconnected,
  stale,
  kicked,
}

class const CagPlayer({
  required final CagIdentifier id,
  required final String name,
  required final List<CagResponseCard> _hand,
  required final List<CagResponseCard> _played,
  required final int score,
  required final CagPlayerRole role,
  required final PlayerActivityStatus status,

  /// a way to manipulate turn order so it is not based on first joined
  required final int turnOrderIdentifier,
}) {
  factory CagPlayer.fresh(String playerName, [CagPlayerRole? role]) => CagPlayer(
    id: .create(),
    name: playerName,
    hand: const [],
    played: const [],
    score: 0,
    role: role ?? .player,
    turnOrderIdentifier: Random().nextInt(9999),
    status: .active,
  );

  List<CagResponseCard> get hand => .unmodifiable(_hand);
  List<CagResponseCard> get played => .unmodifiable(_played);
}

class const CagResponseCard({
  required final CagIdentifier id,
  required final String text,
  required final bool visible,
});

class const CagPromptCard({
  required final CagIdentifier id,
  required final String prompt,
  required final int picks,
  required final bool visible,
});

class const CagRoundResult({
  required final List<CagResponseCard> _winningResponses,
  required final CagPromptCard relatedPrompt,
  required final CagIdentifier playerIdentifier,
}) {
  List<CagResponseCard> get winningResponses => .unmodifiable(_winningResponses);
}

extension type CagIdentifier(String id) {
  CagIdentifier.create() : id = const Uuid().v6();
}
