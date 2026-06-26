// Copyright (C) 2021 Michael Debertol
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
import 'package:dr/container/grades_page_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/sorted_grades_widget.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../fixtures/api_fixtures.dart';

class _TestGradesNotifier extends GradesNotifier {
  final GradesState initial;
  _TestGradesNotifier(this.initial);
  @override
  GradesState build() => initial;
  @override
  Future<void> loadDetails(Subject subject, Semester semester) async {}
  @override
  Future<void> load(Semester semester) async {}
}

class _TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;
  _TestSettingsNotifier(this.initial);
  @override
  SettingsState build() => initial;
}

Widget _wrapWithScope(Widget child, AppState appState,
        [SettingsState? settings]) =>
    ProviderScope(
      overrides: [
        gradesProvider.overrideWith(
            () => _TestGradesNotifier(appState.gradesState)),
        settingsProvider.overrideWith(
            () => _TestSettingsNotifier(settings ?? SettingsState())),
      ],
      child: child,
    );

AppState _getGradesState({bool loading = false}) {
  return AppState(
    (b) {
      b.gradesState
        ..loading = loading
        ..subjects = ListBuilder(
          <Subject>[
            Subject(
              (b) => b
                ..name = "Fach1"
                ..grades = MapBuilder()
                ..gradesAll = MapBuilder(
                  {
                    Semester.first: [
                      GradeAll(
                        (b) => b
                          ..weightPercentage = 100
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 2)
                          ..grade = 7 * 100 + 75 // 8-
                          ..type = "Schularbeit1",
                      ),
                      GradeAll(
                        (b) => b
                          ..weightPercentage = 100
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 3)
                          ..grade = 7 * 100 + 50 // 7/8
                          ..type = "Schularbeit2",
                      ),
                      GradeAll(
                        (b) => b
                          ..weightPercentage = 100
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 4)
                          ..grade = 7 * 100 + 25 // 7+
                          ..type = "Schularbeit3",
                      ),
                    ].toBuiltList(),
                  },
                )
                ..grades = MapBuilder(
                  {
                    Semester.first: [
                      GradeDetail(
                        (b) => b
                          ..name = "Erste Schularbeit"
                          ..id = 0
                          ..weightPercentage = 100
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 2)
                          ..created = "am 3. 2. erstellt"
                          ..grade = 7 * 100 + 75 // 8-
                          ..type = "Schularbeit1",
                      ),
                      GradeDetail(
                        (b) => b
                          ..name = "Zweite Schularbeit"
                          ..id = 1
                          ..weightPercentage = 100
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 3)
                          ..created = "am 4. 2. erstellt"
                          ..grade = 7 * 100 + 50 // 7/8
                          ..type = "Schularbeit2",
                      ),
                      GradeDetail(
                        (b) => b
                          ..name = "Dritte Schularbeit"
                          ..id = 2
                          ..weightPercentage = 100
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 4)
                          ..created = "am 5. 2. erstellt"
                          ..grade = 7 * 100 + 25 // 7+
                          ..type = "Schularbeit3"
                          ..competences = ListBuilder(
                            <Competence>[
                              Competence(
                                (b) => b
                                  ..grade = 3
                                  ..typeName = "Kompetenz1",
                              ),
                            ],
                          ),
                      ),
                    ].toBuiltList(),
                  },
                )
                ..observations = MapBuilder({
                  Semester.first: <Observation>[
                    Observation(
                      (b) => b
                        ..typeName = "Beobachtung"
                        ..created = "Am 3. März 2021"
                        ..note = "Notiz blabla bla"
                        ..cancelled = false
                        ..date = UtcDateTime(2021, 2, 21),
                    )
                  ].toBuiltList()
                }),
            ),
            Subject(
              (b) => b
                ..name = "Fach2"
                ..grades = MapBuilder()
                ..gradesAll = MapBuilder(
                  {
                    Semester.first: [
                      GradeAll(
                        (b) => b
                          ..weightPercentage = 25
                          ..cancelled = false
                          ..date = UtcDateTime(2021, 1, 2)
                          ..grade = 4 * 100
                          ..type = "Test",
                      ),
                    ].toBuiltList(),
                  },
                )
                ..observations =
                    MapBuilder({Semester.first: <Observation>[].toBuiltList()}),
            ),
          ],
        )
        ..semester = Semester.first.toBuilder();
    },
  );
}

SettingsState get _gradesSettings => SettingsState(
      subjectThemes: {
        "Fach1": SubjectTheme(color: Colors.red.value, thick: 5),
        "Fach2": SubjectTheme(color: Colors.green.value, thick: 4),
      },
    );

// ---------------------------------------------------------------------------
// Demo data: Deutsch (id=84) grades from KW 2026-05-11 built from fixture data.
// All grades have grade=null (competence-based school), 1 competence each.
// ---------------------------------------------------------------------------

GradeDetail _deutschGrade({
  required int id,
  required UtcDateTime date,
  required String name,
  required String typeName,
  required String created,
  required String competenceTypeName,
  required int competenceGrade,
  String? description,
}) =>
    GradeDetail(
      (b) => b
        ..id = id
        ..date = date
        ..name = name
        ..weightPercentage = 100
        ..cancelled = false
        ..type = typeName
        ..created = created
        ..description = description
        ..competences = ListBuilder([
          Competence(
            (b) => b
              ..typeName = competenceTypeName
              ..grade = competenceGrade,
          ),
        ]),
    );

late GradesState _demoGradesState;

void main() {
  setUpAll(() async {
    await loadFixtures();
    // Three Deutsch grades from the 2026-05-11 week (from subject_detail id=84).
    final grades = [
      _deutschGrade(
        id: 46434,
        date: UtcDateTime(2026, 5, 13),
        name: 'Heftübung: Buchstaben sauber nachspuren',
        typeName: 'h Praktisches Arbeiten / Üben',
        created: 'Von Christine Testfrau am 14.05.2026 eingetragen',
        competenceTypeName: 'Schreiben: Sätze schreiben',
        competenceGrade: 5,
        description:
            'Die Übungen sind vollständig, sauber und weitgehend fehlerfrei.',
      ),
      _deutschGrade(
        id: 19116,
        date: UtcDateTime(2026, 5, 19),
        name: 'Buchstabendiktat: Mitlaute und Lernwörter',
        typeName: 'f Schriftliche Lernzielkontrolle',
        created: 'Von Christine Testfrau am 21.05.2026 eingetragen',
        competenceTypeName: 'Schreiben: geübte Wörter richtig schreiben',
        competenceGrade: 5,
      ),
      _deutschGrade(
        id: 85674,
        date: UtcDateTime(2026, 5, 20),
        name: 'Buchstabe Jj: Lesen auf Silben- und Wortebene',
        typeName: 'g Mündliche Prüfung',
        created: 'Von Christine Testfrau am 21.05.2026 eingetragen',
        competenceTypeName: 'Lesefertigkeit',
        competenceGrade: 6,
      ),
    ];
    _demoGradesState = GradesState(
      (b) => b
        ..loading = false
        ..subjects = ListBuilder([
          Subject(
            (b) => b
              ..id = 84
              ..name = 'Deutsch'
              ..gradesAll = MapBuilder({
                Semester.first: <GradeAll>[].toBuiltList(),
              })
              ..grades = MapBuilder({
                Semester.first: grades.toBuiltList(),
              })
              ..observations = MapBuilder({
                Semester.first: <Observation>[].toBuiltList(),
              }),
          ),
        ])
        ..semester = Semester.first.toBuilder(),
    );
  });

  testGoldens('grades page loading when empty', (tester) async {
    final appState = AppState((b) => b.gradesState.loading = true);
    final widget = _wrapWithScope(
      MaterialApp(
        home: const GradesPageContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
      appState,
      _gradesSettings,
    );
    await tester.pumpWidget(widget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await expectLater(
      find.byType(GradesPageContainer),
      matchesGoldenFile("loading_empty.png"),
    );
  });
  testGoldens('grades page loading when not empty', (tester) async {
    final appState = _getGradesState(loading: true);
    final widget = _wrapWithScope(
      MaterialApp(
        home: const GradesPageContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
      appState,
      _gradesSettings,
    );
    await tester.pumpWidget(widget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // The linear progress indicator will still be animating in.
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(GradesPageContainer),
      matchesGoldenFile("loading_not_empty.png"),
    );
  });
  testGoldens('grades page interactions', (tester) async {
    final appState = _getGradesState();
    final widget = _wrapWithScope(
      MaterialApp(
        home: const GradesPageContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
      appState,
      _gradesSettings,
    );
    await tester.pumpWidget(widget);
    expect(find.text("Dritte Schularbeit"), findsNothing);
    await tester.tap(find.text("Fach1"));
    await tester.pumpAndSettle();
    expect(find.text("Dritte Schularbeit"), findsOneWidget);
    await expectLater(
      find.byType(GradesPageContainer),
      matchesGoldenFile("open_unsorted.png"),
    );
    await tester.tap(find.text("Noten nach Art sortieren"));
    await tester.pumpAndSettle();

    expect(
      find.byType(GradeTypeWidget),
      findsNWidgets(4),
    );
    await expectLater(
      find.byType(GradesPageContainer),
      matchesGoldenFile("open_sorted.png"),
    );
  });
  testWidgets('competences', (tester) async {
    final appState = _getGradesState();
    final widget = _wrapWithScope(
      MaterialApp(
        home: const GradesPageContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
      appState,
      _gradesSettings,
    );
    await tester.pumpWidget(widget);
    await tester.tap(find.text("Fach1"));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(find.byIcon(Icons.star_border), findsNWidgets(3));
  });

  group('demo data Deutsch KW 2026-05-11', () {
    Widget buildDemo() => _wrapWithScope(
          MaterialApp(
            home: const GradesPageContainer(),
            theme: ThemeData(primarySwatch: Colors.deepOrange),
          ),
          AppState((b) => b.gradesState.replace(_demoGradesState)),
        );

    testWidgets('shows subject Deutsch in overview', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.pump();
      expect(find.text('Deutsch'), findsOneWidget);
    });

    testWidgets('grades hidden before expanding', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.pump();
      expect(find.textContaining('Buchstaben sauber nachspuren'), findsNothing);
    });

    testWidgets('shows grade names after expanding Deutsch', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Buchstaben sauber nachspuren'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Buchstabendiktat: Mitlaute'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Buchstabe Jj'),
        findsOneWidget,
      );
    });

    testWidgets('shows typeName in grade subtitle', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Praktisches Arbeiten'), findsOneWidget);
    });

    testWidgets('shows competence stars after expanding', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      // 3 grades: 5+5+6 filled stars, 1+1+0 empty stars = 16 filled, 2 empty
      expect(find.byIcon(Icons.star), findsNWidgets(16));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('shows competence type name', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(find.text('Schreiben: Sätze schreiben'), findsOneWidget);
      expect(find.text('Lesefertigkeit'), findsOneWidget);
    });

    testGoldens('demo overview golden', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.pump();
      await expectLater(
        find.byType(GradesPageContainer),
        matchesGoldenFile('demo_overview.png'),
      );
    });

    testGoldens('demo expanded Deutsch golden', (tester) async {
      await tester.pumpWidget(buildDemo());
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GradesPageContainer),
        matchesGoldenFile('demo_expanded.png'),
      );
    });
  });
}
