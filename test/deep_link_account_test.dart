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

import 'dart:convert';

import 'package:dr/main.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_utils.dart';

class MockWrapper extends Mock implements Wrapper {}

const _ownServer = "https://example.digitales.register.example";
const _otherServer = "https://andere-schule.digitalesregister.it";

/// The stored account, with [url] written the way the app happens to have
/// saved it.
Map<String, String> _storageWith(String url, {List<Object?>? otherAccounts}) => {
      "login": json.encode({
        "user": "username23",
        "pass": "Passwort123",
        "url": url,
        if (otherAccounts != null) "otherAccounts": otherAccounts,
      }),
    };

/// The login blob as it stands in storage now.
Future<Map<String, dynamic>> _storedLogin() async =>
    json.decode(await secureStorage.read(key: "login") ?? "{}")
        as Map<String, dynamic>;

void _stubLoginAttempt(MockWrapper mock, String url) {
  when(
    () => mock.login(
      any(),
      any(),
      null,
      url,
      addProtocolItem: any(named: "addProtocolItem"),
      configLoaded: any(named: "configLoaded"),
      logout: any(named: "logout"),
      relogin: any(named: "relogin"),
    ),
  ).thenAnswer((_) async => null);
  when(() => mock.loggedIn).thenAnswer((_) => Future.value(false));
  when(() => mock.noInternet).thenReturn(true);
  when(() => mock.loginAddress).thenReturn("$url/v2/api/login");
}

void main() {
  late MockWrapper mockWrapper;

  setUp(() {
    skipUnmaintainedAlert = true;
    mockWrapper = MockWrapper();
    wrapper = mockWrapper;
    navigatorKey = GlobalKey();
    scaffoldMessengerKey = GlobalKey();
    pc.providerContainer = ProviderContainer();
    wireLoginDispatchers(pc.providerContainer.read(loginProvider.notifier));
  });

  tearDown(() {
    skipUnmaintainedAlert = false;
    deletedData = false;
    pc.providerContainer.dispose();
  });

  group('a link must not cost the stored account', () {
    test('one naming another school leaves the credentials alone', () async {
      // What #186 did: the link set the address, the comparison against the
      // stored one failed, and the password was thrown away — one account per
      // link, until only the demo account was left.
      secureStorage = FakeSecureStorage(storage: _storageWith(_ownServer));
      _stubLoginAttempt(mockWrapper, _ownServer);

      await startApp(Uri.parse("$_otherServer/"));

      final login = await _storedLogin();
      expect(login["user"], "username23");
      expect(login["pass"], "Passwort123");
    });

    test('one naming the own school is not treated as a different server',
        () async {
      // The stored address keeps a trailing slash when it came from a pasted
      // browser address — fixupUrl strips only "v2/login". Uri.origin never
      // has one, so a plain string comparison called these two servers
      // different and wiped a login over a legitimate link.
      secureStorage = FakeSecureStorage(storage: _storageWith("$_ownServer/"));
      _stubLoginAttempt(mockWrapper, "$_ownServer/");

      await startApp(Uri.parse("$_ownServer/"));

      final login = await _storedLogin();
      expect(login["user"], "username23");
      expect(login["pass"], "Passwort123");
      // Not merely kept: the app got as far as logging in with them.
      verify(() => mockWrapper.login(
            "username23",
            "Passwort123",
            null,
            "$_ownServer/",
            addProtocolItem: any(named: "addProtocolItem"),
            configLoaded: any(named: "configLoaded"),
            logout: any(named: "logout"),
            relogin: any(named: "relogin"),
          )).called(1);
    });

    test('a start without any link still logs in', () async {
      // The guard against fixing the above by never comparing at all.
      secureStorage = FakeSecureStorage(storage: _storageWith(_ownServer));
      _stubLoginAttempt(mockWrapper, _ownServer);

      await startApp(null);

      verify(() => mockWrapper.login(
            "username23",
            "Passwort123",
            null,
            _ownServer,
            addProtocolItem: any(named: "addProtocolItem"),
            configLoaded: any(named: "configLoaded"),
            logout: any(named: "logout"),
            relogin: any(named: "relogin"),
          )).called(1);
    });
  });

  group('saving a second account', () {
    test('moves the first one into the list instead of overwriting it',
        () async {
      // Without this the link fix would only postpone the loss: logging in at
      // the other school replaced the stored account outright.
      secureStorage = FakeSecureStorage(storage: _storageWith(_ownServer));
      when(() => mockWrapper.user).thenReturn("zweitkonto");
      when(() => mockWrapper.pass).thenReturn("Passwort456");
      when(() => mockWrapper.url).thenReturn(_otherServer);
      when(() => mockWrapper.safeMode).thenReturn(false);
      final notifier = pc.providerContainer.read(loginProvider.notifier);
      notifier.setLoggedIn(username: "zweitkonto");

      notifier.saveNoPass(false);
      await pumpEventQueue();

      final login = await _storedLogin();
      expect(login["user"], "zweitkonto");
      expect(login["url"], _otherServer);
      expect(
        login["otherAccounts"],
        [
          {
            "user": "username23",
            "pass": "Passwort123",
            "url": _ownServer,
          }
        ],
      );
    });

    test('re-saving the same account does not duplicate it', () async {
      secureStorage = FakeSecureStorage(
        storage: _storageWith(_ownServer, otherAccounts: const []),
      );
      when(() => mockWrapper.user).thenReturn("username23");
      when(() => mockWrapper.pass).thenReturn("Passwort123");
      when(() => mockWrapper.url).thenReturn(_ownServer);
      when(() => mockWrapper.safeMode).thenReturn(false);
      final notifier = pc.providerContainer.read(loginProvider.notifier);
      notifier.setLoggedIn(username: "username23");

      notifier.saveNoPass(false);
      await pumpEventQueue();

      final login = await _storedLogin();
      expect(login["user"], "username23");
      expect(login["otherAccounts"], isEmpty);
    });
  });
}
