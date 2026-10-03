import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roundtable_client/roundtable_client.dart';

import '../utils/error_message.dart';
import '../repositories/machine_repository.dart';

sealed class MachineListState {
  const MachineListState();
}

class MachineListInitial extends MachineListState {
  const MachineListInitial();
}

class MachineListLoading extends MachineListState {
  const MachineListLoading();
}

class MachineListLoaded extends MachineListState {
  const MachineListLoaded(this.machines, {this.latestRunnerVersion});

  final List<Machine> machines;

  /// Version of the agent-runner binaries the server serves, or null if it
  /// couldn't be determined — machines reporting another version are out
  /// of date.
  final String? latestRunnerVersion;
}

class MachineListError extends MachineListState {
  const MachineListError(this.message);

  final String message;
}

/// Emitted transiently when a delete attempt is blocked because the machine
/// is still `online` (docs/FLOWS.md §1–3) — the panel reacts by showing the
/// uninstall-command dialog instead of a plain error. Always followed by a
/// fresh [MachineListLoaded]/[MachineListError] from a re-fetch.
class MachineDeletionBlockedOnline extends MachineListState {
  const MachineDeletionBlockedOnline(this.scriptUrl);

  /// Base URL the uninstall script is served from, or null if fetching it
  /// failed — the dialog falls back to a repo-relative command in that case.
  final String? scriptUrl;
}

class MachineListCubit extends Cubit<MachineListState> {
  MachineListCubit(this._repository) : super(const MachineListInitial());

  final MachineRepository _repository;

  /// Refreshes the list while a runner update is in flight, so the card
  /// flips from "Updating…" back to up to date without a manual reload.
  Timer? _updatePollTimer;

  /// Fetches the machine list. [silent] skips the loading state, for
  /// background refreshes that shouldn't blank the screen.
  Future<void> fetchMachines({bool silent = false}) async {
    if (!silent) emit(const MachineListLoading());
    try {
      final machines = await _repository.listMachines();
      String? latestRunnerVersion;
      try {
        latestRunnerVersion = await _repository.getLatestRunnerVersion();
      } catch (_) {
        // Non-fatal: without it the panel just doesn't offer updates.
      }
      if (isClosed) return;
      emit(
        MachineListLoaded(machines, latestRunnerVersion: latestRunnerVersion),
      );
      if (!machines.any((m) => m.updateRequestedAt != null)) {
        _updatePollTimer?.cancel();
        _updatePollTimer = null;
      }
    } catch (e) {
      if (isClosed) return;
      emit(MachineListError(errorMessage(e)));
    }
  }

  /// Asks machine [id]'s daemon to update itself, then polls until every
  /// pending update has been picked up.
  Future<void> requestRunnerUpdate(int id) async {
    try {
      await _repository.requestRunnerUpdate(id);
    } catch (e) {
      emit(MachineListError(errorMessage(e)));
    }
    await fetchMachines(silent: true);
    _updatePollTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchMachines(silent: true),
    );
  }

  @override
  Future<void> close() {
    _updatePollTimer?.cancel();
    return super.close();
  }

  Future<void> deleteMachine(int id) async {
    try {
      await _repository.deleteMachine(id);
    } on DeletionBlockedException catch (e) {
      if (e.reason == DeletionBlockReason.machineOnline) {
        String? scriptUrl;
        try {
          scriptUrl = await _repository.getScriptUrl();
        } catch (_) {
          // Fall through with scriptUrl = null; the dialog falls back to a
          // repo-relative command rather than blocking on this fetch.
        }
        emit(MachineDeletionBlockedOnline(scriptUrl));
      } else {
        emit(MachineListError(e.message));
      }
    } catch (e) {
      emit(MachineListError(errorMessage(e)));
    }
    await fetchMachines();
  }
}
