import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A small initials circle for an agent's name — the task detail screen's
/// header/info rail and the machine detail screen's agent rows.
class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map((s) => s[0]).join();
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.accent.withValues(alpha: 0.25),
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accentSoft,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
