import "package:bcrypt/bcrypt.dart";
import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:esynchore_core/esynchore_core.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_domain/src/utils/fpdart.dart";

typedef SerializableCredentials = Either<CagSerializationFailure, CagCredentials>;

class CagCredentials({
  required final CagIdentifier playerIdentifier,
  required final String key,
}) {
  static Serializer<SerializableCredentials> get serializer => _credentialSerializer;
}

final _credentialSerializer = Serializer<SerializableCredentials>(
  fromMap: (Map<String, dynamic> map) => switch (map) {
    {"playerIdentifier": final String identifier, "key": final String key} => Success(
      CagCredentials(key: key, playerIdentifier: CagIdentifier(identifier)),
    ),
    _ => const Failure(CagSerializationFailure(message: "Credentials do not match the correct pattern")),
  },
  toMap: (credentials) => credentials
      .map(
        (credentials) => {"playerIdentifier": credentials.playerIdentifier, "key": credentials.key},
      )
      .getOrElse((_) => {}),
);

class CagAuthPrincipal({
  required final CagIdentifier playerIdentifier,
  required final CagPlayerRole role,
  required final String key,
  required final String sessionId,
});

extension type AuthCredentialsSubscription(Map<CagIdentifier, CagAuthPrincipal> _principals) {
  Either<ApplicationError, Unit> addPrincipal(CagAuthPrincipal principal) {
    if (_principals.containsKey(principal.playerIdentifier))
      return Failure(CagEsynchoreErrorCodes.playerRegistrationFailed.getError());

    _principals[principal.playerIdentifier] = principal;

    return const Success(unit);
  }

  TaskEither<AuthenticationError, CagAuthPrincipal> verifyPrincipal(
    CagGame state,
    SerializableCredentials credentials,
  ) => .Do(($) async {
    const error = CagEsynchoreErrorCodes.authenticationFailed;
    final validatedCredentials = await $(.fromEither(credentials).mapLeft((_) => error.getError()));
    final principal = await $(
      .fromNullable(_principals[validatedCredentials.playerIdentifier], () => error.getError()),
    );
    if (!BCrypt.checkpw(validatedCredentials.key, principal.key)) await $(.left(error.getError()));

    return principal;
  });

  void removeCredential(CagAuthPrincipal principal) {
    _principals.remove(principal.playerIdentifier);
  }
}
