import 'package:roundtable_client/roundtable_client.dart';

/// The text to show the developer for a failed server call: the server's
/// own message for the typed exceptions it throws, `toString()` otherwise.
String errorMessage(Object error) => switch (error) {
  NotFoundException(:final message) => message,
  InvalidStateException(:final message) => message,
  GitHubException(:final message) => message,
  DeletionBlockedException(:final message) => message,
  InvalidTokenException(:final message) => message,
  _ => error.toString(),
};
