import "package:web_socket_channel/web_socket_channel.dart";

// ignore: always_use_package_imports
import "ws_web.dart" if (dart.library.io) "ws_io.dart" as platform;

WebSocketChannel connectWebSocket({
  required Uri uri,
  required String allowedHost,
  required int allowedPort,
}) => platform.connectWebSocket(
  uri: uri,
  allowedHost: allowedHost,
  allowedPort: allowedPort,
);
