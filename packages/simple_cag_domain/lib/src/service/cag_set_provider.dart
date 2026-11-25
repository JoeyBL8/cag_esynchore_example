import "dart:convert";

import "package:fpdart/fpdart.dart";
import "package:http/http.dart" as http;
import "package:simple_cag_domain/simple_cag_domain.dart";

final class const CagSetFailure();

abstract interface class CagSetProvider {
  TaskEither<CagSetFailure, List<String>> getCagSetIdentifiers();
  TaskEither<CagSetFailure, CagSet> getCagSet(String identifier);
}

class CagSet({
  required final String id,
  required final String name,
  required final List<CagResponseCard> responseCards,
  required final List<CagPromptCard> promptCards,
});

class RemoteCaHJsonResourceSetProvider({
  required final Uri setUrl,
}) implements CagSetProvider {
  List<CagSet>? _cachedCagSets;

  TaskEither<CagSetFailure, List<CagSet>> loadInitialData() => .Do(($) async {
    if (_cachedCagSets != null) return _cachedCagSets!;

    final result = await $(.tryCatch(() => http.get(setUrl), (_, _) => const CagSetFailure()));

    final list = await $(.tryCatch(() async => jsonDecode(result.body), (_, _) => const CagSetFailure()));

    if (list is! List<dynamic>) await $(.left(const CagSetFailure()));

    return _cachedCagSets = [
      for (final set in list) ...[
        if (set case {
          "name": final String name,
          "white": final List<dynamic> white,
          "black": final List<dynamic> black,
        }) ...[
          CagSet(
            id: name,
            name: name,
            responseCards: [
              for (final card in white) ...[
                if (card case {"text": final String text}) ...[
                  CagResponseCard(id: .create(), text: text, visible: false),
                ],
              ],
            ],
            promptCards: [
              for (final card in black) ...[
                if (card case {"text": final String text, "pick": final int picks}) ...[
                  CagPromptCard(id: .create(), prompt: text, visible: false, picks: picks),
                ],
              ],
            ],
          ),
        ],
      ],
    ];
  });

  @override
  TaskEither<CagSetFailure, CagSet> getCagSet(String identifier) => .Do(($) async {
    final sets = await $(loadInitialData());

    return $(.fromOption(sets.where((set) => set.id == identifier).firstOption, () => const CagSetFailure()));
  });

  @override
  TaskEither<CagSetFailure, List<String>> getCagSetIdentifiers() => .Do(($) async {
    final sets = await $(loadInitialData());

    return sets.map((set) => set.id).toList();
  });
}
