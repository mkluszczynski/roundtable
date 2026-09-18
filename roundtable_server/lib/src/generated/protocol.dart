/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'agent.dart' as _ijo8h3v4;
import 'agent_effort.dart' as _iexg9pz4;
import 'agent_execution_mode.dart' as _i4babe00;
import 'agent_role.dart' as _idfmm35v;
import 'agent_status.dart' as _i69bozh7;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'log_source.dart' as _ilj2nbps;
import 'machine.dart' as _i0hti3f2;
import 'machine_metric.dart' as _ixivwx7g;
import 'machine_status.dart' as _i6yugb3s;
import 'project.dart' as _ifiazq2p;
import 'task.dart' as _iwn6t6fs;
import 'task_feedback.dart' as _i5hi2zxr;
import 'task_feedback_phase.dart' as _iitmdld3;
import 'task_log_entry.dart' as _ihv3trno;
import 'task_question.dart' as _ivtt8ejd;
import 'task_status.dart' as _ic097rko;
export 'agent.dart';
export 'agent_effort.dart';
export 'agent_execution_mode.dart';
export 'agent_role.dart';
export 'agent_status.dart';
export 'greetings/greeting.dart';
export 'log_source.dart';
export 'machine.dart';
export 'machine_metric.dart';
export 'machine_status.dart';
export 'project.dart';
export 'task.dart';
export 'task_feedback.dart';
export 'task_feedback_phase.dart';
export 'task_log_entry.dart';
export 'task_question.dart';
export 'task_status.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'agent',
      dartName: 'Agent',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'machineId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AgentRole',
          columnDefault: '\'generalist\'',
        ),
        _isp.ColumnDefinition(
          name: 'defaultModel',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'defaultEffort',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:AgentEffort?',
        ),
        _isp.ColumnDefinition(
          name: 'executionMode',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AgentExecutionMode',
          columnDefault: '\'native\'',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AgentStatus',
          columnDefault: '\'idle\'',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'agent_fk_0',
          columns: ['machineId'],
          referenceTable: 'machine',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'machine',
      dartName: 'Machine',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tokenHash',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:MachineStatus',
          columnDefault: '\'offline\'',
        ),
        _isp.ColumnDefinition(
          name: 'lastSeenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'machine_token_hash_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'tokenHash',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'machine_metric',
      dartName: 'MachineMetric',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'machineId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'cpuPercent',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'memoryUsedMb',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'memoryTotalMb',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'recordedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'machine_metric_fk_0',
          columns: ['machineId'],
          referenceTable: 'machine',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'machine_metric_recorded_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'machineId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'recordedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'project',
      dartName: 'Project',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'repoUrl',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'repoAccessToken',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'dockerImage',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'task',
      dartName: 'Task',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'projectId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'agentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'prompt',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'skipPlanning',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:TaskStatus',
          columnDefault: '\'queued\'',
        ),
        _isp.ColumnDefinition(
          name: 'currentPlan',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'failureReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'claudeSessionId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'branchName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'prUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'finishedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'task_fk_0',
          columns: ['projectId'],
          referenceTable: 'project',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'task_fk_1',
          columns: ['agentId'],
          referenceTable: 'agent',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'task_feedback',
      dartName: 'TaskFeedback',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'taskId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'message',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'phase',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:TaskFeedbackPhase',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'task_feedback_fk_0',
          columns: ['taskId'],
          referenceTable: 'task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'task_log_entry',
      dartName: 'TaskLogEntry',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'taskId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'content',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'source',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:LogSource',
          columnDefault: '\'agent\'',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'task_log_entry_fk_0',
          columns: ['taskId'],
          referenceTable: 'task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'task_question',
      dartName: 'TaskQuestion',
      schema: 'public',
      module: 'roundtable',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'taskId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'question',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'options',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'answer',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'answeredAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'task_question_fk_0',
          columns: ['taskId'],
          referenceTable: 'task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ijo8h3v4.Agent) {
      return _ijo8h3v4.Agent.fromJson(data) as T;
    }
    if (t == _iexg9pz4.AgentEffort) {
      return _iexg9pz4.AgentEffort.fromJson(data) as T;
    }
    if (t == _i4babe00.AgentExecutionMode) {
      return _i4babe00.AgentExecutionMode.fromJson(data) as T;
    }
    if (t == _idfmm35v.AgentRole) {
      return _idfmm35v.AgentRole.fromJson(data) as T;
    }
    if (t == _i69bozh7.AgentStatus) {
      return _i69bozh7.AgentStatus.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _ilj2nbps.LogSource) {
      return _ilj2nbps.LogSource.fromJson(data) as T;
    }
    if (t == _i0hti3f2.Machine) {
      return _i0hti3f2.Machine.fromJson(data) as T;
    }
    if (t == _ixivwx7g.MachineMetric) {
      return _ixivwx7g.MachineMetric.fromJson(data) as T;
    }
    if (t == _i6yugb3s.MachineStatus) {
      return _i6yugb3s.MachineStatus.fromJson(data) as T;
    }
    if (t == _ifiazq2p.Project) {
      return _ifiazq2p.Project.fromJson(data) as T;
    }
    if (t == _iwn6t6fs.Task) {
      return _iwn6t6fs.Task.fromJson(data) as T;
    }
    if (t == _i5hi2zxr.TaskFeedback) {
      return _i5hi2zxr.TaskFeedback.fromJson(data) as T;
    }
    if (t == _iitmdld3.TaskFeedbackPhase) {
      return _iitmdld3.TaskFeedbackPhase.fromJson(data) as T;
    }
    if (t == _ihv3trno.TaskLogEntry) {
      return _ihv3trno.TaskLogEntry.fromJson(data) as T;
    }
    if (t == _ivtt8ejd.TaskQuestion) {
      return _ivtt8ejd.TaskQuestion.fromJson(data) as T;
    }
    if (t == _ic097rko.TaskStatus) {
      return _ic097rko.TaskStatus.fromJson(data) as T;
    }
    if (t == _is.getType<_ijo8h3v4.Agent?>()) {
      return (data != null ? _ijo8h3v4.Agent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iexg9pz4.AgentEffort?>()) {
      return (data != null ? _iexg9pz4.AgentEffort.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4babe00.AgentExecutionMode?>()) {
      return (data != null ? _i4babe00.AgentExecutionMode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idfmm35v.AgentRole?>()) {
      return (data != null ? _idfmm35v.AgentRole.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i69bozh7.AgentStatus?>()) {
      return (data != null ? _i69bozh7.AgentStatus.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ilj2nbps.LogSource?>()) {
      return (data != null ? _ilj2nbps.LogSource.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i0hti3f2.Machine?>()) {
      return (data != null ? _i0hti3f2.Machine.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixivwx7g.MachineMetric?>()) {
      return (data != null ? _ixivwx7g.MachineMetric.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6yugb3s.MachineStatus?>()) {
      return (data != null ? _i6yugb3s.MachineStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifiazq2p.Project?>()) {
      return (data != null ? _ifiazq2p.Project.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwn6t6fs.Task?>()) {
      return (data != null ? _iwn6t6fs.Task.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5hi2zxr.TaskFeedback?>()) {
      return (data != null ? _i5hi2zxr.TaskFeedback.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iitmdld3.TaskFeedbackPhase?>()) {
      return (data != null ? _iitmdld3.TaskFeedbackPhase.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihv3trno.TaskLogEntry?>()) {
      return (data != null ? _ihv3trno.TaskLogEntry.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivtt8ejd.TaskQuestion?>()) {
      return (data != null ? _ivtt8ejd.TaskQuestion.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ic097rko.TaskStatus?>()) {
      return (data != null ? _ic097rko.TaskStatus.fromJson(data) : null) as T;
    }
    if (t == List<_iwn6t6fs.Task>) {
      return (data as List).map((e) => deserialize<_iwn6t6fs.Task>(e)).toList()
          as T;
    }
    if (t == _is.getType<List<_iwn6t6fs.Task>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_iwn6t6fs.Task>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ijo8h3v4.Agent>) {
      return (data as List).map((e) => deserialize<_ijo8h3v4.Agent>(e)).toList()
          as T;
    }
    if (t == _is.getType<List<_ijo8h3v4.Agent>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ijo8h3v4.Agent>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ixivwx7g.MachineMetric>) {
      return (data as List)
              .map((e) => deserialize<_ixivwx7g.MachineMetric>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_ixivwx7g.MachineMetric>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ixivwx7g.MachineMetric>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ihv3trno.TaskLogEntry>) {
      return (data as List)
              .map((e) => deserialize<_ihv3trno.TaskLogEntry>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_ihv3trno.TaskLogEntry>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ihv3trno.TaskLogEntry>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i5hi2zxr.TaskFeedback>) {
      return (data as List)
              .map((e) => deserialize<_i5hi2zxr.TaskFeedback>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_i5hi2zxr.TaskFeedback>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i5hi2zxr.TaskFeedback>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_ivtt8ejd.TaskQuestion>) {
      return (data as List)
              .map((e) => deserialize<_ivtt8ejd.TaskQuestion>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_ivtt8ejd.TaskQuestion>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_ivtt8ejd.TaskQuestion>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ijo8h3v4.Agent => 'Agent',
      _iexg9pz4.AgentEffort => 'AgentEffort',
      _i4babe00.AgentExecutionMode => 'AgentExecutionMode',
      _idfmm35v.AgentRole => 'AgentRole',
      _i69bozh7.AgentStatus => 'AgentStatus',
      _izw8z7ou.Greeting => 'Greeting',
      _ilj2nbps.LogSource => 'LogSource',
      _i0hti3f2.Machine => 'Machine',
      _ixivwx7g.MachineMetric => 'MachineMetric',
      _i6yugb3s.MachineStatus => 'MachineStatus',
      _ifiazq2p.Project => 'Project',
      _iwn6t6fs.Task => 'Task',
      _i5hi2zxr.TaskFeedback => 'TaskFeedback',
      _iitmdld3.TaskFeedbackPhase => 'TaskFeedbackPhase',
      _ihv3trno.TaskLogEntry => 'TaskLogEntry',
      _ivtt8ejd.TaskQuestion => 'TaskQuestion',
      _ic097rko.TaskStatus => 'TaskStatus',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('roundtable.', '');
    }

    switch (data) {
      case _ijo8h3v4.Agent():
        return 'Agent';
      case _iexg9pz4.AgentEffort():
        return 'AgentEffort';
      case _i4babe00.AgentExecutionMode():
        return 'AgentExecutionMode';
      case _idfmm35v.AgentRole():
        return 'AgentRole';
      case _i69bozh7.AgentStatus():
        return 'AgentStatus';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _ilj2nbps.LogSource():
        return 'LogSource';
      case _i0hti3f2.Machine():
        return 'Machine';
      case _ixivwx7g.MachineMetric():
        return 'MachineMetric';
      case _i6yugb3s.MachineStatus():
        return 'MachineStatus';
      case _ifiazq2p.Project():
        return 'Project';
      case _iwn6t6fs.Task():
        return 'Task';
      case _i5hi2zxr.TaskFeedback():
        return 'TaskFeedback';
      case _iitmdld3.TaskFeedbackPhase():
        return 'TaskFeedbackPhase';
      case _ihv3trno.TaskLogEntry():
        return 'TaskLogEntry';
      case _ivtt8ejd.TaskQuestion():
        return 'TaskQuestion';
      case _ic097rko.TaskStatus():
        return 'TaskStatus';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Agent') {
      return deserialize<_ijo8h3v4.Agent>(data['data']);
    }
    if (dataClassName == 'AgentEffort') {
      return deserialize<_iexg9pz4.AgentEffort>(data['data']);
    }
    if (dataClassName == 'AgentExecutionMode') {
      return deserialize<_i4babe00.AgentExecutionMode>(data['data']);
    }
    if (dataClassName == 'AgentRole') {
      return deserialize<_idfmm35v.AgentRole>(data['data']);
    }
    if (dataClassName == 'AgentStatus') {
      return deserialize<_i69bozh7.AgentStatus>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'LogSource') {
      return deserialize<_ilj2nbps.LogSource>(data['data']);
    }
    if (dataClassName == 'Machine') {
      return deserialize<_i0hti3f2.Machine>(data['data']);
    }
    if (dataClassName == 'MachineMetric') {
      return deserialize<_ixivwx7g.MachineMetric>(data['data']);
    }
    if (dataClassName == 'MachineStatus') {
      return deserialize<_i6yugb3s.MachineStatus>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_ifiazq2p.Project>(data['data']);
    }
    if (dataClassName == 'Task') {
      return deserialize<_iwn6t6fs.Task>(data['data']);
    }
    if (dataClassName == 'TaskFeedback') {
      return deserialize<_i5hi2zxr.TaskFeedback>(data['data']);
    }
    if (dataClassName == 'TaskFeedbackPhase') {
      return deserialize<_iitmdld3.TaskFeedbackPhase>(data['data']);
    }
    if (dataClassName == 'TaskLogEntry') {
      return deserialize<_ihv3trno.TaskLogEntry>(data['data']);
    }
    if (dataClassName == 'TaskQuestion') {
      return deserialize<_ivtt8ejd.TaskQuestion>(data['data']);
    }
    if (dataClassName == 'TaskStatus') {
      return deserialize<_ic097rko.TaskStatus>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('roundtable', this);
    _iacs.Protocol().registerHostProtocol('roundtable', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _ijo8h3v4.Agent:
        return _ijo8h3v4.Agent.t;
      case _i0hti3f2.Machine:
        return _i0hti3f2.Machine.t;
      case _ixivwx7g.MachineMetric:
        return _ixivwx7g.MachineMetric.t;
      case _ifiazq2p.Project:
        return _ifiazq2p.Project.t;
      case _iwn6t6fs.Task:
        return _iwn6t6fs.Task.t;
      case _i5hi2zxr.TaskFeedback:
        return _i5hi2zxr.TaskFeedback.t;
      case _ihv3trno.TaskLogEntry:
        return _ihv3trno.TaskLogEntry.t;
      case _ivtt8ejd.TaskQuestion:
        return _ivtt8ejd.TaskQuestion.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'roundtable';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
