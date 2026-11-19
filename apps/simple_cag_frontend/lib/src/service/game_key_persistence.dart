import "package:fpdart/fpdart.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

class GameKeyPersistence({
  required final SharedPreferences preferences,
}) {
  Task<Unit> saveName(String name) => .Do(($) async {
    await preferences.setString("name", name);
    return unit;
  });

  String getName() => preferences.getString("name") ?? "";

  Task<Unit> saveKey(String key) => .Do(($) async {
    await preferences.setString("key", key);
    return unit;
  });

  String getKey() => preferences.getString("key") ?? "";

  Task<Unit> persistCredentials(String gameId, String key, CagCredentials credentials) => .Do(($) async {
    final persistenceKey = "$gameId|$key";
    await preferences.setString(persistenceKey, credentials.playerIdentifier.id);
    return unit;
  });

  Option<CagCredentials> getCredentials(String gameId, String key) {
    final persistenceKey = "$gameId|$key";

    final identifier = preferences.getString(persistenceKey);

    if (identifier == null) return const None();

    return Some(CagCredentials(playerIdentifier: CagIdentifier(identifier), key: key));
  }

  Task<Unit> resetCredentials(String gameId, String key) => .Do(
    ($) async {
      final persistenceKey = "$gameId|$key";
      await preferences.remove(persistenceKey);
      return unit;
    },
  );
}
