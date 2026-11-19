import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/widgets/cag_card.dart";

class const PlayerHandDisplay({
  required final List<CagResponseCard> hand,
  required final List<CagIdentifier> selectedCards,
  required final ValueChanged<CagResponseCard>? onTapCard,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (hand.isEmpty) {
      return const _PlayerHandFrame(
        child: Center(
          child: Text(
            "Your hand is empty, wait for a new round to retrieve new cards",
            textAlign: .center,
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: onTapCard == null ? 0.3 : 1,
      child: _PlayerHandFrame(
        child: GridView.count(
          clipBehavior: .none,
          crossAxisCount: 1,
          scrollDirection: .horizontal,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: hand.map(
            (card) {
              final callback = Option.fromNullable(onTapCard)
                  .map(
                    (tappable) =>
                        () => tappable(card),
                  )
                  .toNullable();
      
              return CagResponseCardDisplay(
                card: card,
                onTap: callback,
                selected: selectedCards.contains(card.id),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}

class const _PlayerHandFrame({
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        border: .all(
          color: theme.colorScheme.primary,
          width: 4,
        ),
      ),
      child: Padding(
        padding: const .all(4),
        child: ClipRect(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
