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
import 'package:dr/ui/changelog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:intl/date_symbol_data_local.dart';

class _StubChangelog extends Changelog {
  final List<ChangelogEntry> entries;

  /// What the reader had seen before the installed version, as the real one
  /// would read it back from the preferences.
  final String? previous;

  _StubChangelog(this.entries, {this.previous});
  @override
  Future<List<ChangelogEntry>> load() async => entries;
  @override
  Future<String?> previousSeen() async => previous;
}

Future<void> main() async {
  setUpAll(() => initializeDateFormatting('de'));
  tearDown(() => changelog = Changelog());

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChangelogPage()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the versions with their dates', (tester) async {
    changelog = _StubChangelog(const [
      ChangelogEntry(
        version: '1.2.1',
        date: '2026-09-08',
        sections: [
          ChangelogSection(
            title: 'Neue Funktionen',
            items: ['Detailseite für Bewertungen'],
          ),
          ChangelogSection(
            title: 'Fehlerbehebungen',
            items: ['Sterne wieder in derselben Farbe'],
          ),
        ],
      ),
      ChangelogEntry(
        version: '1.2.0',
        date: '2026-07-11',
        sections: [
          ChangelogSection(
            title: 'Neue Funktionen',
            items: ['Demomodus in allen Versionen'],
          ),
        ],
      ),
    ]);
    await pumpPage(tester);

    expect(find.text('1.2.1'), findsOneWidget);
    expect(find.text('8. September 2026'), findsOneWidget);
    expect(find.text('Detailseite für Bewertungen'), findsOneWidget);
    expect(find.text('1.2.0'), findsOneWidget);
  });

  testWidgets('keeps the headings of a release', (tester) async {
    changelog = _StubChangelog(const [
      ChangelogEntry(
        version: '1.2.1',
        date: '2026-09-08',
        sections: [
          ChangelogSection(title: 'Neue Funktionen', items: ['Etwas Neues']),
          ChangelogSection(title: 'Fehlerbehebungen', items: ['Etwas Krummes']),
        ],
      ),
    ]);
    await pumpPage(tester);
    expect(find.text('Neue Funktionen'), findsOneWidget);
    expect(find.text('Fehlerbehebungen'), findsOneWidget);
    expect(find.text('Etwas Krummes'), findsOneWidget);
  });

  testWidgets('works without a version date', (tester) async {
    changelog = _StubChangelog(const [
      ChangelogEntry(
        version: '1.2.1',
        sections: [
          ChangelogSection(title: 'Neue Funktionen', items: ['Etwas Neues']),
        ],
      ),
    ]);
    await pumpPage(tester);
    expect(find.text('Etwas Neues'), findsOneWidget);
  });

  testWidgets('says so when the app ships no notes', (tester) async {
    // Nothing is fetched any more, so an empty list is the only empty case.
    changelog = _StubChangelog(const []);
    await pumpPage(tester);
    expect(find.text('Keine Einträge'), findsOneWidget);
  });

  testWidgets('shows the real history the app ships with', (tester) async {
    // The shipped file, not a stub. Which version is newest is read from it
    // rather than written here: a release would otherwise have to be entered
    // twice, and a longer release pushes any older heading out of the
    // viewport, where the list has not built it yet.
    final newest = (await Changelog().load()).first.version;
    await pumpPage(tester);
    expect(find.text(newest), findsOneWidget);
    expect(find.text('Keine Einträge'), findsNothing);
  });

  testWidgets('marks the releases that came with the update', (tester) async {
    changelog = _StubChangelog(
      const [
        ChangelogEntry(
          version: '1.3.0',
          sections: [
            ChangelogSection(title: 'Neue Funktionen', items: ['Klassenbuch']),
          ],
        ),
        ChangelogEntry(
          version: '1.2.1',
          sections: [
            ChangelogSection(title: 'Neue Funktionen', items: ['Merkheft']),
          ],
        ),
      ],
      previous: '1.2.1',
    );
    await pumpPage(tester);
    // One mark, and it belongs to the release above the one last seen.
    expect(find.text('(neu)'), findsOneWidget);
    final marked = tester.getTopLeft(find.text('(neu)'));
    expect(marked.dy, lessThan(tester.getTopLeft(find.text('1.2.1')).dy));
  });

  testWidgets('marks nothing when no earlier version is known', (tester) async {
    // A fresh install: none of the releases is news to this reader.
    changelog = _StubChangelog(const [
      ChangelogEntry(
        version: '1.3.0',
        sections: [
          ChangelogSection(title: 'Neue Funktionen', items: ['Klassenbuch']),
        ],
      ),
    ]);
    await pumpPage(tester);
    expect(find.text('(neu)'), findsNothing);
  });

  testGoldens('reads as a list of releases', (tester) async {
    // Fixed entries rather than the shipped file: the picture should not
    // change with every release.
    changelog = _StubChangelog(const [
      ChangelogEntry(
        version: '1.2.1',
        date: '2026-09-08',
        sections: [
          ChangelogSection(
            title: 'Neue Funktionen',
            items: [
              'Bewertungen: eigene Detailseite mit dem Kommentar zu jeder Kompetenz',
              'Farbe der Sterne in den Einstellungen wählbar',
            ],
          ),
          ChangelogSection(
            title: 'Fehlerbehebungen',
            items: [
              'Die Sterne im Merkheft und in den Bewertungen haben wieder dieselbe Farbe',
            ],
          ),
        ],
      ),
      ChangelogEntry(
        version: '1.2.0',
        date: '2026-07-11',
        sections: [
          ChangelogSection(
            title: 'Neue Funktionen',
            items: ['Demomodus in allen Versionen'],
          ),
        ],
      ),
    ]);
    await pumpPage(tester);
    await expectLater(
      find.byType(ChangelogPage),
      matchesGoldenFile('page.png'),
    );
  });
}
