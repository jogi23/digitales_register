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

import 'package:dr/app_links.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/battery_optimization.dart';
import 'package:dr/ui/battery_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../fake_url_launcher.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<int> pump(
    WidgetTester tester, {
    required List<bool?> answers,
    bool notifications = true,
    void Function()? onOpen,
  }) async {
    var asked = 0;
    final c = ProviderContainer(overrides: [
      batteryOptimizationProvider.overrideWith(
        (ref) async => answers[asked++ < answers.length ? asked - 1 : 0],
      ),
      openBatterySettingsProvider.overrideWithValue(() async => onOpen?.call()),
    ]);
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier).setNotificationsEnabled(notifications);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: Scaffold(body: BatteryOptimizationHint()),
      ),
    ));
    await tester.pumpAndSettle();
    return asked;
  }

  const title = 'Benachrichtigungen können sich verspäten';

  testWidgets('shows the hint while the app is not exempt', (tester) async {
    await pump(tester, answers: [false]);
    expect(find.text(title), findsOneWidget);
    expect(find.text('Einstellungen öffnen'), findsOneWidget);
  });

  testWidgets('hides it when the app is exempt', (tester) async {
    await pump(tester, answers: [true]);
    expect(find.text(title), findsNothing);
  });

  testWidgets('hides it when the state is unknown', (tester) async {
    await pump(tester, answers: [null]);
    expect(find.text(title), findsNothing);
  });

  testWidgets('hides it while notifications are off', (tester) async {
    await pump(tester, answers: [false], notifications: false);
    expect(find.text(title), findsNothing);
  });

  testWidgets('the button opens the system page', (tester) async {
    var opened = 0;
    await pump(tester, answers: [false], onOpen: () => opened++);
    await tester.tap(find.text('Einstellungen öffnen'));
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('the link opens the guide for the device', (tester) async {
    final launcher = FakeUrlLauncher.install();
    await pump(tester, answers: [false]);
    await tester.tap(find.text('Anleitung für dein Gerät'));
    await tester.pumpAndSettle();
    expect(launcher.launched, [AppLinks.dontKillMyApp.toString()]);
  });

  testWidgets('checks again after the app resumes', (tester) async {
    await pump(tester, answers: [false, true]);
    expect(find.text(title), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing);
  });
}
