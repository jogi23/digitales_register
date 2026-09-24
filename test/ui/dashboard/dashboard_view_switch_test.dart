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
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockWrapper extends Mock implements Wrapper {}

/// The real [DashboardNotifier.load]: it marks the dashboard as loading
/// before its first await, which is what must not happen mid-build.
class _DashboardNotifier extends DashboardNotifier {
  @override
  DashboardState build() => DashboardState(
        (b) => b
          ..future = true
          ..allDays = ListBuilder(),
      );
}

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

/// Changes the view mode the way an account switch does: the settings
/// change underneath a dashboard that is already on screen.
class _TestSettingsNotifier extends SettingsNotifier {
  /// Starts in the list view, the default.
  @override
  SettingsState build() => SettingsState();

  void switchTo(DashboardViewMode mode) =>
      state = state.copyWith(dashboardViewMode: mode);
}

void main() {
  late _MockWrapper mockWrapper;
  late _TestSettingsNotifier settings;
  late List<bool> requested;

  setUpAll(() => initializeDateFormatting('de'));

  setUp(() {
    mockNow = UtcDateTime(2026, 5, 12);
    requested = [];
    mockWrapper = _MockWrapper();
    wrapper = mockWrapper;
    when(
      () => mockWrapper.send(
        'api/student/dashboard/dashboard',
        args: any(named: 'args'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments[#args] as Map<String, Object?>;
      requested.add(args['viewFuture']! as bool);
      return null;
    });
  });

  tearDown(() => mockNow = null);

  Future<void> pumpList(WidgetTester tester) async {
    settings = _TestSettingsNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith(_DashboardNotifier.new),
          calendarProvider.overrideWith(_TestCalendarNotifier.new),
          gradesProvider.overrideWith(_TestGradesNotifier.new),
          settingsProvider.overrideWith(() => settings),
        ],
        child: MaterialApp(home: DaysContainer()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in [DashboardViewMode.month, DashboardViewMode.week]) {
    testWidgets(
        'switching from the list to the ${mode.name} view loads both '
        'directions without touching a provider mid-build', (tester) async {
      await pumpList(tester);
      // The list view loads nothing by itself.
      expect(requested, isEmpty);

      settings.switchTo(mode);
      await tester.pumpAndSettle();

      // Riverpod reports a provider modified during build as an uncaught
      // async error, which the test binding turns into a failure here.
      expect(tester.takeException(), isNull);
      // Past first, then the direction the dashboard points at.
      expect(requested, [false, true]);
    });
  }
}
