import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/error_message.dart';

void main() {
  test('typed server exceptions show their own message', () {
    expect(
      errorMessage(InvalidStateException(message: 'Task 3 is not planReady')),
      'Task 3 is not planReady',
    );
    expect(
      errorMessage(NotFoundException(message: 'Task 3 not found')),
      'Task 3 not found',
    );
    expect(
      errorMessage(GitHubException(message: 'GitHub refused', statusCode: 405)),
      'GitHub refused',
    );
  });

  test('anything else falls back to toString', () {
    expect(errorMessage(StateError('boom')), 'Bad state: boom');
  });
}
