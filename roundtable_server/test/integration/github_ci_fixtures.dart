import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fake GitHub Actions responses for tests that go through `syncChecks`
/// (e.g. `acceptTask`): the PR's head commit [headSha] with one workflow run
/// whose single job ended with [conclusion] (null = still running), or none
/// at all with [noWorkflows]. The job's log is served through a redirect,
/// like GitHub does. Returns null for any other request.
http.Response? fakeCiResponse(
  http.Request request, {
  String headSha = 'abc1234def',
  String? conclusion = 'success',
  bool noWorkflows = false,
}) {
  final path = request.url.path;
  if (request.method == 'GET' && RegExp(r'/pulls/\d+$').hasMatch(path)) {
    return http.Response(
      jsonEncode({
        'state': 'open',
        'head': {'sha': headSha, 'ref': 'task-1'},
        'base': {'ref': 'main'},
        'mergeable': true,
        'mergeable_state': 'clean',
      }),
      200,
    );
  }
  if (path.endsWith('/actions/runs')) {
    return http.Response(
      jsonEncode({
        'workflow_runs': noWorkflows
            ? []
            : [
                {
                  'id': 77,
                  'name': 'CI',
                  'head_sha': headSha,
                  'status': conclusion == null ? 'in_progress' : 'completed',
                  'conclusion': conclusion,
                  'run_attempt': 1,
                },
              ],
      }),
      200,
    );
  }
  if (path.endsWith('/actions/runs/77/jobs')) {
    return http.Response(
      jsonEncode({
        'jobs': [
          {
            'id': 901,
            'name': 'test',
            'status': conclusion == null ? 'in_progress' : 'completed',
            'conclusion': conclusion,
            'html_url':
                'https://github.com/example/roundtable/actions/runs/77/job/901',
            'started_at': '2026-10-05T10:00:00Z',
            'completed_at': conclusion == null ? null : '2026-10-05T10:02:00Z',
            'steps': [
              {'name': 'Checkout', 'conclusion': 'success'},
              {
                'name': 'Run tests',
                'conclusion': conclusion == 'failure' ? 'failure' : conclusion,
              },
            ],
          },
        ],
      }),
      200,
    );
  }
  if (path.endsWith('/actions/jobs/901/logs')) {
    return http.Response(
      '',
      302,
      headers: {'location': 'https://blob.example.com/logs/901.txt'},
    );
  }
  if (request.url.host == 'blob.example.com') {
    return http.Response(
      '2026-10-05T10:01:00.0000000Z Running tests\n'
      '2026-10-05T10:01:01.0000000Z Expected: 2, Actual: 3\n'
      '2026-10-05T10:01:02.0000000Z ##[error]Process completed with exit '
      'code 1.\n',
      200,
    );
  }
  return null;
}
