/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:roundtable_server/src/generated/protocol.dart' as _iikm6kmi;
import 'package:serverpod/serverpod.dart' as _is;
import 'agent.dart' as _ijo8h3v4;
import 'project.dart' as _ifiazq2p;
import 'task_feedback.dart' as _i5hi2zxr;
import 'task_log_entry.dart' as _ihv3trno;
import 'task_question.dart' as _ivtt8ejd;
import 'task_status.dart' as _ic097rko;

/// A single unit of work assigned to an agent on a project's repository.
abstract class Task implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Task._({
    this.id,
    required this.projectId,
    this.project,
    this.agentId,
    this.agent,
    required this.prompt,
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    this.currentPlan,
    this.failureReason,
    this.claudeSessionId,
    this.branchName,
    this.prUrl,
    DateTime? createdAt,
    this.startedAt,
    this.finishedAt,
    this.logs,
    this.feedback,
    this.questions,
  }) : skipPlanning = skipPlanning ?? false,
       status = status ?? _ic097rko.TaskStatus.queued,
       createdAt = createdAt ?? DateTime.now();

  factory Task({
    int? id,
    required int projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    required String prompt,
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
  }) = _TaskImpl;

  factory Task.fromJson(Map<String, dynamic> jsonSerialization) {
    return Task(
      id: jsonSerialization['id'] as int?,
      projectId: jsonSerialization['projectId'] as int,
      project: jsonSerialization['project'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_ifiazq2p.Project>(
              jsonSerialization['project'],
            ),
      agentId: jsonSerialization['agentId'] as int?,
      agent: jsonSerialization['agent'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<_ijo8h3v4.Agent>(
              jsonSerialization['agent'],
            ),
      prompt: jsonSerialization['prompt'] as String,
      skipPlanning: jsonSerialization['skipPlanning'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['skipPlanning']),
      status: jsonSerialization['status'] == null
          ? null
          : _ic097rko.TaskStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      currentPlan: jsonSerialization['currentPlan'] as String?,
      failureReason: jsonSerialization['failureReason'] as String?,
      claudeSessionId: jsonSerialization['claudeSessionId'] as String?,
      branchName: jsonSerialization['branchName'] as String?,
      prUrl: jsonSerialization['prUrl'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      finishedAt: jsonSerialization['finishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['finishedAt']),
      logs: jsonSerialization['logs'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_ihv3trno.TaskLogEntry>>(
              jsonSerialization['logs'],
            ),
      feedback: jsonSerialization['feedback'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_i5hi2zxr.TaskFeedback>>(
              jsonSerialization['feedback'],
            ),
      questions: jsonSerialization['questions'] == null
          ? null
          : _iikm6kmi.Protocol().deserialize<List<_ivtt8ejd.TaskQuestion>>(
              jsonSerialization['questions'],
            ),
    );
  }

  static final t = TaskTable();

  static const db = TaskRepository._();

  @override
  int? id;

  int projectId;

  _ifiazq2p.Project? project;

  int? agentId;

  /// Optional — this opens the door to task queueing without a schema change.
  /// onDelete=SetNull: deleting an agent (once its non-terminal tasks are
  /// gone) keeps its terminal/historical tasks around, just unassigned.
  _ijo8h3v4.Agent? agent;

  /// The task prompt given by the dev.
  String prompt;

  /// Saves Claude Code usage on trivial tasks by skipping the planning phase entirely.
  bool skipPlanning;

  _ic097rko.TaskStatus status;

  /// Content of the latest ExitPlanMode plan, when status=planReady.
  String? currentPlan;

  /// Short error summary, no log-scrolling needed.
  String? failureReason;

  /// Claude Code session id, for --resume on feedback.
  String? claudeSessionId;

  String? branchName;

  String? prUrl;

  DateTime createdAt;

  DateTime? startedAt;

  DateTime? finishedAt;

  List<_ihv3trno.TaskLogEntry>? logs;

  List<_i5hi2zxr.TaskFeedback>? feedback;

  List<_ivtt8ejd.TaskQuestion>? questions;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Task copyWith({
    int? id,
    int? projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    String? prompt,
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Task',
      if (id != null) 'id': id,
      'projectId': projectId,
      if (project != null) 'project': project?.toJson(),
      if (agentId != null) 'agentId': agentId,
      if (agent != null) 'agent': agent?.toJson(),
      'prompt': prompt,
      'skipPlanning': skipPlanning,
      'status': status.toJson(),
      if (currentPlan != null) 'currentPlan': currentPlan,
      if (failureReason != null) 'failureReason': failureReason,
      if (claudeSessionId != null) 'claudeSessionId': claudeSessionId,
      if (branchName != null) 'branchName': branchName,
      if (prUrl != null) 'prUrl': prUrl,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      if (logs != null) 'logs': logs?.toJson(valueToJson: (v) => v.toJson()),
      if (feedback != null)
        'feedback': feedback?.toJson(valueToJson: (v) => v.toJson()),
      if (questions != null)
        'questions': questions?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Task',
      if (id != null) 'id': id,
      'projectId': projectId,
      if (project != null) 'project': project?.toJsonForProtocol(),
      if (agentId != null) 'agentId': agentId,
      if (agent != null) 'agent': agent?.toJsonForProtocol(),
      'prompt': prompt,
      'skipPlanning': skipPlanning,
      'status': status.toJson(),
      if (currentPlan != null) 'currentPlan': currentPlan,
      if (failureReason != null) 'failureReason': failureReason,
      if (claudeSessionId != null) 'claudeSessionId': claudeSessionId,
      if (branchName != null) 'branchName': branchName,
      if (prUrl != null) 'prUrl': prUrl,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (finishedAt != null) 'finishedAt': finishedAt?.toJson(),
      if (logs != null)
        'logs': logs?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (feedback != null)
        'feedback': feedback?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (questions != null)
        'questions': questions?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
    };
  }

  static TaskInclude include({
    _ifiazq2p.ProjectInclude? project,
    _ijo8h3v4.AgentInclude? agent,
    _ihv3trno.TaskLogEntryIncludeList? logs,
    _i5hi2zxr.TaskFeedbackIncludeList? feedback,
    _ivtt8ejd.TaskQuestionIncludeList? questions,
  }) {
    return TaskInclude._(
      project: project,
      agent: agent,
      logs: logs,
      feedback: feedback,
      questions: questions,
    );
  }

  static TaskIncludeList includeList({
    _is.WhereExpressionBuilder<TaskTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskTable>? orderBy,
    _is.OrderByListBuilder<TaskTable>? orderByList,
    TaskInclude? include,
  }) {
    return TaskIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaskImpl extends Task {
  _TaskImpl({
    int? id,
    required int projectId,
    _ifiazq2p.Project? project,
    int? agentId,
    _ijo8h3v4.Agent? agent,
    required String prompt,
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    String? currentPlan,
    String? failureReason,
    String? claudeSessionId,
    String? branchName,
    String? prUrl,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
    List<_ihv3trno.TaskLogEntry>? logs,
    List<_i5hi2zxr.TaskFeedback>? feedback,
    List<_ivtt8ejd.TaskQuestion>? questions,
  }) : super._(
         id: id,
         projectId: projectId,
         project: project,
         agentId: agentId,
         agent: agent,
         prompt: prompt,
         skipPlanning: skipPlanning,
         status: status,
         currentPlan: currentPlan,
         failureReason: failureReason,
         claudeSessionId: claudeSessionId,
         branchName: branchName,
         prUrl: prUrl,
         createdAt: createdAt,
         startedAt: startedAt,
         finishedAt: finishedAt,
         logs: logs,
         feedback: feedback,
         questions: questions,
       );

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Task copyWith({
    Object? id = _Undefined,
    int? projectId,
    Object? project = _Undefined,
    Object? agentId = _Undefined,
    Object? agent = _Undefined,
    String? prompt,
    bool? skipPlanning,
    _ic097rko.TaskStatus? status,
    Object? currentPlan = _Undefined,
    Object? failureReason = _Undefined,
    Object? claudeSessionId = _Undefined,
    Object? branchName = _Undefined,
    Object? prUrl = _Undefined,
    DateTime? createdAt,
    Object? startedAt = _Undefined,
    Object? finishedAt = _Undefined,
    Object? logs = _Undefined,
    Object? feedback = _Undefined,
    Object? questions = _Undefined,
  }) {
    return Task(
      id: id is int? ? id : this.id,
      projectId: projectId ?? this.projectId,
      project: project is _ifiazq2p.Project?
          ? project
          : this.project?.copyWith(),
      agentId: agentId is int? ? agentId : this.agentId,
      agent: agent is _ijo8h3v4.Agent? ? agent : this.agent?.copyWith(),
      prompt: prompt ?? this.prompt,
      skipPlanning: skipPlanning ?? this.skipPlanning,
      status: status ?? this.status,
      currentPlan: currentPlan is String? ? currentPlan : this.currentPlan,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
      claudeSessionId: claudeSessionId is String?
          ? claudeSessionId
          : this.claudeSessionId,
      branchName: branchName is String? ? branchName : this.branchName,
      prUrl: prUrl is String? ? prUrl : this.prUrl,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      finishedAt: finishedAt is DateTime? ? finishedAt : this.finishedAt,
      logs: logs is List<_ihv3trno.TaskLogEntry>?
          ? logs
          : this.logs?.map((e0) => e0.copyWith()).toList(),
      feedback: feedback is List<_i5hi2zxr.TaskFeedback>?
          ? feedback
          : this.feedback?.map((e0) => e0.copyWith()).toList(),
      questions: questions is List<_ivtt8ejd.TaskQuestion>?
          ? questions
          : this.questions?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class TaskUpdateTable extends _is.UpdateTable<TaskTable> {
  TaskUpdateTable(super.table);

  _is.ColumnValue<int, int> projectId(int value) => _is.ColumnValue(
    table.projectId,
    value,
  );

  _is.ColumnValue<int, int> agentId(int? value) => _is.ColumnValue(
    table.agentId,
    value,
  );

  _is.ColumnValue<String, String> prompt(String value) => _is.ColumnValue(
    table.prompt,
    value,
  );

  _is.ColumnValue<bool, bool> skipPlanning(bool value) => _is.ColumnValue(
    table.skipPlanning,
    value,
  );

  _is.ColumnValue<_ic097rko.TaskStatus, _ic097rko.TaskStatus> status(
    _ic097rko.TaskStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> currentPlan(String? value) => _is.ColumnValue(
    table.currentPlan,
    value,
  );

  _is.ColumnValue<String, String> failureReason(String? value) =>
      _is.ColumnValue(
        table.failureReason,
        value,
      );

  _is.ColumnValue<String, String> claudeSessionId(String? value) =>
      _is.ColumnValue(
        table.claudeSessionId,
        value,
      );

  _is.ColumnValue<String, String> branchName(String? value) => _is.ColumnValue(
    table.branchName,
    value,
  );

  _is.ColumnValue<String, String> prUrl(String? value) => _is.ColumnValue(
    table.prUrl,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _is.ColumnValue(
        table.startedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> finishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.finishedAt,
        value,
      );
}

class TaskTable extends _is.Table<int?> {
  TaskTable({super.tableRelation}) : super(tableName: 'task') {
    updateTable = TaskUpdateTable(this);
    projectId = _is.ColumnInt(
      'projectId',
      this,
    );
    agentId = _is.ColumnInt(
      'agentId',
      this,
    );
    prompt = _is.ColumnString(
      'prompt',
      this,
    );
    skipPlanning = _is.ColumnBool(
      'skipPlanning',
      this,
      hasDefault: true,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    currentPlan = _is.ColumnString(
      'currentPlan',
      this,
    );
    failureReason = _is.ColumnString(
      'failureReason',
      this,
    );
    claudeSessionId = _is.ColumnString(
      'claudeSessionId',
      this,
    );
    branchName = _is.ColumnString(
      'branchName',
      this,
    );
    prUrl = _is.ColumnString(
      'prUrl',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    startedAt = _is.ColumnDateTime(
      'startedAt',
      this,
    );
    finishedAt = _is.ColumnDateTime(
      'finishedAt',
      this,
    );
  }

  late final TaskUpdateTable updateTable;

  late final _is.ColumnInt projectId;

  _ifiazq2p.ProjectTable? _project;

  late final _is.ColumnInt agentId;

  /// Optional — this opens the door to task queueing without a schema change.
  /// onDelete=SetNull: deleting an agent (once its non-terminal tasks are
  /// gone) keeps its terminal/historical tasks around, just unassigned.
  _ijo8h3v4.AgentTable? _agent;

  /// The task prompt given by the dev.
  late final _is.ColumnString prompt;

  /// Saves Claude Code usage on trivial tasks by skipping the planning phase entirely.
  late final _is.ColumnBool skipPlanning;

  late final _is.ColumnEnum<_ic097rko.TaskStatus> status;

  /// Content of the latest ExitPlanMode plan, when status=planReady.
  late final _is.ColumnString currentPlan;

  /// Short error summary, no log-scrolling needed.
  late final _is.ColumnString failureReason;

  /// Claude Code session id, for --resume on feedback.
  late final _is.ColumnString claudeSessionId;

  late final _is.ColumnString branchName;

  late final _is.ColumnString prUrl;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime startedAt;

  late final _is.ColumnDateTime finishedAt;

  _ihv3trno.TaskLogEntryTable? ___logs;

  _is.ManyRelation<_ihv3trno.TaskLogEntryTable>? _logs;

  _i5hi2zxr.TaskFeedbackTable? ___feedback;

  _is.ManyRelation<_i5hi2zxr.TaskFeedbackTable>? _feedback;

  _ivtt8ejd.TaskQuestionTable? ___questions;

  _is.ManyRelation<_ivtt8ejd.TaskQuestionTable>? _questions;

  _ifiazq2p.ProjectTable get project {
    if (_project != null) return _project!;
    _project = _is.createRelationTable(
      relationFieldName: 'project',
      field: Task.t.projectId,
      foreignField: _ifiazq2p.Project.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ifiazq2p.ProjectTable(tableRelation: foreignTableRelation),
    );
    return _project!;
  }

  _ijo8h3v4.AgentTable get agent {
    if (_agent != null) return _agent!;
    _agent = _is.createRelationTable(
      relationFieldName: 'agent',
      field: Task.t.agentId,
      foreignField: _ijo8h3v4.Agent.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ijo8h3v4.AgentTable(tableRelation: foreignTableRelation),
    );
    return _agent!;
  }

  _ihv3trno.TaskLogEntryTable get __logs {
    if (___logs != null) return ___logs!;
    ___logs = _is.createRelationTable(
      relationFieldName: '__logs',
      field: Task.t.id,
      foreignField: _ihv3trno.TaskLogEntry.t.taskId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ihv3trno.TaskLogEntryTable(tableRelation: foreignTableRelation),
    );
    return ___logs!;
  }

  _i5hi2zxr.TaskFeedbackTable get __feedback {
    if (___feedback != null) return ___feedback!;
    ___feedback = _is.createRelationTable(
      relationFieldName: '__feedback',
      field: Task.t.id,
      foreignField: _i5hi2zxr.TaskFeedback.t.taskId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5hi2zxr.TaskFeedbackTable(tableRelation: foreignTableRelation),
    );
    return ___feedback!;
  }

  _ivtt8ejd.TaskQuestionTable get __questions {
    if (___questions != null) return ___questions!;
    ___questions = _is.createRelationTable(
      relationFieldName: '__questions',
      field: Task.t.id,
      foreignField: _ivtt8ejd.TaskQuestion.t.taskId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ivtt8ejd.TaskQuestionTable(tableRelation: foreignTableRelation),
    );
    return ___questions!;
  }

  _is.ManyRelation<_ihv3trno.TaskLogEntryTable> get logs {
    if (_logs != null) return _logs!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'logs',
      field: Task.t.id,
      foreignField: _ihv3trno.TaskLogEntry.t.taskId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ihv3trno.TaskLogEntryTable(tableRelation: foreignTableRelation),
    );
    _logs = _is.ManyRelation<_ihv3trno.TaskLogEntryTable>(
      tableWithRelations: relationTable,
      table: _ihv3trno.TaskLogEntryTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _logs!;
  }

  _is.ManyRelation<_i5hi2zxr.TaskFeedbackTable> get feedback {
    if (_feedback != null) return _feedback!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'feedback',
      field: Task.t.id,
      foreignField: _i5hi2zxr.TaskFeedback.t.taskId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5hi2zxr.TaskFeedbackTable(tableRelation: foreignTableRelation),
    );
    _feedback = _is.ManyRelation<_i5hi2zxr.TaskFeedbackTable>(
      tableWithRelations: relationTable,
      table: _i5hi2zxr.TaskFeedbackTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _feedback!;
  }

  _is.ManyRelation<_ivtt8ejd.TaskQuestionTable> get questions {
    if (_questions != null) return _questions!;
    var relationTable = _is.createRelationTable(
      relationFieldName: 'questions',
      field: Task.t.id,
      foreignField: _ivtt8ejd.TaskQuestion.t.taskId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ivtt8ejd.TaskQuestionTable(tableRelation: foreignTableRelation),
    );
    _questions = _is.ManyRelation<_ivtt8ejd.TaskQuestionTable>(
      tableWithRelations: relationTable,
      table: _ivtt8ejd.TaskQuestionTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _questions!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    projectId,
    agentId,
    prompt,
    skipPlanning,
    status,
    currentPlan,
    failureReason,
    claudeSessionId,
    branchName,
    prUrl,
    createdAt,
    startedAt,
    finishedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'project') {
      return project;
    }
    if (relationField == 'agent') {
      return agent;
    }
    if (relationField == 'logs') {
      return __logs;
    }
    if (relationField == 'feedback') {
      return __feedback;
    }
    if (relationField == 'questions') {
      return __questions;
    }
    return null;
  }
}

class TaskInclude extends _is.IncludeObject {
  TaskInclude._({
    _ifiazq2p.ProjectInclude? project,
    _ijo8h3v4.AgentInclude? agent,
    _ihv3trno.TaskLogEntryIncludeList? logs,
    _i5hi2zxr.TaskFeedbackIncludeList? feedback,
    _ivtt8ejd.TaskQuestionIncludeList? questions,
  }) {
    _project = project;
    _agent = agent;
    _logs = logs;
    _feedback = feedback;
    _questions = questions;
  }

  _ifiazq2p.ProjectInclude? _project;

  _ijo8h3v4.AgentInclude? _agent;

  _ihv3trno.TaskLogEntryIncludeList? _logs;

  _i5hi2zxr.TaskFeedbackIncludeList? _feedback;

  _ivtt8ejd.TaskQuestionIncludeList? _questions;

  @override
  Map<String, _is.Include?> get includes => {
    'project': _project,
    'agent': _agent,
    'logs': _logs,
    'feedback': _feedback,
    'questions': _questions,
  };

  @override
  _is.Table<int?> get table => Task.t;
}

class TaskIncludeList extends _is.IncludeList {
  TaskIncludeList._({
    _is.WhereExpressionBuilder<TaskTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Task.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Task.t;
}

class TaskRepository {
  const TaskRepository._();

  final attach = const TaskAttachRepository._();

  final attachRow = const TaskAttachRowRepository._();

  final detachRow = const TaskDetachRowRepository._();

  /// Returns a list of [Task]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Task>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskTable>? orderBy,
    _is.OrderByListBuilder<TaskTable>? orderByList,
    _is.Transaction? transaction,
    TaskInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Task>(
      where: where?.call(Task.t),
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Task] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Task?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskTable>? where,
    int? offset,
    _is.OrderByBuilder<TaskTable>? orderBy,
    _is.OrderByListBuilder<TaskTable>? orderByList,
    _is.Transaction? transaction,
    TaskInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Task>(
      where: where?.call(Task.t),
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Task] by its [id] or null if no such row exists.
  Future<Task?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    TaskInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Task>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Task]s in the list and returns the inserted rows.
  ///
  /// The returned [Task]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Task>> insert(
    _is.DatabaseSession session,
    List<Task> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Task>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Task] and returns the inserted row.
  ///
  /// The returned [Task] will have its `id` field set.
  Future<Task> insertRow(
    _is.DatabaseSession session,
    Task row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Task>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Task]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [Task]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Task>> upsert(
    _is.DatabaseSession session,
    List<Task> rows, {
    required _is.ColumnSelections<TaskTable> conflictColumns,
    _is.ColumnSelections<TaskTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Task>(
      rows,
      conflictColumns: conflictColumns(Task.t),
      updateColumns: updateColumns?.call(Task.t),
      updateWhere: updateWhere?.call(Task.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Task] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [Task] will have its `id` field set.
  Future<Task?> upsertRow(
    _is.DatabaseSession session,
    Task row, {
    required _is.ColumnSelections<TaskTable> conflictColumns,
    _is.ColumnSelections<TaskTable>? updateColumns,
    _is.WhereExpressionBuilder<TaskTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Task>(
      row,
      conflictColumns: conflictColumns(Task.t),
      updateColumns: updateColumns?.call(Task.t),
      updateWhere: updateWhere?.call(Task.t),
      transaction: transaction,
    );
  }

  /// Updates all [Task]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Task>> update(
    _is.DatabaseSession session,
    List<Task> rows, {
    _is.ColumnSelections<TaskTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Task>(
      rows,
      columns: columns?.call(Task.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Task]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Task> updateRow(
    _is.DatabaseSession session,
    Task row, {
    _is.ColumnSelections<TaskTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Task>(
      row,
      columns: columns?.call(Task.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Task] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Task?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaskUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Task>(
      id,
      columnValues: columnValues(Task.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Task]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Task>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaskUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaskTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaskTable>? orderBy,
    _is.OrderByListBuilder<TaskTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Task>(
      columnValues: columnValues(Task.t.updateTable),
      where: where(Task.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Task]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Task>> delete(
    _is.DatabaseSession session,
    List<Task> rows, {
    _is.OrderByBuilder<TaskTable>? orderBy,
    _is.OrderByListBuilder<TaskTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Task>(
      rows,
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Task].
  Future<Task> deleteRow(
    _is.DatabaseSession session,
    Task row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Task>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Task>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskTable> where,
    _is.OrderByBuilder<TaskTable>? orderBy,
    _is.OrderByListBuilder<TaskTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Task>(
      where: where(Task.t),
      orderBy: orderBy?.call(Task.t),
      orderByList: orderByList?.call(Task.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaskTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Task>(
      where: where?.call(Task.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Task] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaskTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Task>(
      where: where(Task.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class TaskAttachRepository {
  const TaskAttachRepository._();

  /// Creates a relation between this [Task] and the given [TaskLogEntry]s
  /// by setting each [TaskLogEntry]'s foreign key `taskId` to refer to this [Task].
  Future<void> logs(
    _is.DatabaseSession session,
    Task task,
    List<_ihv3trno.TaskLogEntry> taskLogEntry, {
    _is.Transaction? transaction,
  }) async {
    if (taskLogEntry.any((e) => e.id == null)) {
      throw ArgumentError.notNull('taskLogEntry.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskLogEntry = taskLogEntry
        .map((e) => e.copyWith(taskId: task.id))
        .toList();
    await session.db.update<_ihv3trno.TaskLogEntry>(
      $taskLogEntry,
      columns: [_ihv3trno.TaskLogEntry.t.taskId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Task] and the given [TaskFeedback]s
  /// by setting each [TaskFeedback]'s foreign key `taskId` to refer to this [Task].
  Future<void> feedback(
    _is.DatabaseSession session,
    Task task,
    List<_i5hi2zxr.TaskFeedback> taskFeedback, {
    _is.Transaction? transaction,
  }) async {
    if (taskFeedback.any((e) => e.id == null)) {
      throw ArgumentError.notNull('taskFeedback.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskFeedback = taskFeedback
        .map((e) => e.copyWith(taskId: task.id))
        .toList();
    await session.db.update<_i5hi2zxr.TaskFeedback>(
      $taskFeedback,
      columns: [_i5hi2zxr.TaskFeedback.t.taskId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Task] and the given [TaskQuestion]s
  /// by setting each [TaskQuestion]'s foreign key `taskId` to refer to this [Task].
  Future<void> questions(
    _is.DatabaseSession session,
    Task task,
    List<_ivtt8ejd.TaskQuestion> taskQuestion, {
    _is.Transaction? transaction,
  }) async {
    if (taskQuestion.any((e) => e.id == null)) {
      throw ArgumentError.notNull('taskQuestion.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskQuestion = taskQuestion
        .map((e) => e.copyWith(taskId: task.id))
        .toList();
    await session.db.update<_ivtt8ejd.TaskQuestion>(
      $taskQuestion,
      columns: [_ivtt8ejd.TaskQuestion.t.taskId],
      transaction: transaction,
    );
  }
}

class TaskAttachRowRepository {
  const TaskAttachRowRepository._();

  /// Creates a relation between the given [Task] and [Project]
  /// by setting the [Task]'s foreign key `projectId` to refer to the [Project].
  Future<void> project(
    _is.DatabaseSession session,
    Task task,
    _ifiazq2p.Project project, {
    _is.Transaction? transaction,
  }) async {
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $task = task.copyWith(projectId: project.id);
    await session.db.updateRow<Task>(
      $task,
      columns: [Task.t.projectId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Task] and [Agent]
  /// by setting the [Task]'s foreign key `agentId` to refer to the [Agent].
  Future<void> agent(
    _is.DatabaseSession session,
    Task task,
    _ijo8h3v4.Agent agent, {
    _is.Transaction? transaction,
  }) async {
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }
    if (agent.id == null) {
      throw ArgumentError.notNull('agent.id');
    }

    var $task = task.copyWith(agentId: agent.id);
    await session.db.updateRow<Task>(
      $task,
      columns: [Task.t.agentId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Task] and the given [TaskLogEntry]
  /// by setting the [TaskLogEntry]'s foreign key `taskId` to refer to this [Task].
  Future<void> logs(
    _is.DatabaseSession session,
    Task task,
    _ihv3trno.TaskLogEntry taskLogEntry, {
    _is.Transaction? transaction,
  }) async {
    if (taskLogEntry.id == null) {
      throw ArgumentError.notNull('taskLogEntry.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskLogEntry = taskLogEntry.copyWith(taskId: task.id);
    await session.db.updateRow<_ihv3trno.TaskLogEntry>(
      $taskLogEntry,
      columns: [_ihv3trno.TaskLogEntry.t.taskId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Task] and the given [TaskFeedback]
  /// by setting the [TaskFeedback]'s foreign key `taskId` to refer to this [Task].
  Future<void> feedback(
    _is.DatabaseSession session,
    Task task,
    _i5hi2zxr.TaskFeedback taskFeedback, {
    _is.Transaction? transaction,
  }) async {
    if (taskFeedback.id == null) {
      throw ArgumentError.notNull('taskFeedback.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskFeedback = taskFeedback.copyWith(taskId: task.id);
    await session.db.updateRow<_i5hi2zxr.TaskFeedback>(
      $taskFeedback,
      columns: [_i5hi2zxr.TaskFeedback.t.taskId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [Task] and the given [TaskQuestion]
  /// by setting the [TaskQuestion]'s foreign key `taskId` to refer to this [Task].
  Future<void> questions(
    _is.DatabaseSession session,
    Task task,
    _ivtt8ejd.TaskQuestion taskQuestion, {
    _is.Transaction? transaction,
  }) async {
    if (taskQuestion.id == null) {
      throw ArgumentError.notNull('taskQuestion.id');
    }
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $taskQuestion = taskQuestion.copyWith(taskId: task.id);
    await session.db.updateRow<_ivtt8ejd.TaskQuestion>(
      $taskQuestion,
      columns: [_ivtt8ejd.TaskQuestion.t.taskId],
      transaction: transaction,
    );
  }
}

class TaskDetachRowRepository {
  const TaskDetachRowRepository._();

  /// Detaches the relation between this [Task] and the [Agent] set in `agent`
  /// by setting the [Task]'s foreign key `agentId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> agent(
    _is.DatabaseSession session,
    Task task, {
    _is.Transaction? transaction,
  }) async {
    if (task.id == null) {
      throw ArgumentError.notNull('task.id');
    }

    var $task = task.copyWith(agentId: null);
    await session.db.updateRow<Task>(
      $task,
      columns: [Task.t.agentId],
      transaction: transaction,
    );
  }
}
