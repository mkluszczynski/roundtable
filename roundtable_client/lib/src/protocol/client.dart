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
import 'dart:typed_data' as _idt;
import 'package:http/http.dart' as _i85jenna;
import 'package:roundtable_client/src/protocol/agent.dart' as _ikth53tp;
import 'package:roundtable_client/src/protocol/agent_effort.dart' as _izylr20v;
import 'package:roundtable_client/src/protocol/agent_execution_mode.dart'
    as _iplk739p;
import 'package:roundtable_client/src/protocol/agent_role_definition.dart'
    as _iw3o4s27;
import 'package:roundtable_client/src/protocol/agent_status.dart' as _ijqfzoc4;
import 'package:roundtable_client/src/protocol/code_review.dart' as _i38oxrkr;
import 'package:roundtable_client/src/protocol/code_review_verdict.dart'
    as _ijtwbvlr;
import 'package:roundtable_client/src/protocol/diff_file.dart' as _iusyva9a;
import 'package:roundtable_client/src/protocol/greetings/greeting.dart'
    as _ixjw1k71;
import 'package:roundtable_client/src/protocol/log_source.dart' as _ict2bn87;
import 'package:roundtable_client/src/protocol/machine.dart' as _iwz93qz1;
import 'package:roundtable_client/src/protocol/machine_metric.dart'
    as _il2pq5ll;
import 'package:roundtable_client/src/protocol/machine_registration.dart'
    as _i80z6wcv;
import 'package:roundtable_client/src/protocol/pr_checks.dart' as _ixcrf414;
import 'package:roundtable_client/src/protocol/pr_merge_status.dart'
    as _ikiwas8h;
import 'package:roundtable_client/src/protocol/project.dart' as _i76mncv2;
import 'package:roundtable_client/src/protocol/project_tool.dart' as _itcevbxn;
import 'package:roundtable_client/src/protocol/review_comment.dart'
    as _ij6tkwdt;
import 'package:roundtable_client/src/protocol/review_comment_check.dart'
    as _iabe8ujm;
import 'package:roundtable_client/src/protocol/review_comment_draft.dart'
    as _ithbrqha;
import 'package:roundtable_client/src/protocol/review_comment_state.dart'
    as _i3j6boid;
import 'package:roundtable_client/src/protocol/task.dart' as _iw53rmon;
import 'package:roundtable_client/src/protocol/task_attachment.dart'
    as _iowm7apo;
import 'package:roundtable_client/src/protocol/task_defaults.dart' as _ik8cj6du;
import 'package:roundtable_client/src/protocol/task_deleted.dart' as _iwt28wmq;
import 'package:roundtable_client/src/protocol/task_feedback.dart' as _ifl2c5cu;
import 'package:roundtable_client/src/protocol/task_log_entry.dart'
    as _inlvye37;
import 'package:roundtable_client/src/protocol/task_question.dart' as _ihmnezqk;
import 'package:roundtable_client/src/protocol/workspace_settings.dart'
    as _ix9sl716;
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
/// task (docs/ARCHITECTURE.md).
/// {@category Endpoint}
class EndpointAgent extends _isc.EndpointRef {
  EndpointAgent(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agent';

  _ida.Future<_ikth53tp.Agent> create(
    String name,
    int machineId, {
    int? roleId,
    String? defaultModel,
    _izylr20v.AgentEffort? defaultEffort,
    _iplk739p.AgentExecutionMode? executionMode,
  }) => caller.callServerEndpoint<_ikth53tp.Agent>(
    'agent',
    'create',
    {
      'name': name,
      'machineId': machineId,
      'roleId': roleId,
      'defaultModel': defaultModel,
      'defaultEffort': defaultEffort,
      'executionMode': executionMode,
    },
  );

  /// With its role — the daemon builds the prompt prefix from it.
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

  /// Streams every agent (with its role) on subscribe, then each agent as
  /// it changes — created, edited, or its status reported by a daemon — so
  /// the panel's agent statuses stay live. Deletions aren't streamed: the
  /// panel refetches [list] after deleting.
  _ida.Stream<_ikth53tp.Agent> watchAgents() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ikth53tp.Agent>,
        _ikth53tp.Agent
      >(
        'agent',
        'watchAgents',
        {},
        {},
      );

  /// Edits an agent's settings from the panel. The machine it lives on and
  /// its status can't be changed here — status is reported by the daemon
  /// through [setStatus]. The execution mode changes only while the agent
  /// has no open task: a task's Claude Code session lives on the machine or
  /// in the container, and can't be resumed from the other one.
  _ida.Future<_ikth53tp.Agent> update(_ikth53tp.Agent agent) =>
      caller.callServerEndpoint<_ikth53tp.Agent>(
        'agent',
        'update',
        {'agent': agent},
      );

  /// Reports what an agent is doing (`idle`/`busy`/`waitingForResponse`),
  /// called by the daemon running its tasks and reviews.
  _ida.Future<_ikth53tp.Agent> setStatus(
    int agentId,
    _ijqfzoc4.AgentStatus status,
  ) => caller.callServerEndpoint<_ikth53tp.Agent>(
    'agent',
    'setStatus',
    {
      'agentId': agentId,
      'status': status,
    },
  );

  _ida.Future<void> delete(int id) => caller.callServerEndpoint<void>(
    'agent',
    'delete',
    {'id': id},
  );
}

/// CRUD for [AgentRoleDefinition] — the workspace's agent roles, edited in
/// the panel's Settings. Deletion is blocked while an agent uses the role.
/// {@category Endpoint}
class EndpointAgentRole extends _isc.EndpointRef {
  EndpointAgentRole(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'agentRole';

  _ida.Future<List<_iw3o4s27.AgentRoleDefinition>> list() =>
      caller.callServerEndpoint<List<_iw3o4s27.AgentRoleDefinition>>(
        'agentRole',
        'list',
        {},
      );

  _ida.Future<_iw3o4s27.AgentRoleDefinition> create(
    _iw3o4s27.AgentRoleDefinition role,
  ) => caller.callServerEndpoint<_iw3o4s27.AgentRoleDefinition>(
    'agentRole',
    'create',
    {'role': role},
  );

  _ida.Future<_iw3o4s27.AgentRoleDefinition> update(
    _iw3o4s27.AgentRoleDefinition role,
  ) => caller.callServerEndpoint<_iw3o4s27.AgentRoleDefinition>(
    'agentRole',
    'update',
    {'role': role},
  );

  _ida.Future<void> delete(int id) => caller.callServerEndpoint<void>(
    'agentRole',
    'delete',
    {'id': id},
  );
}

/// AI code review of a task's PR: a reviewer agent leaves comments, the dev
/// triages them and sends the ones worth fixing back to the task's agent.
/// {@category Endpoint}
class EndpointCodeReview extends _isc.EndpointRef {
  EndpointCodeReview(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'codeReview';

  /// Queues a review of [taskId]'s PR by [agentId]. The reviewer's daemon
  /// picks it up via [watchAssignedReviews].
  _ida.Future<_i38oxrkr.CodeReview> requestReview(
    int taskId,
    int agentId,
  ) => caller.callServerEndpoint<_i38oxrkr.CodeReview>(
    'codeReview',
    'requestReview',
    {
      'taskId': taskId,
      'agentId': agentId,
    },
  );

  /// Streams reviews assigned to agents hosted on [machineId], for the
  /// daemon. Replays the queued ones on subscribe, like
  /// `TaskEndpoint.watchAssignedTasks`.
  _ida.Stream<_i38oxrkr.CodeReview> watchAssignedReviews(int machineId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i38oxrkr.CodeReview>,
        _i38oxrkr.CodeReview
      >(
        'codeReview',
        'watchAssignedReviews',
        {'machineId': machineId},
        {},
      );

  /// Called by the daemon when it starts [reviewId]: flips it to `running`
  /// and its reviewer to `busy`. Returns the task under review, which the
  /// daemon needs for the branch and original prompt.
  _ida.Future<_iw53rmon.Task> startReview(int reviewId) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'codeReview',
        'startReview',
        {'reviewId': reviewId},
      );

  /// The comments of [reviewId]'s earlier reviews of the same task, oldest
  /// first, for the reviewer to check (`buildReviewPrompt`). Superseded ones
  /// are left out — their carried-over copy stands in for them.
  _ida.Future<List<_ij6tkwdt.ReviewComment>> previousComments(int reviewId) =>
      caller.callServerEndpoint<List<_ij6tkwdt.ReviewComment>>(
        'codeReview',
        'previousComments',
        {'reviewId': reviewId},
      );

  /// Stores the reviewer's findings and mirrors them to the PR as a GitHub
  /// review. Mirroring is best effort: on failure the comments still live in
  /// Roundtable, just without `githubCommentId`.
  ///
  /// [checks] are the reviewer's verdicts on earlier comments
  /// ([previousComments]): a fixed one is resolved, one that isn't is
  /// carried over into this review as a new open comment and the old one
  /// becomes `superseded` — so the latest review lists everything still
  /// open. Dismissed comments and ids from other tasks are ignored.
  ///
  /// [verdict] is the reviewer's decision — auto merge needs `approve`.
  _ida.Future<_i38oxrkr.CodeReview> completeReview(
    int reviewId,
    String summary,
    List<_ithbrqha.ReviewCommentDraft> drafts, {
    List<_iabe8ujm.ReviewCommentCheck>? checks,
    _ijtwbvlr.CodeReviewVerdict? verdict,
  }) => caller.callServerEndpoint<_i38oxrkr.CodeReview>(
    'codeReview',
    'completeReview',
    {
      'reviewId': reviewId,
      'summary': summary,
      'drafts': drafts,
      'checks': checks,
      'verdict': verdict,
    },
  );

  /// Called by the daemon when a running review was cut short by the Claude
  /// usage limit: it goes back to `queued`, and the daemon runs it again
  /// once the limit resets.
  _ida.Future<_i38oxrkr.CodeReview> requeueReview(int reviewId) =>
      caller.callServerEndpoint<_i38oxrkr.CodeReview>(
        'codeReview',
        'requeueReview',
        {'reviewId': reviewId},
      );

  /// Called by the daemon when the review run couldn't produce findings.
  _ida.Future<_i38oxrkr.CodeReview> failReview(
    int reviewId,
    String reason,
  ) => caller.callServerEndpoint<_i38oxrkr.CodeReview>(
    'codeReview',
    'failReview',
    {
      'reviewId': reviewId,
      'reason': reason,
    },
  );

  /// Streams [taskId]'s reviews, each with its comments, for the panel.
  /// Replays them all on subscribe, then yields a review again whenever it
  /// or one of its comments changes — merge by id.
  _ida.Stream<_i38oxrkr.CodeReview> watchReviews(int taskId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i38oxrkr.CodeReview>,
        _i38oxrkr.CodeReview
      >(
        'codeReview',
        'watchReviews',
        {'taskId': taskId},
        {},
      );

  /// Triage by hand: dismiss, reopen, or resolve a comment. Resolving also
  /// resolves its mirrored GitHub thread.
  _ida.Future<_ij6tkwdt.ReviewComment> setCommentState(
    int commentId,
    _i3j6boid.ReviewCommentState state,
  ) => caller.callServerEndpoint<_ij6tkwdt.ReviewComment>(
    'codeReview',
    'setCommentState',
    {
      'commentId': commentId,
      'state': state,
    },
  );

  /// Sends [commentIds] — plus an optional [note] from the dev — to
  /// [taskId]'s agent as one review-feedback iteration. They're marked
  /// `sentToFix`, then `resolved` once that run finishes
  /// (`TaskEndpoint.update`).
  _ida.Future<_ifl2c5cu.TaskFeedback> sendCommentsToFix(
    int taskId,
    List<int> commentIds,
    String? note,
  ) => caller.callServerEndpoint<_ifl2c5cu.TaskFeedback>(
    'codeReview',
    'sendCommentsToFix',
    {
      'taskId': taskId,
      'commentIds': commentIds,
      'note': note,
    },
  );
}

/// Registration and CRUD for [Machine]. Deletion is blocked while the machine
/// is `online`, or while any of its agents has a non-terminal task
/// (docs/ARCHITECTURE.md).
/// {@category Endpoint}
class EndpointMachine extends _isc.EndpointRef {
  EndpointMachine(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'machine';

  _ida.Future<_i80z6wcv.MachineRegistration> register(
    String name, {
    String? hostInfo,
  }) => caller.callServerEndpoint<_i80z6wcv.MachineRegistration>(
    'machine',
    'register',
    {
      'name': name,
      'hostInfo': hostInfo,
    },
  );

  /// Base URL the install/uninstall scripts (and the agent-runner binary
  /// install-agent.sh downloads) are served from — the panel's "Delete"
  /// dialog for an online machine uses this to render a working
  /// `curl | sudo bash` uninstall command (docs/FLOWS.md §1–3).
  _ida.Future<String> getScriptUrl() => caller.callServerEndpoint<String>(
    'machine',
    'getScriptUrl',
    {},
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

  /// Renames a machine. Everything else on it (token, status, versions)
  /// is owned by the daemon-facing methods and can't be written here.
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

  /// Heartbeat for daemons that support in-panel updates: does what
  /// [heartbeat] does, records the daemon's installed [runnerVersion], and
  /// returns whether the dev requested an update via [requestRunnerUpdate].
  /// A pending request is cleared once the daemon reports a version other
  /// than the one it was requested from, i.e. after the update restarted it.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<bool> checkIn(
    String token,
    String? runnerVersion,
  ) => caller.callServerEndpoint<bool>(
    'machine',
    'checkIn',
    {
      'token': token,
      'runnerVersion': runnerVersion,
    },
  );

  /// Called by the daemon when a run hits the Claude usage limit: the
  /// machine starts no new work until [until] (docs/FLOWS.md §4).
  _ida.Future<void> reportUsageLimit(
    String token,
    DateTime until,
  ) => caller.callServerEndpoint<void>(
    'machine',
    'reportUsageLimit',
    {
      'token': token,
      'until': until,
    },
  );

  /// The version of the agent-runner binaries the server currently serves —
  /// a machine whose [Machine.runnerVersion] differs is out of date. Null if
  /// the binaries can't be resolved (e.g. the dev-mode build failed).
  _ida.Future<String?> latestRunnerVersion() =>
      caller.callServerEndpoint<String?>(
        'machine',
        'latestRunnerVersion',
        {},
      );

  /// Asks machine [id]'s daemon to update itself to the binaries the server
  /// currently serves, on its next check-in.
  _ida.Future<_iwz93qz1.Machine> requestRunnerUpdate(int id) =>
      caller.callServerEndpoint<_iwz93qz1.Machine>(
        'machine',
        'requestRunnerUpdate',
        {'id': id},
      );

  /// Called by the uninstall script once it has stopped the daemon
  /// (docs/FLOWS.md §3). The uninstall is the dev's deliberate removal of the
  /// machine, so it's deleted right away. The dev doesn't have to click
  /// "Delete" again in the panel.
  ///
  /// The machine is first marked offline and [Machine.tokenHash] is cleared,
  /// so the raw token can never match again even if the delete doesn't go
  /// through. Then the agent runs lost with the daemon are failed, as in
  /// [reportStartup], along with `queued` code reviews: no daemon is left to
  /// pick them up, and they would block their task forever.
  ///
  /// If the machine's agents still have other non-terminal tasks (queued,
  /// awaiting review, …), deleting it is blocked as in [delete], and the
  /// machine stays offline. The dev deletes it from the panel once those
  /// tasks are resolved. The same happens if the delete keeps losing a
  /// serialization conflict.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> deregister(String token) => caller.callServerEndpoint<void>(
    'machine',
    'deregister',
    {'token': token},
  );

  /// Called by the daemon once at startup, right after [identify]. A fresh
  /// daemon process has no `claude` subprocesses, so any task of this
  /// machine's agents still in an agent-driven state (planning, waiting on a
  /// question/plan decision, running) lost its process in the restart —
  /// fail it with a clear reason instead of leaving it stuck. Code reviews
  /// that were `running` on it are failed the same way (a stuck review would
  /// block merging), and the agents are reset to `idle`, since nothing is
  /// running on them anymore.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> reportStartup(String token) =>
      caller.callServerEndpoint<void>(
        'machine',
        'reportStartup',
        {'token': token},
      );

  /// Resolves the [Machine] a registration token belongs to, without
  /// mutating heartbeat state. Used by the agent-runner daemon at startup to
  /// learn its own machine id before subscribing to
  /// [TaskEndpoint.watchAssignedTasks] (docs/FLOWS.md §4).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<_iwz93qz1.Machine> identify(String token) =>
      caller.callServerEndpoint<_iwz93qz1.Machine>(
        'machine',
        'identify',
        {'token': token},
      );

  /// Called periodically by the agent-runner daemon (docs/FLOWS.md §4). Stores
  /// a new [MachineMetric] row and notifies [watchLatestMetric] subscribers.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> reportMetric(
    String token,
    double cpuPercent,
    int memoryUsedMb,
    int memoryTotalMb,
  ) => caller.callServerEndpoint<void>(
    'machine',
    'reportMetric',
    {
      'token': token,
      'cpuPercent': cpuPercent,
      'memoryUsedMb': memoryUsedMb,
      'memoryTotalMb': memoryTotalMb,
    },
  );

  /// Called by the daemon at startup and on every heartbeat tick to report
  /// whether its configured `claude` executable can actually be launched —
  /// surfaced as a warning banner on the machine's card in the panel instead
  /// of only in `journalctl -u agent-runner`. [message] should be null when
  /// [ok] is true, and an actionable error description otherwise.
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> reportClaudeStatus(
    String token,
    bool ok,
    String? message,
  ) => caller.callServerEndpoint<void>(
    'machine',
    'reportClaudeStatus',
    {
      'token': token,
      'ok': ok,
      'message': message,
    },
  );

  /// Called by the daemon at startup with the tools it found on its PATH
  /// (see [Machine.toolchain]).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> reportToolchain(
    String token,
    List<String> toolchain,
  ) => caller.callServerEndpoint<void>(
    'machine',
    'reportToolchain',
    {
      'token': token,
      'toolchain': toolchain,
    },
  );

  /// Called by the daemon at startup with the OS it runs on (see
  /// [Machine.osVersion]).
  ///
  /// Throws [InvalidTokenException] if [token] doesn't match any currently
  /// registered machine.
  _ida.Future<void> reportOsVersion(
    String token,
    String osVersion,
  ) => caller.callServerEndpoint<void>(
    'machine',
    'reportOsVersion',
    {
      'token': token,
      'osVersion': osVersion,
    },
  );

  /// Streams the latest [MachineMetric] for [machineId] (docs/FLOWS.md §6
  /// snapshot) — replays the current latest row on subscribe, then yields
  /// each new one as [reportMetric] stores it.
  _ida.Stream<_il2pq5ll.MachineMetric> watchLatestMetric(int machineId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_il2pq5ll.MachineMetric>,
        _il2pq5ll.MachineMetric
      >(
        'machine',
        'watchLatestMetric',
        {'machineId': machineId},
        {},
      );

  /// Deletes an offline machine whose agents have no non-terminal tasks.
  /// Its agents go with it, so their still-active code reviews are failed
  /// (see [_deleteMachine]).
  _ida.Future<void> delete(int id) => caller.callServerEndpoint<void>(
    'machine',
    'delete',
    {'id': id},
  );
}

/// Basic CRUD for [Project]. Deletion is blocked while it has non-terminal
/// tasks, mirroring [AgentEndpoint]/[MachineEndpoint]'s guard.
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
    List<_itcevbxn.ProjectTool>? tools,
  }) => caller.callServerEndpoint<_i76mncv2.Project>(
    'project',
    'create',
    {
      'name': name,
      'repoUrl': repoUrl,
      'repoAccessToken': repoAccessToken,
      'dockerImage': dockerImage,
      'tools': tools,
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

  /// Edits a project's name, repo URL and docker image. The access token
  /// goes through [updateRepoAccessToken], task defaults through
  /// `SettingsEndpoint.updateProjectTaskDefaults`.
  _ida.Future<_i76mncv2.Project> update(_i76mncv2.Project project) =>
      caller.callServerEndpoint<_i76mncv2.Project>(
        'project',
        'update',
        {'project': project},
      );

  /// Replaces the toolchains the runner installs before each task.
  _ida.Future<_i76mncv2.Project> updateTools(
    int projectId,
    List<_itcevbxn.ProjectTool> tools,
  ) => caller.callServerEndpoint<_i76mncv2.Project>(
    'project',
    'updateTools',
    {
      'projectId': projectId,
      'tools': tools,
    },
  );

  /// Suggests the toolchains of the GitHub repo at [repoUrl] from its
  /// manifests (pubspec.yaml, package.json, .nvmrc, …) — a proposal the
  /// panel shows for confirmation. Uses [repoAccessToken], else the stored
  /// token of [projectId], else none (public repos). Empty for a non-GitHub
  /// URL.
  _ida.Future<List<_itcevbxn.ProjectTool>> detectTools(
    String repoUrl, {
    String? repoAccessToken,
    int? projectId,
  }) => caller.callServerEndpoint<List<_itcevbxn.ProjectTool>>(
    'project',
    'detectTools',
    {
      'repoUrl': repoUrl,
      'repoAccessToken': repoAccessToken,
      'projectId': projectId,
    },
  );

  /// Sets a new repo access token, keeping `scope=serverOnly` intact — the
  /// token itself is never echoed back, only the (non-sensitive)
  /// `repoAccessTokenUpdatedAt` timestamp is observable from the panel.
  _ida.Future<void> updateRepoAccessToken(
    int projectId,
    String token,
  ) => caller.callServerEndpoint<void>(
    'project',
    'updateRepoAccessToken',
    {
      'projectId': projectId,
      'token': token,
    },
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
  /// agent side (docs/ARCHITECTURE.md).
  _ida.Future<String> getCloneUrl(int projectId) =>
      caller.callServerEndpoint<String>(
        'project',
        'getCloneUrl',
        {'projectId': projectId},
      );
}

/// Workspace settings and the task defaults resolved from them.
///
/// Defaults cascade workspace → project → task: a project's nullable
/// override wins over the workspace value, and the result only pre-fills the
/// new-task form — the task stores its own copy, so later settings changes
/// never affect tasks that already exist.
/// {@category Endpoint}
class EndpointSettings extends _isc.EndpointRef {
  EndpointSettings(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  _ida.Future<_ix9sl716.WorkspaceSettings> getWorkspace() =>
      caller.callServerEndpoint<_ix9sl716.WorkspaceSettings>(
        'settings',
        'getWorkspace',
        {},
      );

  _ida.Future<_ix9sl716.WorkspaceSettings> updateWorkspace(
    _ix9sl716.WorkspaceSettings settings,
  ) => caller.callServerEndpoint<_ix9sl716.WorkspaceSettings>(
    'settings',
    'updateWorkspace',
    {'settings': settings},
  );

  /// Saves [project]'s task-default overrides (a null field inherits the
  /// workspace value); its other fields are ignored.
  _ida.Future<_i76mncv2.Project> updateProjectTaskDefaults(
    _i76mncv2.Project project,
  ) => caller.callServerEndpoint<_i76mncv2.Project>(
    'settings',
    'updateProjectTaskDefaults',
    {'project': project},
  );

  /// The options a new task in [projectId] starts with.
  _ida.Future<_ik8cj6du.TaskDefaults> taskDefaults(int projectId) =>
      caller.callServerEndpoint<_ik8cj6du.TaskDefaults>(
        'settings',
        'taskDefaults',
        {'projectId': projectId},
      );
}

/// Images attached to a task's prompt. The panel uploads them while the dev
/// writes the prompt ([upload]) and links them on `TaskEndpoint.createTask`;
/// the panel and the agent runner read them back by id.
/// {@category Endpoint}
class EndpointTaskAttachment extends _isc.EndpointRef {
  EndpointTaskAttachment(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'taskAttachment';

  /// Stores [bytes] and returns the not-yet-linked attachment. The type is
  /// sniffed from the bytes rather than trusted from the client, and the
  /// storage path is generated here.
  _ida.Future<_iowm7apo.TaskAttachment> upload(
    String fileName,
    _idt.ByteData bytes,
  ) => caller.callServerEndpoint<_iowm7apo.TaskAttachment>(
    'taskAttachment',
    'upload',
    {
      'fileName': fileName,
      'bytes': bytes,
    },
  );

  /// The attachments of [taskId], oldest first.
  _ida.Future<List<_iowm7apo.TaskAttachment>> list(int taskId) =>
      caller.callServerEndpoint<List<_iowm7apo.TaskAttachment>>(
        'taskAttachment',
        'list',
        {'taskId': taskId},
      );

  /// The image bytes of attachment [id].
  _ida.Future<_idt.ByteData> download(int id) =>
      caller.callServerEndpoint<_idt.ByteData>(
        'taskAttachment',
        'download',
        {'id': id},
      );

  /// Removes an attachment that isn't linked to a task yet — the dev took
  /// it out of the prompt before creating the task.
  _ida.Future<void> discard(int id) => caller.callServerEndpoint<void>(
    'taskAttachment',
    'discard',
    {'id': id},
  );
}

/// Task creation and the daemon's assignment feed (docs/FLOWS.md §4).
/// {@category Endpoint}
class EndpointTask extends _isc.EndpointRef {
  EndpointTask(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'task';

  /// Creates a [Task] (docs/FLOWS.md §4). With an [agentId] it's
  /// `queued` and the agent's machine is notified via [watchAssignedTasks];
  /// without one it's a `draft` that nothing picks up until an agent is
  /// assigned via [reassignAgent].
  _ida.Future<_iw53rmon.Task> createTask(
    int projectId,
    int? agentId,
    String prompt, {
    required bool skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
    List<int>? attachmentIds,
  }) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'createTask',
    {
      'projectId': projectId,
      'agentId': agentId,
      'prompt': prompt,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      'reviewerAgentId': reviewerAgentId,
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
      'attachmentIds': attachmentIds,
    },
  );

  /// Used by the agent daemon to report a run's progress and outcome —
  /// e.g. `queued` → `planning`/`running`, `running` →
  /// `awaitingReview`/`failed` — and to persist `claudeSessionId`, the branch
  /// and the PR URL. Only the columns the daemon owns are written, and only
  /// to a status in [_runnerSettableStatuses] — any other status in [task]
  /// is ignored and the current one kept. Bumps `lastProgressAt` (see
  /// [StalledTaskFutureCall]).
  ///
  /// A task that already reached a terminal state server-side (cancelled
  /// from the panel, failed by a future call, merged) is final: a late
  /// write from the daemon is ignored and the current row returned, rather
  /// than reviving it or throwing at a daemon that can't do anything about
  /// it. The same goes for a `draft` — nothing runs a draft, so a write to
  /// one comes from a run that was cancelled back to the backlog.
  _ida.Future<_iw53rmon.Task> update(_iw53rmon.Task task) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'update',
        {'task': task},
      );

  /// Squash-merges [taskId]'s PR and marks the task `done` — only once the
  /// GitHub Actions checks of the PR's current head commit passed (or the
  /// repo has no CI, or they can't be read), read fresh from GitHub rather
  /// than trusted from the last poll, no fix run is queued, and only that
  /// exact commit. With [force] the dev overrides the checks (e.g. a flaky
  /// or non-required job) — GitHub's branch protection still applies. If
  /// GitHub refuses the merge (conflicts, a newer commit, a required check,
  /// ...) the task stays in `awaitingReview` and the reason is thrown back
  /// to the panel. Also wakes the agent's daemon so it removes the task's
  /// worktree.
  _ida.Future<_iw53rmon.Task> acceptTask(
    int taskId, {
    required bool force,
  }) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'acceptTask',
    {
      'taskId': taskId,
      'force': force,
    },
  );

  /// Whether [taskId]'s PR conflicts with its base branch, so the panel can
  /// offer "Resolve conflicts" instead of "Accept & merge".
  _ida.Future<_ikiwas8h.PrMergeStatus> getMergeStatus(int taskId) =>
      caller.callServerEndpoint<_ikiwas8h.PrMergeStatus>(
        'task',
        'getMergeStatus',
        {'taskId': taskId},
      );

  /// Sends the agent a fix run that merges the base branch into the task's
  /// branch, resolves the conflicts and pushes — the same `--resume` path as
  /// [submitFeedback].
  _ida.Future<_ifl2c5cu.TaskFeedback> resolveConflicts(int taskId) =>
      caller.callServerEndpoint<_ifl2c5cu.TaskFeedback>(
        'task',
        'resolveConflicts',
        {'taskId': taskId},
      );

  /// Returns [taskId]'s GitHub Actions checks as last synced (see
  /// [watchChecks]).
  _ida.Future<_ixcrf414.PrChecks> getChecks(int taskId) =>
      caller.callServerEndpoint<_ixcrf414.PrChecks>(
        'task',
        'getChecks',
        {'taskId': taskId},
      );

  /// Streams [taskId]'s GitHub Actions checks: the current snapshot on
  /// subscribe, then a new one whenever a sync (every 30 s while the task is
  /// in review, or [refreshChecks]) changes them.
  _ida.Stream<_ixcrf414.PrChecks> watchChecks(int taskId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ixcrf414.PrChecks>,
        _ixcrf414.PrChecks
      >(
        'task',
        'watchChecks',
        {'taskId': taskId},
        {},
      );

  /// Reads [taskId]'s checks from GitHub now, instead of waiting for the
  /// next poll.
  _ida.Future<_ixcrf414.PrChecks> refreshChecks(int taskId) =>
      caller.callServerEndpoint<_ixcrf414.PrChecks>(
        'task',
        'refreshChecks',
        {'taskId': taskId},
      );

  /// Sends the agent a fix run for [taskId]'s failing CI checks — all of
  /// them, or only [jobIds] — with each job's log in the prompt and the
  /// dev's optional [note]. Same `--resume` path as [resolveConflicts].
  _ida.Future<_ifl2c5cu.TaskFeedback> fixFailingChecks(
    int taskId, {
    List<int>? jobIds,
    String? note,
  }) => caller.callServerEndpoint<_ifl2c5cu.TaskFeedback>(
    'task',
    'fixFailingChecks',
    {
      'taskId': taskId,
      'jobIds': jobIds,
      'note': note,
    },
  );

  /// Persists one line of a task's execution output as a [TaskLogEntry]
  /// (docs/FLOWS.md §4) and notifies any [watchLogs] subscribers for this
  /// task. Also bumps `Task.lastProgressAt`, since a log line is a sign of
  /// activity — see [StalledTaskFutureCall].
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

  /// Continues a task that finished without code changes (its result is
  /// the agent's reply, e.g. an analysis or an answer) by resuming the same
  /// Claude Code session with [message] — "now implement it". The task goes
  /// back to `awaitingReview` so the daemon's resume path picks it up; it
  /// ends either with a PR (if the agent changes code) or `done` again with
  /// a new result.
  _ida.Future<_ifl2c5cu.TaskFeedback> continueTask(
    int taskId,
    String message,
  ) => caller.callServerEndpoint<_ifl2c5cu.TaskFeedback>(
    'task',
    'continueTask',
    {
      'taskId': taskId,
      'message': message,
    },
  );

  /// Resumes a task paused by a usage limit right away instead of waiting
  /// for `pausedUntil` — e.g. after the dev raised the plan's limit.
  _ida.Future<_iw53rmon.Task> resumeTask(int taskId) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'resumeTask',
        {'taskId': taskId},
      );

  /// Persists a structured log entry (kind, run, tool…) from the daemon —
  /// see [TaskLogEntry]. Same side effects as [appendLog]; the server
  /// assigns the id and timestamp.
  _ida.Future<_inlvye37.TaskLogEntry> appendLogEntry(
    _inlvye37.TaskLogEntry entry,
  ) => caller.callServerEndpoint<_inlvye37.TaskLogEntry>(
    'task',
    'appendLogEntry',
    {'entry': entry},
  );

  /// Cancels a task that hasn't reached a terminal state yet (docs/FLOWS.md §4
  /// "Cancelling mid-run"): moves it back to the backlog as an agent-less
  /// `draft`, reset like [retryTask] does (the branch and PR are kept, so a
  /// later run pushes onto them), and notifies [watchTask] subscribers — the
  /// daemon running the task reacts by sending `SIGTERM` to the Claude Code
  /// subprocess and resetting the worktree. Assigning an agent again
  /// ([reassignAgent]) restarts it.
  _ida.Future<_iw53rmon.Task> cancelTask(int taskId) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'cancelTask',
        {'taskId': taskId},
      );

  /// Re-queues a `failed` or `cancelled` task for another attempt, without
  /// the dev having to recreate it from scratch. Resets it to look exactly
  /// like a brand new `queued` task — clearing `claudeSessionId` in
  /// particular, so `TaskDispatcher.handle` starts a fresh Claude Code
  /// invocation rather than trying to `--resume` a session that already
  /// ended in failure/cancellation. Wakes the daemon via the same channel
  /// [createTask] uses.
  _ida.Future<_iw53rmon.Task> retryTask(int taskId) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'retryTask',
        {'taskId': taskId},
      );

  /// Assigns [agentId] to [taskId] — either giving an agent-less task one
  /// (its previous agent was deleted, see `Agent.machine`'s
  /// `onDelete=Cascade`) or moving a backlog/review task to a different
  /// agent. Blocked while the task is actively executing under its current
  /// agent (`planning`/`running`/etc.) to avoid pulling an agent out from
  /// under a live Claude Code run; not blocked when there's no current agent
  /// at all, since in that case nothing is actually running.
  _ida.Future<_iw53rmon.Task> reassignAgent(
    int taskId,
    int agentId,
  ) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'reassignAgent',
    {
      'taskId': taskId,
      'agentId': agentId,
    },
  );

  /// Records feedback on a completed run (docs/FLOWS.md §4) and
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

  /// Edits [taskId]'s prompt and advanced options from the panel. Every
  /// value is sent; a null [reviewerAgentId] clears the reviewer. The
  /// automation options are read fresh each time they apply, so they can
  /// change any time before the task is `done`; the prompt and
  /// [skipPlanning] only while no run is under way (see
  /// [_promptEditableStatuses]). Turning auto review on applies from the
  /// next version the agent finishes.
  _ida.Future<_iw53rmon.Task> updateTaskSettings(
    int taskId,
    String prompt, {
    bool? skipPlanning,
    bool? autoReview,
    int? reviewerAgentId,
    bool? autoFixReview,
    int? maxReviewFixRounds,
    bool? autoMerge,
    bool? autoFixFailingChecks,
    int? maxCheckFixAttempts,
  }) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'updateTaskSettings',
    {
      'taskId': taskId,
      'prompt': prompt,
      'skipPlanning': skipPlanning,
      'autoReview': autoReview,
      'reviewerAgentId': reviewerAgentId,
      'autoFixReview': autoFixReview,
      'maxReviewFixRounds': maxReviewFixRounds,
      'autoMerge': autoMerge,
      'autoFixFailingChecks': autoFixFailingChecks,
      'maxCheckFixAttempts': maxCheckFixAttempts,
    },
  );

  /// Sets [taskId]'s title from the agent's `set_task_title` tool
  /// (docs/FLOWS.md §4) — only while the task has none, so it never
  /// replaces a title the dev chose or one from an earlier run. A blank
  /// [title] is ignored. Returns the current task either way.
  _ida.Future<_iw53rmon.Task> suggestTitle(
    int taskId,
    String title,
  ) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'suggestTitle',
    {
      'taskId': taskId,
      'title': title,
    },
  );

  /// Renames [taskId] from the panel. A blank [title] clears it: the board
  /// falls back to the prompt and the agent may suggest one again on its
  /// next run.
  _ida.Future<_iw53rmon.Task> setTitle(
    int taskId,
    String? title,
  ) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'setTitle',
    {
      'taskId': taskId,
      'title': title,
    },
  );

  /// Records a plan-mode clarifying question (docs/FLOWS.md §4
  /// `AskUserQuestion`), asked by the permission-prompt-tool intercepting
  /// Claude Code's tool call. Flips `Task.status = waitingForAnswer` so the
  /// panel can render it.
  _ida.Future<_ihmnezqk.TaskQuestion> createQuestion(
    int taskId,
    String question,
    List<String> options,
  ) => caller.callServerEndpoint<_ihmnezqk.TaskQuestion>(
    'task',
    'createQuestion',
    {
      'taskId': taskId,
      'question': question,
      'options': options,
    },
  );

  /// Answers a plan-mode clarifying question (docs/FLOWS.md §4), waking the
  /// permission-prompt-tool blocked on [watchAnswer], and moves the task back
  /// to `planning` since Claude Code resumes as soon as the tool returns.
  _ida.Future<_ihmnezqk.TaskQuestion> answerQuestion(
    int questionId,
    String answer,
  ) => caller.callServerEndpoint<_ihmnezqk.TaskQuestion>(
    'task',
    'answerQuestion',
    {
      'questionId': questionId,
      'answer': answer,
    },
  );

  /// Streams [questionId]'s answer, for the permission-prompt-tool to block
  /// on while Claude Code waits on `AskUserQuestion` (docs/FLOWS.md §4). On
  /// subscribe, replays the question immediately if it was already answered
  /// before the subscriber attached.
  _ida.Stream<_ihmnezqk.TaskQuestion> watchAnswer(int questionId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ihmnezqk.TaskQuestion>,
        _ihmnezqk.TaskQuestion
      >(
        'task',
        'watchAnswer',
        {'questionId': questionId},
        {},
      );

  /// Returns the most recently asked [TaskQuestion] for [taskId], or `null`
  /// if none exists — mirrors [latestFeedback]. The panel checks
  /// `Task.status == waitingForAnswer` to decide whether this is still
  /// pending, since this method doesn't distinguish an answered question
  /// from an unanswered one.
  _ida.Future<_ihmnezqk.TaskQuestion?> latestQuestion(int taskId) =>
      caller.callServerEndpoint<_ihmnezqk.TaskQuestion?>(
        'task',
        'latestQuestion',
        {'taskId': taskId},
      );

  /// Stores a ready plan (docs/FLOWS.md §4 `ExitPlanMode`) and flips
  /// `Task.status = planReady`, so the dev can approve it or give feedback.
  _ida.Future<_iw53rmon.Task> setPlanReady(
    int taskId,
    String plan,
  ) => caller.callServerEndpoint<_iw53rmon.Task>(
    'task',
    'setPlanReady',
    {
      'taskId': taskId,
      'plan': plan,
    },
  );

  /// Approves the current plan (docs/FLOWS.md §4), waking the
  /// permission-prompt-tool blocked on [watchPlanDecision] so it lets
  /// `ExitPlanMode` through and Claude Code proceeds to implement.
  _ida.Future<_iw53rmon.Task> approvePlan(int taskId) =>
      caller.callServerEndpoint<_iw53rmon.Task>(
        'task',
        'approvePlan',
        {'taskId': taskId},
      );

  /// Rejects the current plan with feedback (docs/FLOWS.md §4), waking the
  /// permission-prompt-tool so it denies `ExitPlanMode` and returns the
  /// feedback message as the reason — Claude Code plans again in the same
  /// process.
  _ida.Future<_ifl2c5cu.TaskFeedback> submitPlanFeedback(
    int taskId,
    String message,
  ) => caller.callServerEndpoint<_ifl2c5cu.TaskFeedback>(
    'task',
    'submitPlanFeedback',
    {
      'taskId': taskId,
      'message': message,
    },
  );

  /// Streams the dev's decision on [taskId]'s current plan (docs/FLOWS.md §4),
  /// for the permission-prompt-tool to block on while `ExitPlanMode`
  /// is pending. Deliberately doesn't replay on subscribe — the tool always
  /// subscribes right after setting `planReady` itself via [setPlanReady],
  /// so a decision is always a future event, never one already made.
  _ida.Stream<_iw53rmon.Task> watchPlanDecision(int taskId) => caller
      .callStreamingServerEndpoint<_ida.Stream<_iw53rmon.Task>, _iw53rmon.Task>(
        'task',
        'watchPlanDecision',
        {'taskId': taskId},
        {},
      );

  /// Deletes a task once it's reached a terminal state — a non-terminal one
  /// has to be cancelled first (mirrors [cancelTask]'s own guard, just
  /// inverted). Its logs/questions/feedback cascade-delete with it (see
  /// `Task`'s relations). Broadcasts a [TaskDeleted] on the same channel
  /// [watchAllTasks] uses, since deleting the row leaves no `Task` to post as
  /// an update.
  _ida.Future<void> deleteTask(int taskId) => caller.callServerEndpoint<void>(
    'task',
    'deleteTask',
    {'taskId': taskId},
  );

  /// Streams [TaskDeleted] broadcasts from [deleteTask], for the dashboard
  /// kanban to drop a deleted task from its local list. Uses its own channel:
  /// sharing [channelForAllTasks] would feed `Task` messages into a
  /// `TaskDeleted`-typed stream (and vice versa for [watchAllTasks]).
  /// Deliberately doesn't replay anything on subscribe, same reasoning as
  /// [watchPlanDecision]: a deletion is always a future event relative to
  /// subscribing.
  _ida.Stream<_iwt28wmq.TaskDeleted> watchTaskDeletions() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_iwt28wmq.TaskDeleted>,
        _iwt28wmq.TaskDeleted
      >(
        'task',
        'watchTaskDeletions',
        {},
        {},
      );

  /// Returns the tasks among [taskIds] that still exist. Used by the
  /// daemon's worktree cleanup to tell which on-disk worktrees belong to
  /// deleted or finished tasks.
  _ida.Future<List<_iw53rmon.Task>> findTasks(List<int> taskIds) =>
      caller.callServerEndpoint<List<_iw53rmon.Task>>(
        'task',
        'findTasks',
        {'taskIds': taskIds},
      );

  /// Returns the list of files changed in [taskId]'s pull request
  /// (docs/FLOWS.md §4), fetched from the GitHub API using the project's
  /// `repoAccessToken` — never returned to the panel.
  _ida.Future<List<_iusyva9a.DiffFile>> getChangedFiles(int taskId) =>
      caller.callServerEndpoint<List<_iusyva9a.DiffFile>>(
        'task',
        'getChangedFiles',
        {'taskId': taskId},
      );

  /// Returns the raw content of the file at [contentsUrl] (as returned by
  /// [getChangedFiles]) for [taskId]'s repository (docs/FLOWS.md §4).
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

  /// Streams every task, for the panel's dashboard kanban (docs/ARCHITECTURE.md
  /// "Should"), not the daemon, which uses [watchAssignedTasks] instead. On
  /// subscribe, replays every task currently in the database, then yields
  /// each task again whenever any of the status-changing methods above
  /// (create/update/cancel/plan transitions) touches it — the panel merges
  /// each update into its in-memory task list by id.
  _ida.Stream<_iw53rmon.Task> watchAllTasks() => caller
      .callStreamingServerEndpoint<_ida.Stream<_iw53rmon.Task>, _iw53rmon.Task>(
        'task',
        'watchAllTasks',
        {},
        {},
      );

  /// Streams tasks newly assigned to any agent hosted on [machineId] — by
  /// machine, not by agent, since one daemon serves every agent it hosts.
  /// On subscribe, first replays the machine's non-terminal tasks —
  /// otherwise a task created while the daemon was offline/restarting would
  /// never surface — then yields each task posted to the machine's channel
  /// (created, retried, reassigned, fed back, merged).
  _ida.Stream<_iw53rmon.Task> watchAssignedTasks(int machineId) => caller
      .callStreamingServerEndpoint<_ida.Stream<_iw53rmon.Task>, _iw53rmon.Task>(
        'task',
        'watchAssignedTasks',
        {'machineId': machineId},
        {},
      );

  /// Streams a task's execution output as it's persisted via [appendLog]
  /// (docs/FLOWS.md §4), for the panel to render live. On subscribe, first
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
  /// cancellation mid-run, docs/FLOWS.md §4) and the panel alike. On
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
    agentRole = EndpointAgentRole(this);
    codeReview = EndpointCodeReview(this);
    machine = EndpointMachine(this);
    project = EndpointProject(this);
    settings = EndpointSettings(this);
    taskAttachment = EndpointTaskAttachment(this);
    task = EndpointTask(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAgent agent;

  late final EndpointAgentRole agentRole;

  late final EndpointCodeReview codeReview;

  late final EndpointMachine machine;

  late final EndpointProject project;

  late final EndpointSettings settings;

  late final EndpointTaskAttachment taskAttachment;

  late final EndpointTask task;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'agent': agent,
    'agentRole': agentRole,
    'codeReview': codeReview,
    'machine': machine,
    'project': project,
    'settings': settings,
    'taskAttachment': taskAttachment,
    'task': task,
    'greeting': greeting,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
