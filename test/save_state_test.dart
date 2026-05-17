// Copyright (C) 2021 Michael Debertol
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
import 'dart:collection';
import 'dart:convert';

import 'package:dr/app_state.dart';
import 'package:dr/main.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/login_provider.dart' hide LoginState;
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/providers/settings_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/testing/src/async/fake_async.dart';

import 'test_utils.dart';

const serverUrl = "null/v2/api/auth/login";

bool _isFullState(String? raw) {
  if (raw == null) return false;
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return decoded['v'] == 2 && decoded.containsKey('state');
}

class StorageHelper {
  Future<bool> exists(String user) async {
    final value = await read(user);
    return value != null;
  }

  Future<String?> read(String user) async {
    return secureStorage.read(key: escapeKey(getStorageKey(user, serverUrl)));
  }

  Future<void> cleanup() async {
    await secureStorage.deleteAll();
  }
}

class _TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;

  _TestSettingsNotifier(this.initial);

  @override
  SettingsState build() => initial;
}

ProviderContainer _makeContainer({SettingsState? settings}) {
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(
        () => _TestSettingsNotifier(settings ?? SettingsState()),
      ),
    ],
  );
  pc.providerContainer = container;
  return container;
}

void main() {
  secureStorage = FakeSecureStorage();
  final storageHelper = StorageHelper();

  setUp(() => skipUnmaintainedAlert = true);
  tearDown(() {
    skipUnmaintainedAlert = false;
    deletedData = false;
    storageHelper.cleanup();
  });

  test('save state occurs after five seconds', () {
    FakeAsync().run((async) async {
      const username = "test_username";
      final container = _makeContainer();
      addTearDown(container.dispose);
      container.read(loginProvider.notifier).setLoggedIn(username: username);
      // trigger a deferred state save
      unawaited(triggerDeferredSaveState());
      // saving the state is throttled by five seconds
      async.elapse(const Duration(seconds: 1));

      expect(
        await storageHelper.exists(username),
        false,
      );
      // after over 5 seconds, the state should be saved
      async.elapse(const Duration(seconds: 6));
      expect(
        await storageHelper.exists(username),
        true,
      );
    });
  });
  test('save state occurs immediately', () async {
    const username = "test_username2";
    final container = _makeContainer();
    addTearDown(container.dispose);
    container.read(loginProvider.notifier).setLoggedIn(username: username);

    await saveStateImmediately();

    // the state should be saved immediately
    expect(
      await storageHelper.exists(username),
      true,
    );
    expect(_isFullState(await storageHelper.read(username)), true);
  });
  test('state is not saved when data saving is disabled', () async {
    const username = "test_username2";
    final container = _makeContainer(
      settings: SettingsState(noDataSaving: true),
    );
    addTearDown(container.dispose);
    container.read(loginProvider.notifier).setLoggedIn(username: username);

    await saveStateImmediately();

    expect(
      await storageHelper.exists(username),
      true,
    );

    expect(_isFullState(await storageHelper.read(username)), false);
  });
  test('state is deleted on logout when state saving is disabled', () async {
    navigatorKey = GlobalKey();
    const username = "test_username3";
    final container = _makeContainer(
      settings: SettingsState(deleteDataOnLogout: true),
    );
    addTearDown(container.dispose);
    container.read(loginProvider.notifier).setLoggedIn(username: username);

    await saveStateImmediately();

    // the state should be saved immediately
    expect(
      await storageHelper.exists(username),
      true,
    );

    expect(_isFullState(await storageHelper.read(username)), true);
    deletedData = true;
    await saveStateImmediately();

    expect(_isFullState(await storageHelper.read(username)), false);
  });
  test('state is deleted/saved when the setting is switched', () async {
    const username = "test_username4";
    final container = _makeContainer();
    addTearDown(container.dispose);
    container.read(loginProvider.notifier).setLoggedIn(username: username);
    container.read(settingsProvider.notifier).onSaveState =
        () => unawaited(saveStateImmediately());

    await saveStateImmediately();

    // the state should be saved immediately
    expect(
      await storageHelper.exists(username),
      true,
    );

    expect(_isFullState(await storageHelper.read(username)), true);

    container.read(settingsProvider.notifier).setSaveNoData(true);
    await Future<void>.value();

    expect(_isFullState(await storageHelper.read(username)), false);

    container.read(settingsProvider.notifier).setSaveNoData(false);
    await Future<void>.value();

    expect(_isFullState(await storageHelper.read(username)), true);

    container.read(settingsProvider.notifier).setSaveNoData(true);
    await Future<void>.value();

    expect(_isFullState(await storageHelper.read(username)), false);

    container.read(settingsProvider.notifier).setSaveNoData(false);
    await Future<void>.value();

    expect(_isFullState(await storageHelper.read(username)), true);
  });

  test('Default map is ordered', () {
    expect({"username": "asdf", "url": "foo"}, isA<LinkedHashMap>());
    final keys = {"username": "asdf", "url": "foo"}.keys.toList();
    expect(keys[0], "username");
    expect(keys[1], "url");
  });
}
