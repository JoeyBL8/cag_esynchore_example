import "package:material_ui/material_ui.dart";
import "package:simple_cag_frontend/main.dart";
import "package:simple_cag_frontend/src/widgets/server_discovery/common.dart";
import "package:url_launcher/url_launcher.dart";

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
  final _controller = TextEditingController(text: globalPersistence.preferences.getString("web_last_host"));
  Uri? _host;
  String? _error;

  Future<void> _connect() async {
    final input = _controller.text.trim();
    final uri = Uri.tryParse(
      input.contains("://") ? input : "https://$input",
    );

    if (uri == null || uri.host.isEmpty || uri.port == 0 || (uri.scheme != "http" && uri.scheme != "https")) {
      setState(() {
        _host = null;
        _error = "Enter a valid address, such as 192.168.1.20:43234";
      });
      return;
    }

    await globalPersistence.preferences.setString("web_last_host", uri.toString());

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
    spacing: 20,
    children: [
      TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: "192.168.1.20:43234",
          alignLabelWithHint: true,
          errorText: _error,
        ),
        textAlign: .center,
        onSubmitted: (_) => _connect(),
      ),
      Center(
        child: FilledButton(
          onPressed: _connect,
          child: const Text("Connect"),
        ),
      ),
      if (_host case final host?) ...[
        Padding(
          padding: const .symmetric(horizontal: 40),
          child: ExpansionTile(
            dense: true,
            title: const Text("Info for browsers!"),
            children: [
              const SizedBox(height: 8),
              const Text(
                "We used self-signed certificates for our servers. "
                "Most browsers don't trust these, but there is a workaround. "
                "Open the url of the server in a separate tab and then make sure to proceed past the security check "
                "and accept the prompts regarding server security. "
                "Then you can close that tab.",
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await launchUrl(host);
                },
                child: const Text("Open server in new browser window"),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: GameListWidget(
              address: host,
              onCreateGame: () => widget.onCreateGame(host),
              onJoinGame: (game) => widget.onJoinGame(
                JoinGameAction(gameId: game.id, host: host),
              ),
            ),
          ),
        ),
      ],
    ],
  );
}
