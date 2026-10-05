import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../client.dart';
import '../repositories/settings_repository.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../utils/error_message.dart';
import '../utils/task_options.dart';
import '../widgets/app_card.dart';
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
                Text('Workspace defaults', style: AppTypography.caption),
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
                        child: _TaskDefaultsCard(
                          settings: settings,
                          onChanged: _save,
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
