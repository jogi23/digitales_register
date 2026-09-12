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
import 'package:dr/ui/layout.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

/// A day with lessons from the first to the eighth hour: more than fits into
/// a phone held sideways.
CalendarDay _fullDay(UtcDateTime date) => CalendarDay(
      (b) => b
        ..date = date
        ..hours = ListBuilder(<CalendarHour>[
          for (var hour = 1; hour <= 8; hour++)
            CalendarHour(
              (b) => b
                ..subject = "Fach $hour"
                ..fromHour = hour
                ..toHour = hour
                ..rooms = ListBuilder()
                ..homeworkExams = ListBuilder()
                ..lessonContents = ListBuilder()
                ..timeSpans = ListBuilder(),
            ),
        ]),
    );

Future<void> main() async {
  setUpAll(() => initializeDateFormatting('de'));

  group('system insets', () {
    testWidgets('keep content clear of the bar at the side, not just below',
        (tester) async {
      late EdgeInsets insets;
      await tester.pumpWidget(
        MediaQuery(
          // Held sideways, the navigation bar sits on the right.
          data: const MediaQueryData(
            viewPadding: EdgeInsets.only(left: 24, right: 48, bottom: 16),
          ),
          child: Builder(
            builder: (context) {
              insets = context.systemInsets;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(insets.right, 48);
      expect(insets.left, 24);
      expect(insets.bottom, 16);
      // The top is an app bar's business, not the content's.
      expect(insets.top, 0);
    });

    testWidgets('a short frame counts as compact', (tester) async {
      late bool short;
      late bool tall;
      await tester.pumpWidget(
        Column(
          children: <Widget>[
            MediaQuery(
              data: const MediaQueryData(size: Size(900, 420)),
              child: Builder(builder: (context) {
                short = context.isCompactHeight;
                return const SizedBox();
              }),
            ),
            MediaQuery(
              data: const MediaQueryData(size: Size(420, 900)),
              child: Builder(builder: (context) {
                tall = context.isCompactHeight;
                return const SizedBox();
              }),
            ),
          ],
        ),
      );
      expect(short, isTrue);
      expect(tall, isFalse);
    });
  });

  group('the app bar', () {
    Future<AppBar> pumpBar(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: ResponsiveAppBar(title: const Text('Merkheft')),
          ),
        ),
      );
      return tester.widget<AppBar>(find.byType(AppBar));
    }

    testWidgets('gives up half its height when the frame is short',
        (tester) async {
      final bar = await pumpBar(tester, const Size(900, 420));
      expect(bar.toolbarHeight, compactToolbarHeight);
      expect(bar.titleTextStyle?.fontSize, lessThan(20));
    });

    testWidgets('keeps its usual height otherwise', (tester) async {
      final bar = await pumpBar(tester, const Size(420, 900));
      expect(bar.toolbarHeight, kToolbarHeight);
      expect(bar.titleTextStyle, isNull);
    });

    testWidgets('reserves the height it actually draws', (tester) async {
      // The scaffold asks without a context; both answers have to agree, or
      // a gap opens between bar and content.
      tester.view.physicalSize = const Size(900, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const bar = ResponsiveAppBar(title: Text('Merkheft'));
      expect(bar.preferredSize.height, compactToolbarHeight);
    });
  });

  group('the week timetable', () {
    Widget week(List<CalendarDay> days, {required double height}) {
      return ProviderScope(
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
                  subjectThemes: const {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('scrolls instead of squeezing the hours when height is short',
        (tester) async {
      await tester.pumpWidget(
        week([_fullDay(UtcDateTime(2026, 5, 11))], height: 260),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('fills the height it is given when there is enough',
        (tester) async {
      await tester.pumpWidget(
        week([_fullDay(UtcDateTime(2026, 5, 11))], height: 800),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });
}
