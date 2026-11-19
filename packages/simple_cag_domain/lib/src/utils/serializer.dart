import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:fpdart/fpdart.dart";

extension Deserialization<T> on Serializer<T> {
  T deserialize() {
    final data = this.data;
    if (data == null) throw StateError("Cannot deserialize if no data was bound");
    return fromMap(data);
  }
}

extension FpDartSerializer<T> on Serializer<T> {
  Either<ValidationException, bool> fValidate() =>
      .tryCatch(() => validate(raiseException: true), (error, _) => error as ValidationException);

  Either<ValidationException, T> fDeserializeValidated() => fValidate().map((_) => deserialize());
}
