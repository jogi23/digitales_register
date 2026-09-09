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
import 'package:dr/ui/classbook_page.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

CalendarHour _hour({
  required int fromHour,
  required String subject,
  List<String> contents = const [],
  String teacher = 'Musterfrau',
}) =>
    CalendarHour(
      (b) => b
        ..fromHour = fromHour
        ..toHour = fromHour
        ..subject = subject
        ..rooms = ListBuilder<String>()
        ..timeSpans = ListBuilder<TimeSpan>()
        ..homeworkExams = ListBuilder<HomeworkExam>()
        ..teachers = ListBuilder<Teacher>([
          Teacher((t) => t
            ..firstName = 'Anna'
            ..lastName = teacher),
        ])
        ..lessonContents = ListBuilder<LessonContent>([
          for (final name in contents)
            LessonContent((c) => c
              ..name = name
              ..typeName = 'Fachunterricht'
              ..submissions = ListBuilder<LessonContentSubmission>()),
        ]),
    );

CalendarDay _day(UtcDateTime date, List<CalendarHour> hours) => CalendarDay(
      (b) => b
        ..date = date
        ..hours = ListBuilder<CalendarHour>(hours),
    );

final _montag = UtcDateTime(2026, 5, 11);
final _dienstag = UtcDateTime(2026, 5, 12);

/// Two days, three lessons, four entries — one lesson deliberately empty.
List<CalendarDay> _tage() => [
      _day(_montag, [
        _hour(fromHour: 1, subject: 'Deutsch', contents: ['Silbenlesen']),
        _hour(fromHour: 2, subject: 'Mathematik', contents: const []),
      ]),
      _day(_dienstag, [
        _hour(
          fromHour: 1,
          subject: 'Deutsch',
          contents: ['Diktat', 'Leseübung'],
        ),
        _hour(fromHour: 3, subject: 'Musik', contents: ['Notenlehre']),
      ]),
    ];

Widget _seite(
  List<ClassbookEntry> entries, {
  ClassbookViewMode mode = ClassbookViewMode.chronological,
  bool loading = false,
}) =>
    MaterialApp(
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: ClassbookPage(
          entries: entries,
          viewMode: mode,
          loading: loading,
        ),
      ),
    );

void main() {
  setUpAll(() async => initializeDateFormatting('de'));

  group('flattening the calendar', () {
    test('takes every lesson content, newest lesson first', () {
      final entries = classbookEntries(_tage());
      expect(entries, hasLength(4));
      // Neuester Tag zuerst, innerhalb des Tages nach der Stunde.
      expect(entries.map((e) => e.content.name),
          ['Diktat', 'Leseübung', 'Notenlehre', 'Silbenlesen']);
    });

    test('leaves out lessons without an entry', () {
      // Eine leere Stunde sagt nichts und würde die vollen zudecken.
      final entries = classbookEntries(_tage());
      expect(entries.any((e) => e.subject == 'Mathematik'), isFalse);
    });

    test('keeps subject, hour and teacher with each entry', () {
      final entry = classbookEntries(_tage()).last;
      expect(entry.subject, 'Deutsch');
      expect(entry.fromHour, 1);
      expect(entry.teachers, ['Anna Musterfrau']);
      expect(entry.date, _montag);
    });

    test('lists only subjects that carry entries, alphabetically', () {
      expect(classbookSubjects(classbookEntries(_tage())),
          ['Deutsch', 'Musik']);
    });
  });

  group('with nothing to show', () {
    testWidgets('says so once the weeks are loaded', (tester) async {
      await tester.pumpWidget(_seite(const []));
      expect(find.textContaining('nichts eingetragen'), findsOneWidget);
    });

    testWidgets('says it is still loading while a week is on its way',
        (tester) async {
      // Sonst liest sich ein noch leerer Anfang wie ein leeres Klassenbuch.
      await tester.pumpWidget(_seite(const [], loading: true));
      expect(find.textContaining('wird geladen'), findsOneWidget);
    });
  });

  group('by day', () {
    testWidgets('puts a headline over each day', (tester) async {
      await tester.pumpWidget(_seite(classbookEntries(_tage())));
      await tester.pumpAndSettle();
      expect(find.textContaining('12. Mai 2026'), findsOneWidget);
      expect(find.textContaining('11. Mai 2026'), findsOneWidget);
      expect(find.text('Diktat'), findsOneWidget);
    });
  });

  group('by subject', () {
    testWidgets('gives every subject one row with its count', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        mode: ClassbookViewMode.bySubject,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Musik'), findsOneWidget);
      expect(find.text('3 Einträge'), findsOneWidget);
      expect(find.text('1 Eintrag'), findsOneWidget);
      // Zugeklappt: die Einträge selbst stehen noch nicht da.
      expect(find.text('Diktat'), findsNothing);
    });

    testWidgets('shows the entries after expanding', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        mode: ClassbookViewMode.bySubject,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      expect(find.text('Diktat'), findsOneWidget);
      expect(find.text('Silbenlesen'), findsOneWidget);
      expect(find.text('Notenlehre'), findsNothing);
    });
  });

  group('with a subject filter', () {
    testWidgets('shows everything until a subject is picked', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        mode: ClassbookViewMode.filtered,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alle Fächer'), findsOneWidget);
      expect(find.text('Diktat'), findsOneWidget);
      expect(find.text('Notenlehre'), findsOneWidget);
    });

    testWidgets('narrows down to the chosen subject', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        mode: ClassbookViewMode.filtered,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Musik').last);
      await tester.pumpAndSettle();

      expect(find.text('Notenlehre'), findsOneWidget);
      expect(find.text('Diktat'), findsNothing);
      expect(find.text('Silbenlesen'), findsNothing);
    });
  });
}
