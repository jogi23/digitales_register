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
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings/pages/subjects_calendar_settings_page.dart';
import 'package:dr/ui/subject_appearance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

void main() {
  testWidgets('opens the subject appearance screen from "Kürzel und Farben"',
      (tester) async {
    await pumpSettings(tester, const SubjectsCalendarSettingsPage());

    await tester.tap(find.text('Kürzel und Farben'));
    await tester.pumpAndSettle();

    expect(find.byType(SubjectAppearancePage), findsOneWidget);
  });

  testWidgets('each calendar switch writes its setting', (tester) async {
    final container =
        await pumpSettings(tester, const SubjectsCalendarSettingsPage());

    final fields = <String, bool Function(SettingsState)>{
      'Stunden im Kalender mit diesen Farben färben': (s) =>
          s.calendarColorBackground,
      'Uhrzeiten im Kalender anzeigen': (s) => s.calendarShowTimes,
      'Alle Details im Kalender anzeigen': (s) => s.calendarShowAllDetails,
      '6-Tages-Woche (beta)': (s) => s.sixDayWeek,
    };
    for (final entry in fields.entries) {
      final before = entry.value(container.read(settingsProvider));
      await tester.tap(find.widgetWithText(SwitchListTile, entry.key));
      await tester.pumpAndSettle();
      expect(entry.value(container.read(settingsProvider)), !before,
          reason: entry.key);
    }
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, const SubjectsCalendarSettingsPage());

    await expectMeetsGuidelines(tester);
  });
}
