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
import 'package:dr/container/dashboard_week_container.dart';
import 'package:dr/container/days_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/dashboard_parser.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/calendar_week.dart';
import 'package:dr/ui/days.dart';
import 'package:dr/utc_date_time.dart';
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

class _TestCalendarNotifier extends CalendarNotifier {
  _TestCalendarNotifier(this._initialState);
  final CalendarState _initialState;

  @override
  CalendarState build() => _initialState;

  // The week is already in the state; loading would need the network.
  @override
  Future<void> load(UtcDateTime monday) async {}
}

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

class _TestSubjectAppearanceNotifier extends SubjectAppearanceNotifier {
  _TestSubjectAppearanceNotifier(this.initial);
  final SubjectAppearanceState initial;

  @override
  SubjectAppearanceState build() => initial;
}

final _monday = UtcDateTime(2026, 5, 11);

// Monday 11.05.2026 has entries for Mathematik, NatGeGeo and Deutsch, while
// its timetable also holds Religion and Vormittagspause — those get dimmed.
late DashboardState _dashboardState;
late CalendarState _calendarState;

Future<void> main() async {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await loadFixtures();

    final rawDays = fixtureFor(
      'api/student/dashboard/dashboard',
      params: {'viewFuture': false},
    ) as List;
    final may = rawDays
        .where((dynamic d) =>
            (d as Map)['date'].toString().startsWith('2026-05'))
        .toList();
    _dashboardState = DashboardState(
      (b) => b
        ..allDays =
            ListBuilder(parseDays(may, deduplicate: false).whereType<Day>())
        ..future = false,
    );

    final container = ProviderContainer();
    final rawWeek = fixtureFor(
      'api/calendar/student',
      params: {'startDate': '2026-05-11'},
    ) as Map<String, dynamic>;
    final weekDays =
        container.read(calendarProvider.notifier).parseLoaded(rawWeek);
    container.dispose();
    _calendarState = CalendarState(
      (b) => b
        ..currentMonday = _monday
        ..days = MapBuilder(weekDays),
    );
  });

  Widget dashboard({DashboardViewMode mode = DashboardViewMode.week}) {
    return ProviderScope(
      overrides: [
        dashboardProvider
            .overrideWith(() => _TestDashboardNotifier(_dashboardState)),
        calendarProvider.overrideWith(() => _TestCalendarNotifier(_calendarState)),
        gradesProvider.overrideWith(() => _TestGradesNotifier(GradesState())),
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(SettingsState(dashboardViewMode: mode)),
        ),
        subjectAppearanceProvider.overrideWith(
          () => _TestSubjectAppearanceNotifier(const SubjectAppearanceState()),
        ),
      ],
      child: MaterialApp(
        home: DaysContainer(),
        theme: ThemeData(primarySwatch: Colors.deepOrange),
      ),
    );
  }

  /// Renders the week view on the week the fixtures cover.
  Future<void> pumpWeek(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarProvider
              .overrideWith(() => _TestCalendarNotifier(_calendarState)),
          settingsProvider.overrideWith(
            () => _TestSettingsNotifier(
              SettingsState(dashboardViewMode: DashboardViewMode.week),
            ),
          ),
          subjectAppearanceProvider.overrideWith(
            () => _TestSubjectAppearanceNotifier(const SubjectAppearanceState()),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DashboardWeekContainer(
              days: _dashboardState.allDays!,
              initialMonday: _monday,
            ),
          ),
          theme: ThemeData(
            primarySwatch: Colors.deepOrange,
            brightness: brightness,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Whether the lesson of [subject] on Monday is pushed into the background.
  bool dimmedOnMonday(WidgetTester tester, String subject) {
    return tester
        .widgetList<HourWidget>(find.byType(HourWidget))
        .firstWhere(
          (w) => w.hour.subject == subject && w.day.date == _monday,
        )
        .dimmed;
  }

  group('showing the week', () {
    testWidgets('the setting turns the timetable on', (tester) async {
      await tester.pumpWidget(dashboard());
      await tester.pump();
      expect(find.byType(DashboardWeekContainer), findsOneWidget);
    });

    testWidgets('opens on the current week', (tester) async {
      await pumpWeek(tester);
      expect(find.text('11.05.26 - 15.05.26'), findsOneWidget);
      expect(find.byType(CalendarWeek), findsOneWidget);
    });

    testWidgets('the list view shows no timetable', (tester) async {
      await tester.pumpWidget(dashboard(mode: DashboardViewMode.list));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardWeekContainer), findsNothing);
    });

    testWidgets('the month view shows no timetable', (tester) async {
      await tester.pumpWidget(dashboard(mode: DashboardViewMode.month));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardWeekContainer), findsNothing);
    });
  });

  /// How far the lesson of [subject] on Monday is faded out.
  double opacityOnMonday(WidgetTester tester, String subject) {
    final hour = find.byWidgetPredicate((w) =>
        w is HourWidget && w.hour.subject == subject && w.day.date == _monday);
    return tester
        .widget<Opacity>(
          find.descendant(of: hour, matching: find.byType(Opacity)).first,
        )
        .opacity;
  }

  /// The tile's own background colour, null when it keeps the plain one.
  Color? tintOnMonday(WidgetTester tester, String subject) {
    final hour = find.byWidgetPredicate((w) =>
        w is HourWidget && w.hour.subject == subject && w.day.date == _monday);
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: hour, matching: find.byType(DecoratedBox)).first,
    );
    return (box.decoration as BoxDecoration).color;
  }

  group('dimming', () {
    testWidgets('subjects with entries stay in the foreground',
        (tester) async {
      await pumpWeek(tester);
      expect(dimmedOnMonday(tester, 'Mathematik'), isFalse);
      expect(dimmedOnMonday(tester, 'Deutsch'), isFalse);
      expect(dimmedOnMonday(tester, 'NatGeGeo'), isFalse);
    });

    testWidgets('subjects without entries are dimmed', (tester) async {
      await pumpWeek(tester);
      expect(dimmedOnMonday(tester, 'Religion'), isTrue);
      expect(dimmedOnMonday(tester, 'Vormittagspause'), isTrue);
    });

    testWidgets('a dimmed subject stays readable', (tester) async {
      // Dimming tones the tile down, it must not hide the text: the subject
      // has to stay in the tree with a colour of its own.
      await pumpWeek(tester);
      expect(find.text('Religion'), findsWidgets);
      final style = tester
          .widget<Text>(find.text('Religion').first)
          .style;
      expect(style?.color, isNot(Colors.transparent));
    });

  });

  // The first attempt tinted dimmed tiles, which turned nearly black on a
  // dark background — the quiet lessons became the loudest ones.
  for (final brightness in Brightness.values) {
    group('dimming in ${brightness.name} mode', () {
      testWidgets('fades lessons without entries', (tester) async {
        await pumpWeek(tester, brightness: brightness);
        expect(opacityOnMonday(tester, 'Religion'), lessThan(1.0));
        expect(opacityOnMonday(tester, 'Vormittagspause'), lessThan(1.0));
      });

      testWidgets('leaves lessons with entries untouched', (tester) async {
        await pumpWeek(tester, brightness: brightness);
        expect(opacityOnMonday(tester, 'Mathematik'), 1.0);
        expect(opacityOnMonday(tester, 'NatGeGeo'), 1.0);
      });

      testWidgets('gives dimmed lessons no background of their own',
          (tester) async {
        await pumpWeek(tester, brightness: brightness);
        expect(tintOnMonday(tester, 'Religion'), isNull);
      });

      testWidgets('keeps the text readable', (tester) async {
        await pumpWeek(tester, brightness: brightness);
        // Material treats 0.6 as the lower bound for readable secondary text.
        expect(opacityOnMonday(tester, 'Religion'),
            greaterThanOrEqualTo(0.6));
        expect(find.text('Religion'), findsWidgets);
      });
    });
  }

  group('changing the week', () {
    testWidgets('moves forward and back', (tester) async {
      await pumpWeek(tester);
      // Only plain pumps here: a week without timetable data shows a
      // progress indicator, which never settles.
      await tester.tap(find.byTooltip('Nächste Woche'));
      await tester.pump();
      expect(find.text('18.05.26 - 22.05.26'), findsOneWidget);

      await tester.tap(find.byTooltip('Vorige Woche'));
      await tester.pump();
      expect(find.text('11.05.26 - 15.05.26'), findsOneWidget);
    });
  });

  testGoldens('week view golden', (tester) async {
    await loadAppFonts();
    await pumpWeek(tester);
    await expectLater(
      find.byType(DashboardWeekContainer),
      matchesGoldenFile('week_view.png'),
    );
  });

  // Dimming used to tint the tile, which turned nearly black on a dark
  // background and made the quiet lessons the loudest thing on screen.
  testGoldens('week view golden in dark mode', (tester) async {
    await loadAppFonts();
    await pumpWeek(tester, brightness: Brightness.dark);
    await expectLater(
      find.byType(DashboardWeekContainer),
      matchesGoldenFile('week_view_dark.png'),
    );
  });
}
