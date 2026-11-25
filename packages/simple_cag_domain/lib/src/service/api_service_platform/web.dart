import "package:http/http.dart" as http;

http.Client createApiClient({
  required String allowedHost,
  required int allowedPort,
}) => // The browser enforces TLS certificate validation.
    http.Client();
