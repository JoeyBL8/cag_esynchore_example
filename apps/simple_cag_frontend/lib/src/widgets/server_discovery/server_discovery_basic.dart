import "package:material_ui/material_ui.dart";
import "package:simple_cag_frontend/src/widgets/server_discovery/common.dart";

class ServerDiscovery extends StatefulWidget {
  const ServerDiscovery({
    required this.onJoinGame,
    required this.onCreateGame,
    super.key,
  });

  final ValueChanged<JoinGameAction> onJoinGame;
  final Future<void> Function(Uri host) onCreateGame;

  @override
  State<ServerDiscovery> createState() => _ServerDiscoveryState();
}

class _ServerDiscoveryState extends State<ServerDiscovery> {
  final _controller = TextEditingController();
  Uri? _host;
  String? _error;

  void _connect() {
    final input = _controller.text.trim();
    final uri = Uri.tryParse(
      input.contains("://") ? input : "http://$input",
    );

    if (uri == null || uri.host.isEmpty || uri.port == 0 || (uri.scheme != "http" && uri.scheme != "https")) {
      setState(() {
        _host = null;
        _error = "Enter a valid address, such as 192.168.1.20:43234";
      });
      return;
    }

    setState(() {
      _host = uri;
      _error = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: "Server address",
          hintText: "192.168.1.20:43234",
          errorText: _error,
        ),
        onSubmitted: (_) => _connect(),
      ),
      FilledButton(
        onPressed: _connect,
        child: const Text("Connect"),
      ),
      if (_host case final host?)
        Expanded(
          child: GameListWidget(
            address: host,
            onCreateGame: () => widget.onCreateGame(host),
            onJoinGame: (game) => widget.onJoinGame(
              JoinGameAction(gameId: game.id, host: host),
            ),
          ),
        ),
    ],
  );
}
