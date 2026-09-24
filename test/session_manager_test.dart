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
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dr/api_client.dart';
import 'package:dr/app_state.dart';
import 'package:dr/auth_service.dart';
import 'package:dr/session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quiver/testing/async.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockApiClient extends Mock implements ApiClient {}

class _MockDio extends Mock implements Dio {}

Config _config({required int autoLogoutSeconds}) => Config(
      (b) => b
        ..autoLogoutSeconds = autoLogoutSeconds
        ..userId = 1
        ..fullName = 'Test'
        ..imgSource = ''
        ..currentSemesterMaybe = 1
        ..isStudentOrParent = true,
    );

int _seconds(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

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
  when(() => auth.appHasSignedIn).thenReturn(true);
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
/// Answers every request with nothing, noting where it went.
class _PathAdapter implements HttpClientAdapter {
  _PathAdapter(this.paths);

  final List<String> paths;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return ResponseBody.fromString(
      '{"loggedIn":false}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

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
    when(() => auth.appHasSignedIn).thenReturn(true);
    when(() => auth.login(
          any(),
          any(),
          any(),
          any(),
          allowInteractive2fa: any(named: 'allowInteractive2fa'),
        )).thenAnswer((_) async {
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
        when(() => auth.appHasSignedIn).thenReturn(true);
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

      test('turned into the demo while signing in, it asks no server (#283)',
          () async {
        // The request set out before the stored login turned out to be the
        // demo: it went to the network and crashed writing the protocol.
        final signedIn = _SignedInAuth();
        var asked = 0;
        when(() => signedIn.auth.demoMode).thenAnswer((_) => asked++ > 0);
        final adapter = _StatusAdapter([200]);
        final sm = _sessionAnswering(signedIn, adapter);

        final result = await sm.send('api/student/dashboard/toggle_reminder');
        expect(adapter.requests, 0);
        expect((result as Map)['success'], isTrue);
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
    // Extending the session (#231)
    // -----------------------------------------------------------------------
    group('extending the session', () {
      const url = 'https://school.digitalesregister.it';
      // The device clock runs 30 minutes ahead of the server.
      final deviceNow = DateTime(2026, 9, 15, 9, 30);
      final serverNow = DateTime(2026, 9, 15, 9);
      late _MockAuthService auth;
      late _MockDio dio;
      late SessionManager sm;

      /// A session that runs out within the next check, so it is extended
      /// right away.
      Config runningOut() => _config(autoLogoutSeconds: 10);

      void serverAnswers({
        bool forceLogout = false,
        bool noSession = false,
        Duration extendedBy = const Duration(minutes: 20),
      }) {
        when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
            .thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(),
            data: <String, Object?>{
              'forceLogout': forceLogout,
              'newExpiration': _seconds(serverNow.add(extendedBy)),
              'serverTime': _seconds(serverNow),
              'noSession': noSession,
            },
          ),
        );
      }

      /// Starts the session and lets the first check finish. Runs in fake
      /// time, so the next check waits instead of polling the mocks forever.
      void startSession(Config config, [void Function(FakeAsync)? then]) {
        FakeAsync().run((async) {
          sm.startSession(config);
          async.flushMicrotasks();
          then?.call(async);
        });
      }

      void verifyNoLogout() => verifyNever(
            () => auth.logout(
              hard: any(named: 'hard'),
              logoutForcedByServer: any(named: 'logoutForcedByServer'),
            ),
          );

      setUp(() {
        auth = _MockAuthService();
        when(() => auth.demoMode).thenReturn(false);
        when(() => auth.loggedIn).thenAnswer((_) async => true);
        when(() => auth.onAddProtocolItem).thenReturn((_) {});
        final client = _MockApiClient();
        dio = _MockDio();
        when(() => client.dio).thenReturn(dio);
        when(() => client.url).thenReturn(url);
        when(() => client.baseAddress).thenReturn('$url/v2/');
        sm = SessionManager(client, auth, clock: () => deviceNow);
      });

      test('judges the new expiration by the server clock', () async {
        // 20 more minutes by the server's clock — by the device clock that
        // is already ten minutes past.
        serverAnswers();
        startSession(runningOut());

        await sm.ensureLoggedIn();
        verifyNever(() => auth.forceLoggedOut());
      });

      test('reports the last action by the server clock', () {
        serverAnswers(extendedBy: const Duration(seconds: 10));
        sm.lastInteraction = deviceNow.subtract(const Duration(minutes: 1));

        // The first answer reveals the offset, the second extension uses it.
        startSession(runningOut(), (async) {
          async.elapse(const Duration(seconds: 5));
        });

        final sent = verify(
          () => dio.post<dynamic>(any(), data: captureAny(named: 'data')),
        ).captured;
        expect(sent, hasLength(2));
        expect(
          (sent.last as Map)['lastAction'],
          _seconds(serverNow.subtract(const Duration(minutes: 1))),
        );
      });

      test('logs out when the server asks for it', () {
        serverAnswers(forceLogout: true);
        startSession(runningOut());

        verify(() => auth.logout(hard: false, logoutForcedByServer: true))
            .called(1);
      });

      test('a session the server no longer knows signs in again quietly', () {
        serverAnswers(noSession: true);
        startSession(runningOut());

        verify(() => auth.forceLoggedOut()).called(1);
        verifyNoLogout();
      });

      test('a missing network does not log out', () {
        when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
            .thenThrow(TimeoutException('no network'));
        startSession(runningOut());

        expect(sm.noInternet, isTrue);
        verifyNoLogout();
      });

      test('a retired session stops checking and extending (#282)', () {
        serverAnswers();
        startSession(runningOut(), (async) {
          sm.retire();
          async.elapse(const Duration(minutes: 5));
        });

        // The first extension went out before the switch; none after it.
        verify(() => dio.post<dynamic>(any(), data: any(named: 'data')))
            .called(1);
        verifyNoLogout();
      });

      test('a retired session never logs the app out (#282)', () {
        // Its extension answered after the account switch: the server wants
        // the old session gone, which is no reason to touch the new one.
        final answer = Completer<Response<dynamic>>();
        when(() => dio.post<dynamic>(any(), data: any(named: 'data')))
            .thenAnswer((_) => answer.future);
        startSession(runningOut(), (async) {
          sm.retire();
          answer.complete(
            Response<dynamic>(
              requestOptions: RequestOptions(),
              data: <String, Object?>{'forceLogout': true},
            ),
          );
          async.flushMicrotasks();
        });

        verifyNoLogout();
        verifyNever(() => auth.forceLoggedOut());
      });

      test('a new login leaves exactly one check waiting', () {
        startSession(_config(autoLogoutSeconds: 3600), (async) {
          sm.startSession(_config(autoLogoutSeconds: 3600));
          sm.startSession(_config(autoLogoutSeconds: 3600));
          async.flushMicrotasks();
          expect(async.nonPeriodicTimerCount, 1);

          async.elapse(const Duration(seconds: 5));
          expect(async.nonPeriodicTimerCount, 1);
        });
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
        when(() => signedIn.auth.login(
              any(),
              any(),
              any(),
              any(),
              allowInteractive2fa: any(named: 'allowInteractive2fa'),
            )).thenAnswer((_) async {});
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

  group('signing in again from storage', () {
    /// An account whose session ran out: nothing is signed in and the
    /// credentials this session held are gone, but storage still has them.
    ({_MockAuthService auth, SessionManager sm, List<List<String?>> logins})
        signedOut({bool loginWorks = true}) {
      final auth = makeSignedOutAuth();
      final logins = <List<String?>>[];
      var loggedIn = false;
      when(() => auth.loggedIn).thenAnswer((_) async => loggedIn);
      when(() => auth.login(
            any(),
            any(),
            any(),
            any(),
            allowInteractive2fa: any(named: 'allowInteractive2fa'),
          )).thenAnswer((invocation) async {
        logins.add([
          for (final argument in invocation.positionalArguments)
            argument as String?,
        ]);
        loggedIn = loginWorks;
        return null;
      });
      final sm = SessionManager(ApiClient(), auth)
        ..storedLogin = () async => (
              user: 'anna',
              pass: 'geheim',
              url: 'https://schule.digitalesregister.it',
            );
      return (auth: auth, sm: sm, logins: logins);
    }

    test('takes the password storage still has', () async {
      // The account switch worked for exactly this reason: it reads the
      // password from storage. Reconnecting did not, and ended on the login
      // form.
      final setup = signedOut();
      expect(await setup.sm.ensureLoggedIn(), isTrue);
      expect(setup.logins, hasLength(1));
      expect(setup.logins.single.first, 'anna');
      expect(setup.logins.single[1], 'geheim');
    });

    test('without stored credentials it gives up as before', () async {
      final auth = makeSignedOutAuth();
      final sm = SessionManager(ApiClient(), auth);
      expect(await sm.ensureLoggedIn(), isFalse);
    });

    test('nothing stored for this account is no login attempt', () async {
      final setup = signedOut();
      setup.sm.storedLogin = () async => null;
      expect(await setup.sm.ensureLoggedIn(), isFalse);
      expect(setup.logins, isEmpty);
    });

    test('a retired session signs in no more (#282)', () async {
      final setup = signedOut();
      var expired = 0;
      setup.sm.onSessionExpired = () => expired++;
      setup.sm.retire();

      expect(await setup.sm.ensureLoggedIn(), isFalse);
      expect(await setup.sm.send('api/student/dashboard/dashboard'), isNull);
      expect(setup.logins, isEmpty);
      // Nor does it tell the app its session ran out: that is the new one's.
      expect(expired, 0);
    });

    test('a password the server refuses is not sent again and again', () async {
      final setup = signedOut(loginWorks: false);
      expect(await setup.sm.ensureLoggedIn(), isFalse);
      expect(await setup.sm.ensureLoggedIn(), isFalse);
      expect(setup.logins, hasLength(1));
    });
  });

  group('a request before the app has signed in', () {
    /// A fresh session with nothing signed in yet, as the app has it between
    /// creating it and its own sign-in — after an account switch, or at
    /// every start from storage, where the Merkheft shows the stored state
    /// before the login goes out.
    ({AuthService auth, SessionManager sm, List<String> paths}) fresh() {
      final api = ApiClient();
      final paths = <String>[];
      api.dio.httpClientAdapter = _PathAdapter(paths);
      final auth = AuthService(api);
      final sm = SessionManager(api, auth)
        ..storedLogin = () async => (
              user: 'anna',
              pass: 'geheim',
              url: 'https://schule.digitalesregister.it',
            );
      return (auth: auth, sm: sm, paths: paths);
    }

    test('leaves the login to the app instead of racing it', () async {
      final setup = fresh();
      var expired = 0;
      setup.sm.onSessionExpired = () => expired++;

      // Signing in from storage here went through without the app's
      // callbacks: an assertion in debug builds, and in release a session
      // whose forced logout had nothing to call.
      expect(await setup.sm.send('api/student/dashboard/dashboard'), isNull);
      expect(setup.paths, isEmpty);
      // Not an expired session either: the app's own login is on its way.
      expect(expired, 0);
    });

    test('once the app has tried, storage may sign in again', () async {
      final setup = fresh();
      // The app's login, failed for want of a network — as after a start
      // without one. Coming back online must still sign in from storage.
      setup.paths.clear();
      await setup.auth.login(
        'anna',
        'geheim',
        null,
        'https://schule.digitalesregister.it',
        logout: () {},
        configLoaded: () {},
        relogin: () {},
        addProtocolItem: (_) {},
      );
      setup.paths.clear();

      await setup.sm.send('api/student/dashboard/dashboard');
      expect(setup.paths, contains(endsWith('api/auth/login')));
    });
  });
}
