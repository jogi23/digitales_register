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
import 'package:dr/ui/settings/pages/account_settings_page.dart';
import 'package:dr/ui/settings/pages/advanced_settings_page.dart';
import 'package:dr/ui/settings/pages/appearance_settings_page.dart';
import 'package:dr/ui/settings/pages/grades_settings_page.dart';
import 'package:dr/ui/settings/pages/homework_settings_page.dart';
import 'package:dr/ui/settings/pages/notification_settings_page.dart';
import 'package:dr/ui/settings/pages/subjects_calendar_settings_page.dart';
import 'package:dr/ui/settings/settings_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'settings_pump.dart';

const _titles = [
  'Konto & Sicherheit',
  'Benachrichtigungen',
  'Darstellung',
  'Fächer & Kalender',
  'Hausaufgaben & Klassenbuch',
  'Noten',
  'Erweitert',
];

void main() {
  testWidgets('shows the seven categories in order', (tester) async {
    await pumpSettings(tester, const SettingsHubPage());

    final tops = [
      for (final title in _titles) tester.getTopLeft(find.text(title)).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.byType(ListTile), findsNWidgets(7));
  });

  testWidgets('each category opens its page and back returns to the hub',
      (tester) async {
    await pumpSettings(tester, const SettingsHubPage());

    final pages = <String, Type>{
      'Konto & Sicherheit': AccountSettingsPage,
      'Benachrichtigungen': NotificationSettingsPage,
      'Darstellung': AppearanceSettingsPage,
      'Fächer & Kalender': SubjectsCalendarSettingsPage,
      'Hausaufgaben & Klassenbuch': HomeworkSettingsPage,
      'Noten': GradesSettingsPage,
      'Erweitert': AdvancedSettingsPage,
    };
    for (final entry in pages.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate((w) => w.runtimeType == entry.value),
        findsOneWidget,
        reason: entry.key,
      );

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsHubPage), findsOneWidget, reason: entry.key);
    }
  });

  testWidgets('summaries reflect the state', (tester) async {
    await pumpSettings(
      tester,
      const SettingsHubPage(),
      settings: SettingsState(
        notificationsEnabled: true,
        notificationPollMinutes: 180,
        appLockEnabled: true,
        diagnosticsEnabled: true,
      ),
    );

    expect(find.text('An · Alle 3 Stunden'), findsOneWidget);
    expect(find.text('App-Sperre an'), findsOneWidget);
    expect(find.text('Diagnose-Protokoll an'), findsOneWidget);
    expect(find.text('Geräte-Theme folgen · Gerätesprache'), findsOneWidget);
  });

  testWidgets('summaries say when things are off', (tester) async {
    await pumpSettings(
      tester,
      const SettingsHubPage(),
      settings: SettingsState(
        notificationsEnabled: false,
        appLockEnabled: false,
        diagnosticsEnabled: false,
        language: 'it',
      ),
    );

    expect(find.text('Aus'), findsOneWidget);
    expect(find.text('App-Sperre aus'), findsOneWidget);
    expect(find.text('Diagnose-Protokoll aus'), findsOneWidget);
    expect(find.text('Geräte-Theme folgen · Italiano'), findsOneWidget);
  });

  testWidgets('demo mode keeps all seven categories', (tester) async {
    await pumpSettings(tester, const SettingsHubPage(), demo: true);

    for (final title in _titles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('text scale 2.0 does not overflow', (tester) async {
    await pumpSettings(tester, const SettingsHubPage(), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, const SettingsHubPage());

    await expectMeetsGuidelines(tester);
  });
}
