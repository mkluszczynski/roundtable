import 'dart:async';
import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod/protocol.dart' as sp;
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/agent_runner_binaries.dart';
import 'src/cache_busting.dart';
import 'src/generated/serverpod.dart';
import 'src/web/routes/app_config_route.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod. The generated Serverpod class is already connected
  // with your project's generated code.
  final pod = Serverpod(args);

  // Initialize authentication services for the server.
  // Token managers will be used to validate and issue authentication keys,
  // and the identity providers will be the authentication options available for users.
  pod.initializeAuthServices(
    tokenManagerBuilders: [
      // Use JWT for authentication keys towards the server.
      JwtConfigFromPasswords(),
    ],
    identityProviderBuilders: [
      // Configure the email identity provider for email/password authentication.
      // The default setup works with Serverpod Cloud without configuration. In
      // development the verification codes are logged to the console, and in
      // staging and production they are sent through the Serverpod Cloud email
      // service. If you want to use a custom provider for sending emails, use
      // `EmailIdpConfigFromPasswords`.
      ServerpodCloudEmailIdpConfig(
        appDisplayName: 'roundtable',
      ),
    ],
  );

  // Serve all files in the web/static relative directory under /web.
  // These are used by the default web page.
  pod.webServer.addRoute(
    StaticRoute.withCacheBusting(cacheBustingConfig),
    cacheBustingConfig.mountPrefix,
  );

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/assets/assets/config.json',
  );

  // Serve the machine install script so the "add machine" command works on a
  // fresh host that doesn't have this repo checked out. In development it's
  // read straight from the repo's scripts/ directory; the packaged Docker
  // image only ships web/, so the Dockerfile copies the script there too.
  final devInstallScript = File(
    Uri(path: '../scripts/install-agent.sh').toFilePath(),
  );
  final packagedInstallScript = File(
    Uri(path: 'web/static/install-agent.sh').toFilePath(),
  );
  pod.webServer.addRoute(
    StaticRoute.file(
      devInstallScript.existsSync() ? devInstallScript : packagedInstallScript,
    ),
    '/install-agent.sh',
  );

  // Serve the uninstall script too — a machine installed via the curl
  // one-liner above has no repo checkout to run `./scripts/uninstall-agent.sh`
  // from, so the panel's "still online" delete dialog points at this route
  // instead (docs/FLOWS.md §1–3).
  final devUninstallScript = File(
    Uri(path: '../scripts/uninstall-agent.sh').toFilePath(),
  );
  final packagedUninstallScript = File(
    Uri(path: 'web/static/uninstall-agent.sh').toFilePath(),
  );
  pod.webServer.addRoute(
    StaticRoute.file(
      devUninstallScript.existsSync()
          ? devUninstallScript
          : packagedUninstallScript,
    ),
    '/uninstall-agent.sh',
  );

  // Serve prebuilt agent-runner and permission-prompt-tool binaries so
  // install-agent.sh (and the root-side updater it installs) can install a
  // self-executable agent without a Dart SDK or repo checkout on the target
  // machine (docs/FLOWS.md §4). The packaged Docker image ships them
  // prebuilt; in development they're compiled from the sibling package and
  // rebuilt whenever its sources change.
  pod.webServer.addRoute(
    AgentRunnerBinaryRoute(AgentRunnerBinary.agentRunner),
    '/agent-runner-bin',
  );
  pod.webServer.addRoute(
    AgentRunnerBinaryRoute(AgentRunnerBinary.permissionPromptTool),
    '/permission-prompt-tool-bin',
  );
  // Warm the dev-mode build cache so the first install doesn't wait on it.
  unawaited(AgentRunnerBinaries.instance.version());

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under /.
    pod.webServer.addRoute(
      FlutterRoute(
        appDir,
        // If building the Flutter app with WASM, set the below parameter to
        // true and add the --wasm flag to the flutter build command.
        enableWasmHeaders: false,
      ),
      '/',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    final defaultRoute = StaticRoute.file(
      File(
        Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
      ),
    );

    pod.webServer.addMiddleware(
      FallbackMiddleware(
        fallback: defaultRoute,
        on: (response) => response.statusCode == 404,
      ).call,
      '/',
    );

    pod.webServer.addRoute(
      defaultRoute,
      '/**',
    );
  }

  // Configure cloud storage.
  // This setup works with Serverpod Cloud without extra configuration.
  // If you want to use a custom provider for cloud storage, replace these
  // with your preferred provider.
  pod.addCloudStorage(
    await ServerpodCloudProvider.private(
      fallback: () => DatabaseCloudStorage('private'),
    ),
  );
  pod.addCloudStorage(
    await ServerpodCloudProvider.public(
      fallback: () => DatabaseCloudStorage('public'),
    ),
  );

  // Start the server.
  await pod.start();

  // Recurring calls are persisted, so scheduling them on every start stacks
  // up duplicates. Drop any existing rows (including ones from before they
  // had an identifier) and schedule exactly one of each.
  final session = await pod.createSession(enableLogging: false);
  try {
    await sp.FutureCallEntry.db.deleteWhere(
      session,
      where: (t) => t.name.inSet({
        'MachineOfflineCheckFutureCall',
        'StalledTaskCheckFutureCall',
        'MachineMetricCleanupCheckFutureCall',
        'PrChecksCheckFutureCall',
        'PausedTaskResumeCheckFutureCall',
      }),
    );
  } finally {
    await session.close();
  }

  // Periodically detect machines whose daemon has stopped heartbeating and
  // fail their in-progress tasks (docs/FLOWS.md §1–3).
  await pod.futureCalls
      .callRecurring(identifier: 'machine-offline-check')
      .every(const Duration(seconds: 30))
      .machineOffline
      .check();

  // Periodically detect tasks that have made no progress for too long, even
  // on a machine that's still online (docs/ARCHITECTURE.md "Timeout for a stuck
  // task").
  await pod.futureCalls
      .callRecurring(identifier: 'stalled-task-check')
      .every(const Duration(seconds: 30))
      .stalledTask
      .check();

  // Resume tasks paused by a Claude usage limit once it has reset.
  await pod.futureCalls
      .callRecurring(identifier: 'paused-task-resume')
      .every(const Duration(seconds: 30))
      .pausedTaskResume
      .check();

  // Keep only the last hour of machine metrics — the panel shows just the
  // latest sample per machine.
  await pod.futureCalls
      .callRecurring(identifier: 'machine-metric-cleanup')
      .every(const Duration(minutes: 10))
      .machineMetricCleanup
      .check();

  // Mirror the GitHub Actions checks of tasks in review, so the panel shows
  // them and can send failures to the agent (docs/FLOWS.md §4 "CI checks").
  await pod.futureCalls
      .callRecurring(identifier: 'pr-checks')
      .every(const Duration(seconds: 30))
      .prChecks
      .check();
}
