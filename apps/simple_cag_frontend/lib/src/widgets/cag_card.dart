import "package:material_ui/material_ui.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class const CagResponseCardDisplay({
  required final CagResponseCard card,
  final bool selected = false,
  final VoidCallback? onTap,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final visibleContent = Align(
      alignment: .topLeft,
      child: Text(
        card.text,
        style: .new(
          color: theme.colorScheme.primary,
          fontWeight: switch (selected) {
            true => .w900,
            false => .w600,
          },
        ),
      ),
    );
    final invisibleContent = Padding(
      padding: const .all(8),
      child: FittedBox(
        fit: .fitHeight,
        child: Text(
          "CAG",
          style: TextStyle(color: theme.colorScheme.primary, fontWeight: .w900),
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: 1,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const .all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            border: .all(width: selected ? 4 : 2, color: theme.colorScheme.primary),
            boxShadow: [.new(color: theme.colorScheme.primary, blurRadius: 1)],
          ),
          child: card.visible ? visibleContent : invisibleContent,
        ),
      ),
    );
  }
}

class const CagPromptCardDisplay({
  required final CagPromptCard card,
  final List<CagResponseCard> playedCards = const [],
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final invisibleContent = Padding(
      padding: const .all(8),
      child: FittedBox(
        fit: .fitHeight,
        child: Text(
          "CAG",
          style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: .w900),
        ),
      ),
    );

    final visibleContent = Align(
      alignment: .topLeft,
      child: Text(
        card.prompt.replaceAll("_", "___"),
        style: .new(color: theme.colorScheme.onPrimary, fontWeight: .w900),
      ),
    );

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const .all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          border: .all(width: 2, color: theme.colorScheme.onPrimary),
          boxShadow: [.new(color: theme.colorScheme.primary, blurRadius: 1)],
        ),
        child: card.visible ? visibleContent : invisibleContent,
      ),
    );
  }
}
