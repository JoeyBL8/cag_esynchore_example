import "package:material_ui/material_ui.dart";

class const ScaledDownSize({
  required final Size perceivedSize,
  required final Size actualSize,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: actualSize,
    child: FittedBox(
      fit: .contain,
      child: SizedBox.fromSize(
        size: perceivedSize,
        child: child,
      ),
    ),
  );
}
