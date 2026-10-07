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

import 'dart:async';

import 'package:dr/providers/app_lock_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/device_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_device_auth.dart';

void main() {
  late FakeDeviceAuth auth;
  late DateTime now;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    auth = FakeDeviceAuth();
    now = DateTime(2026, 10, 7, 12);
  });

  /// A container whose lock starts as [enabled] says, with [grace] minutes.
  ProviderContainer make({
    bool enabled = true,
    int grace = 1,
    bool supported = true,
  }) {
    final c = ProviderContainer(overrides: [
      appLockInitiallyEnabledProvider.overrideWithValue(enabled),
      appLockSupportedProvider.overrideWithValue(supported),
      appLockClockProvider.overrideWithValue(() => now),
      deviceAuthProvider.overrideWithValue(auth),
    ]);
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier)
      ..setAppLockEnabled(enabled)
      ..setAppLockGraceMinutes(grace);
    return c;
  }

  AppLockController lock(ProviderContainer c) =>
      c.read(appLockProvider.notifier);
  bool locked(ProviderContainer c) => c.read(appLockProvider).locked;

  /// Leaves the app unlocked, as after a successful prompt.
  Future<void> unlocked(ProviderContainer c) async {
    await lock(c).unlock('');
    expect(locked(c), isFalse);
    auth.calls = 0;
  }

  group('at start', () {
    test('locked when enabled', () {
      expect(locked(make()), isTrue);
    });

    test('not locked when disabled', () {
      expect(locked(make(enabled: false)), isFalse);
    });

    test('not locked where the platform has no lock', () {
      expect(locked(make(supported: false)), isFalse);
    });

    test('locked before the stored settings are loaded', () {
      final c = ProviderContainer(overrides: [
        appLockInitiallyEnabledProvider.overrideWithValue(true),
        appLockSupportedProvider.overrideWithValue(true),
        deviceAuthProvider.overrideWithValue(auth),
      ]);
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).appLockEnabled, isFalse);
      expect(locked(c), isTrue);
    });
  });

  group('back from the background', () {
    for (final grace in [1, 5, 15]) {
      test('locks after $grace min, not before', () async {
        final c = make(grace: grace);
        await unlocked(c);

        lock(c).onPaused();
        now = now.add(Duration(minutes: grace) - const Duration(seconds: 1));
        lock(c).onResumed();
        expect(locked(c), isFalse);
        expect(auth.calls, 0);

        lock(c).onPaused();
        now = now.add(Duration(minutes: grace));
        lock(c).onResumed();
        await pumpEventQueue();
        expect(auth.calls, 1);
        expect(locked(c), isFalse, reason: 'the fake unlocks again');
      });
    }

    test('grace zero locks as soon as the app leaves', () async {
      final c = make(grace: 0);
      await unlocked(c);
      lock(c).onPaused();
      expect(locked(c), isTrue);
    });

    test('nothing happens while the lock is off', () {
      final c = make(enabled: false);
      lock(c).onPaused();
      now = now.add(const Duration(hours: 1));
      lock(c).onResumed();
      expect(locked(c), isFalse);
      expect(auth.calls, 0);
    });

    test('a resume without a pause before it asks nothing', () async {
      final c = make();
      await unlocked(c);
      lock(c).onResumed();
      expect(auth.calls, 0);
    });
  });

  test('the prompt of its own does not lock or ask again', () async {
    final c = make();
    auth.pending = Completer();
    unawaited(lock(c).unlock(''));
    expect(c.read(appLockProvider).authenticating, isTrue);

    // The device's PIN screen sends the app to the background and back.
    lock(c).onPaused();
    now = now.add(const Duration(minutes: 20));
    lock(c).onResumed();
    expect(auth.calls, 1);

    auth.pending!.complete(DeviceAuthResult.cancelled);
    await pumpEventQueue();
    // The resume the prompt causes arrives once it has closed.
    lock(c).onResumed();
    expect(auth.calls, 1);
    expect(locked(c), isTrue);
  });

  group('unlock', () {
    test('success unlocks', () async {
      final c = make();
      await lock(c).unlock('');
      expect(locked(c), isFalse);
      expect(c.read(appLockProvider).message, isNull);
    });

    test('cancelled stays locked and does not ask again', () async {
      final c = make();
      auth.result = DeviceAuthResult.cancelled;
      await lock(c).unlock('');
      await pumpEventQueue();
      expect(locked(c), isTrue);
      expect(auth.calls, 1);
      expect(c.read(appLockProvider).message, isNull);
    });

    test('locked out stays locked and says so', () async {
      final c = make();
      auth.result = DeviceAuthResult.lockedOut;
      await lock(c).unlock('');
      expect(locked(c), isTrue);
      expect(c.read(appLockProvider).message, AppLockMessage.lockedOut);
    });

    test('an error stays locked and says so', () async {
      final c = make();
      auth.result = DeviceAuthResult.error;
      await lock(c).unlock('');
      expect(locked(c), isTrue);
      expect(c.read(appLockProvider).message, AppLockMessage.error);
    });

    test('no lock on the device unlocks and switches the lock off', () async {
      final c = make();
      auth.result = DeviceAuthResult.notAvailable;
      await lock(c).unlock('');
      expect(locked(c), isFalse);
      expect(c.read(settingsProvider).appLockEnabled, isFalse);
      expect(c.read(appLockProvider).message, AppLockMessage.disabled);

      // Off for good: the next return does not lock.
      lock(c).onPaused();
      now = now.add(const Duration(hours: 1));
      lock(c).onResumed();
      expect(locked(c), isFalse);
    });
  });

  group('cover while leaving', () {
    test('covers on inactive when Android keeps the preview', () async {
      final c = make();
      await unlocked(c);
      lock(c).onInactive();
      expect(c.read(appLockProvider).covered, isTrue);
      lock(c).onResumed();
      expect(c.read(appLockProvider).covered, isFalse);
    });

    test('no cover when Android hides the preview itself', () async {
      final c = make();
      await unlocked(c);
      c.read(recentsHiddenByAndroidProvider.notifier).state = true;
      lock(c).onInactive();
      expect(c.read(appLockProvider).covered, isFalse);
    });

    test('no cover while the lock is off', () {
      final c = make(enabled: false);
      lock(c).onInactive();
      expect(c.read(appLockProvider).covered, isFalse);
    });

    test('no cover from the prompt of its own', () {
      final c = make();
      auth.pending = Completer();
      unawaited(lock(c).unlock(''));
      lock(c).onInactive();
      expect(c.read(appLockProvider).covered, isFalse);
    });
  });

  group('at a cold start', () {
    test('asks once', () async {
      final c = make();
      auth.result = DeviceAuthResult.cancelled;
      await lock(c).unlockAtStart();
      await lock(c).unlockAtStart();
      expect(auth.calls, 1);
    });

    test('asks nothing when not locked', () async {
      final c = make(enabled: false);
      await lock(c).unlockAtStart();
      expect(auth.calls, 0);
    });
  });

  test('switching the lock off unlocks', () {
    final c = make();
    expect(locked(c), isTrue);
    c.read(settingsProvider.notifier).setAppLockEnabled(false);
    expect(locked(c), isFalse);
  });
}
