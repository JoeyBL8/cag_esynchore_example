import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:simple_cag_frontend/src/screens/game_screen.dart";
import "package:simple_cag_frontend/src/screens/login_screen.dart";
import "package:simple_cag_frontend/src/screens/screen_state.dart";
import "package:simple_cag_frontend/src/screens/select_server_screen.dart";

class const CagScreen({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final currentState = useState<CagScreenState>(const InitialCagScreenState());

    void updateState(CagScreenState state) {
      currentState.value = state;
    }

    return Scaffold(
      body: SafeArea(
        child: switch (currentState.value) {
          InitialCagScreenState state => LoginScreen(state: state, onStateChanged: updateState),
          SelectServerCagScreenState state => SelectServerScreen(state: state, onStateChanged: updateState),
          GameCagScreenState state => GameScreen(state: state, onStateChanged: updateState),
        },
      ),
    );
  }
}
