import "dart:async";
import "dart:convert";

import "package:esynchore_core/esynchore_core.dart";
import "package:esynchore_flutter/esynchore_flutter.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";
import "package:simple_cag_frontend/src/screens/screen_state.dart";
import "package:web_socket_channel/web_socket_channel.dart";

typedef SerializableCredentials = Either<CagSerializationFailure, CagCredentials>;

sealed class const CagGameConnectionState(
  final CagGameConnectionController controller,
);

final class const CagGameDisconnected(
  super.controller,
) extends CagGameConnectionState;

final class const CagGameConnecting(
  super.controller,
) extends CagGameConnectionState;

final class CagGameConnected({
  required CagGameConnectionController controller,
  required final Either<String, CagGame> gameState,
  required final HttpCommandClient<CagCredentials, CagCommand> _commandClient,
  required final CagCredentials _credentials,
}) extends CagGameConnectionState {
  this : super(controller);

  Future<Either<ErrorMessage, Unit>> sendCommand(CagCommand command) async =>
      _commandClient.submit(command, _credentials);
}

final class const CagGameConnectionFailed({
  required CagGameConnectionController controller,
  required final CagConnectionFailure error,
}) extends CagGameConnectionState {
  this : super(controller);
}

final class CagGameConnectionController {
  Future<void> Function()? _reconnect;
  Future<void> Function()? _disconnect;

  Future<void> reconnect() async {
    await _reconnect?.call();
  }

  Future<void> disconnect() async {
    await _disconnect?.call();
  }
}

sealed class const CagConnectionFailure();

final class const EsynchoreConnectionFailure({
  required final ErrorMessage message,
}) extends CagConnectionFailure;

final class const UnknownConnectionFailure() extends CagConnectionFailure;

CagGameConnectionState useCagGameConnection(
  GameCagScreenState screenState,
) {
  final controller = useMemoized(CagGameConnectionController.new);
  final state = useState<CagGameConnectionState>(
    CagGameDisconnected(controller),
  );

  useEffect(
    () {
      var active = true;
      var connecting = false;

      WebSocketProtocolConnection? connection;
      ProtocolClient<SerializableCredentials, CagProjection>? client;
      HttpCommandClient<CagCredentials, CagCommand>? commandClient;

      void setState(CagGameConnectionState nextState) {
        if (active) state.value = nextState;
      }

      Future<void> disconnect() async {
        final oldConnection = connection;
        final oldClient = client;
        final oldCommandClient = commandClient;

        connection = null;
        client = null;
        commandClient = null;

        oldCommandClient?.close();
        await oldConnection?.close();
        await oldClient?.close();

        setState(CagGameDisconnected(controller));
      }

      Future<void> connect() async {
        if (!active || connecting) return;
        connecting = true;

        final oldConnection = connection;
        final oldClient = client;
        final oldCommandClient = commandClient;

        connection = null;
        client = null;
        commandClient = null;

        oldCommandClient?.close();
        await oldConnection?.close();
        await oldClient?.close();

        if (!active) {
          connecting = false;
          return;
        }

        setState(CagGameConnecting(controller));

        final nextClient = ProtocolClient<SerializableCredentials, CagProjection>(
          credentialsSerializer: CagCredentials.serializer,
          stateSerializer: CagGameSerializer().serializer,
        );

        HttpCommandClient<CagCredentials, CagCommand>? nextCommandClient;

        try {
          final credentials = screenState.credentials;

          nextCommandClient = HttpCommandClient<CagCredentials, CagCommand>(
            endpoint: _gameEndpoint(
              screenState.serverUri,
              screenState.gameId,
              "commands",
            ),
            commandSerializer: cagCommandSerializer,
            headersForCredentials: (credentials) => {
              "authorization": jsonEncode(
                CagCredentials.serializer.toMap(Right(credentials)),
              ),
            },
          );

          final websocketUri = _webSocketUri(
            _gameEndpoint(
              screenState.serverUri,
              screenState.gameId,
              "states",
            ),
          );

          final channel = WebSocketChannel.connect(websocketUri);

          final nextConnection = WebSocketProtocolConnection.client(channel, nextClient);

          client = nextClient;
          connection = nextConnection;
          commandClient = nextCommandClient;

          nextClient.stateChanges.listen((projection) {
            if (!active || !identical(connection, nextConnection)) return;

            setState(
              CagGameConnected(
                controller: controller,
                gameState: Right(projection.game),
                commandClient: nextCommandClient!,
                credentials: credentials,
              ),
            );
          });

          nextClient.errors.listen((error) {
            if (!active || !identical(connection, nextConnection)) return;

            setState(
              CagGameConnectionFailed(
                controller: controller,
                error: EsynchoreConnectionFailure(message: error),
              ),
            );
          });

          unawaited(
            nextConnection.done.then((_) {
              if (!active || !identical(connection, nextConnection)) return;

              connection = null;
              commandClient?.close();
              commandClient = null;

              setState(CagGameDisconnected(controller));
            }),
          );

          await channel.ready;
          if (!active) return;

          final result = await nextClient.authenticate(
            Right<CagSerializationFailure, CagCredentials>(credentials),
          );

          if (!active) return;

          result.match(
            (error) {
              if (!identical(connection, nextConnection)) return;

              connection = null;
              commandClient?.close();
              commandClient = null;

              setState(
                CagGameConnectionFailed(
                  controller: controller,
                  error: EsynchoreConnectionFailure(message: error),
                ),
              );

              unawaited(nextConnection.close());
            },
            (_) {
              // The game state arrives through stateChanges.
            },
          );
        } on Object {
          nextCommandClient?.close();

          final failedConnection = connection;
          connection = null;
          commandClient = null;

          if (failedConnection != null) {
            await failedConnection.close();
          } else {
            await nextClient.close();
          }

          setState(
            CagGameConnectionFailed(
              controller: controller,
              error: const UnknownConnectionFailure(),
            ),
          );
        } finally {
          connecting = false;
        }
      }

      controller
        .._reconnect = connect
        .._disconnect = disconnect;

      unawaited(connect());

      return () {
        active = false;
        controller
          .._reconnect = null
          .._disconnect = null;

        commandClient?.close();
        unawaited(connection?.close());
        unawaited(client?.close());
      };
    },
    [
      controller,
      screenState.credentials,
      screenState.serverUri,
      screenState.gameId,
      screenState.playerName,
    ],
  );

  return state.value;
}

Uri _gameEndpoint(Uri serverUri, String gameId, String endpoint) {
  final segments = <String>[
    ...serverUri.pathSegments.where((segment) => segment.isNotEmpty),
    "games",
    gameId,
    endpoint,
  ];

  return serverUri.replace(pathSegments: segments);
}

Uri _webSocketUri(Uri uri) => switch (uri.scheme) {
  "http" => uri.replace(scheme: "ws"),
  "https" => uri.replace(scheme: "wss"),
  "ws" || "wss" => uri,
  _ => throw ArgumentError.value(
    uri,
    "serverUri",
    "Expected an http, https, ws, or wss URI",
  ),
};
