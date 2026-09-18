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
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
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
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

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
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _isc.getType<_ijo8h3v4.Agent?>()) {
      return (data != null ? _ijo8h3v4.Agent.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iexg9pz4.AgentEffort?>()) {
      return (data != null ? _iexg9pz4.AgentEffort.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i4babe00.AgentExecutionMode?>()) {
      return (data != null ? _i4babe00.AgentExecutionMode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idfmm35v.AgentRole?>()) {
      return (data != null ? _idfmm35v.AgentRole.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i69bozh7.AgentStatus?>()) {
      return (data != null ? _i69bozh7.AgentStatus.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilj2nbps.LogSource?>()) {
      return (data != null ? _ilj2nbps.LogSource.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i0hti3f2.Machine?>()) {
      return (data != null ? _i0hti3f2.Machine.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ixivwx7g.MachineMetric?>()) {
      return (data != null ? _ixivwx7g.MachineMetric.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6yugb3s.MachineStatus?>()) {
      return (data != null ? _i6yugb3s.MachineStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ifiazq2p.Project?>()) {
      return (data != null ? _ifiazq2p.Project.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iwn6t6fs.Task?>()) {
      return (data != null ? _iwn6t6fs.Task.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i5hi2zxr.TaskFeedback?>()) {
      return (data != null ? _i5hi2zxr.TaskFeedback.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iitmdld3.TaskFeedbackPhase?>()) {
      return (data != null ? _iitmdld3.TaskFeedbackPhase.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihv3trno.TaskLogEntry?>()) {
      return (data != null ? _ihv3trno.TaskLogEntry.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ivtt8ejd.TaskQuestion?>()) {
      return (data != null ? _ivtt8ejd.TaskQuestion.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ic097rko.TaskStatus?>()) {
      return (data != null ? _ic097rko.TaskStatus.fromJson(data) : null) as T;
    }
    if (t == List<_iwn6t6fs.Task>) {
      return (data as List).map((e) => deserialize<_iwn6t6fs.Task>(e)).toList()
          as T;
    }
    if (t == _isc.getType<List<_iwn6t6fs.Task>?>()) {
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
    if (t == _isc.getType<List<_ijo8h3v4.Agent>?>()) {
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
    if (t == _isc.getType<List<_ixivwx7g.MachineMetric>?>()) {
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
    if (t == _isc.getType<List<_ihv3trno.TaskLogEntry>?>()) {
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
    if (t == _isc.getType<List<_i5hi2zxr.TaskFeedback>?>()) {
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
    if (t == _isc.getType<List<_ivtt8ejd.TaskQuestion>?>()) {
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
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
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
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
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
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('roundtable', this);
    _iacc.Protocol().registerHostProtocol('roundtable', this);
  }

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
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
