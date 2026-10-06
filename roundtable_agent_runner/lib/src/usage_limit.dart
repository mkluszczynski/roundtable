/// Recognises Claude's usage-limit message ("You've hit your session limit ·
/// resets 12:40am (Europe/Warsaw)") so the runner can pause the task and
/// resume it after the reset instead of failing it.
library;

final _limitPattern = RegExp(
  r"(hit|reached) your [\w ]*limit|usage limit reached",
  caseSensitive: false,
);

/// "resets 12:40am", "resets 3pm", "resets Oct 6, 3pm", "resets 15:00".
final _resetPattern = RegExp(
  r'resets?\s+(?:at\s+)?(?:([A-Za-z]{3})[a-z]*\.?\s+(\d{1,2}),?\s+(?:at\s+)?)?'
  r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?',
  caseSensitive: false,
);

const _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

/// When a reset time can't be read, check again after this long — a still
/// active limit just pauses the task again.
const usageLimitFallbackWait = Duration(minutes: 30);

bool isUsageLimitMessage(String? text) =>
    text != null && _limitPattern.hasMatch(text);

/// When the limit in [message] resets, in UTC, plus a minute of slack. The
/// time is read in the machine's local time zone (Claude prints it in the
/// same zone). Falls back to [usageLimitFallbackWait] from [now].
DateTime usageLimitResetAt(String message, {DateTime? now}) {
  final current = (now ?? DateTime.now()).toLocal();
  final fallback = current.add(usageLimitFallbackWait).toUtc();
  final match = _resetPattern.firstMatch(message);
  if (match == null) return fallback;

  var hour = int.parse(match.group(3)!);
  final minute = int.tryParse(match.group(4) ?? '') ?? 0;
  final meridiem = match.group(5)?.toLowerCase();
  if (meridiem == 'pm' && hour < 12) hour += 12;
  if (meridiem == 'am' && hour == 12) hour = 0;
  if (hour > 23 || minute > 59) return fallback;

  DateTime reset;
  final monthName = match.group(1)?.toLowerCase();
  if (monthName != null && _months.contains(monthName)) {
    final month = _months.indexOf(monthName) + 1;
    final day = int.parse(match.group(2)!);
    reset = DateTime(current.year, month, day, hour, minute);
    if (reset.isBefore(current)) {
      reset = DateTime(current.year + 1, month, day, hour, minute);
    }
  } else {
    reset = DateTime(current.year, current.month, current.day, hour, minute);
    if (!reset.isAfter(current)) reset = reset.add(const Duration(days: 1));
  }
  return reset.add(const Duration(minutes: 1)).toUtc();
}

/// The machine's Claude usage limit (docs/FLOWS.md §4): every task run and
/// review on this machine shares one Claude account, so once one run hits
/// the limit, work that hasn't started yet waits here until the reset
/// instead of starting `claude` only to hit it again.
class UsageLimitGate {
  UsageLimitGate({this.onHit, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Called when the limit is hit (or pushed later), e.g. to report it to
  /// the server for the panel.
  final void Function(DateTime until)? onHit;
  final DateTime Function() _now;
  DateTime? _until;

  /// When the limit resets, or null while there's none.
  DateTime? get limitedUntil {
    final until = _until;
    return until != null && until.isAfter(_now()) ? until : null;
  }

  /// Records a run hitting the limit, which resets at [until].
  void hit(DateTime until) {
    final current = _until;
    if (current != null && !until.isAfter(current)) return;
    _until = until;
    onHit?.call(until);
  }

  /// Waits until the limit resets — again if it's pushed later meanwhile.
  /// [onWaiting] is told when, once per wait. Returns whether it waited.
  Future<bool> wait({void Function(DateTime until)? onWaiting}) async {
    var waited = false;
    for (var until = limitedUntil; until != null; until = limitedUntil) {
      onWaiting?.call(until);
      waited = true;
      await Future<void>.delayed(until.difference(_now()));
    }
    return waited;
  }
}

/// [time] (UTC) as the machine's local "HH:MM", for timeline messages.
String localClock(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
