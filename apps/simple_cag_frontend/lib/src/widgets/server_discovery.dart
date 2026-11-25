// lib/server_discovery.dart
export "server_discovery/common.dart" show JoinGameAction;
export "server_discovery/server_discovery_basic.dart" if (dart.library.io) "server_discovery/server_discovery_io.dart";
