import "package:dart_iconica_utilities/dart_iconica_utilities.dart";
import "package:fpdart/fpdart.dart";
import "package:simple_cag_domain/simple_cag_domain.dart";

const _keyType = "type";
const _keyData = "data";

final cagCommandSerializer = Serializer<CagCommand>(
  fromMap: (map) {
    final (type, data) = switch (map) {
      {_keyType: final String type, _keyData: final Map<String, dynamic> data} => (type, data),
      _ => throw const FormatException("Expected a command structure, got the wrong "),
    };

    final commandType = CagCommands.values
        .where((commandType) => commandType.commandType == type)
        .firstOption
        .getOrElse(() => throw StateError("Missing serializer for this command"));

    final serializer = _getSerializerForCommand(commandType);

    return serializer.fromMap(data);
  },
  toMap: (command) {
    final commandType = CagCommands.values
        .where((commandType) => commandType.commandType == command.type)
        .firstOption
        .getOrElse(() => throw StateError("Missing serializer for this command"));
    final serializer = _getSerializerForCommand(commandType);

    return {
      _keyType: command.type,
      _keyData: serializer.toMap(command),
    };
  },
);

Serializer<CagCommand> _getSerializerForCommand(CagCommands command) => switch (command) {
  .joinGame => _unserializableCommandSerializer<JoinGameCommand>(),
  .updatePlayerConnectionStatus => _unserializableCommandSerializer<UpdatePlayerConnectionStatusCommand>(),
  .startNewRound => StartNewRoundCommand.serializer,
  .playCards => PlayCardsCommand.serializer,
  .votePick => VotePickCommand.serializer,
  .progressToVoting => ProgressToVotingCommand.serializer,
};

Serializer<T> _unserializableCommandSerializer<T extends CagCommand>() => Serializer(
  fromMap: (map) {
    throw StateError("This command is not supported for serialization as it should purely exist on the server");
  },
  toMap: (command) {
    throw StateError("This command is not supported for serialization as it should purely exist on the server");
  },
);

Serializer<CagCommand> emptySerializer(CagCommand Function() constructor) =>
    Serializer(fromMap: (_) => constructor(), toMap: (CagCommand _) => {});
