/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:roundtable_client/src/protocol/agent.dart' as _ikth53tp;
import 'package:roundtable_client/src/protocol/agent_effort.dart' as _izylr20v;
import 'package:roundtable_client/src/protocol/agent_role.dart' as _i7934w80;
import 'package:roundtable_client/src/protocol/diff_file.dart' as _iusyva9a;
import 'package:roundtable_client/src/protocol/greetings/greeting.dart'
    as _ixjw1k71;
import 'package:roundtable_client/src/protocol/log_source.dart' as _ict2bn87;
import 'package:roundtable_client/src/protocol/machine.dart' as _iwz93qz1;
import 'package:roundtable_client/src/protocol/machine_registration.dart'
    as _i80z6wcv;
import 'package:roundtable_client/src/protocol/project.dart' as _i76mncv2;
import 'package:roundtable_client/src/protocol/task.dart' as _iw53rmon;
import 'package:roundtable_client/src/protocol/task_feedback.dart' as _ifl2c5cu;
import 'package:roundtable_client/src/protocol/task_log_entry.dart'
    as _inlvye37;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// CRUD for [Agent]. Deletion is blocked while the agent has a non-terminal
/// task (design doc §5, §6.8).
/// {@category Endpoint}
class EndpointAgent extends _isc.EndpointRef {
  EndpointAgent(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agent';

  _ida.Future<_ikth53tp.Agent> create(
    String name,
    int machineId, {
    required _i7934w80.AgentRole role,
    String? defaultModel,
    _izylr20v.AgentEffort? defaultEffort,
  }) => caller.callServerEndpoint<_ikth53tp.Agent>(
    'agent',
    'create',
    {
      'name': name,
      'machineId': machineId,
      'role': role,
      'defaultModel': defaultModel,
      'defaultEffort': defaultEffort,
    },
  );

  _ida.Future<_ikth53tp.Agent?> get(int id) =>
      caller.callServerEndpoint<_ikth53tp.Agent?>(
        'agent',
        'get',
        {'id': id},
      );

  _ida.Future<List<_ikth53tp.Agent>> list() =>
      caller.callServerEndpoint<List<_ikth53tp.Agent>>(
        'agent',
        'list',
        {},
      );

  _ida.Future<_ikth53tp.Agent> update(_ikth53tp.Agent agent) =>
      caller.callServerEndpoint<_ikth53tp.Agent>(
        'agent',
        'update',
        {'agent': agent},
      );

  _ida.Future<void> delete(int id) => caller.callServerEndpoint<void>(
    'agent',
    'delete',
    {'id': id},
  );
}

/// Registration and CRUD for [Machine]. Deletion is blocked while the machine
/// is `online`, or while any of its agents has a non-terminal task (design
/// doc §5, §6.8).
/// {@category Endpoint}
class EndpointMachine extends _isc.EndpointRef {
  EndpointMachine(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'machine';

  _ida.Future<_i80z6wcv.MachineRegistration> register(String name) =>
      caller.callServerEndpoint<_i80z6wcv.MachineRegistration>(
        'machine',
        'register',
        {'name': name},
      );

  _ida.Future<_iwz93qz1.Machine?> get(int id) =>
      caller.callServerEndpoint<_iwz93qz1.Machine?>(
        'machine',
        'get',
        {'id': id},
      );

  _ida.Future<List<_iwz93qz1.Machine>> list() =>
      caller.callServerEndpoint<List<_iwz93qz1.Machine>>(
        'machine',
        'list',
        {},
      );

  _ida.Future<_iwz93qz1.Machine> update(_iwz93qz1.Machine machine) =>
      caller.callServerEndpoint<_iwz93qz1.Machine>(
        'machine',
        'update',
        {'machine': machine},
      );

  /// Called periodically by the agent-runner daemon on a registered
  /// machine. Marks the machine online and refreshes [Machine.lastSeenAt].
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine (unknown, or revoked via [deregister]).
  _ida.Future<void> heartbeat(String token) => caller.callServerEndpoint<void>(
    'machine',
    'heartbeat',
    {'token': token},
  );

  /// Called by the uninstall script as a deliberate deregistration, so the
  /// server doesn't have to wait for the heartbeat timeout to notice the
  /// machine is gone (design doc §6.8). Marks the machine offline and clears
  /// [Machine.tokenHash] so the raw token can never match again.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> deregister(String token) => caller.callServerEndpoint<void>(
    'machine',
    'deregister',
    {'token': token},
  );

  /// Resolves the [Machine] a registration token belongs to, without
  /// mutating heartbeat state. Used by the agent-runner daemon at startup to
  /// learn its own machine id before subscribing to
  /// [TaskEndpoint.watchAssignedTasks] (design doc §6.1).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<_iwz93qz1.Machine> identify(String token) =>
      caller.callServerEndpoint<_iwz93qz1.Machine>(
        'machine',
        'identify',
        {'token': token},
      );

  _ida.Future<void> delete(int id) => caller.callServerEndpoint<void>(
    'machine',
    'delete',
    {'id': id},
  );
}

/// Basic CRUD for [Project]. No deletion guards apply here — see
/// [MachineEndpoint] and [AgentEndpoint] for the entities that have them.
/// {@category Endpoint}
class EndpointProject extends _isc.EndpointRef {
  EndpointProject(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'project';

  _ida.Future<_i76mncv2.Project> create(
    String name,
    String repoUrl, {
    String? repoAccessToken,
    String? dockerImage,
  }) => caller.callServerEndpoint<_i76mncv2.Project>(
    'project',
    'create',
    {
      'name': name,
      'repoUrl': repoUrl,
      'repoAccessToken': repoAccessToken,
      'dockerImage': dockerImage,
    },
  );

  _ida.Future<_i76mncv2.Project?> get(int id) =>
      caller.callServerEndpoint<_i76mncv2.Project?>(
        'project',
        'get',
        {'id': id},
      );

  _ida.Future<List<_i76mncv2.Project>> list() =>
      caller.callServerEndpoint<List<_i76mncv2.Project>>(
        'project',
        'list',
        {},
      );

  _ida.Future<_i76mncv2.Project> update(_i76mncv2.Project project) =>
      caller.callServerEndpoint<_i76mncv2.Project>(
        'project',
        'update',
        {'project': project},
      );

  _ida.Future<void> delete(int id) => caller.callServerEndpoint<void>(
    'project',
    'delete',
    {'id': id},
  );

  /// Returns a ready-to-clone HTTPS URL for [projectId], with
  /// `repoAccessToken` (`scope=serverOnly`, never returned as its own field)
  /// injected as the userinfo component when present. Called by the agent
  /// daemon only at the moment a task starts, never persisted to disk on the
  /// agent side (design doc §6.5).
  _ida.Future<String> getCloneUrl(int projectId) =>
      caller.callServerEndpoint<String>(
        'project',
        'getCloneUrl',
        {'projectId': projectId},
      );
}

/// Task creation and the daemon's assignment feed (design doc §6.1).
/// {@category Endpoint}
class EndpointTask extends _isc.EndpointRef {
  EndpointTask(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'task';

  /// Creates a [Task] already assigned to [agentId] (design doc §6.1 step 1 —
  /// queueing without an agent is a Should-scope feature, not implemented
  /// here even though the schema allows `Task.agent` to be null).
  ///
  /// Notifies the assigned agent's machine via [watchAssignedTasks].
  _ida.Future<_iw53rmon.Task> createTask(
    int projectId,
    int agentId,
    String prompt, {
    required bool skipPlanning,
  }) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'createTask',
    {
      'projectId': projectId,
      'agentId': agentId,
      'prompt': prompt,
      'skipPlanning': skipPlanning,
    },
  );

  /// Streams tasks newly assigned to any agent hosted on [machineId] (design
  /// doc §6.1 step 2 — by machine, not by agent, since one daemon serves
  /// every agent it hosts). On subscribe, first replays any already-queued,
  /// non-terminal tasks for that machine — otherwise a task created while the
  /// daemon was offline/restarting would never surface — then yields each
  /// task as it's created via [createTask].
  /// Generic CRUD update, mirroring [ProjectEndpoint.update] /
  /// [AgentEndpoint.update] / [MachineEndpoint.update]. Used by the agent
  /// daemon to move a task through its lifecycle (design doc §6.1) —
  /// e.g. `running` → `awaitingReview`/`failed` — and to persist
  /// `claudeSessionId` once Claude Code reports one.
  _ida.Future<_iw53rmon.Task> update(_iw53rmon.Task task) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'update',
        {'task': task},
      );

  /// Persists one line of a task's execution output as a [TaskLogEntry]
  /// (design doc §6.3) and notifies any [watchLogs] subscribers for this
  /// task.
  _ida.Future<_inlvye37.TaskLogEntry> appendLog(
    int taskId,
    String content, {
    required _ict2bn87.LogSource source,
  }) => caller.callServerEndpoint<_inlvye37.TaskLogEntry>(
    'task',
    'appendLog',
    {
      'taskId': taskId,
      'content': content,
      'source': source,
    },
  );

  /// Cancels a task that hasn't reached a terminal state yet (design doc
  /// §6.1 "Cancelling mid-run"): marks it `cancelled` and notifies
  /// [watchTask] subscribers — the daemon running the task reacts by
  /// sending `SIGTERM` to the Claude Code subprocess and resetting the
  /// worktree.
  _ida.Future<_iw53rmon.Task> cancelTask(int taskId) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'cancelTask',
        {'taskId': taskId},
      );

  /// Records feedback on a completed run (design doc §6.1 step 9, §6.4) and
  /// wakes the daemon via the same channel [createTask] uses — the daemon
  /// picks it up through its existing [watchAssignedTasks] subscription and
  /// resumes the same Claude Code session (`TaskDispatcher.handle`).
  _ida.Future<_ifl2c5cu.TaskFeedback> submitFeedback(
    int taskId,
    String message,
  ) => caller.callServerEndpoint<_ifl2c5cu.TaskFeedback>(
    'task',
    'submitFeedback',
    {
      'taskId': taskId,
      'message': message,
    },
  );

  /// Returns the most recently submitted [TaskFeedback] for [taskId], or
  /// `null` if none exists. Used by the daemon to fetch the message text of
  /// a review-phase feedback that woke it via [submitFeedback], and to tell
  /// a stale replay (e.g. after a daemon restart) apart from a real pending
  /// one — see `TaskDispatcher.handle`'s use of `Task.finishedAt`.
  _ida.Future<_ifl2c5cu.TaskFeedback?> latestFeedback(int taskId) =>
      caller.callServerEndpoint<_ifl2c5cu.TaskFeedback?>(
        'task',
        'latestFeedback',
        {'taskId': taskId},
      );

  /// Returns the list of files changed in [taskId]'s pull request (design
  /// doc §6.7), fetched from the GitHub API using the project's
  /// `repoAccessToken` — never returned to the panel.
  _ida.Future<List<_iusyva9a.DiffFile>> getChangedFiles(int taskId) =>
      caller.callServerEndpoint<List<_iusyva9a.DiffFile>>(
        'task',
        'getChangedFiles',
        {'taskId': taskId},
      );

  /// Returns the raw content of the file at [contentsUrl] (as returned by
  /// [getChangedFiles]) for [taskId]'s repository (design doc §6.7).
  _ida.Future<String> getFileContent(
    int taskId,
    String contentsUrl,
  ) => caller.callServerEndpoint<String>(
    'task',
    'getFileContent',
    {
      'taskId': taskId,
      'contentsUrl': contentsUrl,
    },
  );

  _ida.Stream<_iw53rmon.Task> watchAssignedTasks(int machineId) => caller
      .callStreamingServerEndpoint<_ida.Stream<_iw53rmon.Task>, _iw53rmon.Task>(
        'task',
        'watchAssignedTasks',
        {'machineId': machineId},
        {},
      );

  /// Streams a task's execution output as it's persisted via [appendLog]
  /// (design doc §6.3), for the panel to render live. On subscribe, first
  /// replays every already-persisted [TaskLogEntry] for [taskId] in order,
  /// then yields each new entry as it's appended.
  _ida.Stream<_inlvye37.TaskLogEntry> watchLogs(int taskId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_inlvye37.TaskLogEntry>,
        _inlvye37.TaskLogEntry
      >(
        'task',
        'watchLogs',
        {'taskId': taskId},
        {},
      );

  /// Streams [taskId]'s status, for the daemon running it (to detect a
  /// cancellation mid-run, design doc §6.1) and the panel alike. On
  /// subscribe, first replays the task's current row, then yields it again
  /// each time [cancelTask] cancels it.
  _ida.Stream<_iw53rmon.Task> watchTask(int taskId) => caller
      .callStreamingServerEndpoint<_ida.Stream<_iw53rmon.Task>, _iw53rmon.Task>(
        'task',
        'watchTask',
        {'taskId': taskId},
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _isc.EndpointRef {
  EndpointGreeting(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _ida.Future<_ixjw1k71.Greeting> hello(String name) =>
      caller.callServerEndpoint<_ixjw1k71.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    agent = EndpointAgent(this);
    machine = EndpointMachine(this);
    project = EndpointProject(this);
    task = EndpointTask(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAgent agent;

  late final EndpointMachine machine;

  late final EndpointProject project;

  late final EndpointTask task;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'agent': agent,
    'machine': machine,
    'project': project,
    'task': task,
    'greeting': greeting,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
