import "dart:io";

import "package:shelf/shelf_io.dart" as shelf_io;
import "package:simple_cag_backend/src/router.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class ServerSubscription({
  required final HttpServer _server,
}) {
  int get port => _server.port;

  Uri get uri => Uri.http("${_server.address.host}:$port");

  Future<void> dispose() => _server.close();
}

Future<ServerSubscription> openServer({
  required CagSessionService sessionService,
  required CagGameSerializer serializer,
  required CagSetProvider setProvider,
  int? port,
}) async {
  final stateSerializer = CagGameSerializer();

  final router = createRouter(
    setProvider: setProvider,
    sessionService: sessionService,
    gameSerializer: stateSerializer,
  );

  final rootHandler = createPipeline(router: router);

  final server = await shelf_io.serve(
    rootHandler,
    InternetAddress.anyIPv4,
    port ?? 43234,
  );

  return ServerSubscription(server: server);
}
