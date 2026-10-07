import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../repositories/agent_repository.dart';
import '../repositories/agent_role_repository.dart';
import '../repositories/settings_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/task_options.dart';
import '../widgets/agent_role_dialog.dart';
import '../widgets/app_card.dart';
import '../widgets/app_modal.dart';
import '../widgets/load_failed_view.dart';
import '../widgets/pill_selector.dart';
import '../widgets/reviewer_select.dart';
import '../widgets/setting_row.dart';

/// Workspace-wide settings. For now: the advanced task options every
/// project starts from unless it overrides them.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _repository = SettingsRepository(client);
  WorkspaceSettings? _settings;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final settings = await _repository.getWorkspace();
      if (mounted) setState(() => _settings = settings);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save(WorkspaceSettings updated) async {
    final previous = _settings;
    setState(() => _settings = updated);
    try {
      final saved = await _repository.updateWorkspace(updated);
      if (mounted) setState(() => _settings = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _settings = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't save: ${errorMessage(e)}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loadError != null
          ? LoadFailedView(
              title: "Couldn't load settings",
              message: errorMessage(_loadError!),
              onRetry: _load,
            )
          : settings == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.xl),
              // A centered reading column, like the task detail views.
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Settings', style: AppTypography.screenTitle),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Workspace defaults and agent roles',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: Spacing.xl),
                      _TaskDefaultsCard(settings: settings, onChanged: _save),
                      const SizedBox(height: Spacing.xl),
                      const _AgentRolesCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _TaskDefaultsCard extends StatelessWidget {
  const _TaskDefaultsCard({required this.settings, required this.onChanged});

  final WorkspaceSettings settings;
  final ValueChanged<WorkspaceSettings> onChanged;

  Widget _switch(TaskOptionInfo option, bool value, ValueChanged<bool> set) =>
      SettingRow(
        title: option.title,
        description: option.description,
        control: Switch(
          value: value,
          activeThumbColor: AppColors.accent,
          onChanged: set,
        ),
      );

  Widget _count(TaskOptionInfo option, int value, ValueChanged<int> set) =>
      SettingRow(
        title: option.title,
        description: option.description,
        control: PillSelector<int>(
          options: fixRoundChoices,
          labelBuilder: (n) => '$n',
          selected: value,
          onChanged: set,
        ),
      );

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.xs),
    child: Text(label, style: AppTypography.label),
  );

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return AppCard(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TASK DEFAULTS', style: AppTypography.label),
          const SizedBox(height: Spacing.xs),
          Text(
            'New tasks start with these options. A project can override '
            'each one in its own settings, and every task can still change '
            'them in the form.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: Spacing.sm),
          Divider(color: AppColors.border, height: 1),
          _section('PLANNING'),
          _switch(
            skipPlanningOption,
            s.skipPlanning,
            (v) => onChanged(s.copyWith(skipPlanning: v)),
          ),
          _section('REVIEW'),
          _switch(
            autoReviewOption,
            s.autoReview,
            (v) => onChanged(s.copyWith(autoReview: v)),
          ),
          SettingRow(
            title: reviewerOption.title,
            description: reviewerOption.description,
            control: ReviewerSelect(
              selected: s.reviewerAgentId,
              onChanged: (id) => onChanged(s.copyWith(reviewerAgentId: id)),
            ),
          ),
          _switch(
            autoFixOption,
            s.autoFixReview,
            (v) => onChanged(s.copyWith(autoFixReview: v)),
          ),
          // Fix rounds only cap auto fix.
          if (s.autoFixReview)
            _count(
              maxFixRoundsOption,
              s.maxReviewFixRounds,
              (n) => onChanged(s.copyWith(maxReviewFixRounds: n)),
            ),
          _section('MERGE & CI'),
          SettingRow(
            title: autoMergeOption.title,
            description: s.autoMerge && !s.autoReview
                ? autoMergeWithoutReviewHint
                : autoMergeOption.description,
            control: Switch(
              value: s.autoMerge,
              activeThumbColor: AppColors.accent,
              onChanged: (v) => onChanged(s.copyWith(autoMerge: v)),
            ),
          ),
          _switch(
            autoFixChecksOption,
            s.autoFixFailingChecks,
            (v) => onChanged(s.copyWith(autoFixFailingChecks: v)),
          ),
          _count(
            maxCheckFixAttemptsOption,
            s.maxCheckFixAttempts,
            (n) => onChanged(s.copyWith(maxCheckFixAttempts: n)),
          ),
        ],
      ),
    );
  }
}

/// The workspace's agent roles: name, description and the prompt prefix
/// the runner puts in front of every task and review.
class _AgentRolesCard extends StatefulWidget {
  const _AgentRolesCard();

  @override
  State<_AgentRolesCard> createState() => _AgentRolesCardState();
}

class _AgentRolesCardState extends State<_AgentRolesCard> {
  late final _roles = AgentRoleRepository(client);
  late final _agents = AgentRepository(client);
  List<AgentRoleDefinition>? _list;
  Map<int, int> _agentCounts = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (roles, agents) = (
        await _roles.listRoles(),
        await _agents.listAgents(),
      );
      final counts = <int, int>{};
      for (final agent in agents) {
        final id = agent.roleId;
        if (id != null) counts[id] = (counts[id] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _list = roles;
        _agentCounts = counts;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  Future<void> _edit([AgentRoleDefinition? role]) async {
    final saved = await showDialog<AgentRoleDefinition>(
      context: context,
      builder: (_) => AgentRoleDialog(existing: role),
    );
    if (saved != null) await _load();
  }

  Future<void> _delete(AgentRoleDefinition role) async {
    final confirmed = await showAppModal<bool>(
      context,
      icon: Icons.delete_outline,
      tone: AppModalTone.danger,
      title: 'Delete ${role.name}?',
      subtitle: 'Agents can no longer pick this role.',
      child: const SizedBox.shrink(),
      actions: [
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ),
        Builder(
          builder: (context) => FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ),
      ],
    );
    if (!(confirmed ?? false)) return;
    try {
      await _roles.deleteRole(role.id!);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = _list;
    return AppCard(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('AGENT ROLES', style: AppTypography.label),
              ),
              TextButton.icon(
                onPressed: roles == null ? null : () => _edit(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add role'),
              ),
            ],
          ),
          Text(
            'A role is the prompt prefix of every task and review its agents '
            'get — context, not a permission. Edits apply from the next run.',
            style: AppTypography.caption,
          ),
          const SizedBox(height: Spacing.sm),
          Divider(color: AppColors.border, height: 1),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.red),
              ),
            )
          else if (roles == null)
            const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (final role in roles)
              _RoleRow(
                role: role,
                agentCount: _agentCounts[role.id] ?? 0,
                onEdit: () => _edit(role),
                onDelete: () => _delete(role),
              ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({
    required this.role,
    required this.agentCount,
    required this.onEdit,
    required this.onDelete,
  });

  final AgentRoleDefinition role;
  final int agentCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final inUse = agentCount > 0;
    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(role.name, style: AppTypography.bodyStrong),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        inUse
                            ? '$agentCount '
                                  '${agentCount == 1 ? 'agent' : 'agents'}'
                            : 'unused',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  if (role.description != null)
                    Text(role.description!, style: AppTypography.caption),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    role.prompt,
                    style: AppTypography.code.copyWith(color: AppColors.text1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: AppColors.text1,
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: inUse
                  ? 'In use — give its agents another role first'
                  : 'Delete',
              icon: const Icon(Icons.delete_outline, size: 16),
              color: AppColors.red,
              onPressed: inUse ? null : onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
