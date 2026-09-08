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

import 'package:dr/services/changelog.dart';
import 'package:dr/ui/changelog_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class _StubChangelog extends Changelog {
  final List<ChangelogEntry> entries;
  _StubChangelog(this.entries);
  @override
  Future<List<ChangelogEntry>> pending() async => entries;
}

ChangelogEntry _entry(String version, List<String> points) =>
    ChangelogEntry(version: version, points: points);

const _oneVersion = [
  ChangelogEntry(
    version: '1.2.1',
    points: [
      'Bewertungen: eigene Detailseite mit dem Kommentar zu jeder Kompetenz',
      'Bewertungen: Anzahl der Einträge und Durchschnitt je Fach',
      'Die App startet ohne Kontoabfrage im zuletzt genutzten Konto',
    ],
  ),
];

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    List<ChangelogEntry> entries, {
    Brightness brightness = Brightness.light,
  }) async {
    changelog = _StubChangelog(entries);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.deepOrange,
          brightness: brightness,
        ),
        home: const Scaffold(
          body: Column(children: [ChangelogCard()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() => changelog = Changelog());

  testWidgets('takes no room when there is nothing new', (tester) async {
    await pumpCard(tester, const []);
    expect(find.byType(Card), findsNothing);
    expect(tester.getSize(find.byType(ChangelogCard)), Size.zero);
  });

  testWidgets('names the version and lists what it brought', (tester) async {
    await pumpCard(tester, _oneVersion);
    expect(find.text('Neu in Version 1.2.1'), findsOneWidget);
    expect(
      find.text('Die App startet ohne Kontoabfrage im zuletzt genutzten Konto'),
      findsOneWidget,
    );
    expect(find.text('Alle Neuerungen'), findsOneWidget);
  });

  testWidgets('spells out the versions when several were skipped',
      (tester) async {
    // It cannot name one version, and "since 1.2.1" would be wrong — that one
    // is being shown, not already seen.
    await pumpCard(tester, [
      _entry('1.3.0', ['Kalender mit Uhrzeiten']),
      _entry('1.2.1', ['Detailseite für Bewertungen']),
    ]);
    expect(find.text('Neu seit deinem letzten Update'), findsOneWidget);
    expect(find.text('1.3.0'), findsOneWidget);
    expect(find.text('1.2.1'), findsOneWidget);
  });

  testWidgets('stops after two versions and three lines each', (tester) async {
    // Otherwise the card pushes the day list out of view.
    await pumpCard(tester, [
      _entry('1.4.0', ['a', 'b', 'c', 'd']),
      _entry('1.3.0', ['e']),
      _entry('1.2.1', ['f']),
    ]);
    expect(find.text('d'), findsNothing);
    expect(find.text('1.2.1'), findsNothing);
    expect(find.text('e'), findsOneWidget);
  });

  testWidgets('goes away when dismissed', (tester) async {
    await pumpCard(tester, _oneVersion);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
  });

  for (final (name, brightness) in [
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testGoldens('reads well in $name mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 260));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpCard(tester, _oneVersion, brightness: brightness);
      await expectLater(
        find.byType(ChangelogCard),
        matchesGoldenFile('card_$name.png'),
      );
    });
  }
}
