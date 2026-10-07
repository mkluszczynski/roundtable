import 'package:flutter/foundation.dart';

/// The task whose detail screen was opened last and is still open — the nav
/// rail's active tasks highlight it. Set by `TaskDetailScreen`.
final openTaskId = ValueNotifier<int?>(null);
