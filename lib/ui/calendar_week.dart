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

import 'package:dr/app_state.dart';
import 'package:dr/container/calendar_week_container.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/calendar_grid.dart';
import 'package:dr/ui/last_fetched_overlay.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

const holidayIconSize = 65.0;

class CalendarWeek extends StatelessWidget {
  final CalendarWeekViewModel vm;

  const CalendarWeek({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final latestHour =
        vm.days.fold<int>(0, (a, b) => a < b.toHour ? b.toHour : a);
    final grid = CalendarGrid.fromDays(vm.days, latestHour);
    return vm.days.isEmpty
        ? vm.noInternet
            ? const NoInternet()
            // An empty week is not the same as one still loading: without the
            // distinction a week that simply has no lessons spins forever.
            : vm.loading
                ? const Center(child: CircularProgressIndicator())
                : const _NoLessons()
        : LastFetchedOverlay(
            lastFetched: vm.days.first.lastFetched,
            noInternet: vm.noInternet,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      if (vm.showTimes && grid.hasTimes) _TimeAxis(grid: grid),
                      for (final d in vm.days)
                        Expanded(
                          child: CalendarDayWidget(
                            calendarDay: d,
                            grid: grid,
                            // A day the dashboard never loaded has nothing
                            // due — passing null would leave it undimmed and
                            // make past days look like they carry work.
                            onTap: vm.onDayTap,
                            onAddReminder: vm.onAddReminder,
                            onEntryTap: vm.onEntryTap,
                            hasEntries: vm.daysWithEntries.contains(
                              UtcDateTime(
                                  d.date.year, d.date.month, d.date.day),
                            ),
                            highlightedSubjects: vm.subjectsWithEntries == null
                                ? null
                                : vm.subjectsWithEntries![UtcDateTime(
                                      d.date.year,
                                      d.date.month,
                                      d.date.day,
                                    )] ??
                                    const <String>{},
                            subjectNicks: vm.subjectNicks,
                            isSelected: vm.selection?.date == d.date,
                            selectedHour: vm.selection?.date == d.date
                                ? vm.selection?.hour
                                : null,
                            colorBackground: vm.colorBackground,
                            subjectThemes: vm.subjectThemes,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}

/// The time column left of the week grid.
///
/// Uses the same slots as the day columns, so every label lines up with the
/// lesson it belongs to. Each lesson shows its start time; the last one also
/// shows when the day ends.
class _TimeAxis extends StatelessWidget {
  final CalendarGrid grid;

  const _TimeAxis({required this.grid});

  static final _format = DateFormat("HH:mm");

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style;
    final labelStyle = baseStyle.copyWith(
      fontSize: 10,
      color: Theme.of(context).hintColor,
    );

    // Show an end time where the reader would otherwise not know when the
    // block stops: at the very end, and before a break.
    final showsEnd = <LessonSlot>{};
    LessonSlot? previous;
    for (final slot in grid.slots) {
      if (slot is BreakSlot && previous != null) showsEnd.add(previous);
      if (slot is LessonSlot && slot.time != null) previous = slot;
    }
    if (previous != null) showsEnd.add(previous);

    return SizedBox(
      width: 42,
      child: Column(
        children: <Widget>[
          // Placeholders for the weekday and date labels of a day column, so
          // the axis starts at the same height as the grid.
          const Text(""),
          Text("", style: baseStyle.copyWith(fontSize: 12)),
          for (final slot in grid.slots)
            Expanded(
              flex: slot.flex,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child:
                    _label(slot, labelStyle, showsEnd: showsEnd.contains(slot)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(CalendarSlot slot, TextStyle style, {required bool showsEnd}) {
    if (slot is BreakSlot) {
      return Center(
        child: Text("${slot.duration.inMinutes} min", style: style),
      );
    }
    final time = (slot as LessonSlot).time;
    if (time == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(_format.format(time.from), style: style),
        if (showsEnd) Text(_format.format(time.to), style: style),
      ],
    );
  }
}

/// Shown for a week the server has no lessons for — holidays, or a week
/// beyond the timetable.
class _NoLessons extends StatelessWidget {
  const _NoLessons();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          tr(context).calendarNoLessons,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// The weekday and date above a column.
///
/// Tapping it opens the day; the plus goes straight to a new reminder. A day
/// that carries entries is set apart — reminders have no subject, so the
/// coloured lessons alone would never reveal them.
class _DayHeader extends StatelessWidget {
  final UtcDateTime date;
  final bool isToday;
  final bool hasEntries;
  final void Function(UtcDateTime date)? onTap;
  final void Function(UtcDateTime date)? onAddReminder;

  const _DayHeader({
    required this.date,
    required this.isToday,
    required this.hasEntries,
    required this.onTap,
    required this.onAddReminder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isToday ? scheme.primary : null;

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(date),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasEntries
              ? scheme.primaryContainer.withValues(alpha: 0.6)
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              DateFormat("E", tr(context).localeName).format(date),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : null,
                color: accent,
              ),
            ),
            Text(
              DateFormat("dd.MM", tr(context).localeName).format(date),
              style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: accent,
                  ),
            ),
            if (onAddReminder != null)
              InkWell(
                onTap: () => onAddReminder!(date),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.add, size: 16, color: scheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HoursChunk extends StatelessWidget {
  final Set<String>? highlightedSubjects;

  /// Opens the day behind a lesson that carries an entry.
  final VoidCallback? onEntryTap;
  final Map<String, String> subjectNicks;
  final List<CalendarHour> hours;
  final CalendarDay day;
  final int? selectedHour;
  final bool isSelected;
  final bool colorBackground;
  final Map<String, SubjectTheme> subjectThemes;

  const _HoursChunk({
    this.highlightedSubjects,
    this.onEntryTap,
    required this.subjectNicks,
    required this.hours,
    required this.day,
    required this.selectedHour,
    required this.isSelected,
    required this.colorBackground,
    required this.subjectThemes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: <Widget>[
        Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey,
              width: 0.75,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          child: Container(),
        ),
        Card(
          color: Colors.transparent,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: List.generate(
              hours.length * 2 - 1,
              (n) => n.isEven
                  ? HourWidget(
                      hour: hours[n ~/ 2],
                      dimmed: highlightedSubjects != null &&
                          !highlightedSubjects!.contains(
                            normalizeSubject(hours[n ~/ 2].subject),
                          ),
                      // Only lessons that carry an entry lead anywhere; a
                      // dimmed one has nothing to show.
                      onEntryTap: highlightedSubjects != null &&
                              !highlightedSubjects!.contains(
                                normalizeSubject(hours[n ~/ 2].subject),
                              )
                          ? null
                          : onEntryTap,
                      subjectNicks: subjectNicks,
                      day: day,
                      isSelected: selectedHour == hours[n ~/ 2].fromHour,
                      backgroundColor: colorBackground &&
                              subjectThemes.containsKey(
                                  normalizeSubject(hours[n ~/ 2].subject))
                          ? Color(subjectThemes[
                                      normalizeSubject(hours[n ~/ 2].subject)]!
                                  .color)
                              .withOpacity(isDark ? 0.4 : 0.25)
                          : Colors.transparent,
                      selectedBackgroundColor: colorBackground &&
                              subjectThemes.containsKey(
                                  normalizeSubject(hours[n ~/ 2].subject))
                          ? Color(subjectThemes[
                                      normalizeSubject(hours[n ~/ 2].subject)]!
                                  .color)
                              .withOpacity(isDark ? 0.65 : 0.5)
                          : Theme.of(context)
                              .colorScheme
                              .secondary
                              .withAlpha(35),
                    )
                  : const Divider(
                      height: 0,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class CalendarDayWidget extends StatelessWidget {
  final CalendarGrid grid;
  final CalendarDay calendarDay;

  /// Lessons whose subject is not in here are dimmed. `null` dims nothing.
  final Set<String>? highlightedSubjects;

  /// Tapping the day header; null leaves it inert.
  final void Function(UtcDateTime date)? onTap;

  /// Adding a reminder for this day; null hides the button.
  final void Function(UtcDateTime date)? onAddReminder;

  /// Tapping a lesson that carries an entry; null leaves the lesson to the
  /// calendar's own selection.
  final void Function(UtcDateTime date)? onEntryTap;

  /// Whether anything is noted for this day.
  final bool hasEntries;
  final Map<String, String> subjectNicks;
  final bool isSelected;
  final int? selectedHour;
  final bool colorBackground;
  final Map<String, SubjectTheme> subjectThemes;

  const CalendarDayWidget({
    super.key,
    required this.grid,
    required this.calendarDay,
    this.highlightedSubjects,
    this.onTap,
    this.onAddReminder,
    this.onEntryTap,
    this.hasEntries = false,
    required this.subjectNicks,
    required this.isSelected,
    required this.selectedHour,
    required this.colorBackground,
    required this.subjectThemes,
  });

  /// Whether this column is the day the user is living through.
  bool get isToday {
    final today = Day.dateToday();
    return calendarDay.date.year == today.year &&
        calendarDay.date.month == today.month &&
        calendarDay.date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final chunks = <List<CalendarHour>>[];
    for (final hour in grid.splitAtBreaks(calendarDay.hours)) {
      if (chunks.isEmpty) {
        chunks.add([hour]);
      } else {
        final last = chunks.last;
        // Split on a skipped hour number (a cancelled lesson) and on a break,
        // so the gap is visible between two cards instead of inside one.
        if (last.last.toHour + 1 < hour.fromHour ||
            grid.breakAfter(last.last.toHour)) {
          chunks.add([hour]);
        } else {
          last.add(hour);
        }
      }
    }
    return Column(
      children: <Widget>[
        // Tapping a day adds a reminder to it; inert on the calendar page.
        _DayHeader(
          date: calendarDay.date,
          isToday: isToday,
          hasEntries: hasEntries,
          onTap: onTap,
          onAddReminder: onAddReminder,
        ),
        if (chunks.isNotEmpty) ...[
          for (var i = 0; i < chunks.length; i++) ...[
            Expanded(
              flex: grid.flexBefore(chunks[i].first.fromHour) -
                  (i == 0 ? 0 : grid.flexThrough(chunks[i - 1].last.toHour)),
              child: Container(),
            ),
            Expanded(
              flex: grid.flexThrough(chunks[i].last.toHour) -
                  grid.flexBefore(chunks[i].first.fromHour),
              child: _HoursChunk(
                hours: chunks[i],
                highlightedSubjects: highlightedSubjects,
                onEntryTap: onEntryTap == null
                    ? null
                    : () => onEntryTap!(calendarDay.date),
                subjectNicks: subjectNicks,
                day: calendarDay,
                selectedHour: selectedHour,
                isSelected: isSelected,
                colorBackground: colorBackground,
                subjectThemes: subjectThemes,
              ),
            )
          ],
          Expanded(
            flex: grid.totalFlex - grid.flexThrough(calendarDay.toHour),
            child: Container(),
          )
        ] else
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 4),
                  child: SizedBox(
                    height: 75,
                    width: 75,
                    child: findHolidayIconForSeason(
                      calendarDay.date,
                      Theme.of(context).iconTheme.color!,
                      holidayIconSize,
                    ),
                  ),
                ),
                Text(
                  tr(context).calendarFree,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class HourWidget extends ConsumerWidget {
  final CalendarHour hour;

  /// Pushes the lesson into the background because nothing is due in it.
  final bool dimmed;

  /// Opens the day this lesson belongs to. Null falls back to selecting the
  /// lesson, which is what the calendar page does.
  final VoidCallback? onEntryTap;
  final CalendarDay day;
  final Map<String, String> subjectNicks;
  final bool isSelected;
  final Color backgroundColor;
  final Color selectedBackgroundColor;

  const HourWidget({
    super.key,
    required this.hour,
    this.dimmed = false,
    this.onEntryTap,
    required this.subjectNicks,
    required this.day,
    required this.isSelected,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      flex: hour.length,
      child: ClipRect(child: _lesson(context, ref)),
    );
  }

  Widget _lesson(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onEntryTap ??
          () {
            ref.read(calendarProvider.notifier).select(
                  CalendarSelection((b) => b
                    ..date = day.date
                    ..hour = hour.fromHour),
                );
          },
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: hour.warning
              ? Border(
                  left: BorderSide(
                      color: Theme.of(context).colorScheme.error, width: 5),
                )
              : null,
          // Dimmed lessons lose their subject colour and keep the plain
          // background. Tinting them instead broke in dark mode, where the
          // tint was darker than the tile and made them stand out.
          color: dimmed
              ? null
              : isSelected
                  ? selectedBackgroundColor
                  : backgroundColor,
        ),
        // Fading the content is theme independent: it reads as "in the
        // background" on light and dark alike, and at this level the text
        // stays comfortably readable.
        child: Opacity(
          opacity: dimmed ? 0.6 : 1,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subjectNicks[hour.subject.toLowerCase()] ?? hour.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  if (hour.teachers.isNotEmpty)
                    const SizedBox(
                      height: 5,
                    ),
                  for (final teacher in hour.teachers)
                    Text(
                      teacher.lastName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(fontSize: 11),
                    ),
                  if (hour.rooms.isNotEmpty)
                    const SizedBox(
                      height: 5,
                    ),
                  for (final room in hour.rooms)
                    Text(
                      room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: DefaultTextStyle.of(context)
                          .style
                          .copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _dateIsNear(UtcDateTime date1, UtcDateTime date2) {
  return date1.difference(date2).inDays.abs() <= 3;
}

Widget findHolidayIconForSeason(UtcDateTime date, Color color, double size) {
  // Weekends
  if (date.weekday >= 6) {
    return Icon(
      Icons.weekend,
      color: color,
      size: size,
    );
  }
  final month = date.month;
  final day = date.day;
  // Summer
  if (month >= 6 && month <= 9) {
    return Icon(
      Icons.beach_access,
      size: size,
      color: color,
    );
  }
  // Christmas
  if (month == 12 && day >= 22 || month == 1 && day <= 10) {
    return Icon(
      Icons.ac_unit_rounded,
      size: size,
      color: color,
    );
  }
  // Halloween
  if (month == 10 && day >= 24 || month == 11 && day <= 8) {
    return SvgPicture.asset(
      "assets/halloween.svg",
      color: color,
      height: size,
      width: size,
    );
  }
  // Easter
  final easter = calculateEaster(date.year);
  if (_dateIsNear(date, easter)) {
    return SvgPicture.asset(
      "assets/easter.svg",
      color: color,
      height: size,
      width: size,
    );
  }
  // Carnival
  final carnival = easter.subtract(const Duration(days: 47));
  if (_dateIsNear(date, carnival)) {
    return SvgPicture.asset(
      "assets/carnival.svg",
      color: color,
      height: size,
      width: size,
    );
  }

  // Default
  return Icon(
    Icons.celebration,
    size: size,
    color: color,
  );
}

/// Calculate the date of easter
// https://en.wikipedia.org/wiki/Date_of_Easter#Meeus.27s_Julian_algorithm
UtcDateTime calculateEaster(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final g = (8 * b + 13) ~/ 25;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 19 * l) ~/ 433;
  final n = (h + l - 7 * m + 90) ~/ 25;
  final p = (h + l - 7 * m + 33 * n + 19) % 32;
  return UtcDateTime(year, n, p);
}
