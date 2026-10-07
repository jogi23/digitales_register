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

import 'package:dr/providers/app_lock_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/device_auth.dart';
import 'package:dr/ui/app_lock_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fake_device_auth.dart';

void main() {
  late FakeDeviceAuth auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeDeviceAuth();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool supported = true,
    bool enabled = false,
  }) async {
    final c = ProviderContainer(overrides: [
      appLockSupportedProvider.overrideWithValue(supported),
      deviceAuthProvider.overrideWithValue(auth),
    ]);
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier).setAppLockEnabled(enabled);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: ListView(children: const [AppLockSettingsTiles()]),
        ),
      ),
    ));
    return c;
  }

  bool enabled(ProviderContainer c) => c.read(settingsProvider).appLockEnabled;

  testWidgets('hidden where the platform has no lock', (tester) async {
    await pump(tester, supported: false);
    expect(find.text('App sperren'), findsNothing);
  });

  testWidgets('no lock on the device: a dialog, and it stays off',
      (tester) async {
    auth.available = false;
    final c = await pump(tester);
    await tester.tap(find.text('App sperren'));
    await tester.pumpAndSettle();
    expect(find.textContaining('keine Bildschirmsperre'), findsOneWidget);
    expect(enabled(c), isFalse);
    expect(auth.calls, 0);
  });

  testWidgets('switching on needs the lock to be passed', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    final c = await pump(tester);
    await tester.tap(find.text('App sperren'));
    await tester.pumpAndSettle();
    expect(enabled(c), isFalse);

    auth.result = DeviceAuthResult.success;
    await tester.tap(find.text('App sperren'));
    await tester.pumpAndSettle();
    expect(enabled(c), isTrue);
  });

  testWidgets('switching off needs the lock to be passed', (tester) async {
    auth.result = DeviceAuthResult.cancelled;
    final c = await pump(tester, enabled: true);
    await tester.tap(find.text('App sperren'));
    await tester.pumpAndSettle();
    expect(enabled(c), isTrue);

    auth.result = DeviceAuthResult.success;
    await tester.tap(find.text('App sperren'));
    await tester.pumpAndSettle();
    expect(enabled(c), isFalse);
  });

  testWidgets('the grace picker shows only while on, and sets the value',
      (tester) async {
    await pump(tester);
    expect(find.text('Sperren nach'), findsNothing);

    final c = await pump(tester, enabled: true);
    expect(find.text('Sperren nach'), findsOneWidget);
    await tester.tap(find.text('1 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 min').last);
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).appLockGraceMinutes, 5);
  });
}
