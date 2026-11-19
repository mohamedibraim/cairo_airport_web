import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fixtures.dart';

/// A demo-only wall clock that starts at the frozen design reference and ticks.
/// It never claims a live Cairo feed.
final demoClockProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (i) => Fixtures.reference.add(Duration(seconds: i)),
  );
});

String cairoClock(DateTime utc, {bool seconds = true}) {
  final local = utc.add(const Duration(hours: 2));
  String two(int n) => n.toString().padLeft(2, '0');
  return seconds
      ? '${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      : '${two(local.hour)}:${two(local.minute)}';
}

String cairoDate(DateTime utc) {
  final local = utc.add(const Duration(hours: 2));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}
