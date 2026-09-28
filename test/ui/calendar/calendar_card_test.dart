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
import 'package:dr/ui/calendar_card.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CalendarHour _hour({required bool test}) => CalendarHour(
      (b) => b
        ..fromHour = 1
        ..toHour = 1
        ..subject = 'Mathematik'
        ..rooms = ListBuilder()
        ..lessonContents = ListBuilder()
        ..homeworkExams = ListBuilder(<HomeworkExam>[
          HomeworkExam(
            (b) => b
              ..id = 1
              ..name = test ? 'Schularbeit' : 'S. 12'
              ..homework = !test
              ..warning = test
              ..online = false
              ..deadline = UtcDateTime(2026, 9, 28)
              ..hasGrades = false
              ..hasGradeGroupSubmissions = false
              ..typeId = 1
              ..typeName = test ? 'Test' : 'Hausaufgabe',
          ),
        ]),
    );

void main() {
  Future<BorderSide> frameOf(
    WidgetTester tester, {
    required bool test,
    required bool colorTestsInRed,
    bool selected = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarCard(
              hour: _hour(test: test),
              theme: const SubjectTheme(),
              selected: selected,
              onOpenFile: (_) {},
              noInternet: false,
              colorTestsInRed: colorTestsInRed,
            ),
          ),
        ),
      ),
    );
    final card = tester.widget<Card>(find.byType(Card));
    return (card.shape! as RoundedRectangleBorder).side;
  }

  ColorScheme scheme(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Card))).colorScheme;

  group('"Tests immer rot umrahmen" (#302)', () {
    testWidgets('frames a lesson with a test in red', (tester) async {
      final side = await frameOf(tester, test: true, colorTestsInRed: true);
      expect(side.color, scheme(tester).error);
      expect(side.width, 1.5);
    });

    testWidgets('leaves it unframed with the setting off', (tester) async {
      final side = await frameOf(tester, test: true, colorTestsInRed: false);
      expect(side, BorderSide.none);
    });

    testWidgets('leaves a lesson without a test unframed', (tester) async {
      final side = await frameOf(tester, test: false, colorTestsInRed: true);
      expect(side, BorderSide.none);
    });

    testWidgets('a picked lesson with a test stays red, only bolder',
        (tester) async {
      final side = await frameOf(
        tester,
        test: true,
        colorTestsInRed: true,
        selected: true,
      );
      expect(side.color, scheme(tester).error);
      expect(side.width, 2);
    });
  });

  testWidgets('a picked lesson keeps its accent frame', (tester) async {
    final side = await frameOf(
      tester,
      test: false,
      colorTestsInRed: true,
      selected: true,
    );
    expect(side.color, scheme(tester).secondary);
    expect(side.width, 2);
  });
}
