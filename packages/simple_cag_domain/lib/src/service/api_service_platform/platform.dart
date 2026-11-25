import "package:http/http.dart" as http;

// ignore: always_use_package_imports
import "web.dart" if (dart.library.io) "io.dart" as platform;

http.Client createApiClient({
  required String allowedHost,
  required int allowedPort,
}) => platform.createApiClient(
  allowedHost: allowedHost,
  allowedPort: allowedPort,
);
