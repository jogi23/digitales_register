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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/settings/blocks/grades_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

const _exclude = 'Fächer aus dem Notendurchschnitt ausschließen';

void main() {
  testWidgets('the grade switches write their settings', (tester) async {
    useTallWindow(tester);
    final container =
        await pumpSettings(tester, blockHost([const GradesBlock()]));

    final fields = <String, bool Function(SettingsState)>{
      'Noten in einem Diagramm darstellen': (s) => s.showGradesDiagram,
      'Durchschnitt aller Fächer anzeigen': (s) => s.showAllSubjectsAverage,
      'Durchschnitt je Fach anzeigen': (s) => s.showSubjectAverage,
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

  testWidgets('picking a star colour writes the setting', (tester) async {
    useTallWindow(tester);
    final container =
        await pumpSettings(tester, blockHost([const GradesBlock()]));
    expect(container.read(settingsProvider).starColor, accentStarColorId);

    await tester.tap(find.text('Farbe der Sterne'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Gelb'),
    ));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).starColor, 'amber');
  });

  testWidgets('the display mode writes the grades setting', (tester) async {
    useTallWindow(tester);
    final container =
        await pumpSettings(tester, blockHost([const GradesBlock()]));

    await tester.tap(find.text('Karten'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).gradesDisplayMode,
        EntryDisplayMode.cards);
  });

  group('grades average ignore-list', () {
    testWidgets('adds an item, also with no known subject to suggest',
        (tester) async {
      useTallWindow(tester);
      final container =
          await pumpSettings(tester, blockHost([const GradesBlock()]));
      await tester.tap(find.descendant(
        of: find.ancestor(
          of: find.text(_exclude),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.add),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(InfoDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.testTextInput.enterText('Fach1');
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).ignoreForGradesAverage,
          <String>[].toBuiltList());
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).ignoreForGradesAverage,
          ['Fach1'].toBuiltList());
    });

    testWidgets('removes an item and shows the empty hint after the last',
        (tester) async {
      useTallWindow(tester);
      final container = await pumpSettings(
        tester,
        blockHost([const GradesBlock()]),
        settings: SettingsState(ignoreForGradesAverage: ['Fach1']),
      );
      // Both halves of the cross-fade are built; the list is the shown one.
      expect(
        tester
            .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
            .crossFadeState,
        CrossFadeState.showSecond,
      );

      await tester.tap(find.descendant(
        of: find.ancestor(
          of: find.text('Fach1'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).ignoreForGradesAverage,
          <String>[].toBuiltList());
      expect(
        tester
            .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
            .crossFadeState,
        CrossFadeState.showFirst,
      );
    });

    testWidgets('removing two subjects in quick succession removes both',
        (tester) async {
      useTallWindow(tester);
      final container = await pumpSettings(
        tester,
        blockHost([const GradesBlock()]),
        settings: SettingsState(ignoreForGradesAverage: ['A', 'B', 'C']),
      );
      Finder closeOf(String subject) => find.descendant(
            of: find.ancestor(
              of: find.text(subject),
              matching: find.byType(ListTile),
            ),
            matching: find.byIcon(Icons.close),
          );

      await tester.tap(closeOf('A'));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(closeOf('B'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).ignoreForGradesAverage,
          ['C'].toBuiltList());
    });

    testWidgets('adding a subject that is already excluded changes nothing',
        (tester) async {
      useTallWindow(tester);
      final container = await pumpSettings(
        tester,
        blockHost([const GradesBlock()]),
        settings: SettingsState(ignoreForGradesAverage: ['Fach1']),
      );
      await tester.tap(find.byTooltip('Fach hinzufügen'));
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('Fach1');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).ignoreForGradesAverage,
          ['Fach1'].toBuiltList());
    });

    testWidgets('adding writes onto the list as it is when the dialog closes',
        (tester) async {
      useTallWindow(tester);
      final container = await pumpSettings(
        tester,
        blockHost([const GradesBlock()]),
        settings: SettingsState(ignoreForGradesAverage: ['A']),
      );
      await tester.tap(find.byTooltip('Fach hinzufügen'));
      await tester.pumpAndSettle();
      // Changed while the dialog is open.
      container
          .read(settingsProvider.notifier)
          .setIgnoreForGradesAverage(['A', 'B']);
      tester.testTextInput.enterText('C');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).ignoreForGradesAverage,
          ['A', 'B', 'C'].toBuiltList());
    });

    testWidgets('each remove button names its subject', (tester) async {
      useTallWindow(tester);
      await pumpSettings(
        tester,
        blockHost([const GradesBlock()]),
        settings: SettingsState(ignoreForGradesAverage: ['A', 'B']),
      );

      expect(find.byTooltip('A entfernen'), findsOneWidget);
      expect(find.byTooltip('B entfernen'), findsOneWidget);
    });

    testWidgets('the empty hint is not a hardcoded grey', (tester) async {
      useTallWindow(tester);
      await pumpSettings(tester, blockHost([const GradesBlock()]));

      final text = tester.widget<Text>(find.text('Kein Fach ausgeschlossen'));
      final context = tester.element(find.text('Kein Fach ausgeschlossen'));
      expect(text.style?.color, Theme.of(context).colorScheme.onSurfaceVariant);
    });
  });

  testWidgets('meets tap target guidelines', (tester) async {
    useTallWindow(tester);
    await pumpSettings(tester, blockHost([const GradesBlock()]));

    await expectMeetsGuidelines(tester);
  });
}
