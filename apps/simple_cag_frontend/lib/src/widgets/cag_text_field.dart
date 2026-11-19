import "package:fpdart/fpdart.dart";
import "package:material_ui/material_ui.dart";

class const CagInputField({
  final TextEditingController? controller,
  final VoidCallback? onSubmit,
  final String? hint,
  final IconData? icon,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      TextField(
        controller: controller,
        decoration: .new(
          hint: Option.fromNullable(hint)
              .map((hint) => Center(child: Opacity(opacity: 0.5, child: Text(hint))))
              .toNullable(),
        ),
        textAlignVertical: const .new(y: -0.2),
        textAlign: .center,
      ),
      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        child: Center(
          child: Opacity(
            opacity: onSubmit == null ? 0 : 1,
            child: IconButton(onPressed: onSubmit, icon: Icon(icon ?? Icons.play_arrow), padding: .zero),
          ),
        ),
      ),
    ],
  );
}
