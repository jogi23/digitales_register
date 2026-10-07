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
import 'package:dr/services/app_lock_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<MethodCall> calls;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appLockChannel, (call) async {
      calls.add(call);
      return null;
    });
  });

  test('the recents preview follows the lock setting', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    keepRecentsInSync(c, isAndroid: true);
    await pumpEventQueue();
    expect(calls.map((c) => (c.method, c.arguments)), [
      ('setRecentsHidden', false),
    ]);

    c.read(settingsProvider.notifier).setAppLockEnabled(true);
    await pumpEventQueue();
    c.read(settingsProvider.notifier).setAppLockEnabled(false);
    await pumpEventQueue();
    expect(calls.map((c) => (c.method, c.arguments)).skip(1), [
      ('setRecentsHidden', true),
      ('setRecentsHidden', false),
    ]);
  });

  test('remembers whether Android hides the preview itself', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appLockChannel, (call) async => true);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    keepRecentsInSync(c, isAndroid: true);
    await pumpEventQueue();
    expect(c.read(recentsHiddenByAndroidProvider), isTrue);
  });

  test('nothing is sent off Android', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    keepRecentsInSync(c, isAndroid: false);
    c.read(settingsProvider.notifier).setAppLockEnabled(true);
    await moveTaskToBack(isAndroid: false);
    await pumpEventQueue();
    expect(calls, isEmpty);
  });

  test('moveTaskToBack goes to the activity', () async {
    await moveTaskToBack(isAndroid: true);
    expect(calls.single.method, 'moveTaskToBack');
  });
}
