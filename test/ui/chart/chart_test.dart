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
import 'package:dr/container/grades_chart_container.dart';
import 'package:dr/container/grades_page_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/grades_chart.dart';
import 'package:dr/ui/grades_chart_page.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

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

class _TestSubjectAppearanceNotifier extends SubjectAppearanceNotifier {
  final SubjectAppearanceState initial;
  _TestSubjectAppearanceNotifier(this.initial);
  @override
  SubjectAppearanceState build() => initial;
}

Widget _wrapWithScope(Widget child, AppState appState,
        [SubjectAppearanceState? subjectAppearance]) =>
    ProviderScope(
      overrides: [
        gradesProvider
            .overrideWith(() => _TestGradesNotifier(appState.gradesState)),
        settingsProvider.overrideWith(
            () => _TestSettingsNotifier(SettingsState())),
        subjectAppearanceProvider.overrideWith(
          () => _TestSubjectAppearanceNotifier(
            subjectAppearance ?? const SubjectAppearanceState(),
          ),
        ),
      ],
      child: child,
    );

AppState get _gradesState {
  return AppState(
    (b) {
      b.gradesState
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
                ..observations = MapBuilder(),
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
                ..observations = MapBuilder(),
            ),
          ],
        )
        ..semester = Semester.first.toBuilder();
    },
  );
}

AppState get _starGradesState {
  return AppState(
    (b) {
      b.gradesState
        ..subjects = ListBuilder(
          <Subject>[
            Subject(
              (b) => b
                ..name = "KuTE"
                ..gradesAll = MapBuilder({
                  Semester.first: [
                    GradeAll(
                      (b) => b
                        ..weightPercentage = 100
                        ..cancelled = false
                        ..date = UtcDateTime(2021, 1, 4)
                        ..type = "Praktisches Arbeiten / Üben",
                    ),
                  ].toBuiltList(),
                })
                ..grades = MapBuilder({
                  Semester.first: [
                    GradeDetail(
                      (b) => b
                        ..id = 1
                        ..name = "Von der Bleistiftzeichnung zum Ölkreidebild"
                        ..created = "created"
                        ..date = UtcDateTime(2021, 1, 4)
                        ..type = "Praktisches Arbeiten / Üben"
                        ..weightPercentage = 100
                        ..cancelled = false
                        ..competences = ListBuilder([
                          Competence(
                            (b) => b
                              ..typeName = "Technik: Bastelmaterial"
                              ..grade = 5,
                          ),
                          Competence(
                            (b) => b
                              ..typeName = "Gestalten: Gestalterische Sorgfalt"
                              ..grade = 6,
                          ),
                        ]),
                    ),
                  ].toBuiltList(),
                })
                ..observations = MapBuilder({
                  Semester.first: <Observation>[].toBuiltList(),
                }),
            ),
          ],
        )
        ..semester = Semester.first.toBuilder();
    },
  );
}

SubjectAppearanceState get _gradesSettings => SubjectAppearanceState(
      themes: {
        "fach1": SubjectTheme(color: Colors.red.value, thick: 5),
        "fach2": SubjectTheme(color: Colors.green.value, thick: 4),
      },
    );

void main() {
  testGoldens(
    'grades chart interactions',
    (tester) async {
      final appState = _gradesState;
      final widget = _wrapWithScope(
        MaterialApp(
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale("de"),
          ],
          home: const Material(
            child: GradesChartContainer(
              isFullscreen: true,
            ),
          ),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
        appState,
        _gradesSettings,
      );

      await tester.pumpWidget(widget);
      expect(
        find.text("Tippe auf das Diagramm, um Details zu sehen"),
        findsOneWidget,
      );
      await expectLater(
        find.byType(GradesChartContainer),
        matchesGoldenFile("chart.png"),
      );
      await tester.tapAt(const Offset(750, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await expectLater(
        find.byType(GradesChartContainer),
        matchesGoldenFile("chart_animating_label1.png"),
      );
      await tester.pumpAndSettle();
      expect(find.text("Fach1 – Schularbeit3: 7+"), findsOneWidget);
      expect(find.text("4. Januar"), findsOneWidget);
      await expectLater(
        find.byType(GradesChartContainer),
        matchesGoldenFile("chart_label1.png"),
      );
      await tester.tapAt(const Offset(50, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await expectLater(
        find.byType(GradesChartContainer),
        matchesGoldenFile("chart_animating_label2.png"),
      );
      await tester.pumpAndSettle();
      expect(find.text("Fach2 – Test: 4"), findsOneWidget);
      expect(find.text("2. Januar"), findsOneWidget);
      await expectLater(
        find.byType(GradesChartContainer),
        matchesGoldenFile("chart_label2.png"),
      );
    },
  );
  testGoldens(
    'grades chart legend interactions',
    (tester) async {
      final appState = _gradesState;
      final widget = _wrapWithScope(
        MaterialApp(
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale("de"),
          ],
          home: const Material(
            child: GradesChartPage(),
          ),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
        appState,
        _gradesSettings,
      );

      await tester.pumpWidget(widget);
      expect(find.text("Legende"), findsOneWidget);
      await tester.tap(find.text("Legende"));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GradesChartPage),
        matchesGoldenFile("page_legend_open.png"),
      );
      await tester.tapAt(const Offset(510, 515));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(GradesChartPage),
        matchesGoldenFile("page_legend_tapped.png"),
      );
    },
  );
  testWidgets(
    'changing the thickness of a subject clears the selection',
    (tester) async {
      final appState = _gradesState;
      final widget = _wrapWithScope(
        MaterialApp(
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale("de"),
          ],
          home: const Material(
            child: GradesChartPage(),
          ),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
          ),
        ),
        appState,
        _gradesSettings,
      );

      await tester.pumpWidget(widget);
      expect(find.text("Tippe auf das Diagramm, um Details zu sehen"),
          findsOneWidget);
      // select an item in the diagram
      await tester.tapAt(const Offset(750, 200));
      await tester.pumpAndSettle();
      expect(find.text("Tippe auf das Diagramm, um Details zu sehen"),
          findsNothing);
      expect(find.text("Fach1 – Schularbeit3: 7+"), findsOneWidget);

      expect(find.text("4. Januar"), findsOneWidget);
      expect(find.text("Legende"), findsOneWidget);
      // open the legend
      await tester.tap(find.text("Legende"));
      await tester.pumpAndSettle();
      // increase the thickness of a subject
      await tester.tapAt(const Offset(510, 515));
      await tester.pumpAndSettle();
      expect(find.text("Tippe auf das Diagramm, um Details zu sehen"),
          findsOneWidget);
      expect(find.text("Fach1 – Schularbeit3: 7+"), findsNothing);

      expect(find.text("4. Januar"), findsNothing);
    },
  );

  test('star all-subjects average is formatted out of 6', () {
    final subjects = _starGradesState.gradesState.subjects;
    expect(
      calculateAllSubjectsAverage(
        subjects,
        Semester.first,
        const [],
        GradingMode.stars,
      ),
      '5,5/6',
    );
  });

  test('star chart selection text shows star values and competence lines', () {
    final text = formatChartSelectionText(
      'KuTE',
      GradeChartPoint(
        value: 5.5,
        type: 'Praktisches Arbeiten / Üben',
        mode: GradingMode.stars,
        competences: BuiltList([
          Competence(
            (b) => b
              ..typeName = 'Technik: Bastelmaterial'
              ..grade = 5,
          ),
          Competence(
            (b) => b
              ..typeName = 'Gestalten: Gestalterische Sorgfalt'
              ..grade = 6,
          ),
        ]),
      ),
    );

    expect(text, contains('KuTE – Praktisches Arbeiten / Üben: 5,5/6★'));
    expect(text, contains('Technik: Bastelmaterial: 5★'));
    expect(text, contains('Gestalten: Gestalterische Sorgfalt: 6★'));
  });
}
