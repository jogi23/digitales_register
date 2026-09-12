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
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/pull_to_refresh.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _TestDashboardNotifier extends DashboardNotifier {
  _TestDashboardNotifier(this._initialState);
  final DashboardState _initialState;

  @override
  DashboardState build() => _initialState;

  int loads = 0;
  int bothDirectionsLoads = 0;

  // The calendar views fetch on their own, which would hit the network.
  @override
  Future<void> load(bool future) async {
    loads++;
  }

  @override
  Future<void> loadBothDirections() async {
    bothDirectionsLoads++;
  }
}

/// The week view loads its timetable itself. A real load would go through
/// the global wrapper and could still be pending when the next test starts,
/// leaving its week spinning.
class _TestCalendarNotifier extends CalendarNotifier {
  @override
  CalendarState build() => CalendarState();

  @override
  Future<void> load(UtcDateTime monday) async {}
}

class _TestGradesNotifier extends GradesNotifier {
  @override
  GradesState build() => GradesState();

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

/// The 12th of May 2026, a Tuesday — a month that holds both directions
/// comfortably.
final _today = UtcDateTime(2026, 5, 12);

Homework _entry(int id, String title, {bool isNew = false}) => Homework(
      (b) => b
        ..checkable = true
        ..checked = false
        ..deleteable = false
        ..deleted = false
        ..firstSeen = _today
        ..id = id
        ..isChanged = false
        ..isNew = isNew
        ..type = HomeworkType.lessonHomework
        ..title = title
        // The "neu" badge sits beside the subject label, so an entry without
        // one would never show it.
        ..label = "Deutsch"
        ..subtitle = "",
    );

Day _day(UtcDateTime date, List<Homework> homework) => Day(
      (b) => b
        ..date = date
        ..deletedHomework = ListBuilder()
        ..homework = ListBuilder(homework)
        ..lastRequested = _today,
    );

void main() {
  setUpAll(() => initializeDateFormatting('de'));
  setUp(() => mockNow = _today);
  tearDown(() => mockNow = null);

  /// Both directions loaded, while the list view stands on the future — the
  /// state the dashboard is in after the calendar views asked for both.
  DashboardState _bothDirections() => DashboardState(
        (b) => b
          ..future = true
          ..allDays = ListBuilder(<Day>[
            _day(UtcDateTime(2026, 5, 8), [_entry(1, "Vergangenes")]),
            _day(UtcDateTime(2026, 5, 20), [_entry(2, "Kommendes", isNew: true)]),
          ]),
      );

  late _TestDashboardNotifier notifier;

  Widget dashboard(DashboardViewMode viewMode, {DashboardState? state}) {
    notifier = _TestDashboardNotifier(state ?? _bothDirections());
    return ProviderScope(
      overrides: [
        dashboardProvider.overrideWith(() => notifier),
        calendarProvider.overrideWith(_TestCalendarNotifier.new),
        gradesProvider.overrideWith(_TestGradesNotifier.new),
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(
            SettingsState(dashboardViewMode: viewMode),
          ),
        ),
      ],
      child: MaterialApp(home: DaysContainer()),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    DashboardViewMode viewMode, {
    DashboardState? state,
  }) async {
    await tester.pumpWidget(dashboard(viewMode, state: state));
    await tester.pumpAndSettle();
  }

  group('past entries in the calendar views', () {
    testWidgets('the month view shows them although the list stands ahead',
        (tester) async {
      await pump(tester, DashboardViewMode.month);
      // The 8th lies behind, and the dashboard is pointing at the future.
      await tester.tap(find.text('8').first);
      await tester.pumpAndSettle();
      expect(find.text('Vergangenes'), findsOneWidget);
    });

    testWidgets('the list view keeps to the direction it is set to',
        (tester) async {
      await pump(tester, DashboardViewMode.list);
      expect(find.text('Kommendes'), findsOneWidget);
      expect(find.text('Vergangenes'), findsNothing);
      // The list highlights a new entry it scrolled past, which leaves a
      // timer running past the end of the test.
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('the button for new entries', () {
    testWidgets('opens the day the entry sits on in the month view',
        (tester) async {
      await pump(tester, DashboardViewMode.month);
      // Nothing of the 20th is shown while the view opens on today.
      expect(find.text('Kommendes'), findsNothing);
      await tester.tap(find.text('Neue Einträge'));
      await tester.pumpAndSettle();
      expect(find.text('Kommendes'), findsOneWidget);
    });

  });

  group('news seen in the calendar views', () {
    testWidgets('the badge stays while the day is on screen', (tester) async {
      await pump(tester, DashboardViewMode.month);
      await tester.tap(find.text('Neue Einträge'));
      await tester.pumpAndSettle();
      expect(find.text('Kommendes'), findsOneWidget);
      expect(find.text('neu'), findsOneWidget);
      expect(find.text('Neue Einträge'), findsOneWidget);
    });

    testWidgets('picking another day marks the one left as seen',
        (tester) async {
      await pump(tester, DashboardViewMode.month);
      await tester.tap(find.text('Neue Einträge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8').first);
      await tester.pumpAndSettle();
      expect(find.text('Neue Einträge'), findsNothing);
    });

    testWidgets('tapping the button again on the last day finishes it',
        (tester) async {
      await pump(tester, DashboardViewMode.month);
      await tester.tap(find.text('Neue Einträge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neue Einträge'));
      await tester.pumpAndSettle();
      expect(find.text('Neue Einträge'), findsNothing);
      // The day itself stays open, now without its badge.
      expect(find.text('Kommendes'), findsOneWidget);
      expect(find.text('neu'), findsNothing);
    });

    testWidgets('closing the day opened in the week view marks it as seen',
        (tester) async {
      await pump(tester, DashboardViewMode.week);
      await tester.tap(find.text('Neue Einträge'));
      await tester.pumpAndSettle();
      expect(find.text('Kommendes'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Neue Einträge'), findsNothing);
    });
  });

  group('pulling down', () {
    Future<void> pull(WidgetTester tester) async {
      await tester.fling(
        find.byType(PullToRefresh),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      // The list highlights new entries it passes, on a timer of its own.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('reloads the list', (tester) async {
      await pump(tester, DashboardViewMode.list);
      final before = notifier.loads;
      await pull(tester);
      expect(notifier.loads, before + 1);
    });

    testWidgets('reloads both directions in the month view', (tester) async {
      await pump(tester, DashboardViewMode.month);
      final before = notifier.bothDirectionsLoads;
      await pull(tester);
      expect(notifier.bothDirectionsLoads, before + 1);
    });

    testWidgets('reloads both directions in the week view', (tester) async {
      await pump(tester, DashboardViewMode.week);
      final before = notifier.bothDirectionsLoads;
      await pull(tester);
      expect(notifier.bothDirectionsLoads, before + 1);
    });

    testWidgets('works on an empty dashboard too', (tester) async {
      await pump(
        tester,
        DashboardViewMode.list,
        state: DashboardState(
          (b) => b
            ..future = true
            ..allDays = ListBuilder(),
        ),
      );
      final before = notifier.loads;
      await pull(tester);
      expect(notifier.loads, before + 1);
    });
  });

  group('sideways', () {
    Future<void> pumpSideways(WidgetTester tester) async {
      // A phone held sideways: wide, and barely any height.
      tester.view.physicalSize = const Size(900, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, DashboardViewMode.month);
    }

    testWidgets('month grid and entries stand next to each other',
        (tester) async {
      await pumpSideways(tester);
      // Side by side: height is what is missing, width is not.
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('upright they stand above each other', (tester) async {
      await pump(tester, DashboardViewMode.month);
      expect(find.byType(VerticalDivider), findsNothing);
    });
  });
}
