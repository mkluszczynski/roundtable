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
import 'dart:typed_data' as _idt;
import 'package:roundtable_server/src/generated/agent.dart' as _iaucj7w0;
import 'package:roundtable_server/src/generated/agent_effort.dart' as _i293npqp;
import 'package:roundtable_server/src/generated/agent_execution_mode.dart'
    as _i5zg6kl8;
import 'package:roundtable_server/src/generated/agent_role_definition.dart'
    as _ifj5d7s0;
import 'package:roundtable_server/src/generated/agent_status.dart' as _ii7o6oli;
import 'package:roundtable_server/src/generated/code_review_verdict.dart'
    as _i0brbj9a;
import 'package:roundtable_server/src/generated/future_calls.dart' as _iewj8v67;
import 'package:roundtable_server/src/generated/log_source.dart' as _iexu01r8;
import 'package:roundtable_server/src/generated/machine.dart' as _ilqrziin;
import 'package:roundtable_server/src/generated/project.dart' as _ii35q81x;
import 'package:roundtable_server/src/generated/project_tool.dart' as _i1odv8ju;
import 'package:roundtable_server/src/generated/review_comment_check.dart'
    as _iqs7w1y3;
import 'package:roundtable_server/src/generated/review_comment_draft.dart'
    as _i245mzjz;
import 'package:roundtable_server/src/generated/review_comment_state.dart'
    as _i5cy068t;
import 'package:roundtable_server/src/generated/task.dart' as _i77xifuu;
import 'package:roundtable_server/src/generated/task_log_entry.dart'
    as _in2gwlh7;
import 'package:roundtable_server/src/generated/workspace_settings.dart'
    as _ivf29hul;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../endpoints/agent_endpoint.dart' as _ik1xrao3;
import '../endpoints/agent_role_endpoint.dart' as _i9jtfumf;
import '../endpoints/code_review_endpoint.dart' as _ia5tunx2;
import '../endpoints/machine_endpoint.dart' as _ij6wllr0;
import '../endpoints/project_endpoint.dart' as _iemg8ri2;
import '../endpoints/settings_endpoint.dart' as _ivmxe84z;
import '../endpoints/task_attachment_endpoint.dart' as _iqxurivk;
import '../endpoints/task_endpoint.dart' as _idmllfay;
import '../greetings/greeting_endpoint.dart' as _il624ik7;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'agent': _ik1xrao3.AgentEndpoint()
        ..initialize(
          server,
          'agent',
          null,
        ),
      'agentRole': _i9jtfumf.AgentRoleEndpoint()
        ..initialize(
          server,
          'agentRole',
          null,
        ),
      'codeReview': _ia5tunx2.CodeReviewEndpoint()
        ..initialize(
          server,
          'codeReview',
          null,
        ),
      'machine': _ij6wllr0.MachineEndpoint()
        ..initialize(
          server,
          'machine',
          null,
        ),
      'project': _iemg8ri2.ProjectEndpoint()
        ..initialize(
          server,
          'project',
          null,
        ),
      'settings': _ivmxe84z.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
      'taskAttachment': _iqxurivk.TaskAttachmentEndpoint()
        ..initialize(
          server,
          'taskAttachment',
          null,
        ),
      'task': _idmllfay.TaskEndpoint()
        ..initialize(
          server,
          'task',
          null,
        ),
      'greeting': _il624ik7.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['agent'] = _is.EndpointConnector(
      name: 'agent',
      endpoint: endpoints['agent']!,
      methodConnectors: {
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'machineId': _is.ParameterDescription(
              name: 'machineId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'roleId': _is.ParameterDescription(
              name: 'roleId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'defaultModel': _is.ParameterDescription(
              name: 'defaultModel',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'defaultEffort': _is.ParameterDescription(
              name: 'defaultEffort',
              type: _is.getType<_i293npqp.AgentEffort?>(),
              nullable: true,
            ),
            'executionMode': _is.ParameterDescription(
              name: 'executionMode',
              type: _is.getType<_i5zg6kl8.AgentExecutionMode?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _ik1xrao3.AgentEndpoint).create(
                session,
                params['name'],
                params['machineId'],
                roleId: params['roleId'],
                defaultModel: params['defaultModel'],
                defaultEffort: params['defaultEffort'],
                executionMode: params['executionMode'],
              ),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _ik1xrao3.AgentEndpoint).get(
                session,
                params['id'],
              ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['agent'] as _ik1xrao3.AgentEndpoint).list(session),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'agent': _is.ParameterDescription(
              name: 'agent',
              type: _is.getType<_iaucj7w0.Agent>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _ik1xrao3.AgentEndpoint).update(
                session,
                params['agent'],
              ),
        ),
        'setStatus': _is.MethodConnector(
          name: 'setStatus',
          params: {
            'agentId': _is.ParameterDescription(
              name: 'agentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'status': _is.ParameterDescription(
              name: 'status',
              type: _is.getType<_ii7o6oli.AgentStatus>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['agent'] as _ik1xrao3.AgentEndpoint).setStatus(
                    session,
                    params['agentId'],
                    params['status'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _ik1xrao3.AgentEndpoint).delete(
                session,
                params['id'],
              ),
        ),
      },
    );
    connectors['agentRole'] = _is.EndpointConnector(
      name: 'agentRole',
      endpoint: endpoints['agentRole']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agentRole'] as _i9jtfumf.AgentRoleEndpoint)
                  .list(session),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_ifj5d7s0.AgentRoleDefinition>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agentRole'] as _i9jtfumf.AgentRoleEndpoint)
                  .create(
                    session,
                    params['role'],
                  ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_ifj5d7s0.AgentRoleDefinition>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agentRole'] as _i9jtfumf.AgentRoleEndpoint)
                  .update(
                    session,
                    params['role'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agentRole'] as _i9jtfumf.AgentRoleEndpoint)
                  .delete(
                    session,
                    params['id'],
                  ),
        ),
      },
    );
    connectors['codeReview'] = _is.EndpointConnector(
      name: 'codeReview',
      endpoint: endpoints['codeReview']!,
      methodConnectors: {
        'requestReview': _is.MethodConnector(
          name: 'requestReview',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'agentId': _is.ParameterDescription(
              name: 'agentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .requestReview(
                        session,
                        params['taskId'],
                        params['agentId'],
                      ),
        ),
        'startReview': _is.MethodConnector(
          name: 'startReview',
          params: {
            'reviewId': _is.ParameterDescription(
              name: 'reviewId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .startReview(
                        session,
                        params['reviewId'],
                      ),
        ),
        'previousComments': _is.MethodConnector(
          name: 'previousComments',
          params: {
            'reviewId': _is.ParameterDescription(
              name: 'reviewId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .previousComments(
                        session,
                        params['reviewId'],
                      ),
        ),
        'completeReview': _is.MethodConnector(
          name: 'completeReview',
          params: {
            'reviewId': _is.ParameterDescription(
              name: 'reviewId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'summary': _is.ParameterDescription(
              name: 'summary',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'drafts': _is.ParameterDescription(
              name: 'drafts',
              type: _is.getType<List<_i245mzjz.ReviewCommentDraft>>(),
              nullable: false,
            ),
            'checks': _is.ParameterDescription(
              name: 'checks',
              type: _is.getType<List<_iqs7w1y3.ReviewCommentCheck>?>(),
              nullable: true,
            ),
            'verdict': _is.ParameterDescription(
              name: 'verdict',
              type: _is.getType<_i0brbj9a.CodeReviewVerdict?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .completeReview(
                        session,
                        params['reviewId'],
                        params['summary'],
                        params['drafts'],
                        checks: params['checks'],
                        verdict: params['verdict'],
                      ),
        ),
        'requeueReview': _is.MethodConnector(
          name: 'requeueReview',
          params: {
            'reviewId': _is.ParameterDescription(
              name: 'reviewId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .requeueReview(
                        session,
                        params['reviewId'],
                      ),
        ),
        'failReview': _is.MethodConnector(
          name: 'failReview',
          params: {
            'reviewId': _is.ParameterDescription(
              name: 'reviewId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .failReview(
                        session,
                        params['reviewId'],
                        params['reason'],
                      ),
        ),
        'setCommentState': _is.MethodConnector(
          name: 'setCommentState',
          params: {
            'commentId': _is.ParameterDescription(
              name: 'commentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'state': _is.ParameterDescription(
              name: 'state',
              type: _is.getType<_i5cy068t.ReviewCommentState>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .setCommentState(
                        session,
                        params['commentId'],
                        params['state'],
                      ),
        ),
        'sendCommentsToFix': _is.MethodConnector(
          name: 'sendCommentsToFix',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'commentIds': _is.ParameterDescription(
              name: 'commentIds',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                      .sendCommentsToFix(
                        session,
                        params['taskId'],
                        params['commentIds'],
                        params['note'],
                      ),
        ),
        'watchAssignedReviews': _is.MethodStreamConnector(
          name: 'watchAssignedReviews',
          params: {
            'machineId': _is.ParameterDescription(
              name: 'machineId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                  .watchAssignedReviews(
                    session,
                    params['machineId'],
                  ),
        ),
        'watchReviews': _is.MethodStreamConnector(
          name: 'watchReviews',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['codeReview'] as _ia5tunx2.CodeReviewEndpoint)
                  .watchReviews(
                    session,
                    params['taskId'],
                  ),
        ),
      },
    );
    connectors['machine'] = _is.EndpointConnector(
      name: 'machine',
      endpoint: endpoints['machine']!,
      methodConnectors: {
        'register': _is.MethodConnector(
          name: 'register',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'hostInfo': _is.ParameterDescription(
              name: 'hostInfo',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).register(
                    session,
                    params['name'],
                    hostInfo: params['hostInfo'],
                  ),
        ),
        'getScriptUrl': _is.MethodConnector(
          name: 'getScriptUrl',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .getScriptUrl(session),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).get(
                    session,
                    params['id'],
                  ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .list(session),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'machine': _is.ParameterDescription(
              name: 'machine',
              type: _is.getType<_ilqrziin.Machine>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).update(
                    session,
                    params['machine'],
                  ),
        ),
        'heartbeat': _is.MethodConnector(
          name: 'heartbeat',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).heartbeat(
                    session,
                    params['token'],
                  ),
        ),
        'checkIn': _is.MethodConnector(
          name: 'checkIn',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'runnerVersion': _is.ParameterDescription(
              name: 'runnerVersion',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).checkIn(
                    session,
                    params['token'],
                    params['runnerVersion'],
                  ),
        ),
        'reportUsageLimit': _is.MethodConnector(
          name: 'reportUsageLimit',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'until': _is.ParameterDescription(
              name: 'until',
              type: _is.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .reportUsageLimit(
                    session,
                    params['token'],
                    params['until'],
                  ),
        ),
        'latestRunnerVersion': _is.MethodConnector(
          name: 'latestRunnerVersion',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .latestRunnerVersion(session),
        ),
        'requestRunnerUpdate': _is.MethodConnector(
          name: 'requestRunnerUpdate',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .requestRunnerUpdate(
                    session,
                    params['id'],
                  ),
        ),
        'deregister': _is.MethodConnector(
          name: 'deregister',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .deregister(
                    session,
                    params['token'],
                  ),
        ),
        'reportStartup': _is.MethodConnector(
          name: 'reportStartup',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .reportStartup(
                    session,
                    params['token'],
                  ),
        ),
        'identify': _is.MethodConnector(
          name: 'identify',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).identify(
                    session,
                    params['token'],
                  ),
        ),
        'reportMetric': _is.MethodConnector(
          name: 'reportMetric',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'cpuPercent': _is.ParameterDescription(
              name: 'cpuPercent',
              type: _is.getType<double>(),
              nullable: false,
            ),
            'memoryUsedMb': _is.ParameterDescription(
              name: 'memoryUsedMb',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'memoryTotalMb': _is.ParameterDescription(
              name: 'memoryTotalMb',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .reportMetric(
                    session,
                    params['token'],
                    params['cpuPercent'],
                    params['memoryUsedMb'],
                    params['memoryTotalMb'],
                  ),
        ),
        'reportClaudeStatus': _is.MethodConnector(
          name: 'reportClaudeStatus',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'ok': _is.ParameterDescription(
              name: 'ok',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .reportClaudeStatus(
                    session,
                    params['token'],
                    params['ok'],
                    params['message'],
                  ),
        ),
        'reportToolchain': _is.MethodConnector(
          name: 'reportToolchain',
          params: {
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'toolchain': _is.ParameterDescription(
              name: 'toolchain',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .reportToolchain(
                    session,
                    params['token'],
                    params['toolchain'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).delete(
                    session,
                    params['id'],
                  ),
        ),
        'watchLatestMetric': _is.MethodStreamConnector(
          name: 'watchLatestMetric',
          params: {
            'machineId': _is.ParameterDescription(
              name: 'machineId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['machine'] as _ij6wllr0.MachineEndpoint)
                  .watchLatestMetric(
                    session,
                    params['machineId'],
                  ),
        ),
      },
    );
    connectors['project'] = _is.EndpointConnector(
      name: 'project',
      endpoint: endpoints['project']!,
      methodConnectors: {
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'repoUrl': _is.ParameterDescription(
              name: 'repoUrl',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'repoAccessToken': _is.ParameterDescription(
              name: 'repoAccessToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'dockerImage': _is.ParameterDescription(
              name: 'dockerImage',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'tools': _is.ParameterDescription(
              name: 'tools',
              type: _is.getType<List<_i1odv8ju.ProjectTool>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _iemg8ri2.ProjectEndpoint).create(
                    session,
                    params['name'],
                    params['repoUrl'],
                    repoAccessToken: params['repoAccessToken'],
                    dockerImage: params['dockerImage'],
                    tools: params['tools'],
                  ),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _iemg8ri2.ProjectEndpoint).get(
                    session,
                    params['id'],
                  ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .list(session),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'project': _is.ParameterDescription(
              name: 'project',
              type: _is.getType<_ii35q81x.Project>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _iemg8ri2.ProjectEndpoint).update(
                    session,
                    params['project'],
                  ),
        ),
        'updateTools': _is.MethodConnector(
          name: 'updateTools',
          params: {
            'projectId': _is.ParameterDescription(
              name: 'projectId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'tools': _is.ParameterDescription(
              name: 'tools',
              type: _is.getType<List<_i1odv8ju.ProjectTool>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .updateTools(
                    session,
                    params['projectId'],
                    params['tools'],
                  ),
        ),
        'detectTools': _is.MethodConnector(
          name: 'detectTools',
          params: {
            'repoUrl': _is.ParameterDescription(
              name: 'repoUrl',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'repoAccessToken': _is.ParameterDescription(
              name: 'repoAccessToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
            'projectId': _is.ParameterDescription(
              name: 'projectId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .detectTools(
                    session,
                    params['repoUrl'],
                    repoAccessToken: params['repoAccessToken'],
                    projectId: params['projectId'],
                  ),
        ),
        'updateRepoAccessToken': _is.MethodConnector(
          name: 'updateRepoAccessToken',
          params: {
            'projectId': _is.ParameterDescription(
              name: 'projectId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'token': _is.ParameterDescription(
              name: 'token',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .updateRepoAccessToken(
                    session,
                    params['projectId'],
                    params['token'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['project'] as _iemg8ri2.ProjectEndpoint).delete(
                    session,
                    params['id'],
                  ),
        ),
        'getCloneUrl': _is.MethodConnector(
          name: 'getCloneUrl',
          params: {
            'projectId': _is.ParameterDescription(
              name: 'projectId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['project'] as _iemg8ri2.ProjectEndpoint)
                  .getCloneUrl(
                    session,
                    params['projectId'],
                  ),
        ),
      },
    );
    connectors['settings'] = _is.EndpointConnector(
      name: 'settings',
      endpoint: endpoints['settings']!,
      methodConnectors: {
        'getWorkspace': _is.MethodConnector(
          name: 'getWorkspace',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .getWorkspace(session),
        ),
        'updateWorkspace': _is.MethodConnector(
          name: 'updateWorkspace',
          params: {
            'settings': _is.ParameterDescription(
              name: 'settings',
              type: _is.getType<_ivf29hul.WorkspaceSettings>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .updateWorkspace(
                    session,
                    params['settings'],
                  ),
        ),
        'updateProjectTaskDefaults': _is.MethodConnector(
          name: 'updateProjectTaskDefaults',
          params: {
            'project': _is.ParameterDescription(
              name: 'project',
              type: _is.getType<_ii35q81x.Project>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .updateProjectTaskDefaults(
                    session,
                    params['project'],
                  ),
        ),
        'taskDefaults': _is.MethodConnector(
          name: 'taskDefaults',
          params: {
            'projectId': _is.ParameterDescription(
              name: 'projectId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _ivmxe84z.SettingsEndpoint)
                  .taskDefaults(
                    session,
                    params['projectId'],
                  ),
        ),
      },
    );
    connectors['taskAttachment'] = _is.EndpointConnector(
      name: 'taskAttachment',
      endpoint: endpoints['taskAttachment']!,
      methodConnectors: {
        'upload': _is.MethodConnector(
          name: 'upload',
          params: {
            'fileName': _is.ParameterDescription(
              name: 'fileName',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'bytes': _is.ParameterDescription(
              name: 'bytes',
              type: _is.getType<_idt.ByteData>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['taskAttachment']
                          as _iqxurivk.TaskAttachmentEndpoint)
                      .upload(
                        session,
                        params['fileName'],
                        params['bytes'],
                      ),
        ),
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['taskAttachment']
                          as _iqxurivk.TaskAttachmentEndpoint)
                      .list(
                        session,
                        params['taskId'],
                      ),
        ),
        'download': _is.MethodConnector(
          name: 'download',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['taskAttachment']
                          as _iqxurivk.TaskAttachmentEndpoint)
                      .download(
                        session,
                        params['id'],
                      ),
        ),
        'discard': _is.MethodConnector(
          name: 'discard',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['taskAttachment']
                          as _iqxurivk.TaskAttachmentEndpoint)
                      .discard(
                        session,
                        params['id'],
                      ),
        ),
      },
    );
    connectors['task'] = _is.EndpointConnector(
      name: 'task',
      endpoint: endpoints['task']!,
      methodConnectors: {
        'createTask': _is.MethodConnector(
          name: 'createTask',
          params: {
            'projectId': _is.ParameterDescription(
              name: 'projectId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'agentId': _is.ParameterDescription(
              name: 'agentId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'prompt': _is.ParameterDescription(
              name: 'prompt',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'skipPlanning': _is.ParameterDescription(
              name: 'skipPlanning',
              type: _is.getType<bool>(),
              nullable: false,
            ),
            'autoReview': _is.ParameterDescription(
              name: 'autoReview',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'reviewerAgentId': _is.ParameterDescription(
              name: 'reviewerAgentId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'autoFixReview': _is.ParameterDescription(
              name: 'autoFixReview',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'maxReviewFixRounds': _is.ParameterDescription(
              name: 'maxReviewFixRounds',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'autoMerge': _is.ParameterDescription(
              name: 'autoMerge',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'autoFixFailingChecks': _is.ParameterDescription(
              name: 'autoFixFailingChecks',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'maxCheckFixAttempts': _is.ParameterDescription(
              name: 'maxCheckFixAttempts',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'attachmentIds': _is.ParameterDescription(
              name: 'attachmentIds',
              type: _is.getType<List<int>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).createTask(
                    session,
                    params['projectId'],
                    params['agentId'],
                    params['prompt'],
                    skipPlanning: params['skipPlanning'],
                    autoReview: params['autoReview'],
                    reviewerAgentId: params['reviewerAgentId'],
                    autoFixReview: params['autoFixReview'],
                    maxReviewFixRounds: params['maxReviewFixRounds'],
                    autoMerge: params['autoMerge'],
                    autoFixFailingChecks: params['autoFixFailingChecks'],
                    maxCheckFixAttempts: params['maxCheckFixAttempts'],
                    attachmentIds: params['attachmentIds'],
                  ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'task': _is.ParameterDescription(
              name: 'task',
              type: _is.getType<_i77xifuu.Task>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['task'] as _idmllfay.TaskEndpoint).update(
                session,
                params['task'],
              ),
        ),
        'acceptTask': _is.MethodConnector(
          name: 'acceptTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'force': _is.ParameterDescription(
              name: 'force',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).acceptTask(
                    session,
                    params['taskId'],
                    force: params['force'],
                  ),
        ),
        'getMergeStatus': _is.MethodConnector(
          name: 'getMergeStatus',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).getMergeStatus(
                    session,
                    params['taskId'],
                  ),
        ),
        'resolveConflicts': _is.MethodConnector(
          name: 'resolveConflicts',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .resolveConflicts(
                    session,
                    params['taskId'],
                  ),
        ),
        'getChecks': _is.MethodConnector(
          name: 'getChecks',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).getChecks(
                    session,
                    params['taskId'],
                  ),
        ),
        'refreshChecks': _is.MethodConnector(
          name: 'refreshChecks',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).refreshChecks(
                    session,
                    params['taskId'],
                  ),
        ),
        'fixFailingChecks': _is.MethodConnector(
          name: 'fixFailingChecks',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'jobIds': _is.ParameterDescription(
              name: 'jobIds',
              type: _is.getType<List<int>?>(),
              nullable: true,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .fixFailingChecks(
                    session,
                    params['taskId'],
                    jobIds: params['jobIds'],
                    note: params['note'],
                  ),
        ),
        'appendLog': _is.MethodConnector(
          name: 'appendLog',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'content': _is.ParameterDescription(
              name: 'content',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'source': _is.ParameterDescription(
              name: 'source',
              type: _is.getType<_iexu01r8.LogSource>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).appendLog(
                    session,
                    params['taskId'],
                    params['content'],
                    source: params['source'],
                  ),
        ),
        'continueTask': _is.MethodConnector(
          name: 'continueTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).continueTask(
                    session,
                    params['taskId'],
                    params['message'],
                  ),
        ),
        'resumeTask': _is.MethodConnector(
          name: 'resumeTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).resumeTask(
                    session,
                    params['taskId'],
                  ),
        ),
        'appendLogEntry': _is.MethodConnector(
          name: 'appendLogEntry',
          params: {
            'entry': _is.ParameterDescription(
              name: 'entry',
              type: _is.getType<_in2gwlh7.TaskLogEntry>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).appendLogEntry(
                    session,
                    params['entry'],
                  ),
        ),
        'cancelTask': _is.MethodConnector(
          name: 'cancelTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).cancelTask(
                    session,
                    params['taskId'],
                  ),
        ),
        'retryTask': _is.MethodConnector(
          name: 'retryTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).retryTask(
                    session,
                    params['taskId'],
                  ),
        ),
        'reassignAgent': _is.MethodConnector(
          name: 'reassignAgent',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'agentId': _is.ParameterDescription(
              name: 'agentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).reassignAgent(
                    session,
                    params['taskId'],
                    params['agentId'],
                  ),
        ),
        'submitFeedback': _is.MethodConnector(
          name: 'submitFeedback',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).submitFeedback(
                    session,
                    params['taskId'],
                    params['message'],
                  ),
        ),
        'latestFeedback': _is.MethodConnector(
          name: 'latestFeedback',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).latestFeedback(
                    session,
                    params['taskId'],
                  ),
        ),
        'updateTaskSettings': _is.MethodConnector(
          name: 'updateTaskSettings',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'prompt': _is.ParameterDescription(
              name: 'prompt',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'skipPlanning': _is.ParameterDescription(
              name: 'skipPlanning',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'autoReview': _is.ParameterDescription(
              name: 'autoReview',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'reviewerAgentId': _is.ParameterDescription(
              name: 'reviewerAgentId',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'autoFixReview': _is.ParameterDescription(
              name: 'autoFixReview',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'maxReviewFixRounds': _is.ParameterDescription(
              name: 'maxReviewFixRounds',
              type: _is.getType<int?>(),
              nullable: true,
            ),
            'autoMerge': _is.ParameterDescription(
              name: 'autoMerge',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'autoFixFailingChecks': _is.ParameterDescription(
              name: 'autoFixFailingChecks',
              type: _is.getType<bool?>(),
              nullable: true,
            ),
            'maxCheckFixAttempts': _is.ParameterDescription(
              name: 'maxCheckFixAttempts',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .updateTaskSettings(
                    session,
                    params['taskId'],
                    params['prompt'],
                    skipPlanning: params['skipPlanning'],
                    autoReview: params['autoReview'],
                    reviewerAgentId: params['reviewerAgentId'],
                    autoFixReview: params['autoFixReview'],
                    maxReviewFixRounds: params['maxReviewFixRounds'],
                    autoMerge: params['autoMerge'],
                    autoFixFailingChecks: params['autoFixFailingChecks'],
                    maxCheckFixAttempts: params['maxCheckFixAttempts'],
                  ),
        ),
        'suggestTitle': _is.MethodConnector(
          name: 'suggestTitle',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).suggestTitle(
                    session,
                    params['taskId'],
                    params['title'],
                  ),
        ),
        'setTitle': _is.MethodConnector(
          name: 'setTitle',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['task'] as _idmllfay.TaskEndpoint).setTitle(
                session,
                params['taskId'],
                params['title'],
              ),
        ),
        'createQuestion': _is.MethodConnector(
          name: 'createQuestion',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'question': _is.ParameterDescription(
              name: 'question',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'options': _is.ParameterDescription(
              name: 'options',
              type: _is.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).createQuestion(
                    session,
                    params['taskId'],
                    params['question'],
                    params['options'],
                  ),
        ),
        'answerQuestion': _is.MethodConnector(
          name: 'answerQuestion',
          params: {
            'questionId': _is.ParameterDescription(
              name: 'questionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'answer': _is.ParameterDescription(
              name: 'answer',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).answerQuestion(
                    session,
                    params['questionId'],
                    params['answer'],
                  ),
        ),
        'latestQuestion': _is.MethodConnector(
          name: 'latestQuestion',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).latestQuestion(
                    session,
                    params['taskId'],
                  ),
        ),
        'setPlanReady': _is.MethodConnector(
          name: 'setPlanReady',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'plan': _is.ParameterDescription(
              name: 'plan',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).setPlanReady(
                    session,
                    params['taskId'],
                    params['plan'],
                  ),
        ),
        'approvePlan': _is.MethodConnector(
          name: 'approvePlan',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).approvePlan(
                    session,
                    params['taskId'],
                  ),
        ),
        'submitPlanFeedback': _is.MethodConnector(
          name: 'submitPlanFeedback',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'message': _is.ParameterDescription(
              name: 'message',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .submitPlanFeedback(
                    session,
                    params['taskId'],
                    params['message'],
                  ),
        ),
        'deleteTask': _is.MethodConnector(
          name: 'deleteTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).deleteTask(
                    session,
                    params['taskId'],
                  ),
        ),
        'findTasks': _is.MethodConnector(
          name: 'findTasks',
          params: {
            'taskIds': _is.ParameterDescription(
              name: 'taskIds',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).findTasks(
                    session,
                    params['taskIds'],
                  ),
        ),
        'getChangedFiles': _is.MethodConnector(
          name: 'getChangedFiles',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).getChangedFiles(
                    session,
                    params['taskId'],
                  ),
        ),
        'getFileContent': _is.MethodConnector(
          name: 'getFileContent',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'contentsUrl': _is.ParameterDescription(
              name: 'contentsUrl',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['task'] as _idmllfay.TaskEndpoint).getFileContent(
                    session,
                    params['taskId'],
                    params['contentsUrl'],
                  ),
        ),
        'watchChecks': _is.MethodStreamConnector(
          name: 'watchChecks',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint).watchChecks(
                session,
                params['taskId'],
              ),
        ),
        'watchAnswer': _is.MethodStreamConnector(
          name: 'watchAnswer',
          params: {
            'questionId': _is.ParameterDescription(
              name: 'questionId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint).watchAnswer(
                session,
                params['questionId'],
              ),
        ),
        'watchPlanDecision': _is.MethodStreamConnector(
          name: 'watchPlanDecision',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .watchPlanDecision(
                    session,
                    params['taskId'],
                  ),
        ),
        'watchTaskDeletions': _is.MethodStreamConnector(
          name: 'watchTaskDeletions',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .watchTaskDeletions(session),
        ),
        'watchAllTasks': _is.MethodStreamConnector(
          name: 'watchAllTasks',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint).watchAllTasks(
                session,
              ),
        ),
        'watchAssignedTasks': _is.MethodStreamConnector(
          name: 'watchAssignedTasks',
          params: {
            'machineId': _is.ParameterDescription(
              name: 'machineId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint)
                  .watchAssignedTasks(
                    session,
                    params['machineId'],
                  ),
        ),
        'watchLogs': _is.MethodStreamConnector(
          name: 'watchLogs',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint).watchLogs(
                session,
                params['taskId'],
              ),
        ),
        'watchTask': _is.MethodStreamConnector(
          name: 'watchTask',
          params: {
            'taskId': _is.ParameterDescription(
              name: 'taskId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['task'] as _idmllfay.TaskEndpoint).watchTask(
                session,
                params['taskId'],
              ),
        ),
      },
    );
    connectors['greeting'] = _is.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _is.MethodConnector(
          name: 'hello',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['greeting'] as _il624ik7.GreetingEndpoint).hello(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _iewj8v67.FutureCalls();
  }
}
