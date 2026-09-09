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

import 'package:collection/collection.dart';
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
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/ui/days.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:dr/l10n/l10n.dart';
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

  /// Renders one day with its entries — the same widget the list view uses,
  /// so entries can be read, ticked off and added the usual way.
  final Widget Function(Day day) dayBuilder;

  /// Week to open on. Defaults to the current one.
  @visibleForTesting
  final UtcDateTime? initialMonday;

  const DashboardWeekContainer({
    super.key,
    required this.days,
    required this.dayBuilder,
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

  void _changeWeek(int weeks) =>
      _goTo(_monday.add(Duration(days: 7 * weeks)));

  void _goTo(UtcDateTime monday) {
    if (monday == _monday) return;
    setState(() => _monday = monday);
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

  /// Opens the day the user tapped: its entries, and the way to add one.
  ///
  /// Deliberately the shared day widget rather than a dialog of its own —
  /// that one filed reminders under a date the dashboard did not recognise,
  /// so they vanished until the next refresh.
  Widget Function(Day day) get dayBuilder => widget.dayBuilder;

  /// The dashboard day behind a calendar date, if it holds one.
  Day? _dayFor(UtcDateTime date) => widget.days
      .firstWhereOrNull((d) => _dateOnly(d.date) == _dateOnly(date));

  /// Days that have something noted, for setting their header apart.
  Set<UtcDateTime> _daysWithEntries() => <UtcDateTime>{
        for (final day in widget.days)
          if (day.homework.isNotEmpty) _dateOnly(day.date),
      };

  /// Opens the day full screen: everything noted for it, and the way to add
  /// more — the same widget the list view builds.
  void _showDay(UtcDateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(DateFormat("EEEE, d. MMMM", tr(context).localeName)
                .format(date)),
          ),
          // Watches the dashboard rather than capturing the day: a page built
          // around a fixed day misses new entries, and a deleted one stays in
          // the tree, which the deleteable tile reports as an error.
          body: Consumer(
            builder: (context, ref, _) {
              ref.watch(dashboardProvider);
              final day = _dayFor(date);
              if (day == null) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(tr(context).noDataForDay),
                  ),
                );
              }
              return SingleChildScrollView(child: dayBuilder(day));
            },
          ),
        ),
      ),
    );
  }

  /// Asks for a reminder and files it under the dashboard's own date.
  ///
  /// Its date, not the timetable's: the dashboard matches the saved entry by
  /// exact date, and a value built from the calendar day does not match — the
  /// reminder was stored but never showed up.
  Future<void> _addReminder(UtcDateTime date) async {
    final day = _dayFor(date);
    if (day == null) {
      showSnackBar(tr(context).noDataForDay);
      return;
    }
    final message = await showEnterReminderDialog(context);
    if (message == null || !mounted) return;
    await ref.read(dashboardProvider.notifier).addReminder(day.date, message);
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
          onToday: () => _goTo(toMonday(Day.dateToday())),
          isCurrentWeek: _monday == toMonday(Day.dateToday()),
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
              loading: calendarState.isLoadingWeek(_monday),
              onDayTap: _showDay,
              onEntryTap: _showDay,
              onAddReminder: _addReminder,
              daysWithEntries: _daysWithEntries(),
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
  final VoidCallback onToday;
  final bool isCurrentWeek;

  const _WeekHeader({
    required this.monday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.isCurrentWeek,
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
          tooltip: tr(context).previousWeek,
          onPressed: onPrevious,
        ),
        Text(
          "${format.format(monday)} - ${format.format(friday)}",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Like the calendar page, only tighter: the header has no room
            // for a labelled button. Disabled while already there.
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: tr(context).calendarCurrentWeek,
              onPressed: isCurrentWeek ? null : onToday,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: tr(context).nextWeek,
              onPressed: onNext,
            ),
          ],
        ),
      ],
    );
  }
}
