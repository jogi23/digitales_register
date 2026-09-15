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
import 'package:dr/container/calendar_week_container.dart';
import 'package:dr/data.dart';
import 'package:dr/ui/calendar_week.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Teacher _teacher(String lastName) => Teacher(
      (b) => b
        ..firstName = "Vorname"
        ..lastName = lastName,
    );

CalendarHour _hour(
  int hour,
  String subject, {
  List<String> teachers = const [],
  List<String> rooms = const [],
}) =>
    CalendarHour(
      (b) => b
        ..subject = subject
        ..fromHour = hour
        ..toHour = hour
        ..teachers = ListBuilder([for (final t in teachers) _teacher(t)])
        ..rooms = ListBuilder(rooms)
        ..homeworkExams = ListBuilder()
        ..lessonContents = ListBuilder()
        ..timeSpans = ListBuilder(),
    );

CalendarDay _day(UtcDateTime date, CalendarHour hour) => CalendarDay(
      (b) => b
        ..date = date
        ..hours = ListBuilder(<CalendarHour>[hour]),
    );

/// The three tiles from the report: one row, very different amounts of text.
List<CalendarDay> _reportedRow() => <CalendarDay>[
      _day(
        UtcDateTime(2026, 9, 8),
        _hour(1, "Deutsch",
            teachers: ["Lechner", "Oester"],
            rooms: ["Schlanders Ausweichraum 1. Stock"]),
      ),
      _day(
        UtcDateTime(2026, 9, 9),
        _hour(1, "Englisch", teachers: ["Fleischmann"]),
      ),
      _day(
        UtcDateTime(2026, 9, 10),
        _hour(1, "Italienisch",
            teachers: ["Sberveglieri", "Schmoelzer", "Rossi", "Bianchi"]),
      ),
    ];

Future<void> main() async {
  setUpAll(() => initializeDateFormatting('de'));

  Future<void> pumpWeek(
    WidgetTester tester,
    List<CalendarDay> days, {
    double height = 600,
    bool showAllDetails = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: height,
              child: CalendarWeek(
                vm: CalendarWeekViewModel(
                  days: days,
                  subjectNicks: const {},
                  noInternet: false,
                  selection: null,
                  colorBackground: false,
                  showTimes: false,
                  showAllDetails: showAllDetails,
                  subjectThemes: const {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  TextStyle styleOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!;

  testWidgets('the subject has the same size in every tile', (tester) async {
    await pumpWeek(tester, _reportedRow());
    final sizes = {
      for (final subject in ["Deutsch", "Englisch", "Italienisch"])
        styleOf(tester, subject).fontSize,
    };
    expect(sizes, hasLength(1));
    // Nothing scales the label any more — that is what made the sizes differ.
    expect(
      find.descendant(
        of: find.byType(HourWidget),
        matching: find.byType(FittedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('without the setting the room is left to the detail view',
      (tester) async {
    await pumpWeek(tester, _reportedRow());
    expect(find.text("Schlanders Ausweichraum 1. Stock"), findsNothing);
  });

  testWidgets('a lesson outside its own room carries the corner, either way',
      (tester) async {
    for (final showAllDetails in [false, true]) {
      await pumpWeek(tester, _reportedRow(), showAllDetails: showAllDetails);
      // Only Deutsch has a room.
      expect(find.byType(RoomCorner), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HourWidget).at(0),
          matching: find.byType(RoomCorner),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('the corner sits top right, clear of the warning on the left',
      (tester) async {
    await pumpWeek(tester, _reportedRow());
    final tile = tester.getRect(find.byType(HourWidget).at(0));
    final corner = tester.getRect(find.byType(RoomCorner));
    expect(corner.right, tile.right);
    expect(corner.top, tile.top);
    expect(corner.left, greaterThan(tile.left + 5));
  });

  testWidgets('the corner fades with a dimmed lesson', (tester) async {
    await pumpWeek(tester, _reportedRow());
    expect(
      find.ancestor(
        of: find.byType(RoomCorner),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a long press names the room', (tester) async {
    await pumpWeek(tester, _reportedRow());
    expect(
      find.byTooltip("Raum: Schlanders Ausweichraum 1. Stock"),
      findsOneWidget,
    );
  });

  testWidgets('a booked camera is not a room', (tester) async {
    await pumpWeek(
      tester,
      [
        _day(
          UtcDateTime(2026, 9, 8),
          _hour(1, "Deutsch", rooms: ["Schlanders Präsentationskamera"]),
        ),
      ],
      showAllDetails: true,
    );
    expect(find.byType(RoomCorner), findsNothing);
    expect(find.textContaining("kamera"), findsNothing);
  });

  testWidgets('with the setting the room follows the teachers',
      (tester) async {
    await pumpWeek(tester, _reportedRow(), showAllDetails: true);
    final room = find.text("Schlanders Ausweichraum 1. Stock");
    expect(find.text("Lechner"), findsOneWidget);
    expect(find.text("Oester"), findsOneWidget);
    expect(room, findsOneWidget);
    expect(
      tester.getRect(room).top,
      greaterThan(tester.getRect(find.text("Oester")).top),
    );
    expect(
      tester.widget<Text>(room).style!.color,
      Theme.of(tester.element(room)).colorScheme.tertiary,
    );
    // The subject keeps its size next to tiles without a room.
    expect(
      styleOf(tester, "Deutsch").fontSize,
      styleOf(tester, "Englisch").fontSize,
    );
  });

  testWidgets('the room drops the location all rooms share', (tester) async {
    await pumpWeek(
      tester,
      [
        _day(UtcDateTime(2026, 9, 8),
            _hour(1, "Deutsch", rooms: ["Schlanders Küche"])),
        _day(UtcDateTime(2026, 9, 9),
            _hour(1, "Englisch", rooms: ["Schlanders PC Raum"])),
      ],
      showAllDetails: true,
    );
    expect(find.text("Küche"), findsOneWidget);
    expect(find.text("PC Raum"), findsOneWidget);
  });

  testWidgets('more rooms are counted, and a long name cannot cut the count',
      (tester) async {
    await pumpWeek(
      tester,
      [
        _day(
          UtcDateTime(2026, 9, 7),
          _hour(1, "Deutsch", rooms: [
            "Schlanders Ausweichraum im ersten Stock gleich neben der Aula",
            "Schlanders Küche",
          ]),
        ),
        for (var day = 8; day <= 11; day++)
          _day(UtcDateTime(2026, 9, day), _hour(1, "Englisch")),
      ],
      showAllDetails: true,
    );
    final tile = tester.getRect(find.byType(HourWidget).at(0));
    final count = find.text("+1");
    expect(count, findsOneWidget);
    expect(tester.getRect(count).right, lessThanOrEqualTo(tile.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a short tile with the setting does not overflow',
      (tester) async {
    await pumpWeek(tester, _reportedRow(), height: 90, showAllDetails: true);
    expect(find.text("Deutsch"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('allotLessonLines', () {
    test('the room goes before the second teacher', () {
      expect(
        allotLessonLines(budget: 2, teachers: 2, hasRoom: true),
        (teachers: 1, room: true),
      );
    });

    test('a single line goes to the first teacher', () {
      expect(
        allotLessonLines(budget: 1, teachers: 2, hasRoom: true),
        (teachers: 1, room: false),
      );
    });

    test('without teachers the room takes the line', () {
      expect(
        allotLessonLines(budget: 1, teachers: 0, hasRoom: true),
        (teachers: 0, room: true),
      );
    });

    test('four lines at most, three without a room', () {
      expect(
        allotLessonLines(budget: 9, teachers: 5, hasRoom: true),
        (teachers: 2, room: true),
      );
      expect(
        allotLessonLines(budget: 9, teachers: 5, hasRoom: false),
        (teachers: 2, room: false),
      );
    });

    test('no height, no lines', () {
      expect(
        allotLessonLines(budget: -1, teachers: 2, hasRoom: true),
        (teachers: 0, room: false),
      );
    });
  });

  group('shortRoomNames', () {
    test('drops the words all rooms start with', () {
      expect(
        shortRoomNames([
          "Schlanders Küche",
          "Schlanders PC Raum",
          "Schlanders Ausweichraum 1. Stock",
        ]),
        {
          "Schlanders Küche": "Küche",
          "Schlanders PC Raum": "PC Raum",
          "Schlanders Ausweichraum 1. Stock": "Ausweichraum 1. Stock",
        },
      );
    });

    test('a single room keeps its name', () {
      expect(
        shortRoomNames(["Schlanders Küche", "Schlanders Küche"]),
        {"Schlanders Küche": "Schlanders Küche"},
      );
    });

    test('every room keeps at least one word', () {
      expect(
        shortRoomNames(["Schlanders", "Schlanders Küche"]),
        {"Schlanders": "Schlanders", "Schlanders Küche": "Schlanders Küche"},
      );
    });

    test('rooms with nothing in common stay as they are', () {
      expect(
        shortRoomNames(["Aula Magna", "Küche"]),
        {"Aula Magna": "Aula Magna", "Küche": "Küche"},
      );
    });
  });

  group('tileRooms', () {
    test('leaves out equipment and blanks', () {
      expect(
        tileRooms(["Schlanders Küche", "Schlanders Präsentationskamera", " "]),
        ["Schlanders Küche"],
      );
    });
  });

  testWidgets('teachers are set in italics', (tester) async {
    await pumpWeek(tester, _reportedRow());
    expect(styleOf(tester, "Fleischmann").fontStyle, FontStyle.italic);
    expect(styleOf(tester, "Englisch").fontStyle, isNot(FontStyle.italic));
  });

  testWidgets('no more than three lines, the rest counted', (tester) async {
    await pumpWeek(tester, _reportedRow());
    // Subject, the first teacher, and the second with the two left out.
    expect(find.text("Sberveglieri"), findsOneWidget);
    expect(find.text("Schmoelzer +2"), findsOneWidget);
    expect(find.text("Rossi"), findsNothing);
    expect(find.text("Bianchi"), findsNothing);
  });

  testWidgets('text keeps a gap to the tile edge', (tester) async {
    await pumpWeek(tester, _reportedRow());
    final tile = tester.getRect(find.byType(HourWidget).at(1));
    final subject = tester.getRect(find.text("Englisch"));
    expect(subject.left, greaterThan(tile.left));
    expect(subject.right, lessThan(tile.right));
  });

  testWidgets('the tile colour covers the whole tile, not just the text',
      (tester) async {
    await pumpWeek(tester, _reportedRow());
    final tile = find.byType(HourWidget).at(1);
    final background = find
        .descendant(of: tile, matching: find.byType(DecoratedBox))
        .first;
    expect(tester.getSize(background).width, tester.getSize(tile).width);
  });

  testWidgets('a short tile drops teachers before it overflows',
      (tester) async {
    // Too short for three lines: the subject has to stay, and nothing may
    // overflow.
    await pumpWeek(tester, _reportedRow(), height: 90);
    expect(find.text("Englisch"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
