import "package:flutter/widgets.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:simple_cag_frontend/src/app.dart";
import "package:simple_cag_frontend/src/service/game_key_persistence.dart";

late final GameKeyPersistence globalPersistence;

void main(List<String> args) async {
  final preferences = await SharedPreferences.getInstance();
  globalPersistence = GameKeyPersistence(preferences: preferences);
  runApp(const CagApp());
}
