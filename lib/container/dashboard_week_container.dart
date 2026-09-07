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

import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:dr/container/calendar_week_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/calendar_week.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The dashboard as one week of the timetable, with lessons that have no
/// entries dimmed.
///
/// The timetable comes from the calendar, the entries from the dashboard, so
/// this pulls the week in itself — otherwise the view would stay empty until
/// the user had opened the calendar page.
class DashboardWeekContainer extends ConsumerStatefulWidget {
  /// Dashboard days, which carry the entries.
  final BuiltList<Day> days;

  /// Week to open on. Defaults to the current one.
  @visibleForTesting
  final UtcDateTime? initialMonday;

  const DashboardWeekContainer({
    super.key,
    required this.days,
    this.initialMonday,
  });

  @override
  ConsumerState<DashboardWeekContainer> createState() =>
      _DashboardWeekContainerState();
}

class _DashboardWeekContainerState
    extends ConsumerState<DashboardWeekContainer> {
  late UtcDateTime _monday;

  @override
  void initState() {
    super.initState();
    // Always the current week: deriving it from the loaded days would jump
    // to wherever the dashboard happens to start.
    _monday = widget.initialMonday ?? toMonday(Day.dateToday());
    // Loading during build would be a state change mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLoaded();
      _ensureThemes();
    });
  }

  static UtcDateTime _dateOnly(UtcDateTime date) =>
      UtcDateTime(date.year, date.month, date.day);

  void _ensureLoaded() {
    if (!mounted) return;
    if (ref.read(calendarProvider).daysForWeek(_monday).isEmpty) {
      unawaited(ref.read(calendarProvider.notifier).load(_monday));
    }
  }

  void _changeWeek(int weeks) {
    setState(() => _monday = _monday.add(Duration(days: 7 * weeks)));
    _ensureLoaded();
    _ensureThemes();
  }

  /// Subjects seen only in the timetable may have no colour yet, and here the
  /// colour is what says "something is due" — so make sure one exists.
  void _ensureThemes() {
    if (!mounted) return;
    final subjects = <String>{
      for (final day in ref.read(calendarProvider).daysForWeek(_monday))
        for (final hour in day.hours) hour.subject,
    };
    if (subjects.isEmpty) return;
    unawaited(
      ref
          .read(subjectAppearanceProvider.notifier)
          .ensureThemesFor(subjects.toList()),
    );
  }

  /// The subjects that carry entries, per day. Everything else gets dimmed.
  Map<UtcDateTime, Set<String>> _subjectsWithEntries() {
    return <UtcDateTime, Set<String>>{
      for (final day in widget.days)
        _dateOnly(day.date): <String>{
          for (final entry in day.homework)
            if (entry.label != null) normalizeSubject(entry.label!),
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarProvider);
    final noInternet = ref.watch(noInternetProvider);
    final settings = ref.watch(settingsProvider);
    final subjectAppearance = ref.watch(subjectAppearanceProvider);
    final weekDays = calendarState.daysForWeek(_monday).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      children: <Widget>[
        _WeekHeader(
          monday: _monday,
          onPrevious: () => _changeWeek(-1),
          onNext: () => _changeWeek(1),
        ),
        Expanded(
          child: CalendarWeek(
            vm: CalendarWeekViewModel(
              days: weekDays,
              subjectNicks: subjectAppearance.nicks,
              noInternet: noInternet,
              selection: calendarState.selection,
              // Here the subject colour carries the meaning "something is
              // due", so it is on regardless of the calendar setting.
              colorBackground: true,
              showTimes: settings.calendarShowTimes,
              subjectThemes: subjectAppearance.themes,
              subjectsWithEntries: _subjectsWithEntries(),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final UtcDateTime monday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _WeekHeader({
    required this.monday,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat("dd.MM.yy");
    final friday = monday.add(const Duration(days: 4));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: "Vorige Woche",
          onPressed: onPrevious,
        ),
        Text(
          "${format.format(monday)} - ${format.format(friday)}",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: "Nächste Woche",
          onPressed: onNext,
        ),
      ],
    );
  }
}
