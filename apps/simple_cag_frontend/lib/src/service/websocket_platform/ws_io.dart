import "dart:io";

import "package:web_socket_channel/io.dart";

IOWebSocketChannel connectWebSocket({
  required Uri uri,
  required String allowedHost,
  required int allowedPort,
}) {
  final client = HttpClient()
    ..badCertificateCallback = (certificate, host, port) => host == allowedHost && port == allowedPort;

  return IOWebSocketChannel.connect(
    uri,
    customClient: client,
  );
}
