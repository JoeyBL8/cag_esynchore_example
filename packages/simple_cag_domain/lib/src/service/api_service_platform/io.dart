import "dart:io";

import "package:http/http.dart" as http;
import "package:http/io_client.dart";

http.Client createApiClient({
  required String allowedHost,
  required int allowedPort,
}) {
  final ioClient = HttpClient()
    ..badCertificateCallback = (certificate, host, port) => host == allowedHost && port == allowedPort;

  return IOClient(ioClient);
}
