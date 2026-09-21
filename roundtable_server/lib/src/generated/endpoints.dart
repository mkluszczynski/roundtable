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
import 'package:roundtable_server/src/generated/agent.dart' as _iaucj7w0;
import 'package:roundtable_server/src/generated/agent_effort.dart' as _i293npqp;
import 'package:roundtable_server/src/generated/agent_role.dart' as _i01du5ez;
import 'package:roundtable_server/src/generated/future_calls.dart' as _iewj8v67;
import 'package:roundtable_server/src/generated/log_source.dart' as _iexu01r8;
import 'package:roundtable_server/src/generated/machine.dart' as _ilqrziin;
import 'package:roundtable_server/src/generated/project.dart' as _ii35q81x;
import 'package:roundtable_server/src/generated/task.dart' as _i77xifuu;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../endpoints/agent_endpoint.dart' as _ik1xrao3;
import '../endpoints/machine_endpoint.dart' as _ij6wllr0;
import '../endpoints/project_endpoint.dart' as _iemg8ri2;
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
            'role': _is.ParameterDescription(
              name: 'role',
              type: _is.getType<_i01du5ez.AgentRole>(),
              nullable: false,
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
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['agent'] as _ik1xrao3.AgentEndpoint).create(
                session,
                params['name'],
                params['machineId'],
                role: params['role'],
                defaultModel: params['defaultModel'],
                defaultEffort: params['defaultEffort'],
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
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['machine'] as _ij6wllr0.MachineEndpoint).register(
                    session,
                    params['name'],
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
              type: _is.getType<bool>(),
              nullable: false,
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
