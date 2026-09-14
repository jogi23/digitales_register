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
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// A Wednesday; its week starts on Monday, 14 September.
final _wednesday = UtcDateTime(2026, 9, 16);
final _monday = UtcDateTime(2026, 9, 14);

CalendarDay _day(UtcDateTime date) => CalendarDay(
      (b) => b
        ..date = date
        ..hours = ListBuilder(),
    );

void main() {
  setUp(() => mockNow = _wednesday);
  tearDown(() => mockNow = null);

  test('a calendar that stands on no week shows the current one', () {
    expect(CalendarState().shownMonday, _monday);
  });

  test('the week the calendar stands on wins over the current one', () {
    final other = UtcDateTime(2026, 9, 7);
    expect(CalendarState((b) => b..currentMonday = other).shownMonday, other);
  });

  test('the days of the week need no week to stand on', () {
    // currentMonday is not saved; reading it with `!` crashed the calendar
    // page after a reset or a restore.
    final inWeek = _day(UtcDateTime(2026, 9, 15));
    final state = CalendarState(
      (b) => b.days.addAll({
        inWeek.date: inWeek,
        UtcDateTime(2026, 9, 22): _day(UtcDateTime(2026, 9, 22)),
      }),
    );

    expect(state.currentDays, [inWeek]);
  });

  test('after a reset the calendar still knows which week to show', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(calendarProvider.notifier);

    notifier.setCurrentMonday(UtcDateTime(2026, 9, 7));
    notifier.reset();

    expect(container.read(calendarProvider).currentMonday, isNull);
    expect(container.read(calendarProvider).shownMonday, _monday);
    expect(() => container.read(calendarProvider).currentDays, returnsNormally);
  });
}
