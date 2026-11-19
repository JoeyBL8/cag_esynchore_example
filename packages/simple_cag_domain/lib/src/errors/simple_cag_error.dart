import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:meta/meta.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

final class const SimpleCagFailure({
  required final String errorMessage,
}) {
  static const esynchoreErrorCode = "command_failed_to_apply";
}

extension CagFailureToEsynchore<T> on Either<SimpleCagFailure, T> {
  @useResult
  Either<ApplicationError, T> toEsynchore() =>
      mapLeft((error) => ApplicationError(SimpleCagFailure.esynchoreErrorCode, error.errorMessage));

  TaskEither<ApplicationError, T> toEsynchoreTask() =>
      mapLeft((error) => ApplicationError(SimpleCagFailure.esynchoreErrorCode, error.errorMessage)).toTaskEither();

  @useResult
  Either<E, T> toEsynchoreOf<E extends EsynchoreError>(CagEsynchoreErrorCodes<E> code) =>
      mapLeft((_) => code.getError());
}
