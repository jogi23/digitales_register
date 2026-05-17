// Copyright (C) 2026 Johannes Feichter
import 'package:dr/utc_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UtcDateTime', () {
    test('constructor produces UTC date', () {
      final dt = UtcDateTime(2021, 3, 15, 10, 30);
      expect(dt.isUtc, true);
      expect(dt.year, 2021);
      expect(dt.month, 3);
      expect(dt.day, 15);
      expect(dt.hour, 10);
      expect(dt.minute, 30);
    });

    test('parse returns UtcDateTime', () {
      final dt = UtcDateTime.parse('2021-06-01T12:00:00');
      expect(dt, isA<UtcDateTime>());
      expect(dt.isUtc, true);
      expect(dt.year, 2021);
      expect(dt.month, 6);
      expect(dt.day, 1);
    });

    test('tryParse returns UtcDateTime for valid string', () {
      final dt = UtcDateTime.tryParse('2021-06-01');
      expect(dt, isNotNull);
      expect(dt, isA<UtcDateTime>());
      expect(dt!.isUtc, true);
    });

    test('tryParse returns null for invalid string', () {
      expect(UtcDateTime.tryParse('not-a-date'), isNull);
    });

    test('add returns UtcDateTime', () {
      final dt = UtcDateTime(2021, 1, 1);
      final result = dt.add(const Duration(days: 1));
      expect(result, isA<UtcDateTime>());
      expect(result.isUtc, true);
      expect(result.day, 2);
    });

    test('subtract returns UtcDateTime', () {
      final dt = UtcDateTime(2021, 1, 10);
      final result = dt.subtract(const Duration(days: 3));
      expect(result, isA<UtcDateTime>());
      expect(result.isUtc, true);
      expect(result.day, 7);
    });

    test('stripTime clears time components', () {
      final dt = UtcDateTime(2021, 5, 20, 14, 30, 45);
      final stripped = dt.stripTime();
      expect(stripped.isUtc, true);
      expect(stripped.year, 2021);
      expect(stripped.month, 5);
      expect(stripped.day, 20);
      expect(stripped.hour, 0);
      expect(stripped.minute, 0);
      expect(stripped.second, 0);
    });

    test('makeUtc converts DateTime to UtcDateTime', () {
      final local = DateTime(2021, 4, 1, 9, 0);
      final utc = UtcDateTime.makeUtc(local);
      expect(utc, isA<UtcDateTime>());
      expect(utc.isUtc, true);
      expect(utc.year, local.year);
      expect(utc.month, local.month);
      expect(utc.day, local.day);
    });

    test('now returns UtcDateTime with current local time components', () {
      final before = DateTime.now();
      final now = UtcDateTime.now();
      expect(now, isA<UtcDateTime>());
      expect(now.isUtc, true);
      // UtcDateTime.now() preserves local clock components (hour/minute/day)
      // reinterpreted as UTC — so check components match local time.
      expect(now.year, before.year);
      expect(now.month, before.month);
      expect(now.day, before.day);
    });

    test('MakeUtc extension works on DateTime', () {
      final dt = DateTime(2021, 7, 4);
      final utc = dt.makeUtc();
      expect(utc, isA<UtcDateTime>());
      expect(utc.isUtc, true);
      expect(utc.year, 2021);
      expect(utc.month, 7);
      expect(utc.day, 4);
    });
  });
}
