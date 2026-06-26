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

import 'package:dr/app_state.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/ui/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

// ---------------------------------------------------------------------------
// Demo data (from assets/demo/capture.json → api/profile/get)
// ---------------------------------------------------------------------------

final _demoProfile = ProfileState(
  (b) => b
    ..username = 'demo-user-6540'
    ..roleName = 'Eltern'
    ..name = 'Eltern-Account 2 Mustermann Max'
    ..email = 'demo@example.com'
    ..sendNotificationEmails = true,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _build({
  required ProfileState state,
  bool noInternet = false,
  VoidCallback? onChangeEmail,
  VoidCallback? onChangePass,
  OnSettingChanged<bool>? onNotifications,
}) {
  return MaterialApp(
    home: Profile(
      profileState: state,
      noInternet: noInternet,
      setSendNotificationEmails: onNotifications ?? (_) {},
      changeEmail: onChangeEmail ?? () {},
      changePass: onChangePass ?? () {},
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('loading state', () {
    testWidgets('shows CircularProgressIndicator when no data and online',
        (tester) async {
      await tester.pumpWidget(_build(state: ProfileState()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NoInternet), findsNothing);
    });

    testWidgets('shows NoInternet when no data and offline', (tester) async {
      await tester.pumpWidget(
        _build(state: ProfileState(), noInternet: true),
      );
      expect(find.byType(NoInternet), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('loaded state', () {
    testWidgets('shows name', (tester) async {
      await tester.pumpWidget(_build(state: _demoProfile));
      expect(find.text('Eltern-Account 2 Mustermann Max'), findsOneWidget);
    });

    testWidgets('shows email', (tester) async {
      await tester.pumpWidget(_build(state: _demoProfile));
      expect(find.text('demo@example.com'), findsOneWidget);
    });

    testWidgets('shows role', (tester) async {
      await tester.pumpWidget(_build(state: _demoProfile));
      // UserProfile renders "username · role" as one Text widget.
      expect(
        find.text('demo-user-6540 · Eltern'),
        findsOneWidget,
      );
    });

    testWidgets('shows notification switch', (tester) async {
      await tester.pumpWidget(_build(state: _demoProfile));
      expect(
        find.text('Emails für Benachrichtigungen senden'),
        findsOneWidget,
      );
    });

    testWidgets('notification switch reflects state', (tester) async {
      await tester.pumpWidget(_build(state: _demoProfile));
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('notification callback fires', (tester) async {
      bool? received;
      await tester.pumpWidget(
        _build(
          state: _demoProfile,
          onNotifications: (v) => received = v,
        ),
      );
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(received, isFalse);
    });

    testWidgets('changeEmail callback fires', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _build(state: _demoProfile, onChangeEmail: () => called = true),
      );
      await tester.tap(find.text('Email-Adresse ändern'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('changePass callback fires', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _build(state: _demoProfile, onChangePass: () => called = true),
      );
      await tester.tap(find.text('Passwort ändern'));
      await tester.pump();
      expect(called, isTrue);
    });

    group('noInternet disables actions', () {
      testWidgets('switch disabled', (tester) async {
        await tester.pumpWidget(
          _build(state: _demoProfile, noInternet: true),
        );
        final sw = tester.widget<Switch>(find.byType(Switch));
        expect(sw.onChanged, isNull);
      });

      testWidgets('email tile disabled', (tester) async {
        await tester.pumpWidget(
          _build(state: _demoProfile, noInternet: true),
        );
        final tile = tester.widget<ListTile>(
          find.ancestor(
            of: find.text('Email-Adresse ändern'),
            matching: find.byType(ListTile),
          ),
        );
        expect(tile.enabled, isFalse);
      });

      testWidgets('password tile disabled', (tester) async {
        await tester.pumpWidget(
          _build(state: _demoProfile, noInternet: true),
        );
        final tile = tester.widget<ListTile>(
          find.ancestor(
            of: find.text('Passwort ändern'),
            matching: find.byType(ListTile),
          ),
        );
        expect(tile.enabled, isFalse);
      });
    });
  });

  group('golden', () {
    testGoldens('demo profile loaded', (tester) async {
      await tester.pumpWidget(_build(state: _demoProfile));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_loaded.png'),
      );
    });

    testGoldens('profile loading', (tester) async {
      await tester.pumpWidget(_build(state: ProfileState()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_loading.png'),
      );
    });

    testGoldens('profile no internet loaded', (tester) async {
      await tester.pumpWidget(
        _build(state: _demoProfile, noInternet: true),
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('profile_no_internet.png'),
      );
    });
  });
}
