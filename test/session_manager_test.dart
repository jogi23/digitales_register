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

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/auth_service.dart';
import 'package:dr/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthService extends Mock implements AuthService {}

SessionManager _makeSessionManager({required bool demoMode}) {
  final mockAuth = _MockAuthService();
  when(() => mockAuth.demoMode).thenReturn(demoMode);
  return SessionManager(ApiClient(), mockAuth);
}

/// An account that is not signed in and has nothing stored to sign in with:
/// the state a session leaves behind when it runs out.
_MockAuthService makeSignedOutAuth() {
  final auth = _MockAuthService();
  when(() => auth.demoMode).thenReturn(false);
  when(() => auth.loggedIn).thenAnswer((_) async => false);
  when(() => auth.user).thenReturn(null);
  when(() => auth.pass).thenReturn(null);
  return auth;
}

/// Answers every request with the next status code in [statusCodes]; the
/// last one repeats.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCodes);

  final List<int> statusCodes;
  int requests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index =
        requests < statusCodes.length ? requests : statusCodes.length - 1;
    final statusCode = statusCodes[index];
    requests++;
    return ResponseBody.fromString(
      '{"status":$statusCode}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// An account that is signed in and can sign in again with what it stored.
/// Counts the logins in [logins].
class _SignedInAuth {
  final auth = _MockAuthService();
  bool loggedIn = true;
  int logins = 0;

  _SignedInAuth() {
    when(() => auth.demoMode).thenReturn(false);
    when(() => auth.loggedIn).thenAnswer((_) async => loggedIn);
    when(() => auth.forceLoggedOut()).thenAnswer((_) => loggedIn = false);
    when(() => auth.user).thenReturn('user');
    when(() => auth.pass).thenReturn('pass');
    when(() => auth.login(any(), any(), any(), any())).thenAnswer((_) async {
      logins++;
      loggedIn = true;
    });
    when(() => auth.onRelogin).thenReturn(() {});
    when(() => auth.onAddProtocolItem).thenReturn((_) {});
  }
}

SessionManager _sessionAnswering(
  _SignedInAuth signedIn,
  _StatusAdapter adapter,
) {
  final apiClient = ApiClient()..url = 'https://schule.digitalesregister.it';
  apiClient.dio.httpClientAdapter = adapter;
  return SessionManager(apiClient, signedIn.auth);
}

void main() {
  group('SessionManager', () {
    // -----------------------------------------------------------------------
    // interaction()
    // -----------------------------------------------------------------------
    group('interaction()', () {
      test('updates lastInteraction to a recent DateTime', () {
        final sm = _makeSessionManager(demoMode: false);
        final before = DateTime.now();
        sm.interaction();
        // lastInteraction must be >= before (i.e. not in the past relative to before)
        expect(
          sm.lastInteraction.isBefore(before),
          isFalse,
          reason:
              'lastInteraction should be >= the timestamp captured before calling interaction()',
        );
      });

      test('can be called multiple times without error', () {
        final sm = _makeSessionManager(demoMode: false);
        sm.interaction();
        sm.interaction();
        sm.interaction();
        expect(sm.lastInteraction, isA<DateTime>());
      });
    });

    // -----------------------------------------------------------------------
    // Initial state
    // -----------------------------------------------------------------------
    group('initial state', () {
      test('noInternet defaults to false', () {
        final sm = _makeSessionManager(demoMode: false);
        expect(sm.noInternet, isFalse);
      });

      test('safeMode defaults to false', () {
        final sm = _makeSessionManager(demoMode: false);
        expect(sm.safeMode, isFalse);
      });

      test('lastInteraction is set on construction', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final sm = _makeSessionManager(demoMode: false);
        expect(sm.lastInteraction.isAfter(before), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // send() — demo mode
    // -----------------------------------------------------------------------
    group('send() in demo mode', () {
      test('returns a non-null response for a known demo endpoint', () async {
        final sm = _makeSessionManager(demoMode: true);
        final result = await sm.send('api/student/dashboard/toggle_reminder');
        expect(result, isNotNull);
      });

      test('toggle_reminder demo response has success=true', () async {
        final sm = _makeSessionManager(demoMode: true);
        final result = await sm.send('api/student/dashboard/toggle_reminder');
        expect((result as Map)['success'], isTrue);
      });

      test('returns null for an unknown demo endpoint', () async {
        final sm = _makeSessionManager(demoMode: true);
        final result = await sm.send('api/does/not/exist/in/demo');
        expect(result, isNull);
      });

      test('passes args to demo response function', () async {
        final sm = _makeSessionManager(demoMode: true);
        // save_reminder is a Map (not a Function), so args are ignored and
        // a fixed Map is returned — just verify it's non-null.
        final result = await sm
            .send('api/student/dashboard/save_reminder', args: {'title': 'x'});
        expect(result, isNotNull);
      });
    });

    // -----------------------------------------------------------------------
    // startSession + ensureLoggedIn auto-logout
    // -----------------------------------------------------------------------
    group('startSession + ensureLoggedIn', () {
      _MockAuthService makeAuth() {
        final auth = _MockAuthService();
        when(() => auth.demoMode).thenReturn(false);
        when(() => auth.loggedIn).thenAnswer((_) async => false);
        when(() => auth.user).thenReturn(null);
        when(() => auth.pass).thenReturn(null);
        return auth;
      }

      Config expiredConfig() => Config(
            (b) => b
              ..autoLogoutSeconds = -100
              ..userId = 1
              ..fullName = 'Test'
              ..imgSource = ''
              ..currentSemesterMaybe = 1
              ..isStudentOrParent = true,
          );

      Config validConfig() => Config(
            (b) => b
              ..autoLogoutSeconds = 3600
              ..userId = 1
              ..fullName = 'Test'
              ..imgSource = ''
              ..currentSemesterMaybe = 1
              ..isStudentOrParent = true,
          );

      test('ensureLoggedIn calls forceLoggedOut when session has expired',
          () async {
        final auth = makeAuth();
        final sm = SessionManager(ApiClient(), auth);
        sm.startSession(expiredConfig());
        await sm.ensureLoggedIn();
        verify(() => auth.forceLoggedOut()).called(greaterThanOrEqualTo(1));
      });

      test(
          'ensureLoggedIn does NOT call forceLoggedOut when session is still valid',
          () async {
        final auth = makeAuth();
        final sm = SessionManager(ApiClient(), auth);
        sm.startSession(validConfig());
        await sm.ensureLoggedIn();
        verifyNever(() => auth.forceLoggedOut());
      });
    });

    // -----------------------------------------------------------------------
    // Reporting the state of the session
    // -----------------------------------------------------------------------
    group('reporting an expired session', () {
      test('a request that cannot be sent with a working network reports it',
          () async {
        final auth = makeSignedOutAuth();
        final sm = SessionManager(ApiClient(), auth);
        var expired = 0;
        sm.onSessionExpired = () => expired++;

        // The request never goes out: nothing is logged in, and nothing is
        // stored to log in with. That used to be silent.
        expect(await sm.send('api/student/dashboard/dashboard'), isNull);
        expect(expired, 1);
      });

      test('no network is not reported as an expired session', () async {
        final auth = makeSignedOutAuth();
        final sm = SessionManager(ApiClient(), auth)..noInternet = true;
        var expired = 0;
        sm.onSessionExpired = () => expired++;

        expect(await sm.send('api/student/dashboard/dashboard'), isNull);
        expect(expired, 0);
      });

      test('a demo answer counts as an answer from the server', () async {
        final sm = _makeSessionManager(demoMode: true);
        var answers = 0;
        sm.onRequestSucceeded = () => answers++;

        await sm.send('api/student/dashboard/toggle_reminder');
        expect(answers, 1);
      });

      test('an endpoint the demo does not know is no answer', () async {
        final sm = _makeSessionManager(demoMode: true);
        var answers = 0;
        sm.onRequestSucceeded = () => answers++;

        expect(await sm.send('api/does/not/exist'), isNull);
        expect(answers, 0);
      });

      test('a demo answer is not mistaken for a dead session', () async {
        final sm = _makeSessionManager(demoMode: true);
        var expired = 0;
        sm.onSessionExpired = () => expired++;

        await sm.send('api/student/dashboard/toggle_reminder');
        expect(expired, 0);
      });
    });

    // -----------------------------------------------------------------------
    // send() — the server answers 401
    // -----------------------------------------------------------------------
    group('send() when the server answers 401', () {
      test('signs in again and repeats the request', () async {
        final signedIn = _SignedInAuth();
        final adapter = _StatusAdapter([401, 200]);
        final sm = _sessionAnswering(signedIn, adapter);
        var expired = 0;
        final errors = <Object>[];
        sm.onSessionExpired = () => expired++;

        final result = await sm.send(
          'api/message/getMyMessages',
          onError: errors.add,
        );

        expect(result, {'status': 200});
        expect(adapter.requests, 2);
        expect(signedIn.logins, 1);
        expect(expired, 0);
        expect(errors, isEmpty);
      });

      test('a second 401 reports the session as expired', () async {
        final signedIn = _SignedInAuth();
        final adapter = _StatusAdapter([401]);
        final sm = _sessionAnswering(signedIn, adapter);
        var expired = 0;
        final errors = <Object>[];
        sm.onSessionExpired = () => expired++;

        final result = await sm.send(
          'api/message/getTypes',
          onError: errors.add,
        );

        expect(result, isNull);
        expect(adapter.requests, 2);
        expect(expired, 1);
        expect(errors, hasLength(1));
        expect(
          (errors.single as DioException).response?.statusCode,
          401,
        );
      });

      test('a 401 is not taken for a missing network', () async {
        final signedIn = _SignedInAuth();
        final sm = _sessionAnswering(signedIn, _StatusAdapter([401]));
        var noInternetReports = 0;
        sm.onNoInternet = (_) => noInternetReports++;

        await sm.send('api/message/getMyMessages');

        expect(sm.noInternet, isFalse);
        expect(noInternetReports, 0);
      });

      test('a retry that cannot sign in again still reports the failure',
          () async {
        final signedIn = _SignedInAuth();
        when(() => signedIn.auth.login(any(), any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => signedIn.auth.logout(
              hard: any(named: 'hard'),
              logoutForcedByServer: any(named: 'logoutForcedByServer'),
            )).thenAnswer((_) {});
        final adapter = _StatusAdapter([401]);
        final sm = _sessionAnswering(signedIn, adapter);
        var expired = 0;
        final errors = <Object>[];
        sm.onSessionExpired = () => expired++;

        final result = await sm.send(
          'api/message/getMyMessages',
          onError: errors.add,
        );

        expect(result, isNull);
        expect(adapter.requests, 1);
        expect(expired, 1);
        expect(errors.single, isA<UnexpectedLogoutException>());
      });
    });
  });
}
