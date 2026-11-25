import "package:simple_cag_domain/simple_cag_domain.dart";

extension FullFillPrompt on CagRoundResult {
  static String fromCards(CagPromptCard card, List<CagResponseCard> responseCards) => CagRoundResult(
    winningResponses: responseCards,
    relatedPrompt: card,
    playerIdentifier: .create(),
  ).getFullfilledPrompt();

  String getFullfilledPrompt() {
    final prompt = relatedPrompt.prompt;
    final combined = prompt
        .split(RegExp(r"\s?_\s?\.?\s?"))
        .combineWith(winningResponses.map((response) => response.text))
        .map((element) => element.trim());
    return combined.join(" ");
  }
}

extension Interleave<T> on Iterable<T> {
  Iterable<T> combineWith(Iterable<T> other) sync* {
    final a = iterator;
    final b = other.iterator;

    while (true) {
      final hasA = a.moveNext();
      final hasB = b.moveNext();

      if (!hasA && !hasB) return;
      if (hasA) yield a.current;
      if (hasB) yield b.current;
    }
  }
}
