import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

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
  // instead (design doc §6.8).
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

  // Serve a prebuilt agent-runner binary so install-agent.sh can install a
  // self-executable agent without a Dart SDK or repo checkout on the target
  // machine (design doc §6.8). The packaged Docker image ships it prebuilt;
  // in development it's compiled on demand from the sibling package and
  // cached on disk.
  final agentRunnerBinary = await _resolveAgentRunnerBinary(
    targetScript: 'bin/roundtable_agent_runner.dart',
    packagedFileName: 'roundtable-agent-runner',
    routeName: '/agent-runner-bin',
  );
  if (agentRunnerBinary != null) {
    pod.webServer.addRoute(
      StaticRoute.file(agentRunnerBinary),
      '/agent-runner-bin',
    );
  }

  // Serve a prebuilt permission-prompt-tool binary alongside the agent
  // runner — a deployed daemon (no Dart SDK on the target machine) can't run
  // `bin/permission_prompt_tool.dart` from source, so it needs its own
  // compiled artifact too (design doc §6.4, §6.8).
  final permissionPromptToolBinary = await _resolveAgentRunnerBinary(
    targetScript: 'bin/permission_prompt_tool.dart',
    packagedFileName: 'roundtable-permission-prompt-tool',
    routeName: '/permission-prompt-tool-bin',
  );
  if (permissionPromptToolBinary != null) {
    pod.webServer.addRoute(
      StaticRoute.file(permissionPromptToolBinary),
      '/permission-prompt-tool-bin',
    );
  }

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

  // Periodically detect machines whose daemon has stopped heartbeating and
  // fail their in-progress tasks (design doc §6.8).
  await pod.futureCalls
      .callRecurring()
      .every(const Duration(seconds: 30))
      .machineOffline
      .check();

  // Periodically detect tasks that have made no progress for too long, even
  // on a machine that's still online (design doc §4 "Timeout for a stuck
  // task").
  await pod.futureCalls
      .callRecurring()
      .every(const Duration(seconds: 30))
      .stalledTask
      .check();
}

/// Resolves a compiled binary out of the sibling `roundtable_agent_runner`
/// package, for [targetScript] (a `bin/*.dart` entrypoint in that package)
/// served under [routeName] (used only for log messages).
///
/// Prefers the prebuilt copy the Dockerfile bakes into
/// `web/static/bin/$packagedFileName`. In development, where that package is
/// source, not a binary, it's compiled once with `dart build cli` and cached
/// under a per-target subdirectory of that package's `build/` directory (a
/// separate subdirectory per target, since `dart build cli` wipes its whole
/// `--output` directory on every invocation) — delete the cached binary to
/// force a rebuild after changing its source.
Future<File?> _resolveAgentRunnerBinary({
  required String targetScript,
  required String packagedFileName,
  required String routeName,
}) async {
  final packaged = File(
    Uri(path: 'web/static/bin/$packagedFileName').toFilePath(),
  );
  if (packaged.existsSync()) return packaged;

  final agentRunnerDir = Directory(
    Uri(path: '../roundtable_agent_runner').toFilePath(),
  );
  if (!agentRunnerDir.existsSync()) return null;

  final targetName = targetScript.split('/').last.replaceAll('.dart', '');
  final built = File(
    Uri(
      path:
          '../roundtable_agent_runner/build/$targetName/bundle/bin/$targetName',
    ).toFilePath(),
  );
  if (!built.existsSync()) {
    stdout.writeln(
      'Building $targetName binary for $routeName (first run only; '
      'delete ${built.path} to force a rebuild after changing its source)...',
    );
    final result = await Process.run('dart', [
      'build',
      'cli',
      '--target',
      targetScript,
      '--output',
      'build/$targetName',
    ], workingDirectory: agentRunnerDir.path);
    if (result.exitCode != 0) {
      stderr.writeln(
        'Failed to build $targetName binary, $routeName will 404 '
        'until this is fixed:\n${result.stderr}',
      );
      return null;
    }
  }
  return built.existsSync() ? built : null;
}
