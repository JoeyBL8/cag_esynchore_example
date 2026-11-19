import "package:esynchore_core/esynchore_core.dart";

enum CagEsynchoreErrorCodes<T extends EsynchoreError>(
  final String errorCode,
  final String message,
  final T Function(String, String) createError,
) {
  authUnimplemented(
    "unimplemented",
    "A feature was used which was not ready to use yet",
    AuthenticationError.new,
  ),
  gameNotFound(
    "game_not_found",
    "A game could not be found for the given identifier",
    ApplicationError.new,
  ),
  playerRegistrationFailed(
    "player_creation_failed",
    "Something went wrong during the creation of the player",
    ApplicationError.new,
  ),
  authenticationFailed(
    "player_authentication_failed",
    "Player credentials are invalid for the given game",
    AuthenticationError.new,
  ),
  operationNotAllowed(
    "game_command_authorization_generic",
    "This command is not allowed to be applied given the current principal",
    AuthorizationError.new,
  ),
  createGameWithUnknownSet(
    "game_starting_with_unknown_set",
    "A create game intent was found which contained a set the server has no knowledge of",
    ApplicationError.new,
  ),
  playCardsAsJudge(
    "cannot_play_cards_as_judge",
    "The judge is not allowed to play cards",
    AuthorizationError.new,
  ),
  playCardsWhenCardsAreAlreadyPlayed(
    "play_cards_once_per_round",
    "A player can only play cards if they have not committed to any cards yet",
    AuthorizationError.new,
  ),
  playIncorrectCardAmount(
    "play_invalid_amount_of_cards",
    "A player can only play the same amount of cards as the prompt requires",
    AuthorizationError.new,
  ),
  voteAsNonJudge(
    "vote_from_non_judge",
    "Only the current judge can vote for a round winner",
    AuthorizationError.new,
  );

  T getError() => createError(errorCode, message);
}
