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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "dd.MM.yy - dd.MM.yy", the way both week headers name a week.
String weekRangeLabel(UtcDateTime first, UtcDateTime last) {
  final format = DateFormat("dd.MM.yy");
  return "${format.format(first)} - ${format.format(last)}";
}

/// The bar above a week: arrows to page, the dates in between, and a tap on
/// the dates to pick any week.
///
/// Shared by the calendar and the Merkheft's week view, so both look and
/// behave alike (#305).
class WeekHeader extends StatelessWidget {
  /// Monday of the week shown; the date picker opens on it.
  final UtcDateTime monday;

  /// How many days the week has. Days past it cannot be picked, and a pick
  /// on one of them moves to the next week (#292).
  final int daysInWeek;

  /// What stands between the arrows — usually [weekRangeLabel].
  final Widget label;

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  /// Called with the Monday of the week the user picked, if it differs from
  /// [monday].
  final ValueChanged<UtcDateTime> onPickWeek;

  /// Shows a button back to the current week, disabled while [onToday] is
  /// null. Off where that button sits elsewhere, as in the calendar's app bar.
  final bool showToday;
  final VoidCallback? onToday;

  /// Fade the arrows and dates while the weeks are swiped.
  final Animation<double>? arrowOpacity;
  final Animation<double>? labelOpacity;

  const WeekHeader({
    super.key,
    required this.monday,
    required this.daysInWeek,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onPickWeek,
    this.showToday = false,
    this.onToday,
    this.arrowOpacity,
    this.labelOpacity,
  });

  Future<void> _pickWeek(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      firstDate: UtcDateTime(2018),
      lastDate: UtcDateTime(2050),
      initialDate: monday,
      selectableDayPredicate: (day) => day.weekday <= daysInWeek,
    );
    if (result == null) return;
    final picked = toMonday(result.makeUtc(), daysInWeek: daysInWeek);
    if (picked != monday) onPickWeek(picked);
  }

  @override
  Widget build(BuildContext context) {
    // Sideways the header is height the timetable needs more than it does.
    final density = context.isCompactHeight
        ? VisualDensity.compact
        : VisualDensity.standard;
    Widget arrow(IconData icon, String tooltip, VoidCallback onPressed) {
      return Expanded(
        child: FadeTransition(
          opacity: arrowOpacity ?? kAlwaysCompleteAnimation,
          child: Tooltip(
            message: tooltip,
            child: TextButton(
              style: TextButton.styleFrom(visualDensity: density),
              onPressed: onPressed,
              child: Icon(icon),
            ),
          ),
        ),
      );
    }

    return Material(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Row(
        children: <Widget>[
          arrow(Icons.chevron_left, tr(context).previousWeek, onPrevious),
          FadeTransition(
            opacity: labelOpacity ?? kAlwaysCompleteAnimation,
            child: TextButton(
              style: TextButton.styleFrom(
                visualDensity: density,
                textStyle: Theme.of(context).textTheme.titleLarge,
              ),
              onPressed: () => _pickWeek(context),
              child: label,
            ),
          ),
          arrow(Icons.chevron_right, tr(context).nextWeek, onNext),
          if (showToday)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: tr(context).calendarCurrentWeek,
              color: Theme.of(context).colorScheme.primary,
              visualDensity: density,
              onPressed: onToday,
            ),
        ],
      ),
    );
  }
}
