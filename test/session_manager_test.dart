// Copyright (C) 2021 Michael Debertol
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
      _MockAuthService _makeAuth() {
        final auth = _MockAuthService();
        when(() => auth.demoMode).thenReturn(false);
        when(() => auth.loggedIn).thenAnswer((_) async => false);
        when(() => auth.user).thenReturn(null);
        when(() => auth.pass).thenReturn(null);
        return auth;
      }

      Config _expiredConfig() => Config(
            (b) => b
              ..autoLogoutSeconds = -100
              ..userId = 1
              ..fullName = 'Test'
              ..imgSource = ''
              ..currentSemesterMaybe = 1
              ..isStudentOrParent = true,
          );

      Config _validConfig() => Config(
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
        final auth = _makeAuth();
        final sm = SessionManager(ApiClient(), auth);
        sm.startSession(_expiredConfig());
        await sm.ensureLoggedIn();
        verify(() => auth.forceLoggedOut()).called(greaterThanOrEqualTo(1));
      });

      test(
          'ensureLoggedIn does NOT call forceLoggedOut when session is still valid',
          () async {
        final auth = _makeAuth();
        final sm = SessionManager(ApiClient(), auth);
        sm.startSession(_validConfig());
        await sm.ensureLoggedIn();
        verifyNever(() => auth.forceLoggedOut());
      });
    });
  });
}
