import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_flutter/utils/checkout_command.dart';

void main() {
  test('fetches, checks out and pulls the branch', () {
    expect(
      checkoutCommand('task-50'),
      'git fetch && git checkout task-50 && git pull',
    );
  });
}
