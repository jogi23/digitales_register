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

import 'package:dr/ui/settings/blocks/grades_block.dart';
import 'package:dr/ui/settings/pages/content_settings_page.dart';
import 'package:dr/ui/settings/widgets/settings_expandable_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../settings_pump.dart';

const _titles = [
  'Fächer & Kalender',
  'Merkheft',
  'Klassenbuch',
  'Hausaufgaben',
  'Absenzen',
  'Noten',
];

void main() {
  testWidgets('lists the six blocks, all closed, each with a summary',
      (tester) async {
    await pumpSettings(tester, const ContentSettingsPage());

    final sections = find.byType(SettingsExpandableSection);
    expect(sections, findsNWidgets(6));
    for (final title in _titles) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Kürzel, Farben, Kalender'), findsOneWidget);
    expect(find.text('Diagramm, Durchschnitt, Sterne'), findsOneWidget);
    expect(find.byType(GradesBlock), findsNothing);
  });

  testWidgets('opening a block shows its settings', (tester) async {
    await pumpSettings(tester, const ContentSettingsPage());

    await tester.tap(find.text('Noten'));
    await tester.pumpAndSettle();

    expect(find.byType(GradesBlock), findsOneWidget);
    expect(find.text('Durchschnitt je Fach anzeigen'), findsOneWidget);
  });

  testWidgets('initiallyExpanded opens only the asked-for block',
      (tester) async {
    await pumpSettings(
      tester,
      const ContentSettingsPage(initiallyExpanded: {ContentBlock.grades}),
    );

    expect(find.byType(GradesBlock), findsOneWidget);
    expect(find.text('Uhrzeiten im Kalender anzeigen'), findsNothing);
  });

  testWidgets('"Beim Löschen fragen" is in the Merkheft block', (tester) async {
    await pumpSettings(
      tester,
      const ContentSettingsPage(initiallyExpanded: {ContentBlock.merkheft}),
    );

    expect(find.text('Beim Löschen von Erinnerungen fragen'), findsOneWidget);
  });

  testWidgets('meets tap target guidelines', (tester) async {
    await pumpSettings(tester, const ContentSettingsPage());

    await expectMeetsGuidelines(tester);
  });

  testWidgets('no two blocks share a title in any language', (tester) async {
    for (final locale in const [Locale('de'), Locale('en'), Locale('it')]) {
      await pumpSettings(tester, const ContentSettingsPage(), locale: locale);

      final titles = [
        for (final section in tester.widgetList<SettingsExpandableSection>(
          find.byType(SettingsExpandableSection),
        ))
          section.title,
      ];
      expect(titles.toSet(), hasLength(titles.length), reason: '$locale');
    }
  });

  testWidgets('a block the user opened stays open after scrolling away',
      (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSettings(tester, const ContentSettingsPage());

    await tester.tap(find.text('Merkheft'));
    await tester.pumpAndSettle();
    // Merkheft is tall: Noten starts out of reach until it is scrolled to.
    await tester.scrollUntilVisible(find.text('Noten'), 300);
    await tester.tap(find.text('Noten'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Neue oder geänderte Einträge markieren'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 6000));
    await tester.pumpAndSettle();

    expect(find.text('Neue oder geänderte Einträge markieren'), findsOneWidget);
  });

  testWidgets('the deep link scrolls the asked-for block into view',
      (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSettings(
      tester,
      const ContentSettingsPage(initiallyExpanded: {ContentBlock.grades}),
    );

    expect(tester.getTopLeft(find.text('Noten')).dy, lessThan(300));
  });

  testWidgets('all blocks open at text scale 2.0 do not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpSettings(
      tester,
      const ContentSettingsPage(initiallyExpanded: {...ContentBlock.values}),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
