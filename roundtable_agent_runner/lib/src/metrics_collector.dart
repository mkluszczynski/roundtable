import 'dart:io';

/// One CPU/RAM reading (design doc §6.9).
class MachineMetricReading {
  const MachineMetricReading({
    required this.cpuPercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
  });

  final double cpuPercent;
  final int memoryUsedMb;
  final int memoryTotalMb;
}

/// Reads `/proc/stat` and `/proc/meminfo` (Linux only, consistent with the
/// rest of the daemon's design — design doc §6.9).
class MetricsCollector {
  Future<MachineMetricReading> collect() async {
    final cpuPercent = await _readCpuPercent();
    final (usedMb, totalMb) = await _readMemoryMb();
    return MachineMetricReading(
      cpuPercent: cpuPercent,
      memoryUsedMb: usedMb,
      memoryTotalMb: totalMb,
    );
  }

  /// Two `/proc/stat` samples 200ms apart, self-contained (no cross-tick
  /// state to manage across daemon restarts) — negligible next to the
  /// 5-10s reporting interval.
  Future<double> _readCpuPercent() async {
    final first = _parseCpuJiffies(await File('/proc/stat').readAsLines());
    await Future.delayed(const Duration(milliseconds: 200));
    final second = _parseCpuJiffies(await File('/proc/stat').readAsLines());

    final totalDelta = second.total - first.total;
    final idleDelta = second.idle - first.idle;
    if (totalDelta <= 0) return 0;
    return 100 * (1 - idleDelta / totalDelta);
  }

  ({int total, int idle}) _parseCpuJiffies(List<String> lines) {
    final fields = lines.first
        .split(RegExp(r'\s+'))
        .skip(1)
        .map(int.parse)
        .toList();
    final idle = fields[3] + fields[4]; // idle + iowait
    final total = fields.reduce((a, b) => a + b);
    return (total: total, idle: idle);
  }

  Future<(int, int)> _readMemoryMb() async {
    final lines = await File('/proc/meminfo').readAsLines();
    final values = <String, int>{};
    for (final line in lines) {
      final match = RegExp(r'^(\w+):\s+(\d+) kB').firstMatch(line);
      if (match == null) continue;
      values[match.group(1)!] = int.parse(match.group(2)!);
    }
    final totalKb = values['MemTotal'] ?? 0;
    final availableKb = values['MemAvailable'] ?? totalKb;
    return (((totalKb - availableKb) / 1024).round(), (totalKb / 1024).round());
  }
}
