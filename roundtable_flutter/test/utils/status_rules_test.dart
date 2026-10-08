import 'package:flutter_test/flutter_test.dart';
import 'package:roundtable_client/roundtable_client.dart';
import 'package:roundtable_flutter/utils/repo_slug.dart';
import 'package:roundtable_flutter/utils/status_rules.dart';

void main() {
  group('repoSlug', () {
    test('shows owner/repo', () {
      expect(repoSlug('https://github.com/acme/app.git'), 'acme/app');
      expect(repoSlug('https://github.com/acme/app/'), 'acme/app');
    });

    test('falls back to the URL without a path', () {
      expect(repoSlug('https://github.com'), 'https://github.com');
    });
  });

  group('pausedUntilNow', () {
    final until = DateTime.utc(2026, 10, 9, 3);
    Task task(TaskStatus status, {LogPhase? phase}) => Task(
      id: 1,
      projectId: 1,
      prompt: 'p',
      status: status,
      pausedPhase: phase,
      pausedUntil: until,
    );

    test('a paused run or a paused review resumes at pausedUntil', () {
      expect(task(TaskStatus.paused).pausedUntilNow, until);
      expect(
        task(TaskStatus.awaitingReview, phase: LogPhase.review).pausedUntilNow,
        until,
      );
    });

    test('a stale pausedUntil on a running task means nothing', () {
      expect(task(TaskStatus.running).pausedUntilNow, isNull);
      expect(task(TaskStatus.awaitingReview).pausedUntilNow, isNull);
    });
  });
}
