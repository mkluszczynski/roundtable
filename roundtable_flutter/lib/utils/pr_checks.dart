import 'package:roundtable_client/roundtable_client.dart';

/// Whether [run] finished without passing (mirrors the server's
/// `isFailedCheck`).
bool isFailedCheckRun(PrCheckRun run) =>
    run.status == 'completed' &&
    run.conclusion != null &&
    !const {'success', 'skipped', 'neutral'}.contains(run.conclusion);

/// The label of a PR's aggregated CI state.
String checkStateLabel(PrCheckState state) => switch (state) {
  PrCheckState.none => 'No CI',
  PrCheckState.pending => 'CI running',
  PrCheckState.success => 'CI passed',
  PrCheckState.failure => 'CI failed',
};
