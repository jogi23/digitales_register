// Copyright (C) 2021 Michael Debertol
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

import 'package:collection/collection.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/calendar_detail.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CalendarDetailContainer extends ConsumerWidget {
  final bool isSidebar;
  final bool show;
  const CalendarDetailContainer({
    super.key,
    required this.isSidebar,
    required this.show,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(calendarProvider.select((s) => s.selection));
    return CalendarDetailPage(
      selectedDay: selection?.date,
      selectedHour: selection?.hour,
      isSidebar: isSidebar,
      show: show,
    );
  }
}

class CalendarDetailItemContainer extends ConsumerWidget {
  final UtcDateTime date;
  final bool isSidebar;
  const CalendarDetailItemContainer({
    super.key,
    required this.date,
    required this.isSidebar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarProvider);
    final noInternet = ref.watch(noInternetProvider);

    final day = calendarState.days[date];
    final hourIndex = calendarState.selection?.date == date
        ? calendarState.selection?.hour
        : null;
    final hour = day != null && hourIndex != null
        ? day.hours.firstWhereOrNull(
            (h) => h.fromHour <= hourIndex && h.toHour >= hourIndex)
        : null;
    final loading = calendarState.daysForWeek(toMonday(date)).isEmpty;

    return CalendarDetailWrapper(
      date: date,
      day: day,
      targetHour: hour,
      noInternet: noInternet,
      loading: loading,
      isSidebar: isSidebar,
    );
  }
}
