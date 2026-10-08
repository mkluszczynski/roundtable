import 'package:flutter/material.dart';

import '../utils/agent_role_label.dart';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';
import '../utils/external_url.dart';

import '../blocs/task_detail_bloc.dart';
import '../client.dart';
import '../repositories/agent_repository.dart';
import '../repositories/machine_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import '../utils/checkout_command.dart';
import '../utils/code_language.dart';
import '../utils/follow_up_prompt.dart';
import '../widgets/copy_icon_button.dart';
import '../utils/question_context.dart';
import '../utils/open_task.dart';
import '../utils/task_status_label.dart';
import '../utils/task_timeline.dart';
import '../theme/breakpoints.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/agent_avatar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal.dart';
import '../widgets/code_block.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/diff_view.dart';
import '../widgets/edit_task_dialog.dart';
import '../widgets/horizontal_scroller.dart';
import '../widgets/pill_selector.dart';
import '../widgets/rail_nav_item.dart';
import '../widgets/rail_section.dart';
import '../widgets/plan_content.dart';
import '../widgets/pr_checks_view.dart';
import '../widgets/reassign_agent_dialog.dart';
import '../widgets/rename_task_dialog.dart';
import '../widgets/request_review_dialog.dart';
import '../widgets/review_comment_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/tag_chip.dart';
import '../widgets/task_attachments_view.dart';
import '../widgets/task_options_form.dart';
import '../utils/log_timeline.dart';
import '../widgets/task_log_timeline.dart';
import '../widgets/task_timeline_view.dart';
import '../utils/relative_time.dart';

part 'task_detail/changes_view.dart';
part 'task_detail/dialogs.dart';
part 'task_detail/feedback_row.dart';
part 'task_detail/header.dart';
part 'task_detail/info_rail.dart';
part 'task_detail/overview.dart';
part 'task_detail/question_and_plan.dart';
part 'task_detail/rail_actions.dart';
part 'task_detail/review_view.dart';

/// One screen driven by `Task.status`, switching between the task lifecycle's
/// 4 sub-states (docs/FLOWS.md §4): waiting for an answer, plan
/// approval, live execution (log tail), and diff review. Always entered from
/// a dashboard kanban card with a concrete [initialTaskId].
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.initialTaskId});

  final int initialTaskId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailBloc(
        TaskRepository(client),
        projectRepository: ProjectRepository(client),
        agentRepository: AgentRepository(client),
        machineRepository: MachineRepository(client),
      )..add(TaskDetailSubscribed(initialTaskId)),
      child: _OpenTaskReporter(
        taskId: initialTaskId,
        child: const Scaffold(
          backgroundColor: AppColors.bg0,
          body: _TaskDetailView(),
        ),
      ),
    );
  }
}

/// Marks [taskId] as the open task ([openTaskId]) while this screen lives.
class _OpenTaskReporter extends StatefulWidget {
  const _OpenTaskReporter({required this.taskId, required this.child});

  final int taskId;
  final Widget child;

  @override
  State<_OpenTaskReporter> createState() => _OpenTaskReporterState();
}

class _OpenTaskReporterState extends State<_OpenTaskReporter> {
  @override
  void initState() {
    super.initState();
    // After the frame: the rail listening to it may be building now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) openTaskId.value = widget.taskId;
    });
  }

  @override
  void dispose() {
    // Not now: the tree is locked while it's torn down.
    final id = widget.taskId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (openTaskId.value == id) openTaskId.value = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TaskDetailView extends StatefulWidget {
  const _TaskDetailView();

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  /// Null until the dev picks a section; until then (and after every
  /// status change) the status's default section is shown.
  TaskSection? _section;

  void _select(TaskSection section) => setState(() => _section = section);

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<TaskDetailBloc, TaskDetailState>(
          listenWhen: (previous, current) => current is TaskDetailDeleted,
          listener: (context, state) {
            if (Navigator.canPop(context)) Navigator.of(context).pop();
          },
        ),
        BlocListener<TaskDetailBloc, TaskDetailState>(
          listenWhen: (previous, current) =>
              previous is TaskDetailLoaded &&
              current is TaskDetailLoaded &&
              previous.task.status != current.task.status,
          listener: (context, state) => setState(() => _section = null),
        ),
        BlocListener<TaskDetailBloc, TaskDetailState>(
          listenWhen: (previous, current) =>
              current is TaskDetailLoaded &&
              current.actionError != null &&
              (previous is! TaskDetailLoaded ||
                  previous.actionError != current.actionError),
          listener: (context, state) =>
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(
                  content: Text((state as TaskDetailLoaded).actionError!),
                ),
              ),
        ),
      ],
      child: BlocBuilder<TaskDetailBloc, TaskDetailState>(
        builder: (context, state) {
          return switch (state) {
            TaskDetailInitial() || TaskDetailLoading() || TaskDetailDeleted() =>
              const Center(child: CircularProgressIndicator()),
            TaskDetailError(:final message) => Center(
              child: Text(
                'Failed to load task: $message',
                style: AppTypography.body.copyWith(color: AppColors.red),
              ),
            ),
            TaskDetailLoaded() => _buildLoaded(state),
          };
        },
      ),
    );
  }

  /// The one-column layout's "Info" tab is open instead of a section.
  bool _showInfo = false;

  /// Below this width the rail and the content stack into one column: the
  /// content would be too narrow beside a 320 px rail.
  static const _twoPaneMin = 900.0;

  Widget _buildLoaded(TaskDetailLoaded state) {
    final picked = _section;
    final section = picked != null && state.availableSections.contains(picked)
        ? picked
        : state.task.defaultSection;
    final content = _SectionContent(
      state: state,
      section: section,
      onSectionSelected: _select,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = constraints.maxWidth >= _twoPaneMin;
        final compact = LayoutSize.forWidth(constraints.maxWidth).isCompact;
        if (!twoPane) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(state: state, compact: compact),
              _SectionTabs(
                state: state,
                section: section,
                showingInfo: _showInfo,
                onSelected: (s) {
                  setState(() => _showInfo = false);
                  _select(s);
                },
                onInfo: () => setState(() => _showInfo = true),
              ),
              Expanded(
                child: _showInfo
                    ? _InfoRail(
                        state: state,
                        section: section,
                        onSectionSelected: (s) {
                          setState(() => _showInfo = false);
                          _select(s);
                        },
                        inline: true,
                      )
                    : Padding(
                        padding: EdgeInsets.all(
                          compact ? Spacing.md : Spacing.xl,
                        ),
                        child: content,
                      ),
              ),
              _RailActions(state: state, bar: true),
            ],
          );
        }
        return Column(
          children: [
            _Header(state: state),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 320,
                    child: _InfoRail(
                      state: state,
                      section: section,
                      onSectionSelected: _select,
                    ),
                  ),
                  VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xl),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
