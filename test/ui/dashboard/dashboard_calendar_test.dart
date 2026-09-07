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

  // The calendar views fetch past and future on their own; in tests that
  // would hit the network and leave the progress bar animating forever.
  @override
  Future<void> load(bool future) async {}

  @override
  Future<void> loadBothDirections() async => bothDirectionsCalls++;

  int bothDirectionsCalls = 0;
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

  late _TestDashboardNotifier notifier;

  Widget dashboard({
    required bool calendarView,
    Brightness brightness = Brightness.light,
    bool loading = false,
  }) {
    notifier = _TestDashboardNotifier(
      loading ? _mayState.rebuild((b) => b..loading = true) : _mayState,
    );
    return ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(() => notifier),
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
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          brightness: brightness,
        ),
      ),
    );
  }

  Future<void> pumpCalendar(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      dashboard(calendarView: true, brightness: brightness),
    );
    await tester.pumpAndSettle();
  }

  /// Renders while entries are still being fetched.
  Future<void> pumpLoading(WidgetTester tester) async {
    await tester.pumpWidget(dashboard(calendarView: true, loading: true));
    // Not settled: the progress bar animates forever.
    await tester.pump();
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

  group('loading both directions', () {
    testWidgets('the month view fetches past and future', (tester) async {
      // The server only knows "before" or "after"; with one direction the
      // other half of the calendar would look empty.
      await pumpCalendar(tester);
      expect(notifier.bothDirectionsCalls, 1);
    });

    testWidgets('the list view does not', (tester) async {
      await tester.pumpWidget(dashboard(calendarView: false));
      await tester.pumpAndSettle();
      expect(notifier.bothDirectionsCalls, 0);
    });

    testWidgets('the past/future switch is hidden in the month view',
        (tester) async {
      await pumpCalendar(tester);
      expect(find.text('Zukunft'), findsNothing);
      expect(find.text('Vergangenheit'), findsNothing);
    });

    testWidgets('the list view keeps the switch', (tester) async {
      await tester.pumpWidget(dashboard(calendarView: false));
      await tester.pumpAndSettle();
      expect(
        find.text('Zukunft').evaluate().isNotEmpty ||
            find.text('Vergangenheit').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('fetching what is missing', () {
    testWidgets('picking an unloaded day asks for more', (tester) async {
      await pumpCalendar(tester);
      final before = notifier.bothDirectionsCalls;
      // July was never loaded.
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tapDay(tester, '15');
      expect(notifier.bothDirectionsCalls, before + 1);
    });

    testWidgets('picking an unloaded week asks for more', (tester) async {
      await pumpCalendar(tester);
      final before = notifier.bothDirectionsCalls;
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kalenderwoche 28'));
      await tester.pumpAndSettle();
      expect(notifier.bothDirectionsCalls, before + 1);
    });

    testWidgets('the same day is not asked for twice', (tester) async {
      // The server answers for a limited span; without this a day beyond it
      // would fire a request on every tap.
      await pumpCalendar(tester);
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tapDay(tester, '15');
      final after = notifier.bothDirectionsCalls;
      await tapDay(tester, '15');
      await tapDay(tester, '15');
      expect(notifier.bothDirectionsCalls, after);
    });

    testWidgets('picking a loaded day asks for nothing', (tester) async {
      await pumpCalendar(tester);
      final before = notifier.bothDirectionsCalls;
      await tapDay(tester, '11');
      expect(notifier.bothDirectionsCalls, before);
    });
  });

  group('while the missing days are on their way', () {
    testWidgets('a bar shows that something is happening', (tester) async {
      await pumpLoading(tester);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('an unknown day says it is loading, not that it is empty',
        (tester) async {
      await pumpLoading(tester);
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pump();
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pump();
      await tester.tap(find.text('15').first);
      await tester.pump();
      expect(find.text('Wird geladen …'), findsOneWidget);
      expect(find.text('(Kein Eintrag)'), findsNothing);
    });
  });

  group('days outside the loaded span', () {
    /// The colour the day number is drawn in.
    Color? colourOfDay(WidgetTester tester, String dayOfMonth) => tester
        .widget<Text>(find.text(dayOfMonth).first)
        .style
        ?.color;

    testWidgets('are faded, so no dot does not read as "nothing to do"',
        (tester) async {
      await pumpCalendar(tester);
      // Only May is loaded, so July is unknown territory.
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Nächster Monat'));
      await tester.pumpAndSettle();
      expect(find.text('Juli 2026'), findsOneWidget);
      expect(colourOfDay(tester, '15'), isNotNull);
    });

    testWidgets('loaded days keep the normal colour', (tester) async {
      await pumpCalendar(tester);
      expect(colourOfDay(tester, '15'), isNull);
    });
  });

  group('picking a day', () {
    testWidgets('opens on today', (tester) async {
      // Today is preselected, so the view starts where the user is instead of
      // asking them to pick first.
      await pumpCalendar(tester);
      expect(find.text('Tag auswählen'), findsNothing);
    });

    testWidgets('clearing the selection asks for one again', (tester) async {
      await pumpCalendar(tester);
      await tapDay(tester, '11');
      await tapDay(tester, '11');
      expect(find.text('Tag auswählen'), findsOneWidget);
    });

    testWidgets('a day with entries shows them', (tester) async {
      await pumpCalendar(tester);
      await tapDay(tester, '11');
      expect(find.text('Tag auswählen'), findsNothing);
      // The day header of the entry list carries the date.
      expect(find.textContaining('11.5.'), findsWidgets);
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

  group('picking a week', () {
    testWidgets('the week numbers are shown', (tester) async {
      await pumpCalendar(tester);
      // 11.05.2026 falls into ISO week 20.
      expect(find.byTooltip('Kalenderwoche 20'), findsOneWidget);
    });

    testWidgets('tapping one shows every day of that week', (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byTooltip('Kalenderwoche 20'));
      await tester.pumpAndSettle();
      // Monday to Thursday of that week carry entries.
      expect(find.textContaining('11.5.'), findsWidgets);
      expect(find.textContaining('12.5.'), findsWidgets);
      expect(find.textContaining('14.5.'), findsWidgets);
    });

    testWidgets('tapping it again clears the selection', (tester) async {
      await pumpCalendar(tester);
      await tester.tap(find.byTooltip('Kalenderwoche 20'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kalenderwoche 20'));
      await tester.pumpAndSettle();
      expect(find.text('Tag auswählen'), findsOneWidget);
    });

    testWidgets('a week without entries says so', (tester) async {
      await pumpCalendar(tester);
      // The first week of May 2026 carries nothing.
      await tester.tap(find.byTooltip('Kalenderwoche 18'));
      await tester.pumpAndSettle();
      expect(find.text('(Kein Eintrag)'), findsOneWidget);
    });
  });

  group('day circles', () {
    /// The size of the circle drawn around a day number.
    Size circleOf(WidgetTester tester, String dayOfMonth) {
      final circle = find
          .ancestor(
            of: find.text(dayOfMonth),
            matching: find.byType(SizedBox),
          )
          .first;
      return tester.getSize(circle);
    }

    testWidgets('are the same size for one and two digit days',
        (tester) async {
      // A circle sized to its text alone shrinks for single digits, which
      // made the 7th look smaller than the 17th.
      await pumpCalendar(tester);
      expect(circleOf(tester, '7'), circleOf(tester, '17'));
      expect(circleOf(tester, '9'), circleOf(tester, '30'));
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

  for (final brightness in Brightness.values) {
    testWidgets('the empty-day hint shows in ${brightness.name} mode',
        (tester) async {
      await pumpCalendar(tester, brightness: brightness);
      await tapDay(tester, '9');
      expect(find.text('(Kein Eintrag)'), findsOneWidget);
    });
  }

  testGoldens('month grid golden', (tester) async {
    await loadAppFonts();
    await pumpCalendar(tester);
    await tapDay(tester, '11');
    await expectLater(
      find.byType(DashboardCalendar),
      matchesGoldenFile('calendar_view.png'),
    );
  });

  testGoldens('month grid golden in dark mode', (tester) async {
    await loadAppFonts();
    await pumpCalendar(tester, brightness: Brightness.dark);
    await tapDay(tester, '11');
    await expectLater(
      find.byType(DashboardCalendar),
      matchesGoldenFile('calendar_view_dark.png'),
    );
  });
}
