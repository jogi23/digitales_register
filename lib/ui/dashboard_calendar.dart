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
import 'package:dr/data.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Shown for a day or week that carries nothing.
const _noEntries = "(Kein Eintrag)";

/// Shown while the days being looked at are still on their way.
const _loadingEntries = "Wird geladen …";

/// What the area below the grid shows.
sealed class _Pick {
  const _Pick();
}

class _DayPick extends _Pick {
  final DateTime date;
  const _DayPick(this.date);
}

class _WeekPick extends _Pick {
  final DateTime monday;
  const _WeekPick(this.monday);

  bool covers(DateTime date) =>
      !date.isBefore(monday) &&
      date.isBefore(monday.add(const Duration(days: 7)));
}

/// The dashboard as a month grid: which days carry entries at a glance, with
/// the entries of the picked day — or of a whole week — below.
///
/// Rendering an entry is left to [dayBuilder], so this widget only owns the
/// month and the selection; entries look and behave as in the list view.
class DashboardCalendar extends StatefulWidget {
  final BuiltList<Day> days;
  final Widget Function(Day day) dayBuilder;

  /// Whether entries are being fetched right now.
  final bool loading;

  /// Asks for the days the dashboard does not hold yet.
  final VoidCallback onLoadMissing;

  const DashboardCalendar({
    super.key,
    required this.days,
    required this.dayBuilder,
    this.loading = false,
    required this.onLoadMissing,
  });

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  /// First of the month currently shown.
  late DateTime _month;

  _Pick? _pick;

  /// Days already asked for, so a span the server simply has nothing for is
  /// not requested again on every tap.
  final Set<DateTime> _requested = {};

  @override
  void initState() {
    super.initState();
    _month = _startingMonth();
    // Open on today, so the view starts where the user is.
    _pick = _DayPick(dateOnly(DateTime.now()));
  }

  @override
  void didUpdateWidget(DashboardCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching between past and future replaces the days entirely. Without
    // this the calendar would keep showing a month that now has nothing.
    if (widget.days != oldWidget.days && !_hasDaysIn(_month)) {
      setState(() => _month = _startingMonth());
    }
  }

  /// The month of today when today is loaded, otherwise the month of the first
  /// loaded day: the dashboard shows either past or future, not both.
  DateTime _startingMonth() {
    final today = dateOnly(DateTime.now());
    if (widget.days.isEmpty) return _monthOf(today);
    if (widget.days.any((d) => dateOnly(d.date) == today)) {
      return _monthOf(today);
    }
    return _monthOf(widget.days.first.date);
  }

  static DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  bool _hasDaysIn(DateTime month) => widget.days
      .any((d) => d.date.year == month.year && d.date.month == month.month);

  void _changeMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
      });

  /// Picking the same thing twice clears the selection.
  void _pickDay(DateTime date) {
    setState(() {
      final pick = _pick;
      _pick = pick is _DayPick && pick.date == date ? null : _DayPick(date);
    });
    _fetchIfMissing([date]);
  }

  void _pickWeek(DateTime monday) {
    setState(() {
      final pick = _pick;
      _pick =
          pick is _WeekPick && pick.monday == monday ? null : _WeekPick(monday);
    });
    _fetchIfMissing([
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ]);
  }

  /// Fetches when the picked days are outside what the dashboard holds.
  ///
  /// Asked only once per day: the server answers for a limited span, so days
  /// beyond it would otherwise trigger a request on every tap.
  void _fetchIfMissing(List<DateTime> dates) {
    final range = _loadedRange(
      <DateTime>{for (final day in widget.days) dateOnly(day.date)},
    );
    final missing = dates.where((date) =>
        range == null || date.isBefore(range.$1) || date.isAfter(range.$2));
    if (missing.isEmpty) return;
    if (!missing.any((date) => _requested.add(date))) return;
    widget.onLoadMissing();
  }

  @override
  Widget build(BuildContext context) {
    final byDate = <DateTime, Day>{
      for (final day in widget.days) dateOnly(day.date): day,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthHeader(
          month: _month,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        // Says that something is happening while the missing days arrive;
        // the grid itself fills in as soon as they do.
        SizedBox(
          height: 2,
          child: widget.loading ? const LinearProgressIndicator() : null,
        ),
        _MonthGrid(
          month: _month,
          byDate: byDate,
          loaded: _loadedRange(byDate.keys),
          pick: _pick,
          onPickDay: _pickDay,
          onPickWeek: _pickWeek,
        ),
        const Divider(height: 1),
        Expanded(child: _detail(context, byDate)),
      ],
    );
  }

  /// First and last day the dashboard actually holds. The server answers for
  /// a limited span, and days outside it are unknown — not free.
  static (DateTime, DateTime)? _loadedRange(Iterable<DateTime> dates) {
    if (dates.isEmpty) return null;
    final sorted = dates.toList()..sort();
    return (sorted.first, sorted.last);
  }

  Widget _detail(BuildContext context, Map<DateTime, Day> byDate) {
    final pick = _pick;
    if (pick == null) return Center(child: _hint(context, "Tag auswählen"));

    if (pick is _DayPick) {
      final day = byDate[pick.date];
      if (day == null) {
        return Center(
          child: _hint(context, widget.loading ? _loadingEntries : _noEntries),
        );
      }
      if (day.homework.isEmpty) {
        // The day header stays, so a reminder can still be added here.
        return SingleChildScrollView(
          child: Column(
            children: <Widget>[
              widget.dayBuilder(day),
              _hint(context, _noEntries),
            ],
          ),
        );
      }
      return SingleChildScrollView(child: widget.dayBuilder(day));
    }

    final monday = (pick as _WeekPick).monday;
    final days = <Day>[
      for (var i = 0; i < 7; i++)
        if (byDate[monday.add(Duration(days: i))]?.homework.isNotEmpty ?? false)
          byDate[monday.add(Duration(days: i))]!,
    ];
    if (days.isEmpty) {
      return Center(
        child: _hint(context, widget.loading ? _loadingEntries : _noEntries),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[for (final day in days) widget.dayBuilder(day)],
      ),
    );
  }

  Widget _hint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      );
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: "Voriger Monat",
          onPressed: onPrevious,
        ),
        Text(
          DateFormat("MMMM yyyy", "de").format(month),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: "Nächster Monat",
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<DateTime, Day> byDate;

  /// The span the dashboard has data for, null when it has none at all.
  final (DateTime, DateTime)? loaded;
  final _Pick? pick;
  final void Function(DateTime date) onPickDay;
  final void Function(DateTime monday) onPickWeek;

  const _MonthGrid({
    required this.month,
    required this.byDate,
    required this.loaded,
    required this.pick,
    required this.onPickDay,
    required this.onPickWeek,
  });

  static const _weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
  static const _rowHeight = 46.0;
  static const _weekColumnWidth = 28.0;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    // weekday is 1 for Monday, so this is how many blanks come before the 1st.
    final leading = first.weekday - 1;
    // Day zero of the next month is the last day of this one.
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final weeks = ((leading + dayCount) / 7).ceil();
    final today = dateOnly(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(width: _weekColumnWidth),
              for (final name in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
          // Fixed row height rather than square cells: a month spanning six
          // weeks would otherwise overflow the screen on a phone.
          for (var week = 0; week < weeks; week++)
            SizedBox(
              height: _rowHeight,
              // The row always starts on a Monday, which for the first row
              // can still lie in the previous month.
              child: _week(
                first.subtract(Duration(days: leading - week * 7)),
                today,
              ),
            ),
        ],
      ),
    );
  }

  Widget _week(DateTime monday, DateTime today) {
    final selectedWeek = pick;
    return Row(
      children: <Widget>[
        SizedBox(
          width: _weekColumnWidth,
          child: _WeekCell(
            week: isoWeekNumber(monday),
            isSelected:
                selectedWeek is _WeekPick && selectedWeek.monday == monday,
            onTap: () => onPickWeek(monday),
          ),
        ),
        for (var i = 0; i < 7; i++)
          Expanded(child: _cell(monday.add(Duration(days: i)), today)),
      ],
    );
  }

  Widget _cell(DateTime date, DateTime today) {
    // Days of the neighbouring months stay blank.
    if (date.month != month.month || date.year != month.year) {
      return const SizedBox.shrink();
    }
    final day = byDate[date];
    final current = pick;
    final selected = switch (current) {
      _DayPick() => current.date == date,
      _WeekPick() => current.covers(date),
      null => false,
    };
    final range = loaded;
    return _DayCell(
      dayOfMonth: date.day,
      isKnown:
          range != null && !date.isBefore(range.$1) && !date.isAfter(range.$2),
      hasEntries: day?.homework.isNotEmpty ?? false,
      hasWarning: day?.homework.any((h) => h.warning) ?? false,
      isToday: date == today,
      isSelected: selected,
      onTap: () => onPickDay(date),
    );
  }
}

class _WeekCell extends StatelessWidget {
  final int week;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeekCell({
    required this.week,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: "Kalenderwoche $week",
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            "$week",
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
          ),
        ),
      ),
    );
  }
}

/// Diameter of the day circle, so every day looks the same size.
const _circleSize = 30.0;

class _DayCell extends StatelessWidget {
  final int dayOfMonth;

  /// Whether the dashboard covers this day at all.
  final bool isKnown;
  final bool hasEntries;
  final bool hasWarning;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayOfMonth,
    required this.isKnown,
    required this.hasEntries,
    required this.hasWarning,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Fixed size: a circle around text alone would shrink for the
          // single-digit days, so the 7th looked smaller than the 17th.
          SizedBox(
            width: _circleSize,
            height: _circleSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? scheme.primary : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  "$dayOfMonth",
                  style: TextStyle(
                    // Days the dashboard never loaded are faded: no dot there
                    // means "unknown", not "nothing to do".
                    color: isSelected
                        ? scheme.onPrimary
                        : isKnown
                            ? null
                            : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // A dot marks days that have something due. The count is left out so
          // the cell stays readable on a phone; red marks a test.
          SizedBox(
            height: 6,
            width: 6,
            child: !hasEntries
                ? null
                : DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // The dot sits below the circle, so it keeps its own
                      // colour even while the day is selected.
                      color: hasWarning ? scheme.error : scheme.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
