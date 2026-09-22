import 'package:flutter/material.dart';
import 'package:roundtable_client/roundtable_client.dart';

/// Design tokens from `docs/UI-DESIGN.md` §1 (Palette). Dark theme only.
abstract final class AppColors {
  static const bg0 = Color(0xFF000000);
  static const bg1 = Color(0xFF131316);
  static const bg2 = Color(0xFF1C1C21);
  static const bg3 = Color(0xFF26262C);

  static final border = Colors.white.withValues(alpha: 0.10);
  static final borderStrong = Colors.white.withValues(alpha: 0.22);

  static const text0 = Colors.white;
  static const text1 = Color(0xFFA0A0A8);
  static const text2 = Color(0xFF6B6B72);

  static const accent = Color(0xFF7D39EB);
  static const accentInk = Colors.white;
  static const accentSoft = Color(0xFFA78BFA);

  static const live = Color(0xFFC6FF33);
  static const liveInk = Color(0xFF0A1400);

  static const red = Color(0xFFFF3D57);

  /// Near-black background for code blocks/diffs, distinct from [bg0].
  static const codeBg = Color(0xFF0B0B0D);

  static const diffAddedText = Color(0xFFE4FFA3);
  static const diffRemovedText = Color(0xFFFFC2CC);
}

/// A status's rendered color and whether its dot should pulse, per the
/// semantic status table in `docs/UI-DESIGN.md` §1.
class StatusAppearance {
  const StatusAppearance(this.color, {this.pulsing = false});

  final Color color;
  final bool pulsing;
}

StatusAppearance machineStatusAppearance(MachineStatus status) {
  return switch (status) {
    MachineStatus.online => const StatusAppearance(AppColors.live),
    MachineStatus.offline => const StatusAppearance(AppColors.text2),
  };
}

StatusAppearance agentStatusAppearance(AgentStatus status) {
  return switch (status) {
    AgentStatus.idle => const StatusAppearance(AppColors.text2),
    AgentStatus.busy => const StatusAppearance(AppColors.live, pulsing: true),
    AgentStatus.waitingForResponse => const StatusAppearance(
      AppColors.accent,
      pulsing: true,
    ),
  };
}

StatusAppearance taskStatusAppearance(TaskStatus status) {
  return switch (status) {
    TaskStatus.queued || TaskStatus.cloning => const StatusAppearance(
      AppColors.text2,
    ),
    TaskStatus.planning || TaskStatus.running => const StatusAppearance(
      AppColors.live,
      pulsing: true,
    ),
    TaskStatus.waitingForAnswer ||
    TaskStatus.planReady ||
    TaskStatus.awaitingReview => const StatusAppearance(AppColors.accent),
    TaskStatus.done => const StatusAppearance(AppColors.live),
    TaskStatus.failed => const StatusAppearance(AppColors.red),
    TaskStatus.cancelled => const StatusAppearance(AppColors.text2),
  };
}
