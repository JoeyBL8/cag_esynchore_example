import "dart:convert";
import "dart:io";

import "package:basic_utils/basic_utils.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:material_ui/material_ui.dart";
import "package:network_discovery/network_discovery.dart";
import "package:simple_cag_backend/simple_cag_backend.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/widgets/show_error.dart";

SecurityContext createSelfSignedSecurityContext(String lanIp) {
  final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
  final privateKey = pair.privateKey as RSAPrivateKey;
  final publicKey = pair.publicKey as RSAPublicKey;

  final csr = X509Utils.generateRsaCsrPem(
    {"CN": lanIp},
    privateKey,
    publicKey,
    san: [lanIp],
  );

  final certificate = X509Utils.generateSelfSignedCertificate(
    privateKey,
    csr,
    365,
    sans: [lanIp],
    serialNumber: DateTime.now().microsecondsSinceEpoch.toString(),
  );

  final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

  return SecurityContext()
    ..useCertificateChainBytes(utf8.encode(certificate))
    ..usePrivateKeyBytes(utf8.encode(privateKeyPem));
}

ServerSubscription? _server;
const _defaultCagProvisionUrl =
    "https://github.com/crhallberg/json-against-humanity/raw/refs/heads/latest/cah-all-full.json";

Future<void> _stopServer() async {
  await _server?.dispose();
  _server = null;
}

Future<void> _createServer() async {
  final setProvider = RemoteCaHJsonResourceSetProvider(setUrl: Uri.parse(_defaultCagProvisionUrl));
  final sessions = CagSessionService(setProvider: setProvider);

  final stateSerializer = CagGameSerializer();

  final address = await NetworkDiscovery.discoverDeviceIpAddress();

  _server = await openServer(
    setProvider: setProvider,
    serializer: stateSerializer,
    sessionService: sessions,
    securityContext: switch (address) {
      null => null,
      String address => createSelfSignedSecurityContext(address),
    },
  );
}

class const ServerManager({super.key}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final server = useState(_server);

    Future<void> startServer() async {
      try {
        await _createServer();
      } on Object catch (e) {
        if (context.mounted) {
          context.showError("Failed to start server: $e");
        }
      }
      server.value = _server;
    }

    Future<void> stopServer() async {
      await _stopServer();
      server.value = _server;
    }

    final serverContent = switch (server.value) {
      null => Row(
        children: [
          const Expanded(child: Text("No server running")),
          FilledButton(
            onPressed: startServer,
            child: const Text("Start Server"),
          ),
        ],
      ),
      ServerSubscription server => Row(
        spacing: 8,
        children: [
          Expanded(child: Text("Server running on ${server.uri}")),
          FilledButton(
            onPressed: stopServer,
            child: const Text("Stop server"),
          ),
        ],
      ),
    };

    final theme = Theme.of(context);

    return Container(
      margin: const .all(20),
      padding: const .all(8),
      decoration: BoxDecoration(
        border: .all(
          width: 2,
          color: theme.colorScheme.onSecondary,
        ),
        color: theme.colorScheme.secondary,
      ),
      child: serverContent,
    );
  }
}
