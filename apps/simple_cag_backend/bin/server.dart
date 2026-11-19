import "dart:io";

import "package:simple_cag_backend/simple_cag_backend.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

const _defaultCagProvisionUrl =
    "https://github.com/crhallberg/json-against-humanity/raw/refs/heads/latest/cah-all-full.json";

Future<void> main(List<String> args) async {
  final setProvider = RemoteCaHJsonResourceSetProvider(
    setUrl: Uri.parse(Platform.environment["CAG_SET_SOURCE"] ?? args.elementAtOrNull(1) ?? _defaultCagProvisionUrl),
  );
  final sessions = CagSessionService(
    setProvider: setProvider,
  );

  final stateSerializer = CagGameSerializer();

  final server = await openServer(
    setProvider: setProvider,
    serializer: stateSerializer,
    sessionService: sessions,
    port: int.tryParse(args.elementAtOrNull(0) ?? ""),
  );

  stdout.writeln("Listening on http://localhost:${server.port}");
}
