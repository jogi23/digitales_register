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

import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/background_status.dart';
import 'package:dr/ui/background_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final status = BackgroundStatus(
    finishedAt: DateTime(2026, 10, 8, 12, 30),
    accounts: const [
      AccountCheckResult(
        label: 'Anna',
        outcome: AccountCheckOutcome.ok,
        unread: 3,
        fresh: 1,
      ),
      AccountCheckResult(
          label: 'Ben', outcome: AccountCheckOutcome.unreachable),
      AccountCheckResult(
        label: 'Cleo',
        outcome: AccountCheckOutcome.skippedAppSignedIn,
      ),
      AccountCheckResult(
        label: 'Dora',
        outcome: AccountCheckOutcome.firstRun,
        unread: 2,
      ),
    ],
  );

  Future<void> pump(
    WidgetTester tester, {
    BackgroundStatus? shown,
    bool? permission = true,
    bool notifications = true,
    bool isAndroid = true,
    void Function()? onCheck,
    List<BackgroundStatus?>? runs,
  }) async {
    var asked = 0;
    final c = ProviderContainer(overrides: [
      backgroundStatusProvider.overrideWith(
        (ref) async =>
            runs == null ? shown : runs[asked++ < runs.length ? asked - 1 : 0],
      ),
      notificationPermissionProvider.overrideWith((ref) async => permission),
      checkBackgroundNowProvider.overrideWithValue(() async => onCheck?.call()),
    ]);
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier).setNotificationsEnabled(notifications);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BackgroundStatusCard(isAndroid: isAndroid),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the time and one line per account', (tester) async {
    await pump(tester, shown: status);
    expect(find.text('Letzter Hintergrundabruf'), findsOneWidget);
    expect(find.textContaining('12:30'), findsOneWidget);
    expect(find.text('Anna: 3 ungelesen, 1 neu'), findsOneWidget);
    expect(find.text('Ben: nicht erreicht'), findsOneWidget);
    expect(find.text('Cleo: übersprungen, die App ist angemeldet'),
        findsOneWidget);
    expect(find.text('Dora: erster Lauf, 2 ungelesen'), findsOneWidget);
  });

  testWidgets('says so when no round ran yet', (tester) async {
    await pump(tester);
    expect(find.text('Noch kein Lauf'), findsOneWidget);
  });

  testWidgets('says so when no account can be checked', (tester) async {
    await pump(
      tester,
      shown: BackgroundStatus(
        finishedAt: DateTime(2026, 10, 8, 12, 30),
        accounts: const [],
      ),
    );
    expect(
        find.text('Keine Konten mit gespeichertem Passwort'), findsOneWidget);
  });

  testWidgets('shows whether the system allows notifications', (tester) async {
    await pump(tester, shown: status);
    expect(find.textContaining('Systemberechtigung'), findsOneWidget);
    expect(find.textContaining('erteilt'), findsOneWidget);
    expect(find.textContaining('nicht erteilt'), findsNothing);
  });

  testWidgets('shows a missing permission', (tester) async {
    await pump(tester, shown: status, permission: false);
    expect(find.textContaining('nicht erteilt'), findsOneWidget);
  });

  testWidgets('leaves out the permission when it cannot be told',
      (tester) async {
    await pump(tester, shown: status, permission: null);
    expect(find.textContaining('Systemberechtigung'), findsNothing);
  });

  testWidgets('"Jetzt prüfen" starts a round, in release builds as well',
      (tester) async {
    var checks = 0;
    await pump(tester, shown: status, onCheck: () => checks++);
    await tester.tap(find.text('Jetzt prüfen'));
    await tester.pumpAndSettle();
    expect(checks, 1);
  });

  testWidgets('is not there off Android', (tester) async {
    await pump(tester, shown: status, isAndroid: false);
    expect(find.text('Letzter Hintergrundabruf'), findsNothing);
  });

  testWidgets('is not there while notifications are off', (tester) async {
    await pump(tester, shown: status, notifications: false);
    expect(find.text('Letzter Hintergrundabruf'), findsNothing);
  });

  testWidgets('reads the status again when the app resumes', (tester) async {
    await pump(tester, runs: [null, status]);
    expect(find.text('Noch kein Lauf'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Anna: 3 ungelesen, 1 neu'), findsOneWidget);
  });
}
