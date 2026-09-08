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
import 'package:dr/data.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/grade_detail_page.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

const _subjectId = 7;
const _gradeId = 42;

class _TestGradesNotifier extends GradesNotifier {
  final GradesState initial;
  _TestGradesNotifier(this.initial);
  @override
  GradesState build() => initial;

  /// The page asks for the grade as soon as it opens; nothing to fetch here.
  @override
  Future<void> loadGradeDetail(GradeDetail grade, Semester semester) async {}
}

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => SettingsState();
}

Competence _competence(String name, int grade, {String? description}) =>
    Competence(
      (b) => b
        ..typeName = name
        ..grade = grade
        ..description = description,
    );

GradeDetail _grade({
  bool cancelled = false,
  String? cancelledDescription,
  String? description,
  String? visibleAtFormatted,
  List<Competence> competences = const [],
}) {
  return GradeDetail(
    (b) => b
      ..id = _gradeId
      ..name = "Lernkontrolle: Subtrahieren bis 20"
      ..type = "Praktisches Arbeiten"
      ..created = "Von Anna Musterfrau am 31.05.2026 eingetragen"
      ..weightPercentage = 100
      ..cancelled = cancelled
      ..cancelledDescription = cancelledDescription
      ..description = description
      ..visibleAtFormatted = visibleAtFormatted
      ..grade = 7 * 100
      ..date = UtcDateTime(2026, 5, 29)
      ..competences = ListBuilder(competences),
  );
}

GradesState _state({GradeDetail? grade}) {
  return GradesState(
    (b) => b
      ..semester = Semester.first.toBuilder()
      ..subjects = ListBuilder([
        Subject(
          (b) => b
            ..id = _subjectId
            ..name = "Mathematik"
            ..gradesAll = MapBuilder()
            ..grades = MapBuilder({
              Semester.first:
                  BuiltList<GradeDetail>([if (grade != null) grade]),
            })
            ..observations = MapBuilder({
              Semester.first: BuiltList<Observation>(),
            }),
        ),
      ]),
  );
}

void main() {
  Future<void> pumpPage(WidgetTester tester, GradesState state) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gradesProvider.overrideWith(() => _TestGradesNotifier(state)),
          settingsProvider.overrideWith(_TestSettingsNotifier.new),
        ],
        child: const MaterialApp(
          home: GradeDetailPage(
            args: GradeDetailArgs(subjectId: _subjectId, gradeId: _gradeId),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names the subject and the grade', (tester) async {
    await pumpPage(tester, _state(grade: _grade()));
    expect(find.text("Mathematik"), findsOneWidget);
    expect(find.text("Lernkontrolle: Subtrahieren bis 20"), findsOneWidget);
    expect(find.text("7"), findsOneWidget);
    expect(find.textContaining("29.05.2026"), findsOneWidget);
  });

  testWidgets('shows the comment on the grade', (tester) async {
    await pumpPage(
      tester,
      _state(grade: _grade(description: "Sicher gelöst.")),
    );
    expect(find.text("Kommentar"), findsOneWidget);
    expect(find.text("Sicher gelöst."), findsOneWidget);
  });

  testWidgets('leaves out the comment section when there is none',
      (tester) async {
    await pumpPage(tester, _state(grade: _grade(description: "")));
    expect(find.text("Kommentar"), findsNothing);
  });

  testWidgets('shows every competence with its own comment', (tester) async {
    // This is what the list could not show, and the reason for this page.
    await pumpPage(
      tester,
      _state(
        grade: _grade(
          competences: [
            _competence("Subtraktion im ZR 10", 6,
                description: "Sicher und selbstständig."),
            _competence("Subtraktion im ZR 20", 5,
                description: "Gut entwickelt."),
          ],
        ),
      ),
    );
    expect(find.text("Kompetenzen"), findsOneWidget);
    expect(find.text("Subtraktion im ZR 10"), findsOneWidget);
    expect(find.text("Sicher und selbstständig."), findsOneWidget);
    expect(find.text("Subtraktion im ZR 20"), findsOneWidget);
    expect(find.text("Gut entwickelt."), findsOneWidget);
    // Six stars per competence.
    expect(find.byIcon(Icons.star), findsNWidgets(6 + 5));
  });

  testWidgets('shows a competence without a comment too', (tester) async {
    await pumpPage(
      tester,
      _state(grade: _grade(competences: [_competence("Lesefertigkeit", 4)])),
    );
    expect(find.text("Lesefertigkeit"), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
  });

  testWidgets('shows who entered it and from when it was visible',
      (tester) async {
    await pumpPage(
      tester,
      _state(
        grade: _grade(
          visibleAtFormatted: "Bewertung sichtbar ab Montag, 02.02.2026 17:00",
        ),
      ),
    );
    expect(
      find.text("Von Anna Musterfrau am 31.05.2026 eingetragen"),
      findsOneWidget,
    );
    expect(
      find.text("Bewertung sichtbar ab Montag, 02.02.2026 17:00"),
      findsOneWidget,
    );
  });

  testWidgets('explains a deleted grade', (tester) async {
    await pumpPage(
      tester,
      _state(
        grade: _grade(
          cancelled: true,
          cancelledDescription: "Am 04.06.2026 ersetzt",
        ),
      ),
    );
    expect(find.text("Gelöscht"), findsOneWidget);
    expect(find.text("Am 04.06.2026 ersetzt"), findsOneWidget);
  });

  group('the whole page', () {
    GradesState full() => _state(
          grade: _grade(
            description: "Subtraktionsaufgaben bis 20 werden mit sicherer "
                "Strategie gelöst.",
            visibleAtFormatted:
                "Bewertung sichtbar ab Montag, 02.02.2026 17:00",
            competences: [
              _competence("Subtraktion im ZR 10", 6,
                  description: "Sicher und selbstständig angewendet."),
              _competence("Subtraktion im ZR 20", 5,
                  description: "Gut entwickelt, wird flüssig eingesetzt."),
              _competence("Rechenwege erklären", 4),
            ],
          ),
        );

    for (final (name, brightness) in [
      ("light", Brightness.light),
      ("dark", Brightness.dark),
    ]) {
      testGoldens('reads well in $name mode', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gradesProvider.overrideWith(() => _TestGradesNotifier(full())),
              settingsProvider.overrideWith(_TestSettingsNotifier.new),
            ],
            child: MaterialApp(
              theme: ThemeData(
                colorSchemeSeed: Colors.deepOrange,
                brightness: brightness,
              ),
              home: const GradeDetailPage(
                args: GradeDetailArgs(subjectId: _subjectId, gradeId: _gradeId),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(GradeDetailPage),
          matchesGoldenFile("grade_detail_$name.png"),
        );
      });
    }
  });

  testWidgets('says so when the grade is gone', (tester) async {
    // A semester switch or a refresh can take it away while the page is open.
    await pumpPage(tester, _state());
    expect(
      find.text("Diese Bewertung ist nicht mehr verfügbar"),
      findsOneWidget,
    );
  });
}
