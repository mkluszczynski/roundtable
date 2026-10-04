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
import 'package:roundtable_server/src/generated/agent.dart' as _iaucj7w0;
import 'package:roundtable_server/src/generated/diff_file.dart' as _i16fkh06;
import 'package:roundtable_server/src/generated/machine.dart' as _ilqrziin;
import 'package:roundtable_server/src/generated/project.dart' as _ii35q81x;
import 'package:roundtable_server/src/generated/review_comment_draft.dart'
    as _i245mzjz;
import 'package:roundtable_server/src/generated/task.dart' as _i77xifuu;
import 'package:roundtable_server/src/generated/task_attachment.dart'
    as _i8vmihz0;
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
import 'code_review.dart' as _icksttbv;
import 'code_review_status.dart' as _i4rgwvgz;
import 'deletion_block_reason.dart' as _iwa1mea8;
import 'deletion_blocked_exception.dart' as _i8k4gzq0;
import 'diff_file.dart' as _iji3k3fl;
import 'git_hub_exception.dart' as _ixcrnhlg;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'invalid_state_exception.dart' as _i0q2rwly;
import 'invalid_token_exception.dart' as _isgtss3z;
import 'log_kind.dart' as _i7oqmlti;
import 'log_phase.dart' as _iv8oofn2;
import 'log_source.dart' as _ilj2nbps;
import 'machine.dart' as _i0hti3f2;
import 'machine_metric.dart' as _ixivwx7g;
import 'machine_registration.dart' as _in7daleg;
import 'machine_status.dart' as _i6yugb3s;
import 'not_found_exception.dart' as _i6jvclsf;
import 'pr_check_run.dart' as _idxabcvw;
import 'pr_check_state.dart' as _ivypql97;
import 'pr_checks.dart' as _ik1qpwq1;
import 'pr_merge_status.dart' as _ixuoipsp;
import 'project.dart' as _ifiazq2p;
import 'review_comment.dart' as _itpwl327;
import 'review_comment_draft.dart' as _i6wlz106;
import 'review_comment_severity.dart' as _iml08ymk;
import 'review_comment_state.dart' as _igczzv9q;
import 'task.dart' as _iwn6t6fs;
import 'task_attachment.dart' as _isyamz65;
import 'task_defaults.dart' as _ipm7yd3q;
import 'task_deleted.dart' as _imh5lex6;
import 'task_feedback.dart' as _i5hi2zxr;
import 'task_feedback_phase.dart' as _iitmdld3;
import 'task_log_entry.dart' as _ihv3trno;
import 'task_question.dart' as _ivtt8ejd;
import 'task_status.dart' as _ic097rko;
import 'workspace_settings.dart' as _i88empjm;
export 'agent.dart';
export 'agent_effort.dart';
export 'agent_execution_mode.dart';
export 'agent_role.dart';
export 'agent_status.dart';
export 'code_review.dart';
export 'code_review_status.dart';
export 'deletion_block_reason.dart';
export 'deletion_blocked_exception.dart';
export 'diff_file.dart';
export 'git_hub_exception.dart';
export 'greetings/greeting.dart';
export 'invalid_state_exception.dart';
export 'invalid_token_exception.dart';
export 'log_kind.dart';
export 'log_phase.dart';
export 'log_source.dart';
export 'machine.dart';
export 'machine_metric.dart';
export 'machine_registration.dart';
export 'machine_status.dart';
export 'not_found_exception.dart';
export 'pr_check_run.dart';
export 'pr_check_state.dart';
export 'pr_checks.dart';
export 'pr_merge_status.dart';
export 'project.dart';
export 'review_comment.dart';
export 'review_comment_draft.dart';
export 'review_comment_severity.dart';
export 'review_comment_state.dart';
export 'task.dart';
export 'task_attachment.dart';
export 'task_defaults.dart';
export 'task_deleted.dart';
export 'task_feedback.dart';
export 'task_feedback_phase.dart';
export 'task_log_entry.dart';
export 'task_question.dart';
export 'task_status.dart';
export 'workspace_settings.dart';

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
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'agent_machine_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'machineId',
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
      name: 'code_review',
      dartName: 'CodeReview',
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
          name: 'reviewerAgentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:CodeReviewStatus',
          columnDefault: '\'queued\'',
        ),
        _isp.ColumnDefinition(
          name: 'summary',
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
          name: 'githubReviewId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
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
          constraintName: 'code_review_fk_0',
          columns: ['taskId'],
          referenceTable: 'task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'code_review_fk_1',
          columns: ['reviewerAgentId'],
          referenceTable: 'agent',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'code_review_task_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
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
          name: 'hostInfo',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
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
          name: 'claudeExecutableOk',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'claudeExecutableError',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'runnerVersion',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'updateRequestedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'toolchain',
          columnType: _isp.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
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
          onDelete: _isp.ForeignKeyAction.cascade,
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
      name: 'pr_check_run',
      dartName: 'PrCheckRun',
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
          name: 'headSha',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'workflowRunId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'runAttempt',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'workflowName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'jobId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'jobName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'conclusion',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'failedStep',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'htmlUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'completedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'pr_check_run_fk_0',
          columns: ['taskId'],
          referenceTable: 'task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'pr_check_run_task_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'jobId',
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
          name: 'repoAccessTokenUpdatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'dockerImage',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'autoFixFailingChecks',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'maxCheckFixAttempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '2',
        ),
        _isp.ColumnDefinition(
          name: 'skipPlanning',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
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
      name: 'review_comment',
      dartName: 'ReviewComment',
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
          name: 'reviewId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'path',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'line',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'severity',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReviewCommentSeverity',
          columnDefault: '\'issue\'',
        ),
        _isp.ColumnDefinition(
          name: 'state',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReviewCommentState',
          columnDefault: '\'open\'',
        ),
        _isp.ColumnDefinition(
          name: 'githubCommentId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
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
          constraintName: 'review_comment_fk_0',
          columns: ['reviewId'],
          referenceTable: 'code_review',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'review_comment_review_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'reviewId',
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
          name: 'resultSummary',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'pausedUntil',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'pauseReason',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'pausedPhase',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:LogPhase?',
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
          name: 'prHeadSha',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'prHeadSeenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'checkState',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:PrCheckState',
          columnDefault: '\'none\'',
        ),
        _isp.ColumnDefinition(
          name: 'checkError',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'checkFixAttempts',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'checkFixSentForSha',
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
        _isp.ColumnDefinition(
          name: 'lastProgressAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
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
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _isp.ForeignKeyDefinition(
          constraintName: 'task_fk_1',
          columns: ['agentId'],
          referenceTable: 'agent',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.setNull,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'task_project_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'projectId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'task_agent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'agentId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'task_status_progress_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lastProgressAt',
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
      name: 'task_attachment',
      dartName: 'TaskAttachment',
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
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'storagePath',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'fileName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'mimeType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sizeBytes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
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
          constraintName: 'task_attachment_fk_0',
          columns: ['taskId'],
          referenceTable: 'task',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'task_attachment_task_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
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
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'task_feedback_task_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
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
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:LogKind?',
        ),
        _isp.ColumnDefinition(
          name: 'runId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'phase',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:LogPhase?',
        ),
        _isp.ColumnDefinition(
          name: 'toolName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'toolUseId',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'detail',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'isError',
          columnType: _isp.ColumnType.boolean,
          isNullable: true,
          dartType: 'bool?',
        ),
        _isp.ColumnDefinition(
          name: 'reviewId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
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
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'task_log_entry_task_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
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
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'task_question_task_created_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'taskId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
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
      name: 'workspace_settings',
      dartName: 'WorkspaceSettings',
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
          name: 'skipPlanning',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
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
    if (t == _icksttbv.CodeReview) {
      return _icksttbv.CodeReview.fromJson(data) as T;
    }
    if (t == _i4rgwvgz.CodeReviewStatus) {
      return _i4rgwvgz.CodeReviewStatus.fromJson(data) as T;
    }
    if (t == _iwa1mea8.DeletionBlockReason) {
      return _iwa1mea8.DeletionBlockReason.fromJson(data) as T;
    }
    if (t == _i8k4gzq0.DeletionBlockedException) {
      return _i8k4gzq0.DeletionBlockedException.fromJson(data) as T;
    }
    if (t == _iji3k3fl.DiffFile) {
      return _iji3k3fl.DiffFile.fromJson(data) as T;
    }
    if (t == _ixcrnhlg.GitHubException) {
      return _ixcrnhlg.GitHubException.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _i0q2rwly.InvalidStateException) {
      return _i0q2rwly.InvalidStateException.fromJson(data) as T;
    }
    if (t == _isgtss3z.InvalidTokenException) {
      return _isgtss3z.InvalidTokenException.fromJson(data) as T;
    }
    if (t == _i7oqmlti.LogKind) {
      return _i7oqmlti.LogKind.fromJson(data) as T;
    }
    if (t == _iv8oofn2.LogPhase) {
      return _iv8oofn2.LogPhase.fromJson(data) as T;
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
    if (t == _in7daleg.MachineRegistration) {
      return _in7daleg.MachineRegistration.fromJson(data) as T;
    }
    if (t == _i6yugb3s.MachineStatus) {
      return _i6yugb3s.MachineStatus.fromJson(data) as T;
    }
    if (t == _i6jvclsf.NotFoundException) {
      return _i6jvclsf.NotFoundException.fromJson(data) as T;
    }
    if (t == _idxabcvw.PrCheckRun) {
      return _idxabcvw.PrCheckRun.fromJson(data) as T;
    }
    if (t == _ivypql97.PrCheckState) {
      return _ivypql97.PrCheckState.fromJson(data) as T;
    }
    if (t == _ik1qpwq1.PrChecks) {
      return _ik1qpwq1.PrChecks.fromJson(data) as T;
    }
    if (t == _ixuoipsp.PrMergeStatus) {
      return _ixuoipsp.PrMergeStatus.fromJson(data) as T;
    }
    if (t == _ifiazq2p.Project) {
      return _ifiazq2p.Project.fromJson(data) as T;
    }
    if (t == _itpwl327.ReviewComment) {
      return _itpwl327.ReviewComment.fromJson(data) as T;
    }
    if (t == _i6wlz106.ReviewCommentDraft) {
      return _i6wlz106.ReviewCommentDraft.fromJson(data) as T;
    }
    if (t == _iml08ymk.ReviewCommentSeverity) {
      return _iml08ymk.ReviewCommentSeverity.fromJson(data) as T;
    }
    if (t == _igczzv9q.ReviewCommentState) {
      return _igczzv9q.ReviewCommentState.fromJson(data) as T;
    }
    if (t == _iwn6t6fs.Task) {
      return _iwn6t6fs.Task.fromJson(data) as T;
    }
    if (t == _isyamz65.TaskAttachment) {
      return _isyamz65.TaskAttachment.fromJson(data) as T;
    }
    if (t == _ipm7yd3q.TaskDefaults) {
      return _ipm7yd3q.TaskDefaults.fromJson(data) as T;
    }
    if (t == _imh5lex6.TaskDeleted) {
      return _imh5lex6.TaskDeleted.fromJson(data) as T;
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
    if (t == _i88empjm.WorkspaceSettings) {
      return _i88empjm.WorkspaceSettings.fromJson(data) as T;
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
    if (t == _is.getType<_icksttbv.CodeReview?>()) {
      return (data != null ? _icksttbv.CodeReview.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i4rgwvgz.CodeReviewStatus?>()) {
      return (data != null ? _i4rgwvgz.CodeReviewStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iwa1mea8.DeletionBlockReason?>()) {
      return (data != null
              ? _iwa1mea8.DeletionBlockReason.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i8k4gzq0.DeletionBlockedException?>()) {
      return (data != null
              ? _i8k4gzq0.DeletionBlockedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iji3k3fl.DiffFile?>()) {
      return (data != null ? _iji3k3fl.DiffFile.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixcrnhlg.GitHubException?>()) {
      return (data != null ? _ixcrnhlg.GitHubException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i0q2rwly.InvalidStateException?>()) {
      return (data != null
              ? _i0q2rwly.InvalidStateException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_isgtss3z.InvalidTokenException?>()) {
      return (data != null
              ? _isgtss3z.InvalidTokenException.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i7oqmlti.LogKind?>()) {
      return (data != null ? _i7oqmlti.LogKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iv8oofn2.LogPhase?>()) {
      return (data != null ? _iv8oofn2.LogPhase.fromJson(data) : null) as T;
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
    if (t == _is.getType<_in7daleg.MachineRegistration?>()) {
      return (data != null
              ? _in7daleg.MachineRegistration.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i6yugb3s.MachineStatus?>()) {
      return (data != null ? _i6yugb3s.MachineStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6jvclsf.NotFoundException?>()) {
      return (data != null ? _i6jvclsf.NotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idxabcvw.PrCheckRun?>()) {
      return (data != null ? _idxabcvw.PrCheckRun.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivypql97.PrCheckState?>()) {
      return (data != null ? _ivypql97.PrCheckState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ik1qpwq1.PrChecks?>()) {
      return (data != null ? _ik1qpwq1.PrChecks.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixuoipsp.PrMergeStatus?>()) {
      return (data != null ? _ixuoipsp.PrMergeStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ifiazq2p.Project?>()) {
      return (data != null ? _ifiazq2p.Project.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_itpwl327.ReviewComment?>()) {
      return (data != null ? _itpwl327.ReviewComment.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i6wlz106.ReviewCommentDraft?>()) {
      return (data != null ? _i6wlz106.ReviewCommentDraft.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iml08ymk.ReviewCommentSeverity?>()) {
      return (data != null
              ? _iml08ymk.ReviewCommentSeverity.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_igczzv9q.ReviewCommentState?>()) {
      return (data != null ? _igczzv9q.ReviewCommentState.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iwn6t6fs.Task?>()) {
      return (data != null ? _iwn6t6fs.Task.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_isyamz65.TaskAttachment?>()) {
      return (data != null ? _isyamz65.TaskAttachment.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipm7yd3q.TaskDefaults?>()) {
      return (data != null ? _ipm7yd3q.TaskDefaults.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_imh5lex6.TaskDeleted?>()) {
      return (data != null ? _imh5lex6.TaskDeleted.fromJson(data) : null) as T;
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
    if (t == _is.getType<_i88empjm.WorkspaceSettings?>()) {
      return (data != null ? _i88empjm.WorkspaceSettings.fromJson(data) : null)
          as T;
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
    if (t == List<_itpwl327.ReviewComment>) {
      return (data as List)
              .map((e) => deserialize<_itpwl327.ReviewComment>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_itpwl327.ReviewComment>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_itpwl327.ReviewComment>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _is.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
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
    if (t == List<_idxabcvw.PrCheckRun>) {
      return (data as List)
              .map((e) => deserialize<_idxabcvw.PrCheckRun>(e))
              .toList()
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
    if (t == List<_isyamz65.TaskAttachment>) {
      return (data as List)
              .map((e) => deserialize<_isyamz65.TaskAttachment>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_isyamz65.TaskAttachment>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_isyamz65.TaskAttachment>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_iaucj7w0.Agent>) {
      return (data as List).map((e) => deserialize<_iaucj7w0.Agent>(e)).toList()
          as T;
    }
    if (t == List<_i245mzjz.ReviewCommentDraft>) {
      return (data as List)
              .map((e) => deserialize<_i245mzjz.ReviewCommentDraft>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_ilqrziin.Machine>) {
      return (data as List)
              .map((e) => deserialize<_ilqrziin.Machine>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_ii35q81x.Project>) {
      return (data as List)
              .map((e) => deserialize<_ii35q81x.Project>(e))
              .toList()
          as T;
    }
    if (t == List<_i8vmihz0.TaskAttachment>) {
      return (data as List)
              .map((e) => deserialize<_i8vmihz0.TaskAttachment>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i77xifuu.Task>) {
      return (data as List).map((e) => deserialize<_i77xifuu.Task>(e)).toList()
          as T;
    }
    if (t == List<_i16fkh06.DiffFile>) {
      return (data as List)
              .map((e) => deserialize<_i16fkh06.DiffFile>(e))
              .toList()
          as T;
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
      _icksttbv.CodeReview => 'CodeReview',
      _i4rgwvgz.CodeReviewStatus => 'CodeReviewStatus',
      _iwa1mea8.DeletionBlockReason => 'DeletionBlockReason',
      _i8k4gzq0.DeletionBlockedException => 'DeletionBlockedException',
      _iji3k3fl.DiffFile => 'DiffFile',
      _ixcrnhlg.GitHubException => 'GitHubException',
      _izw8z7ou.Greeting => 'Greeting',
      _i0q2rwly.InvalidStateException => 'InvalidStateException',
      _isgtss3z.InvalidTokenException => 'InvalidTokenException',
      _i7oqmlti.LogKind => 'LogKind',
      _iv8oofn2.LogPhase => 'LogPhase',
      _ilj2nbps.LogSource => 'LogSource',
      _i0hti3f2.Machine => 'Machine',
      _ixivwx7g.MachineMetric => 'MachineMetric',
      _in7daleg.MachineRegistration => 'MachineRegistration',
      _i6yugb3s.MachineStatus => 'MachineStatus',
      _i6jvclsf.NotFoundException => 'NotFoundException',
      _idxabcvw.PrCheckRun => 'PrCheckRun',
      _ivypql97.PrCheckState => 'PrCheckState',
      _ik1qpwq1.PrChecks => 'PrChecks',
      _ixuoipsp.PrMergeStatus => 'PrMergeStatus',
      _ifiazq2p.Project => 'Project',
      _itpwl327.ReviewComment => 'ReviewComment',
      _i6wlz106.ReviewCommentDraft => 'ReviewCommentDraft',
      _iml08ymk.ReviewCommentSeverity => 'ReviewCommentSeverity',
      _igczzv9q.ReviewCommentState => 'ReviewCommentState',
      _iwn6t6fs.Task => 'Task',
      _isyamz65.TaskAttachment => 'TaskAttachment',
      _ipm7yd3q.TaskDefaults => 'TaskDefaults',
      _imh5lex6.TaskDeleted => 'TaskDeleted',
      _i5hi2zxr.TaskFeedback => 'TaskFeedback',
      _iitmdld3.TaskFeedbackPhase => 'TaskFeedbackPhase',
      _ihv3trno.TaskLogEntry => 'TaskLogEntry',
      _ivtt8ejd.TaskQuestion => 'TaskQuestion',
      _ic097rko.TaskStatus => 'TaskStatus',
      _i88empjm.WorkspaceSettings => 'WorkspaceSettings',
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
      case _icksttbv.CodeReview():
        return 'CodeReview';
      case _i4rgwvgz.CodeReviewStatus():
        return 'CodeReviewStatus';
      case _iwa1mea8.DeletionBlockReason():
        return 'DeletionBlockReason';
      case _i8k4gzq0.DeletionBlockedException():
        return 'DeletionBlockedException';
      case _iji3k3fl.DiffFile():
        return 'DiffFile';
      case _ixcrnhlg.GitHubException():
        return 'GitHubException';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _i0q2rwly.InvalidStateException():
        return 'InvalidStateException';
      case _isgtss3z.InvalidTokenException():
        return 'InvalidTokenException';
      case _i7oqmlti.LogKind():
        return 'LogKind';
      case _iv8oofn2.LogPhase():
        return 'LogPhase';
      case _ilj2nbps.LogSource():
        return 'LogSource';
      case _i0hti3f2.Machine():
        return 'Machine';
      case _ixivwx7g.MachineMetric():
        return 'MachineMetric';
      case _in7daleg.MachineRegistration():
        return 'MachineRegistration';
      case _i6yugb3s.MachineStatus():
        return 'MachineStatus';
      case _i6jvclsf.NotFoundException():
        return 'NotFoundException';
      case _idxabcvw.PrCheckRun():
        return 'PrCheckRun';
      case _ivypql97.PrCheckState():
        return 'PrCheckState';
      case _ik1qpwq1.PrChecks():
        return 'PrChecks';
      case _ixuoipsp.PrMergeStatus():
        return 'PrMergeStatus';
      case _ifiazq2p.Project():
        return 'Project';
      case _itpwl327.ReviewComment():
        return 'ReviewComment';
      case _i6wlz106.ReviewCommentDraft():
        return 'ReviewCommentDraft';
      case _iml08ymk.ReviewCommentSeverity():
        return 'ReviewCommentSeverity';
      case _igczzv9q.ReviewCommentState():
        return 'ReviewCommentState';
      case _iwn6t6fs.Task():
        return 'Task';
      case _isyamz65.TaskAttachment():
        return 'TaskAttachment';
      case _ipm7yd3q.TaskDefaults():
        return 'TaskDefaults';
      case _imh5lex6.TaskDeleted():
        return 'TaskDeleted';
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
      case _i88empjm.WorkspaceSettings():
        return 'WorkspaceSettings';
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
    if (dataClassName == 'CodeReview') {
      return deserialize<_icksttbv.CodeReview>(data['data']);
    }
    if (dataClassName == 'CodeReviewStatus') {
      return deserialize<_i4rgwvgz.CodeReviewStatus>(data['data']);
    }
    if (dataClassName == 'DeletionBlockReason') {
      return deserialize<_iwa1mea8.DeletionBlockReason>(data['data']);
    }
    if (dataClassName == 'DeletionBlockedException') {
      return deserialize<_i8k4gzq0.DeletionBlockedException>(data['data']);
    }
    if (dataClassName == 'DiffFile') {
      return deserialize<_iji3k3fl.DiffFile>(data['data']);
    }
    if (dataClassName == 'GitHubException') {
      return deserialize<_ixcrnhlg.GitHubException>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'InvalidStateException') {
      return deserialize<_i0q2rwly.InvalidStateException>(data['data']);
    }
    if (dataClassName == 'InvalidTokenException') {
      return deserialize<_isgtss3z.InvalidTokenException>(data['data']);
    }
    if (dataClassName == 'LogKind') {
      return deserialize<_i7oqmlti.LogKind>(data['data']);
    }
    if (dataClassName == 'LogPhase') {
      return deserialize<_iv8oofn2.LogPhase>(data['data']);
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
    if (dataClassName == 'MachineRegistration') {
      return deserialize<_in7daleg.MachineRegistration>(data['data']);
    }
    if (dataClassName == 'MachineStatus') {
      return deserialize<_i6yugb3s.MachineStatus>(data['data']);
    }
    if (dataClassName == 'NotFoundException') {
      return deserialize<_i6jvclsf.NotFoundException>(data['data']);
    }
    if (dataClassName == 'PrCheckRun') {
      return deserialize<_idxabcvw.PrCheckRun>(data['data']);
    }
    if (dataClassName == 'PrCheckState') {
      return deserialize<_ivypql97.PrCheckState>(data['data']);
    }
    if (dataClassName == 'PrChecks') {
      return deserialize<_ik1qpwq1.PrChecks>(data['data']);
    }
    if (dataClassName == 'PrMergeStatus') {
      return deserialize<_ixuoipsp.PrMergeStatus>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_ifiazq2p.Project>(data['data']);
    }
    if (dataClassName == 'ReviewComment') {
      return deserialize<_itpwl327.ReviewComment>(data['data']);
    }
    if (dataClassName == 'ReviewCommentDraft') {
      return deserialize<_i6wlz106.ReviewCommentDraft>(data['data']);
    }
    if (dataClassName == 'ReviewCommentSeverity') {
      return deserialize<_iml08ymk.ReviewCommentSeverity>(data['data']);
    }
    if (dataClassName == 'ReviewCommentState') {
      return deserialize<_igczzv9q.ReviewCommentState>(data['data']);
    }
    if (dataClassName == 'Task') {
      return deserialize<_iwn6t6fs.Task>(data['data']);
    }
    if (dataClassName == 'TaskAttachment') {
      return deserialize<_isyamz65.TaskAttachment>(data['data']);
    }
    if (dataClassName == 'TaskDefaults') {
      return deserialize<_ipm7yd3q.TaskDefaults>(data['data']);
    }
    if (dataClassName == 'TaskDeleted') {
      return deserialize<_imh5lex6.TaskDeleted>(data['data']);
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
    if (dataClassName == 'WorkspaceSettings') {
      return deserialize<_i88empjm.WorkspaceSettings>(data['data']);
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
      case _icksttbv.CodeReview:
        return _icksttbv.CodeReview.t;
      case _i0hti3f2.Machine:
        return _i0hti3f2.Machine.t;
      case _ixivwx7g.MachineMetric:
        return _ixivwx7g.MachineMetric.t;
      case _idxabcvw.PrCheckRun:
        return _idxabcvw.PrCheckRun.t;
      case _ifiazq2p.Project:
        return _ifiazq2p.Project.t;
      case _itpwl327.ReviewComment:
        return _itpwl327.ReviewComment.t;
      case _iwn6t6fs.Task:
        return _iwn6t6fs.Task.t;
      case _isyamz65.TaskAttachment:
        return _isyamz65.TaskAttachment.t;
      case _i5hi2zxr.TaskFeedback:
        return _i5hi2zxr.TaskFeedback.t;
      case _ihv3trno.TaskLogEntry:
        return _ihv3trno.TaskLogEntry.t;
      case _ivtt8ejd.TaskQuestion:
        return _ivtt8ejd.TaskQuestion.t;
      case _i88empjm.WorkspaceSettings:
        return _i88empjm.WorkspaceSettings.t;
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
