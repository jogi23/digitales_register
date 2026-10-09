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
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings/pages/notification_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

void main() {
  testWidgets('notification settings can be changed', (tester) async {
    useTallWindow(tester);
    final container =
        await pumpSettings(tester, const NotificationSettingsPage());
    final l = tr(tester.element(find.byType(NotificationSettingsPage)));
    expect(container.read(settingsProvider).notificationsEnabled, isTrue);

    await tester.tap(find.text(l.settingsNotificationsEnable));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).notificationsEnabled, isFalse);

    await tester.tap(find.text(l.settingsNotificationsEnable));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.settingsNotificationsInterval));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.notificationsEveryHours(3)));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).notificationPollMinutes, 180);
  });

  testWidgets('each type switch writes its setting', (tester) async {
    useTallWindow(tester);
    final container =
        await pumpSettings(tester, const NotificationSettingsPage());

    final fields = <String, bool Function(SettingsState)>{
      'Merkheft': (s) => s.notifyClassbook,
      'Mitteilungen': (s) => s.notifyMessages,
      'Bewertungen': (s) => s.notifyGrades,
      'Beobachtungen': (s) => s.notifyObservations,
      'Hausaufgaben': (s) => s.notifyHomework,
      'Absenzen': (s) => s.notifyAbsences,
    };
    for (final entry in fields.entries) {
      expect(entry.value(container.read(settingsProvider)), isTrue,
          reason: entry.key);
      await tester.tap(find.widgetWithText(SwitchListTile, entry.key));
      await tester.pumpAndSettle();
      expect(entry.value(container.read(settingsProvider)), isFalse,
          reason: entry.key);
    }
  });

  testWidgets(
      'type switches and interval are disabled while notifications '
      'are off', (tester) async {
    useTallWindow(tester);
    await pumpSettings(
      tester,
      const NotificationSettingsPage(),
      settings: SettingsState(notificationsEnabled: false),
    );

    final typeSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Mitteilungen'),
    );
    expect(typeSwitch.onChanged, isNull);

    await tester.tap(find.text('Prüfintervall'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    useTallWindow(tester);
    await pumpSettings(tester, const NotificationSettingsPage());

    await expectMeetsGuidelines(tester);
  });
}
