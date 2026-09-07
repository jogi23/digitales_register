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
import 'package:dr/app_state.dart' hide LoginState;
import 'package:dr/container/days_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/dashboard_parser.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/dashboard_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../fixtures/api_fixtures.dart';

class _TestDashboardNotifier extends DashboardNotifier {
  _TestDashboardNotifier(this._initialState);
  final DashboardState _initialState;

  @override
  DashboardState build() => _initialState;
}

/// The dashboard pulls grade competences, which would hit the network.
class _TestGradesNotifier extends GradesNotifier {
  _TestGradesNotifier(this._initialState);
  final GradesState _initialState;

  @override
  GradesState build() => _initialState;

  @override
  Future<void> load(Semester semester) async {}

  @override
  Future<void> loadDetails(Subject subject, Semester semester) async {}
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(this.initial);
  final SettingsState initial;

  @override
  SettingsState build() => initial;
}

// All of May 2026 from the demo capture: the 11th carries entries, the 9th
// does not, which is what the calendar has to tell apart.
late DashboardState _mayState;

Future<void> main() async {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await loadFixtures();
    final raw = fixtureFor(
      'api/student/dashboard/dashboard',
      params: {'viewFuture': false},
    ) as List;
    final may = raw
        .where((dynamic d) => (d as Map)['date'].toString().startsWith('2026-05'))
        .toList();
    final days = parseDays(may, deduplicate: false).whereType<Day>().toList();
    _mayState = DashboardState(
      (b) => b
        ..allDays = ListBuilder(days)
        ..future = false,
    );
  });

  Widget dashboard({required bool calendarView}) {
    return ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(() => _TestDashboardNotifier(_mayState)),
        gradesProvider.overrideWith(() => _TestGradesNotifier(GradesState())),
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(
            SettingsState(
              dashboardViewMode: calendarView
                  ? DashboardViewMode.month
                  : DashboardViewMode.list,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: DaysContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
    );
  }

  Future<void> pumpCalendar(WidgetTester tester) async {
    await tester.pumpWidget(dashboard(calendarView: true));
    await tester.pumpAndSettle();
  }

  /// Taps the given day of the month in the grid.
  Future<void> tapDay(WidgetTester tester, String dayOfMonth) async {
    await tester.tap(find.text(dayOfMonth).first);
    await tester.pumpAndSettle();
  }

  group('switching views', () {
    testWidgets('the setting turns the month grid on', (tester) async {
      await pumpCalendar(tester);
      expect(find.byType(DashboardCalendar), findsOneWidget);
      expect(find.text('Mai 2026'), findsOneWidget);
      // Weekday headers, Monday first.
      expect(find.text('Mo'), findsOneWidget);
      expect(find.text('So'), findsOneWidget);
    });

    testWidgets('without the setting the list is shown', (tester) async {
      await tester.pumpWidget(dashboard(calendarView: false));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardCalendar), findsNothing);
      expect(find.text('Mai 2026'), findsNothing);
    });
  });

  group('picking a day', () {
    testWidgets('nothing is selected at first', (tester) async {
      await pumpCalendar(tester);
      expect(find.text('Tag auswählen'), findsOneWidget);
    });

    testWidgets('a day with entries shows them', (tester) async {
      await pumpCalendar(tester);
      await tapDay(tester, '11');
      expect(find.text('Tag auswählen'), findsNothing);
      // The day header of the entry list carries the date.
      expect(find.textContaining('11.5.'), findsWidgets);
    });

    testWidgets('tapping the same day again clears the selection',
        (tester) async {
      await pumpCalendar(tester);
      await tapDay(tester, '11');
      await tapDay(tester, '11');
      expect(find.text('Tag auswählen'), findsOneWidget);
    });

    testWidgets('a loaded day without entries says so', (tester) async {
      await pumpCalendar(tester);
      // The 9th of May is loaded but carries nothing.
      await tapDay(tester, '9');
      expect(find.text('(Kein Eintrag)'), findsOneWidget);
      // The day header stays so a reminder can still be added.
      expect(find.textContaining('9.5.'), findsWidgets);
    });

    testWidgets('a day the dashboard did not load says so', (tester) async {
      await pumpCalendar(tester);
      // July was never loaded, so no day of it can have entries.
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      expect(find.text('Juli 2026'), findsOneWidget);
      await tapDay(tester, '15');
      expect(find.text('(Kein Eintrag)'), findsOneWidget);
    });
  });

  group('changing the month', () {
    testWidgets('moves forward and back', (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      expect(find.text('Juni 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Voriger Monat'));
      await tester.pumpAndSettle();
      expect(find.text('Mai 2026'), findsOneWidget);
    });

    testWidgets('rolls over into the next year', (tester) async {
      await pumpCalendar(tester);
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byTooltip('Nächster Monat'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Januar 2027'), findsOneWidget);
    });
  });

  testGoldens('month grid golden', (tester) async {
    await loadAppFonts();
    await pumpCalendar(tester);
    await tapDay(tester, '11');
    await expectLater(
      find.byType(DashboardCalendar),
      matchesGoldenFile('calendar_view.png'),
    );
  });
}
