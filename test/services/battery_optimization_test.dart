// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// digitales_register is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with digitales_register.  If not, see <http://www.gnu.org/licenses/>.

import 'package:dr/services/battery_optimization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<MethodCall> calls;
  Object? Function(MethodCall call) answer = (_) => null;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    calls = [];
    answer = (_) => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(batteryChannel, (call) async {
      calls.add(call);
      return answer(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(batteryChannel, null);
  });

  group('isIgnoringBatteryOptimizations', () {
    test('asks the channel on Android', () async {
      answer = (_) => true;
      expect(await isIgnoringBatteryOptimizations(isAndroid: true), isTrue);
      expect(calls.single.method, 'isIgnoring');
    });

    test('is false when Android still optimizes the app', () async {
      answer = (_) => false;
      expect(await isIgnoringBatteryOptimizations(isAndroid: true), isFalse);
    });

    test('is null off Android, without calling the channel', () async {
      expect(await isIgnoringBatteryOptimizations(isAndroid: false), isNull);
      expect(calls, isEmpty);
    });

    test('is null when the channel throws', () async {
      answer = (_) => throw PlatformException(code: 'x');
      expect(await isIgnoringBatteryOptimizations(isAndroid: true), isNull);
    });
  });

  group('openBatteryOptimizationSettings', () {
    test('opens the settings through the channel', () async {
      await openBatteryOptimizationSettings(isAndroid: true);
      expect(calls.single.method, 'openSettings');
    });

    test('does nothing off Android', () async {
      await openBatteryOptimizationSettings(isAndroid: false);
      expect(calls, isEmpty);
    });

    test('survives a failing channel', () async {
      answer = (_) => throw PlatformException(code: 'x');
      await openBatteryOptimizationSettings(isAndroid: true);
    });
  });
}
