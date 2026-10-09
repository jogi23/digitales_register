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
import 'package:dr/ui/settings/pages/homework_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

/// The page is one long list; a tall window builds all of it.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('picking the month view writes the setting', (tester) async {
    _tall(tester);
    final container =
        await pumpSettings(tester, const HomeworkSettingsPage());
    expect(
      container.read(settingsProvider).dashboardViewMode,
      DashboardViewMode.list,
    );

    await tester.tap(find.text('Als Monatskalender anzeigen'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).dashboardViewMode,
      DashboardViewMode.month,
    );
  });

  testWidgets('each switch writes its setting', (tester) async {
    _tall(tester);
    final container =
        await pumpSettings(tester, const HomeworkSettingsPage());

    final fields = <String, bool Function(SettingsState)>{
      'Neue oder geänderte Einträge markieren': (s) =>
          s.dashboardMarkNewOrChangedEntries,
      'Doppelte Einträge ignorieren': (s) => s.dashboardDeduplicateEntries,
      'Tests immer rot umrahmen': (s) => s.dashboardColorTestsInRed,
      'Hausaufgaben mit diesen Farben färben': (s) => s.dashboardColorBorders,
      'Beim Löschen von Erinnerungen fragen': (s) => s.askWhenDelete,
    };
    for (final entry in fields.entries) {
      final before = entry.value(container.read(settingsProvider));
      await tester.tap(find.widgetWithText(SwitchListTile, entry.key));
      await tester.pumpAndSettle();
      expect(entry.value(container.read(settingsProvider)), !before,
          reason: entry.key);
    }
  });

  testWidgets('classbook and overview arrangements write their own setting',
      (tester) async {
    _tall(tester);
    final container =
        await pumpSettings(tester, const HomeworkSettingsPage());

    await tester.tap(find.text('Nach Fach').at(0));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).classbookViewMode,
        ClassbookViewMode.bySubject);
    expect(container.read(settingsProvider).homeworkViewMode,
        ClassbookViewMode.chronological);

    await tester.tap(find.text('Nach Fach').at(1));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).homeworkViewMode,
        ClassbookViewMode.bySubject);
  });

  testWidgets('classbook, overview and absences display modes are separate',
      (tester) async {
    _tall(tester);
    final container =
        await pumpSettings(tester, const HomeworkSettingsPage());

    await tester.tap(find.text('Karten').at(0));
    await tester.pumpAndSettle();
    var s = container.read(settingsProvider);
    expect(s.classbookDisplayMode, EntryDisplayMode.cards);
    expect(s.homeworkDisplayMode, EntryDisplayMode.list);
    expect(s.absencesDisplayMode, EntryDisplayMode.list);

    await tester.tap(find.text('Karten').at(1));
    await tester.tap(find.text('Karten').at(2));
    await tester.pumpAndSettle();
    s = container.read(settingsProvider);
    expect(s.homeworkDisplayMode, EntryDisplayMode.cards);
    expect(s.absencesDisplayMode, EntryDisplayMode.cards);
  });

  testWidgets('the classbook timeline is only selectable by day',
      (tester) async {
    _tall(tester);
    final container = await pumpSettings(
      tester,
      const HomeworkSettingsPage(),
      settings: SettingsState(classbookViewMode: ClassbookViewMode.bySubject),
    );
    expect(find.text('Nur bei Anordnung nach Tagen'), findsOneWidget);

    await tester.tap(find.text('Zeitleiste'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).classbookDisplayMode,
        EntryDisplayMode.list);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    _tall(tester);
    await pumpSettings(tester, const HomeworkSettingsPage());

    await expectMeetsGuidelines(tester);
  });
}
