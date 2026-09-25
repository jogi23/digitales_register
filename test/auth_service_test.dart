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

import 'package:dio/dio.dart';
import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/auth_service.dart';
import 'package:dr/config_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockDio extends Mock implements Dio {}

void main() {
  group('AuthService', () {
    // -----------------------------------------------------------------------
    // Demo-Login: no network calls, no mocking needed
    // -----------------------------------------------------------------------
    group('demo login', () {
      late AuthService sut;

      setUp(() {
        sut = AuthService(
          ApiClient(),
          getDemoUserId: () async => 0,
        );
      });

      test('sets demoMode=true and loggedIn=true', () async {
        await sut.login(
          'demo-user-6540',
          'anything',
          null,
          'https://wertwerk-demo.digitalesregister.it',
          logout: () {},
          configLoaded: () {},
          relogin: () {},
          addProtocolItem: (_) {},
        );

        expect(sut.demoMode, isTrue);
        expect(await sut.loggedIn, isTrue);
      });

      test('keeps the callbacks of the app, as any login does (#283)',
          () async {
        var relogins = 0;
        await sut.login(
          'demo-user-6540',
          'anything',
          null,
          'https://wertwerk-demo.digitalesregister.it',
          logout: () {},
          configLoaded: () {},
          relogin: () => relogins++,
          addProtocolItem: (_) {},
        );

        // The demo session runs out after five minutes like any other and
        // signs in again; that called onRelogin, which the demo left null.
        expect(sut.appHasSignedIn, isTrue);
        expect(sut.onAddProtocolItem, isNotNull);
        sut.onRelogin!();
        expect(relogins, 1);
      });

      test('populates config with demo values', () async {
        await sut.login(
          'demo-user-6540',
          'anything',
          null,
          'https://wertwerk-demo.digitalesregister.it',
          logout: () {},
          configLoaded: () {},
          relogin: () {},
          addProtocolItem: (_) {},
        );

        expect(sut.config!.fullName, 'Demo User');
        expect(sut.config!.isStudentOrParent, isTrue);
        expect(sut.config!.autoLogoutSeconds, 300);
        expect(sut.config!.userId, 0);
      });

      test('calls onSessionStarted with config', () async {
        Config? received;
        sut.onSessionStarted = (c) => received = c;

        await sut.login(
          'demo-user-6540',
          'anything',
          null,
          'https://wertwerk-demo.digitalesregister.it',
          logout: () {},
          configLoaded: () {},
          relogin: () {},
          addProtocolItem: (_) {},
        );

        expect(received, isNotNull);
        expect(received!.fullName, 'Demo User');
      });

      test('calls configLoaded callback', () async {
        var called = false;

        await sut.login(
          'demo-user-6540',
          'anything',
          null,
          'https://wertwerk-demo.digitalesregister.it',
          logout: () {},
          configLoaded: () => called = true,
          relogin: () {},
          addProtocolItem: (_) {},
        );

        expect(called, isTrue);
      });

      test('stores user and pass', () async {
        await sut.login(
          'demo-user-6540',
          'myPassword',
          null,
          'https://wertwerk-demo.digitalesregister.it',
          logout: () {},
          configLoaded: () {},
          relogin: () {},
          addProtocolItem: (_) {},
        );

        expect(sut.user, 'demo-user-6540');
        expect(sut.pass, 'myPassword');
      });
    });

    // -----------------------------------------------------------------------
    // forceLoggedOut
    // -----------------------------------------------------------------------
    group('forceLoggedOut', () {
      test('loggedIn resolves as false', () async {
        final sut = AuthService(ApiClient());
        sut.forceLoggedOut();
        expect(await sut.loggedIn, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // logout — hard: false, url is null → no network call
    // -----------------------------------------------------------------------
    group('logout(hard: false)', () {
      late _MockApiClient mockClient;
      late AuthService sut;

      setUp(() {
        mockClient = _MockApiClient();
        // url getter returns null → the conditional dio.get() branch is skipped
        when(() => mockClient.url).thenReturn(null);
        when(() => mockClient.clearCookies()).thenReturn(null);
        sut = AuthService(mockClient);
      });

      test('sets loggedIn=false', () async {
        sut.logout(hard: false);
        expect(await sut.loggedIn, isFalse);
      });

      test('clears cookies', () {
        sut.logout(hard: false);
        verify(() => mockClient.clearCookies()).called(1);
      });

      test('does not clear user/pass', () {
        sut.user = 'alice';
        sut.pass = 's3cr3t';
        sut.logout(hard: false);
        expect(sut.user, 'alice');
        expect(sut.pass, 's3cr3t');
      });
    });

    // -----------------------------------------------------------------------
    // logout — hard: true, logoutForcedByServer: true
    // -----------------------------------------------------------------------
    group('logout(hard: true, logoutForcedByServer: true)', () {
      late _MockApiClient mockClient;
      late AuthService sut;

      setUp(() {
        mockClient = _MockApiClient();
        // The setter _apiClient.url = null is called; track it without stubbing
        // by registering a no-op via fallback.
        when(() => mockClient.clearCookies()).thenReturn(null);
        sut = AuthService(mockClient);
      });

      test('calls onLogout', () {
        var called = false;
        sut.onLogout = () => called = true;

        sut.logout(hard: true, logoutForcedByServer: true);

        expect(called, isTrue);
      });

      test('clears user and pass', () {
        sut.user = 'alice';
        sut.pass = 's3cr3t';

        sut.onLogout = () {};
        sut.logout(hard: true, logoutForcedByServer: true);

        expect(sut.user, isNull);
        expect(sut.pass, isNull);
      });

      test('sets loggedIn=false', () async {
        sut.onLogout = () {};
        sut.logout(hard: true, logoutForcedByServer: true);
        expect(await sut.loggedIn, isFalse);
      });

      test('clears cookies', () {
        sut.onLogout = () {};
        sut.logout(hard: true, logoutForcedByServer: true);
        verify(() => mockClient.clearCookies()).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // login — the server says yes, the home page decides
    // -----------------------------------------------------------------------
    group('login against a server', () {
      const url = 'https://school.digitalesregister.it';
      late _MockApiClient mockClient;
      late _MockDio mockDio;
      late AuthService sut;
      late int configLoadedCalls;

      Future<dynamic> login() => sut.login(
            'alice',
            's3cr3t',
            null,
            url,
            logout: () {},
            configLoaded: () => configLoadedCalls++,
            relogin: () {},
            addProtocolItem: (_) {},
          );

      void serveHomePage(String html) {
        when(() => mockDio.get<String>(any())).thenAnswer(
          (_) async =>
              Response<String>(requestOptions: RequestOptions(), data: html),
        );
      }

      setUp(() {
        configLoadedCalls = 0;
        mockClient = _MockApiClient();
        mockDio = _MockDio();
        when(() => mockClient.dio).thenReturn(mockDio);
        when(() => mockClient.url).thenReturn(url);
        when(() => mockClient.loginAddress).thenReturn('$url/v2/api/auth/login');
        when(() => mockClient.baseAddress).thenReturn('$url/v2/');
        when(() => mockClient.clearCookies()).thenReturn(null);
        when(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(),
            data: {'loggedIn': true},
          ),
        );
        sut = AuthService(mockClient);
      });

      test('counts as logged in once the configuration is loaded', () async {
        serveHomePage(
          'var currentUserId=42;'
          'var config = { auto_logout_seconds: 60, };'
          'navigationProfilePicture" src="https://example.com/pic.png">Alice</span>',
        );

        await login();

        expect(await sut.loggedIn, isTrue);
        expect(sut.config?.userId, 42);
        expect(sut.error, isNull);
        expect(configLoadedCalls, 1);
      });

      test('a home page without configuration fails the login, not the app',
          () async {
        // What the server sent in Sentry 118673931 after a long time in the
        // background: a page without currentUserId.
        serveHomePage('<!DOCTYPE html><html><body>Login</body></html>');

        final result = await login();

        expect(result, isNull);
        expect(await sut.loggedIn, isFalse);
        expect(sut.config, isNull);
        expect(sut.error, contains('$ConfigParseException'));
        expect(sut.noInternetDuringLogin, isFalse);
        expect(configLoadedCalls, 0);
      });

      test('non-interactive login does not try to open a 2FA dialog', () async {
        when(() => mockDio.post<dynamic>(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(),
            data: {
              'loggedIn': false,
              'error': 'two_factor_needed',
              'message': '2FA required',
            },
          ),
        );

        final result = await sut.login(
          'alice',
          's3cr3t',
          null,
          url,
          allowInteractive2fa: false,
          logout: () {},
          configLoaded: () => configLoadedCalls++,
          relogin: () {},
          addProtocolItem: (_) {},
        );

        expect(result, isA<Map>());
        expect((result as Map)['error'], 'two_factor_needed');
        expect(await sut.loggedIn, isFalse);
        expect(configLoadedCalls, 0);
      });
    });
  });
}
