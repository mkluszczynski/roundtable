import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roundtable_server/src/generated/protocol.dart';
import 'package:roundtable_server/src/github_repo_client.dart';
import 'package:roundtable_server/src/pr_checks.dart';
import 'package:test/test.dart';

PrCheckRun _job(String status, String? conclusion, {int jobId = 1}) =>
    PrCheckRun(
      taskId: 1,
      headSha: 'abc',
      workflowRunId: 7,
      runAttempt: 1,
      workflowName: 'CI',
      jobId: jobId,
      jobName: 'test',
      status: status,
      conclusion: conclusion,
    );

void main() {
  group('extractLogTail', () {
    test('strips timestamps and ends shortly after the last error', () {
      final log = [
        for (var i = 0; i < 300; i++)
          '2026-10-05T10:00:00.1234567Z line $i',
      ];
      log[200] = '2026-10-05T10:00:00.1234567Z ##[error]boom';
      final tail = extractLogTail(log.join('\n'), maxLines: 50);
      final lines = tail.split('\n');
      expect(lines, hasLength(50));
      expect(lines.last, 'line 204');
      expect(lines, contains('##[error]boom'));
      expect(tail, isNot(contains('2026-10-05T')));
    });

    test('without an error marker returns the log tail', () {
      final tail = extractLogTail('a\nb\nc\nd', maxLines: 2);
      expect(tail, 'c\nd');
    });
  });

  group('aggregateCheckState', () {
    final now = DateTime.utc(2026, 10, 5, 12);

    test('any failed job fails the checks, even with jobs still running', () {
      expect(
        aggregateCheckState([
          _job('completed', 'failure'),
          _job('in_progress', null, jobId: 2),
        ]),
        PrCheckState.failure,
      );
    });

    test('a running job or a run without jobs yet is pending', () {
      expect(
        aggregateCheckState([_job('queued', null)]),
        PrCheckState.pending,
      );
      expect(
        aggregateCheckState([], hasUnstartedRuns: true),
        PrCheckState.pending,
      );
    });

    test('passed and skipped jobs succeed', () {
      expect(
        aggregateCheckState([
          _job('completed', 'success'),
          _job('completed', 'skipped', jobId: 2),
        ]),
        PrCheckState.success,
      );
    });

    test('no runs is pending during the grace period, then none', () {
      expect(
        aggregateCheckState(
          [],
          headSeenAt: now.subtract(const Duration(seconds: 30)),
          now: now,
        ),
        PrCheckState.pending,
      );
      expect(
        aggregateCheckState(
          [],
          headSeenAt: now.subtract(noCiGracePeriod),
          now: now,
        ),
        PrCheckState.none,
      );
    });
  });

  test('mergeBlockedReason only lets success and none through', () {
    Task task(PrCheckState state) => Task(
      projectId: 1,
      prompt: 'x',
      checkState: state,
      prHeadSha: 'abc1234def',
    );
    expect(mergeBlockedReason(task(PrCheckState.success), []), isNull);
    expect(mergeBlockedReason(task(PrCheckState.none), []), isNull);
    expect(
      mergeBlockedReason(task(PrCheckState.failure), [
        _job('completed', 'failure'),
      ]),
      contains('1 failed'),
    );
    expect(
      mergeBlockedReason(task(PrCheckState.pending), [
        _job('in_progress', null),
      ]),
      contains('1 pending'),
    );
    expect(
      mergeBlockedReason(task(PrCheckState.pending), []),
      contains('abc1234'),
    );
  });

  test('checkFixPrompt includes the job, step, link, log and note', () {
    final prompt = checkFixPrompt(
      headSha: 'abc1234def',
      failures: [
        (
          run: _job('completed', 'failure').copyWith(
            failedStep: 'Run tests',
            htmlUrl: 'https://github.com/x/y/actions/runs/7/job/1',
          ),
          log: 'Expected: 2\n##[error]exit 1',
        ),
      ],
      note: '  Only the unit tests  ',
    );
    expect(prompt, contains('abc1234'));
    expect(prompt, contains('### CI / test — failure at step "Run tests"'));
    expect(prompt, contains('https://github.com/x/y/actions/runs/7/job/1'));
    expect(prompt, contains('##[error]exit 1'));
    expect(prompt, endsWith('Note from the developer: Only the unit tests'));
  });

  test('getJobLogTail follows the redirect without sending the token', () async {
    final requests = <http.BaseRequest>[];
    final client = GitHubRepoClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.host == 'api.github.com') {
          return http.Response(
            '',
            302,
            headers: {'location': 'https://blob.example.com/log.txt'},
          );
        }
        return http.Response('2026-10-05T10:00:00.0Z ##[error]boom\n', 200);
      }),
    );

    final tail = await client.getJobLogTail(
      owner: 'x',
      repo: 'y',
      jobId: 1,
      token: 'secret',
    );

    expect(tail, '##[error]boom');
    expect(requests, hasLength(2));
    expect(requests.first.headers['Authorization'], 'Bearer secret');
    expect(requests.last.headers.containsKey('Authorization'), isFalse);
  });

  test('a 403 from the Actions API points at the missing permission', () {
    final client = GitHubRepoClient(
      httpClient: MockClient(
        (_) async => http.Response(jsonEncode({'message': 'denied'}), 403),
      ),
    );
    expect(
      client.listWorkflowRuns(
        owner: 'x',
        repo: 'y',
        headSha: 'abc',
        token: 'secret',
      ),
      throwsA(
        isA<GitHubException>().having(
          (e) => e.message,
          'message',
          contains('Actions: read'),
        ),
      ),
    );
  });
}
