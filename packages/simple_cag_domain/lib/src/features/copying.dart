import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/src/model/cag_game.dart";

extension CopyCagGame on CagGame {
  CagGame copyWith({
    List<CagPlayer>? players,
    GameStage? stage,
    List<CagResponseCard>? responseCardDeck,
    List<CagResponseCard>? playedResponseCards,
    List<CagPromptCard>? promptCardDeck,
    List<CagRoundResult>? roundResults,
    Option<CagPromptCard>? currentPrompt,
    Option<CagIdentifier>? currentJudge,
  }) => CagGame(
    id: id,
    stage: stage ?? this.stage,
    players: players ?? this.players,
    responseCardDeck: responseCardDeck ?? this.responseCardDeck,
    playedResponseCards: playedResponseCards ?? this.playedResponseCards,
    promptCardDeck: promptCardDeck ?? this.promptCardDeck,
    roundResults: roundResults ?? this.roundResults,
    currentPrompt: currentPrompt ?? this.currentPrompt,
    currentJudge: currentJudge ?? this.currentJudge,
  );
}

extension CopyCagPlayer on CagPlayer {
  CagPlayer copyWith({
    String? name,
    List<CagResponseCard>? hand,
    List<CagResponseCard>? played,
    int? turnOrderIdentifier,
    int? score,
    CagPlayerRole? role,
    PlayerActivityStatus? status,
  }) => CagPlayer(
    id: id,
    status: status ?? this.status,
    name: name ?? this.name,
    hand: hand ?? this.hand,
    played: played ?? this.played,
    score: score ?? this.score,
    role: role ?? this.role,
    turnOrderIdentifier: turnOrderIdentifier ?? this.turnOrderIdentifier,
  );
}

extension CopyCagResponseCard on CagResponseCard {
  CagResponseCard copyWith({
    bool? visible,
    String? text,
  }) => CagResponseCard(
    id: id,
    text: text ?? this.text,
    visible: visible ?? this.visible,
  );
}

extension CopyCagPromptCard on CagPromptCard {
  CagPromptCard copyWith({
    bool? visible,
    String? prompt,
  }) => CagPromptCard(
    id: id,
    prompt: prompt ?? this.prompt,
    picks: picks,
    visible: visible ?? this.visible,
  );
}
