import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class const WinningPrompt({
  required final CagGame game,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = game.roundResults.lastOption;

    final playerName = result
        .flatMap((result) => game.players.where((player) => player.id == result.playerIdentifier).firstOption)
        .map((player) => player.name)
        .getOrElse(() => "Unknown");

    final actualResult = result.toNullable();
    if (actualResult == null) return const SizedBox.shrink();

    final promptText = actualResult.getFullfilledPrompt();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
      ),
      padding: const .all(20),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        spacing: 8,
        children: [
          const Text(
            "Winner!",
            textAlign: .center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: .w700,
            ),
          ),
          Text(
            playerName,
            textAlign: .center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: .w900,
            ),
          ),
          Text(
            promptText,
            textAlign: .center,
          ),
        ],
      ),
    );
  }
}

extension on CagRoundResult {
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
