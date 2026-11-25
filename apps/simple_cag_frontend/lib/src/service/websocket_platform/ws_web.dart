import "package:web_socket_channel/web_socket_channel.dart";

WebSocketChannel connectWebSocket({
  required Uri uri,
  required String allowedHost,
  required int allowedPort,
}) => // The browser enforces WebSocket TLS certificate validation.
    WebSocketChannel.connect(uri);
