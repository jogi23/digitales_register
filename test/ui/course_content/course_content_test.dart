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

import 'package:dr/providers/course_content_provider.dart';
import 'package:dr/ui/course_content_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _deutsch = CourseSubject(classId: 100, subjectId: 84, name: 'Deutsch');
const _musik = CourseSubject(classId: 100, subjectId: 91, name: 'Musik');

const _kurs = Course(
  id: 7,
  title: 'Deutsch 5A',
  topics: [
    CourseTopic(
      id: 1,
      title: 'Rechtschreibung',
      entries: [
        CourseEntry(id: 11, title: 'Arbeitsblatt', type: CourseEntryType.file),
        CourseEntry(
          id: 12,
          title: 'Merksatz',
          type: CourseEntryType.text,
          text: 'Nach kurzem Vokal steht ein doppelter Konsonant.',
        ),
      ],
    ),
    CourseTopic(
      id: 2,
      title: 'Lesen',
      entries: [
        CourseEntry(id: 21, title: 'Онлайн-Übung', type: CourseEntryType.link),
      ],
    ),
  ],
);

Widget _seite(
  CourseContentState state, {
  List<CourseSubject> subjects = const [_deutsch, _musik],
  ValueChanged<CourseSubject>? onSubject,
  ValueChanged<CourseEntry>? onEntry,
}) =>
    MaterialApp(
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: CourseContentPage(
          subjects: subjects,
          state: state,
          subjectLabel: (s) => s.substring(0, 3),
          onSubjectSelected: onSubject ?? (_) {},
          onEntrySelected: onEntry ?? (_) {},
        ),
      ),
    );

void main() {
  group('picking a subject', () {
    testWidgets('offers one chip per subject, labelled with the nickname',
        (tester) async {
      await tester.pumpWidget(_seite(const CourseContentState()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'Deu'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Mus'), findsOneWidget);
    });

    testWidgets('asks for one before anything is shown', (tester) async {
      await tester.pumpWidget(_seite(const CourseContentState()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Fach oben wählen'), findsOneWidget);
    });

    testWidgets('reports the chosen subject', (tester) async {
      CourseSubject? gewaehlt;
      await tester.pumpWidget(
        _seite(const CourseContentState(), onSubject: (s) => gewaehlt = s),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Mus'));
      await tester.pumpAndSettle();
      expect(gewaehlt, _musik);
    });
  });

  group('showing the material', () {
    testWidgets('groups the entries under their topic', (tester) async {
      await tester.pumpWidget(_seite(
        const CourseContentState(subject: _deutsch, course: _kurs),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Rechtschreibung'), findsOneWidget);
      expect(find.text('2 Einträge'), findsOneWidget);
      expect(find.text('Lesen'), findsOneWidget);
      expect(find.text('1 Eintrag'), findsOneWidget);
      // Zugeklappt, solange es mehr als ein Thema gibt.
      expect(find.text('Arbeitsblatt'), findsNothing);
    });

    testWidgets('shows the entries after expanding', (tester) async {
      await tester.pumpWidget(_seite(
        const CourseContentState(subject: _deutsch, course: _kurs),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechtschreibung'));
      await tester.pumpAndSettle();
      expect(find.text('Arbeitsblatt'), findsOneWidget);
      expect(find.text('Merksatz'), findsOneWidget);
    });

    testWidgets('reports the tapped entry', (tester) async {
      CourseEntry? getippt;
      await tester.pumpWidget(_seite(
        const CourseContentState(subject: _deutsch, course: _kurs),
        onEntry: (e) => getippt = e,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rechtschreibung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merksatz'));
      await tester.pumpAndSettle();

      expect(getippt?.id, 12);
      expect(getippt?.type, CourseEntryType.text);
    });
  });

  group('when there is nothing', () {
    testWidgets('says so for a subject without a course', (tester) async {
      // Der Server antwortet mit id 0 - das ist eine Auskunft, kein Fehler,
      // und darf deshalb nicht wie einer aussehen.
      await tester.pumpWidget(_seite(const CourseContentState(
        subject: _deutsch,
        course: Course(id: 0, title: '', topics: []),
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('noch nichts hinterlegt'), findsOneWidget);
    });

    testWidgets('names the likely reason when the call fails', (tester) async {
      // Ob der Endpunkt einem Eltern- oder Schülerkonto offensteht, ist
      // nicht belegt; die Meldung sagt das, statt nur "Fehler" zu zeigen.
      await tester.pumpWidget(_seite(const CourseContentState(
        subject: _deutsch,
        error: 'DioException 403',
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('nicht offen'), findsOneWidget);
    });

    testWidgets('shows a spinner while loading', (tester) async {
      await tester.pumpWidget(_seite(
        const CourseContentState(subject: _deutsch, loading: true),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('the entry type', () {
    testWidgets('picks an icon per kind and disables an unknown one',
        (tester) async {
      const kurs = Course(id: 7, title: 'x', topics: [
        CourseTopic(id: 1, title: 'Alles', entries: [
          CourseEntry(id: 1, title: 'Datei', type: CourseEntryType.file),
          CourseEntry(id: 2, title: 'Verweis', type: CourseEntryType.link),
          CourseEntry(id: 3, title: 'Notiz', type: CourseEntryType.text),
          CourseEntry(id: 4, title: 'Neuartig', type: CourseEntryType.unknown),
        ]),
      ]);
      await tester.pumpWidget(_seite(
        const CourseContentState(subject: _deutsch, course: kurs),
      ));
      await tester.pumpAndSettle();

      // Ein einzelnes Thema steht offen.
      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.notes), findsOneWidget);

      final unbekannt = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Neuartig'),
      );
      expect(unbekannt.enabled, isFalse);
    });
  });

  group('reading the answer', () {
    test('an unknown type does not throw', () {
      expect(CourseEntryType.fromName('video'), CourseEntryType.unknown);
      expect(CourseEntryType.fromName(null), CourseEntryType.unknown);
      expect(CourseEntryType.fromName('file'), CourseEntryType.file);
    });

    test('a course with id 0 counts as absent', () {
      expect(const Course(id: 0, title: '', topics: []).exists, isFalse);
      expect(_kurs.exists, isTrue);
    });

    test('a file gets a name of its own', () {
      // Zwei gleichnamige Dateien aus verschiedenen Kursen dürfen sich nicht
      // überschreiben.
      const a = CourseEntry(id: 11, title: 'Blatt', type: CourseEntryType.file);
      const b = CourseEntry(id: 12, title: 'Blatt', type: CourseEntryType.file);
      expect(a.uniqueName, isNot(b.uniqueName));
    });
  });
}
