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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: AppTypography.screenTitle),
                const SizedBox(height: Spacing.xs),
                Text(
                  "Workspace defaults and agent roles",
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadError != null
                ? LoadFailedView(
                    title: "Couldn't load settings",
                    message: errorMessage(_loadError!),
                    onRetry: _load,
                  )
                : settings == null
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.xl,
                      0,
                      Spacing.xl,
                      Spacing.xl,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TaskDefaultsCard(
                              settings: settings,
                              onChanged: _save,
                            ),
                            const SizedBox(height: Spacing.xl),
                            const _AgentRolesCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskDefaultsCard extends StatelessWidget {
  const _TaskDefaultsCard({required this.settings, required this.onChanged});

  final WorkspaceSettings settings;
  final ValueChanged<WorkspaceSettings> onChanged;

  @override
  Widget build(BuildContext context) {
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
          SettingRow(
            title: skipPlanningOption.title,
            description: skipPlanningOption.description,
            control: Switch(
              value: settings.skipPlanning,
              activeThumbColor: AppColors.accent,
              onChanged: (value) =>
                  onChanged(settings.copyWith(skipPlanning: value)),
            ),
          ),
          SettingRow(
            title: autoReviewOption.title,
            description: autoReviewOption.description,
            control: Switch(
              value: settings.autoReview,
              activeThumbColor: AppColors.accent,
              onChanged: (value) =>
                  onChanged(settings.copyWith(autoReview: value)),
            ),
          ),
          SettingRow(
            title: reviewerOption.title,
            description: reviewerOption.description,
            control: ReviewerSelect(
              selected: settings.reviewerAgentId,
              onChanged: (id) =>
                  onChanged(settings.copyWith(reviewerAgentId: id)),
            ),
          ),
          SettingRow(
            title: autoFixOption.title,
            description: autoFixOption.description,
            control: Switch(
              value: settings.autoFixReview,
              activeThumbColor: AppColors.accent,
              onChanged: (value) =>
                  onChanged(settings.copyWith(autoFixReview: value)),
            ),
          ),
          SettingRow(
            title: autoMergeOption.title,
            description: settings.autoMerge && !settings.autoReview
                ? autoMergeWithoutReviewHint
                : autoMergeOption.description,
            control: Switch(
              value: settings.autoMerge,
              activeThumbColor: AppColors.accent,
              onChanged: (value) =>
                  onChanged(settings.copyWith(autoMerge: value)),
            ),
          ),
          SettingRow(
            title: autoFixChecksOption.title,
            description: autoFixChecksOption.description,
            control: Switch(
              value: settings.autoFixFailingChecks,
              activeThumbColor: AppColors.accent,
              onChanged: (value) =>
                  onChanged(settings.copyWith(autoFixFailingChecks: value)),
            ),
          ),
          SettingRow(
            title: maxCheckFixAttemptsOption.title,
            description: maxCheckFixAttemptsOption.description,
            control: PillSelector<int>(
              options: fixRoundChoices,
              labelBuilder: (n) => '$n',
              selected: settings.maxCheckFixAttempts,
              onChanged: (n) =>
                  onChanged(settings.copyWith(maxCheckFixAttempts: n)),
            ),
          ),
          SettingRow(
            title: maxFixRoundsOption.title,
            description: maxFixRoundsOption.description,
            control: PillSelector<int>(
              options: fixRoundChoices,
              labelBuilder: (n) => '$n',
              selected: settings.maxReviewFixRounds,
              onChanged: (n) =>
                  onChanged(settings.copyWith(maxReviewFixRounds: n)),
            ),
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
