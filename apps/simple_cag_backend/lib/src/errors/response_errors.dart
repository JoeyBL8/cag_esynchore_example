import "dart:convert";

import "package:fpdart/fpdart.dart";
import "package:shelf/shelf.dart";
import "package:simple_cag_backend/src/config/request.dart";

sealed class RequestFailure();

final class InvalidRequestBodyFormatFailure({
  required final Map<String, dynamic> details,
}) extends RequestFailure;

final class TargetResourceNotFoundFailure({
  required final String target,
  required final String identifier,
}) extends RequestFailure;

final class ServerFailure({
  required final String message,
  final String code = "generic_failure",
}) extends RequestFailure;

Response handleResponseFailure<T>(
  Either<RequestFailure, T> result, {
  required Map<String, dynamic> Function(T) onSuccess,
}) => switch (result) {
  Right(:final T value) => Response.ok(
    headers: jsonDefaultHeaders,
    jsonEncode(onSuccess(value)),
  ),
  Left(value: final RequestFailure failure) => switch (failure) {
    InvalidRequestBodyFormatFailure failure => .badRequest(
      headers: jsonDefaultHeaders,
      body: jsonEncode({"message": "Failed to parse request", "details": failure.details}),
    ),
    TargetResourceNotFoundFailure failure => .notFound(
      headers: jsonDefaultHeaders,
      jsonEncode({
        "message": "Failed to find the specified resource",
        "details": {
          "resourceType": failure.target,
          "resourceIdentifier": failure.identifier,
        },
      }),
    ),
    ServerFailure failure => .internalServerError(
      headers: jsonDefaultHeaders,
      body: jsonEncode({
        "message": "An error occurred on the server whilst handling your request",
        "details": {
          "code": failure.message,
          "message": failure.message,
        },
      }),
    ),
  },
};
