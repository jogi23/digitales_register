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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Shown for a day that carries nothing.
const _noEntries = "(Kein Eintrag)";

/// The dashboard as a month grid: which days carry entries at a glance, with
/// the entries of the picked day below.
///
/// Rendering an entry is left to [dayBuilder], so this widget only owns the
/// month and the selection; entries look and behave as in the list view.
class DashboardCalendar extends StatefulWidget {
  final BuiltList<Day> days;
  final Widget Function(Day day) dayBuilder;

  const DashboardCalendar({
    super.key,
    required this.days,
    required this.dayBuilder,
  });

  @override
  State<DashboardCalendar> createState() => _DashboardCalendarState();
}

class _DashboardCalendarState extends State<DashboardCalendar> {
  /// First of the month currently shown.
  late DateTime _month;

  /// The day the user picked, null while none is picked.
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _month = _startingMonth();
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

  @override
  Widget build(BuildContext context) {
    final byDate = <DateTime, Day>{
      for (final day in widget.days) dateOnly(day.date): day,
    };
    final selectedDay = _selected != null ? byDate[_selected] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthHeader(
          month: _month,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        _MonthGrid(
          month: _month,
          byDate: byDate,
          selected: _selected,
          onSelect: (date) => setState(
            () => _selected = _selected == date ? null : date,
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _detail(context, selectedDay)),
      ],
    );
  }

  /// What sits below the grid: the entries of the picked day, or a hint.
  Widget _detail(BuildContext context, Day? day) {
    if (_selected == null) {
      return Center(child: _hint(context, "Tag auswählen"));
    }
    if (day == null) return Center(child: _hint(context, _noEntries));
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
  final DateTime? selected;
  final void Function(DateTime date) onSelect;

  const _MonthGrid({
    required this.month,
    required this.byDate,
    required this.selected,
    required this.onSelect,
  });

  static const _weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];
  static const _rowHeight = 46.0;

  /// The month laid out in weeks of seven, null where no day falls.
  static List<List<int?>> _weeks(int leading, int dayCount) {
    final cells = <int?>[
      for (var i = 0; i < leading; i++) null,
      for (var day = 1; day <= dayCount; day++) day,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return <List<int?>>[
      for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    // weekday is 1 for Monday, so this is how many blanks come before the 1st.
    final leading = first.weekday - 1;
    // Day zero of the next month is the last day of this one.
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final today = dateOnly(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
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
          for (final week in _weeks(leading, dayCount))
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: <Widget>[
                  for (final dayOfMonth in week)
                    Expanded(
                      child: dayOfMonth == null
                          ? const SizedBox.shrink()
                          : _cell(
                              DateTime(month.year, month.month, dayOfMonth),
                              today,
                            ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(DateTime date, DateTime today) {
    final day = byDate[date];
    return _DayCell(
      dayOfMonth: date.day,
      hasEntries: day?.homework.isNotEmpty ?? false,
      hasWarning: day?.homework.any((h) => h.warning) ?? false,
      isToday: date == today,
      isSelected: date == selected,
      onTap: () => onSelect(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int dayOfMonth;
  final bool hasEntries;
  final bool hasWarning;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.dayOfMonth,
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
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? scheme.primary : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                "$dayOfMonth",
                style: TextStyle(
                  color: isSelected ? scheme.onPrimary : null,
                  fontWeight: isToday ? FontWeight.bold : null,
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
