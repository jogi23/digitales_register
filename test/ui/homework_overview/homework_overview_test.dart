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
import 'package:dr/ui/homework_overview_page.dart';
import 'package:dr/ui/lesson_entry_list.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

HomeworkExam _aufgabe(
  String name, {
  required UtcDateTime faellig,
  String art = ordinaryHomeworkType,
  bool istHausaufgabe = true,
}) =>
    HomeworkExam(
      (b) => b
        ..id = name.hashCode
        ..name = name
        ..homework = istHausaufgabe
        ..online = false
        ..deadline = faellig
        ..hasGrades = false
        ..hasGradeGroupSubmissions = false
        ..typeId = 55
        ..typeName = art
        ..warning = !istHausaufgabe,
    );

CalendarHour _stunde({
  required int fromHour,
  required String subject,
  List<HomeworkExam> aufgaben = const [],
  List<String> inhalte = const [],
}) =>
    CalendarHour(
      (b) => b
        ..fromHour = fromHour
        ..toHour = fromHour
        ..subject = subject
        ..rooms = ListBuilder<String>()
        ..timeSpans = ListBuilder<TimeSpan>()
        ..teachers = ListBuilder<Teacher>([
          Teacher((t) => t
            ..firstName = 'Anna'
            ..lastName = 'Musterfrau'),
        ])
        ..homeworkExams = ListBuilder<HomeworkExam>(aufgaben)
        ..lessonContents = ListBuilder<LessonContent>([
          for (final name in inhalte)
            LessonContent((c) => c
              ..name = name
              ..typeName = 'Fachunterricht'
              ..submissions = ListBuilder<LessonContentSubmission>()),
        ]),
    );

final _montag = UtcDateTime(2026, 5, 11);
final _dienstag = UtcDateTime(2026, 5, 12);

List<CalendarDay> _tage() => [
      CalendarDay((b) => b
        ..date = _montag
        ..hours = ListBuilder<CalendarHour>([
          _stunde(
            fromHour: 1,
            subject: 'Deutsch',
            aufgaben: [_aufgabe('Lesetext Seite 12', faellig: _montag)],
            // Unterrichtsinhalte gehören ins Klassenbuch, nicht hierher.
            inhalte: const ['Silbenlesen'],
          ),
          _stunde(fromHour: 2, subject: 'Mathematik'),
        ])),
      CalendarDay((b) => b
        ..date = _dienstag
        ..hours = ListBuilder<CalendarHour>([
          _stunde(
            fromHour: 1,
            subject: 'Deutsch',
            aufgaben: [_aufgabe('Diktat üben', faellig: _dienstag)],
          ),
          _stunde(
            fromHour: 3,
            subject: 'Musik',
            aufgaben: [
              _aufgabe(
                'Notenlehre',
                faellig: _dienstag,
                art: 'Mündliche Prüfung',
                istHausaufgabe: false,
              ),
            ],
          ),
        ])),
    ];

Widget _seite(List<LessonEntry> entries) => MaterialApp(
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: LessonEntryList(
          entries: entries,
          viewMode: ClassbookViewMode.chronological,
          selectedSubjects: const [],
          onSelectedSubjectsChanged: (_) {},
          subjectLabel: (s) => s,
          loadingText: 'wird geladen',
          emptyText: 'nichts aufgegeben',
          ordinaryType: ordinaryHomeworkType,
        ),
      ),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('de'));

  group('flattening the calendar', () {
    test('takes the assignments, newest lesson first', () {
      final entries = homeworkEntries(_tage());
      expect(entries.map((e) => e.title),
          ['Diktat üben', 'Notenlehre', 'Lesetext Seite 12']);
    });

    test('leaves the lesson contents to the classbook', () {
      // Beide Seiten ziehen aus derselben Stunde, aber aus anderen Listen.
      final entries = homeworkEntries(_tage());
      expect(entries.any((e) => e.title == 'Silbenlesen'), isFalse);
    });

    test('leaves out lessons without an assignment', () {
      expect(homeworkEntries(_tage()).any((e) => e.subject == 'Mathematik'),
          isFalse);
    });

    test('keeps subject, hour and teacher with each assignment', () {
      final entry = homeworkEntries(_tage()).last;
      expect(entry.subject, 'Deutsch');
      expect(entry.fromHour, 1);
      expect(entry.teachers, ['Anna Musterfrau']);
      expect(entry.date, _montag);
    });
  });

  group('showing them', () {
    testWidgets('groups the assignments by day', (tester) async {
      await tester.pumpWidget(_seite(homeworkEntries(_tage())));
      await tester.pumpAndSettle();

      expect(find.textContaining('12. Mai 2026'), findsOneWidget);
      expect(find.textContaining('11. Mai 2026'), findsOneWidget);
      expect(find.text('Lesetext Seite 12'), findsOneWidget);
    });

    testWidgets('names an exam but not an ordinary assignment', (tester) async {
      // Von 74 Einträgen der Aufzeichnung tragen 62 "Hausaufgabe" — sie an
      // jeder Zeile zu nennen wäre Rauschen. Eine Prüfung ist die Ausnahme
      // und gehört genannt.
      await tester.pumpWidget(_seite(homeworkEntries(_tage())));
      await tester.pumpAndSettle();

      expect(find.textContaining('Mündliche Prüfung'), findsOneWidget);
      expect(find.textContaining(ordinaryHomeworkType), findsNothing);
    });

    testWidgets('says so when nothing is assigned', (tester) async {
      await tester.pumpWidget(_seite(const []));
      expect(find.text('nichts aufgegeben'), findsOneWidget);
    });
  });
}
