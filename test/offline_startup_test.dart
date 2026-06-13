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

import 'package:dr/main.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'test_utils.dart';

class MockWrapper extends Mock implements Wrapper {}

const _loginUrl = "https://example.digitales.register.example";
const _loginAddress = "$_loginUrl/v2/api/login";

void _stubFailedLogin(
  MockWrapper mock, {
  required bool noInternet,
  String? error,
}) {
  when(
    () => mock.login(
      "username23",
      "Passwort123",
      null,
      _loginUrl,
      addProtocolItem: any(named: "addProtocolItem"),
      configLoaded: any(named: "configLoaded"),
      logout: any(named: "logout"),
      relogin: any(named: "relogin"),
    ),
  ).thenAnswer((_) async => null);
  when(() => mock.loggedIn).thenAnswer((_) => Future.value(false));
  when(() => mock.noInternet).thenReturn(noInternet);
  when(() => mock.loginAddress).thenReturn(_loginAddress);
  if (error != null) {
    when(() => mock.error).thenReturn(error);
  }
}

void main() {
  late MockWrapper mockWrapper;

  setUp(() {
    skipUnmaintainedAlert = true;
    mockWrapper = MockWrapper();
    wrapper = mockWrapper;
    navigatorKey = GlobalKey();
    scaffoldMessengerKey = GlobalKey();
    secureStorage = FakeSecureStorage(storage: {...initialLoggedInStorage});
    pc.providerContainer = ProviderContainer();
    wireLoginDispatchers(pc.providerContainer.read(loginProvider.notifier));
  });

  tearDown(() {
    skipUnmaintainedAlert = false;
    deletedData = false;
    pc.providerContainer.dispose();
  });

  test('cached data shown when no internet on startup', () async {
    _stubFailedLogin(mockWrapper, noInternet: true);

    await startApp(null);

    final container = pc.providerContainer;
    expect(container.read(loginProvider).loggedIn, isTrue);
    expect(container.read(loginProvider).errorMsg, isNull);
    expect(container.read(noInternetProvider), isTrue);
  });

  test('cached data shown when server error on startup', () async {
    _stubFailedLogin(mockWrapper, noInternet: false, error: "Server error");

    await startApp(null);

    final container = pc.providerContainer;
    expect(container.read(loginProvider).loggedIn, isTrue);
    expect(container.read(loginProvider).errorMsg, isNull);
    expect(container.read(noInternetProvider), isFalse);
  });
}
