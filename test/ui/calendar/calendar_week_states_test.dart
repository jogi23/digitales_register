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
import 'package:dr/ui/no_internet.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A week with one lesson, so the loaded-and-filled case has something to show.
List<CalendarDay> _oneLesson() => <CalendarDay>[
      CalendarDay(
        (b) => b
          ..date = UtcDateTime(2026, 5, 11)
          ..hours = ListBuilder(<CalendarHour>[
            CalendarHour(
              (b) => b
                ..subject = "Deutsch"
                ..fromHour = 1
                ..toHour = 1
                ..rooms = ListBuilder()
                ..homeworkExams = ListBuilder()
                ..lessonContents = ListBuilder()
                ..timeSpans = ListBuilder(),
            ),
          ]),
      ),
    ];

Future<void> main() async {
  // The day headers format dates in German.
  setUpAll(() => initializeDateFormatting('de'));

  Widget week({
    bool loading = false,
    bool noInternet = false,
    List<CalendarDay> days = const [],
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: CalendarWeek(
            vm: CalendarWeekViewModel(
              days: days,
              subjectNicks: const {},
              noInternet: noInternet,
              selection: null,
              colorBackground: false,
              showTimes: false,
              subjectThemes: const {},
              loading: loading,
            ),
          ),
        ),
      ),
    );
  }

  group('a week without lessons', () {
    testWidgets('spins while it is still being fetched', (tester) async {
      await tester.pumpWidget(week(loading: true));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Keine Stunden in dieser Woche'), findsNothing);
    });

    testWidgets('says so once the fetch is done', (tester) async {
      // The bug this covers: empty used to mean "still loading", so a week
      // that genuinely has no lessons span forever.
      await tester.pumpWidget(week());
      await tester.pumpAndSettle();
      expect(find.text('Keine Stunden in dieser Woche'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('reports being offline instead', (tester) async {
      await tester.pumpWidget(week(noInternet: true, loading: true));
      await tester.pumpAndSettle();
      expect(find.byType(NoInternet), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('a week with lessons shows the grid', (tester) async {
    await tester.pumpWidget(week(days: _oneLesson()));
    await tester.pumpAndSettle();
    expect(find.text('Keine Stunden in dieser Woche'), findsNothing);
    expect(find.byType(HourWidget), findsOneWidget);
  });
}
