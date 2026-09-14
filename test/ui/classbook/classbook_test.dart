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
import 'package:dr/ui/entry_card.dart';
import 'package:dr/ui/lesson_entry_list.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart' show mockNow;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

CalendarHour _hour({
  required int fromHour,
  required String subject,
  List<String> contents = const [],
  String teacher = 'Musterfrau',
  UtcDateTime? from,
  UtcDateTime? to,
}) =>
    CalendarHour(
      (b) => b
        ..fromHour = fromHour
        ..toHour = fromHour
        ..subject = subject
        ..rooms = ListBuilder<String>()
        ..timeSpans = ListBuilder<TimeSpan>([
          if (from != null && to != null)
            TimeSpan((t) => t
              ..from = from
              ..to = to),
        ])
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

/// Ein Vormittag mit Uhrzeiten, wie ihn der Stundenplan liefert.
List<CalendarDay> _stundenplan() => [
      _day(_dienstag, [
        _hour(
          fromHour: 1,
          subject: 'Englisch',
          contents: ['Vokabelwiederholung'],
          from: UtcDateTime(2026, 5, 12, 7, 50),
          to: UtcDateTime(2026, 5, 12, 8, 45),
        ),
        _hour(
          fromHour: 2,
          subject: 'Deutsch',
          contents: ['Nomen im Zauberlehrling'],
          from: UtcDateTime(2026, 5, 12, 8, 45),
          to: UtcDateTime(2026, 5, 12, 9, 35),
        ),
        _hour(
          fromHour: 3,
          subject: 'Italienisch',
          contents: ['Verbformen in drei Zeiten'],
          from: UtcDateTime(2026, 5, 12, 9, 35),
          to: UtcDateTime(2026, 5, 12, 10, 25),
        ),
      ]),
    ];

/// Haelt die Auswahl so, wie es in der App die Einstellungen tun.
class _Huelle extends StatefulWidget {
  final List<LessonEntry> entries;
  final ClassbookViewMode mode;
  final EntryDisplayMode display;
  final bool loading;
  final List<String> initial;
  final Map<String, String> kuerzel;

  const _Huelle({
    required this.entries,
    required this.mode,
    required this.display,
    required this.loading,
    required this.initial,
    required this.kuerzel,
  });

  @override
  State<_Huelle> createState() => _HuelleState();
}

class _HuelleState extends State<_Huelle> {
  late List<String> _gewaehlt = widget.initial;

  @override
  Widget build(BuildContext context) => LessonEntryList(
        entries: widget.entries,
        viewMode: widget.mode,
        displayMode: widget.display,
        loading: widget.loading,
        selectedSubjects: _gewaehlt,
        onSelectedSubjectsChanged: (f) => setState(() => _gewaehlt = f),
        subjectLabel: (fach) => widget.kuerzel[fach] ?? fach,
        loadingText: 'wird geladen',
        emptyText: 'nichts eingetragen',
        ordinaryType: ordinaryLessonType,
      );
}

Widget _seite(
  List<LessonEntry> entries, {
  ClassbookViewMode mode = ClassbookViewMode.chronological,
  EntryDisplayMode display = EntryDisplayMode.list,
  bool loading = false,
  List<String> selected = const [],
  Map<String, String> kuerzel = const {},
}) =>
    MaterialApp(
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(
        body: _Huelle(
          entries: entries,
          mode: mode,
          display: display,
          loading: loading,
          initial: selected,
          kuerzel: kuerzel,
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
      expect(entries.map((e) => e.title),
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
      expect(entrySubjects(classbookEntries(_tage())), ['Deutsch', 'Musik']);
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

    testWidgets('keeps each day headline pinned on a band of its own',
        (tester) async {
      // Ohne Band lief ein Tag, der mit einer weißen Zeile endet, in den
      // nächsten über, der weiß beginnt.
      await tester.pumpWidget(_seite(classbookEntries(_tage())));
      await tester.pumpAndSettle();

      expect(find.byType(PinnedHeaderSliver), findsNWidgets(2));
      final band = find
          .ancestor(
            of: find.textContaining('12. Mai 2026'),
            matching: find.byType(ColoredBox),
          )
          .first;
      final scheme = Theme.of(tester.element(band)).colorScheme;
      expect(tester.widget<ColoredBox>(band).color, scheme.secondaryContainer);
    });

    testWidgets('sets off the line carrying subject, hour and teacher',
        (tester) async {
      // Der Eintragstext darüber ist oft lang; ohne Absetzung verschwimmt
      // die Zuordnung zwischen den Zeilen.
      await tester.pumpWidget(_seite(classbookEntries(_tage())));
      await tester.pumpAndSettle();

      final zeile = tester.widget<Text>(
        find.textContaining('Deutsch · 1. h').first,
      );
      final farbe = Theme.of(
        tester.element(find.textContaining('Deutsch · 1. h').first),
      ).colorScheme.primary;
      expect(zeile.style?.color, farbe);
      expect(zeile.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('carries the subject filter', (tester) async {
      // Ohne ihn beantwortet die Liste "was hatten wir", aber nicht "was
      // hatten wir in Deutsch" - und danach fragt ein Klassenbuch.
      await tester.pumpWidget(_seite(classbookEntries(_tage())));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Alle Fächer'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Deutsch'), findsOneWidget);
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

  group('the subject filter of the day view', () {
    testWidgets('shows everything until a subject is picked', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alle Fächer'), findsOneWidget);
      expect(find.text('Diktat'), findsOneWidget);
      expect(find.text('Notenlehre'), findsOneWidget);
    });

    testWidgets('labels the chips with the subject nickname', (tester) async {
      // Bei zehn Fächern nebeneinander füllen die vollen Namen mehrere
      // Zeilen, und die Liste rückt nach unten weg.
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        kuerzel: const {'Deutsch': 'Deu', 'Musik': 'Mus'},
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'Deu'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Mus'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Deutsch'), findsNothing);
    });

    testWidgets('falls back to the full name without a nickname',
        (tester) async {
      // Ein leerer Chip wäre schlimmer als ein langer.
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        kuerzel: const {'Deutsch': 'Deu'},
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'Musik'), findsOneWidget);
    });

    testWidgets('filters by the subject behind the nickname', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        kuerzel: const {'Deutsch': 'Deu', 'Musik': 'Mus'},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Mus'));
      await tester.pumpAndSettle();

      expect(find.text('Notenlehre'), findsOneWidget);
      expect(find.text('Diktat'), findsNothing);
    });

    testWidgets('marks a chosen chip without a tick', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        selected: const ['Musik'],
      ));
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Musik'),
      );
      expect(chip.selected, isTrue);
      expect(chip.showCheckmark, isFalse);
    });

    testWidgets('keeps more than one subject at a time', (tester) async {
      // Der eigentliche Zweck der Mehrfachauswahl: zwei Fächer nebeneinander
      // sehen, ohne zwischen ihnen umzuschalten.
      await tester.pumpWidget(_seite(classbookEntries(_tage())));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Musik'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Deutsch'));
      await tester.pumpAndSettle();

      expect(find.text('Notenlehre'), findsOneWidget);
      expect(find.text('Diktat'), findsOneWidget);
    });

    testWidgets('starts from what the account had chosen', (tester) async {
      // Die Auswahl liegt in den Einstellungen, nicht im Widget.
      await tester.pumpWidget(
        _seite(classbookEntries(_tage()), selected: const ['Musik']),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notenlehre'), findsOneWidget);
      expect(find.text('Diktat'), findsNothing);
    });

    testWidgets('ignores a subject that has no entries any more',
        (tester) async {
      // Sonst bliebe die Liste leer, ohne dass ein Grund zu sehen wäre.
      await tester.pumpWidget(
        _seite(classbookEntries(_tage()), selected: const ['Chemie']),
      );
      await tester.pumpAndSettle();

      expect(find.text('Diktat'), findsOneWidget);
      expect(find.text('Notenlehre'), findsOneWidget);
    });

    testWidgets('goes back to everything through the all-subjects chip',
        (tester) async {
      await tester.pumpWidget(
        _seite(classbookEntries(_tage()), selected: const ['Musik']),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Alle Fächer'));
      await tester.pumpAndSettle();

      expect(find.text('Diktat'), findsOneWidget);
      expect(find.text('Notenlehre'), findsOneWidget);
    });

    testWidgets('narrows down to the chosen subject', (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Musik'));
      await tester.pumpAndSettle();

      expect(find.text('Notenlehre'), findsOneWidget);
      expect(find.text('Diktat'), findsNothing);
      expect(find.text('Silbenlesen'), findsNothing);
    });
  });

  group('lesson times', () {
    test('keep start and end of the lesson with each entry', () {
      final entry = classbookEntries(_stundenplan()).first;
      expect(entry.from, UtcDateTime(2026, 5, 12, 7, 50));
      expect(entry.to, UtcDateTime(2026, 5, 12, 8, 45));
      expect(entry.toHour, 1);
    });

    test('are left out where the timetable has none', () {
      // Ältere gespeicherte Stände kennen keine Uhrzeiten.
      final entry = classbookEntries(_tage()).first;
      expect(entry.from, isNull);
      expect(entry.to, isNull);
    });

    test('entries of one lesson belong together', () {
      // Diktat und Leseübung: dieselbe Stunde, also eine Karte.
      final lessons = lessonsOf(classbookEntries(_tage()));
      expect(lessons.map((l) => l.map((e) => e.title).toList()), [
        ['Diktat', 'Leseübung'],
        ['Notenlehre'],
        ['Silbenlesen'],
      ]);
    });
  });

  group('the list', () {
    testWidgets('tints every second row', (tester) async {
      // Lange Einträge laufen sonst ineinander.
      await tester.pumpWidget(_seite(classbookEntries(_tage())));
      await tester.pumpAndSettle();

      ListTile zeile(String title) =>
          tester.widget<ListTile>(find.widgetWithText(ListTile, title));
      expect(zeile('Diktat').tileColor, isNull);
      expect(zeile('Leseübung').tileColor, isNotNull);
      expect(zeile('Notenlehre').tileColor, isNull);
    });
  });

  group('cards', () {
    testWidgets('give every lesson a card with its time and teacher',
        (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_stundenplan()),
        display: EntryDisplayMode.cards,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard), findsNWidgets(3));
      expect(find.textContaining('07:50–08:45'), findsOneWidget);
      expect(find.text('Anna Musterfrau'), findsNWidgets(3));
    });

    testWidgets('put two entries of one lesson into the same card',
        (tester) async {
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        display: EntryDisplayMode.cards,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(EntryCard), findsNWidgets(3));
      final karte = find.ancestor(
        of: find.text('Diktat'),
        matching: find.byType(EntryCard),
      );
      expect(
        find.descendant(of: karte, matching: find.text('Leseübung')),
        findsOneWidget,
      );
    });
  });

  group('the timeline', () {
    tearDown(() => mockNow = null);

    testWidgets('fills the lessons that are over', (tester) async {
      // Mitten in der dritten Stunde: die ersten beiden sind vorbei.
      mockNow = UtcDateTime(2026, 5, 12, 9, 40);
      await tester.pumpWidget(_seite(
        classbookEntries(_stundenplan()),
        display: EntryDisplayMode.timeline,
      ));
      await tester.pumpAndSettle();

      final punkte =
          tester.widgetList<TimelineDot>(find.byType(TimelineDot)).toList();
      expect(punkte.map((p) => p.label), ['1', '2', '3']);
      expect(punkte.map((p) => p.over), [true, true, false]);
    });

    test('goes by the day where the timetable has no times', () {
      final montag = [classbookEntries(_tage()).last];
      expect(lessonIsOver(montag, at: UtcDateTime(2026, 5, 12, 7)), isTrue);
      expect(lessonIsOver(montag, at: UtcDateTime(2026, 5, 11, 23)), isFalse);
    });

    testWidgets('becomes cards when arranged by subject', (tester) async {
      // Nach Fach gibt es keinen Tag, dessen Ablauf sie zeigen könnte.
      await tester.pumpWidget(_seite(
        classbookEntries(_tage()),
        mode: ClassbookViewMode.bySubject,
        display: EntryDisplayMode.timeline,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();

      expect(find.byType(TimelineDot), findsNothing);
      expect(find.byType(EntryCard), findsNWidgets(2));
    });
  });
}
