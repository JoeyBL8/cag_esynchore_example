import "package:shelf/shelf.dart";

Middleware corsMiddleware() {
  const headers = {
    "access-control-allow-origin": "*",
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "authorization, content-type",
  };
  return (handler) => (request) async {
    if (request.method == "OPTIONS") {
      return Response(204, headers: headers);
    }
    final response = await handler(request);
    return response.change(headers: headers);
  };
}
