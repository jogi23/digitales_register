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
import 'package:dr/ui/layout.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
// intl has a TextDirection of its own, which shadows the one text layout
// needs.
import 'package:intl/intl.dart' hide TextDirection;

const holidayIconSize = 65.0;

class CalendarWeek extends StatelessWidget {
  final CalendarWeekViewModel vm;

  /// Height one unit of [CalendarSlot.flex] may not fall below — a lesson is
  /// worth two of them.
  ///
  /// Sideways the frame is shorter than the timetable needs; without a floor
  /// the rows were squeezed until the time column overflowed and no lesson
  /// could be read. Below the floor the week scrolls instead.
  static const minSlotHeight = 24.0;

  /// Room for the weekday and date above the grid.
  static const headerHeight = 56.0;

  const CalendarWeek({
    super.key,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    final latestHour =
        vm.days.fold<int>(0, (a, b) => a < b.toHour ? b.toHour : a);
    final grid = CalendarGrid.fromDays(vm.days, latestHour);
    // Shortened across the whole week: a room alone does not show which of
    // its words are the location every room carries.
    final roomNames = shortRoomNames([
      for (final day in vm.days)
        for (final hour in day.hours) ...tileRooms(hour.rooms),
    ]);
    return vm.days.isEmpty
        ? vm.noInternet
            ? const NoInternet()
            // An empty week is not the same as one still loading: without the
            // distinction a week that simply has no lessons spins forever.
            : vm.loading
                ? const Center(child: CircularProgressIndicator())
                : const _NoLessons()
        : _fill(
            context,
            minHeight: headerHeight + grid.totalFlex * minSlotHeight,
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
                        UtcDateTime(d.date.year, d.date.month, d.date.day),
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
                      markEntries: vm.markEntries,
                      subjectThemes: vm.subjectThemes,
                      showAllDetails: vm.showAllDetails,
                      roomNames: roomNames,
                    ),
                  ),
              ],
            ),
          );
  }

  /// The week fills the height it is given — unless that is less than
  /// [minHeight], in which case it keeps its size and scrolls.
  ///
  /// Also keeps the grid clear of the system bars, which sit at the side
  /// when the device is held sideways.
  Widget _fill(
    BuildContext context, {
    required double minHeight,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padded = Padding(padding: context.systemInsets, child: child);
        if (!constraints.hasBoundedHeight ||
            constraints.maxHeight >= minHeight) {
          return padded;
        }
        return SingleChildScrollView(
          child: SizedBox(height: minHeight, child: padded),
        );
      },
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

  /// Whether a lesson that carries an entry is marked as such.
  final bool markEntries;
  final Map<String, SubjectTheme> subjectThemes;
  final bool showAllDetails;
  final Map<String, String> roomNames;

  const _HoursChunk({
    this.highlightedSubjects,
    this.onEntryTap,
    required this.subjectNicks,
    required this.hours,
    required this.day,
    required this.selectedHour,
    required this.isSelected,
    required this.colorBackground,
    required this.markEntries,
    required this.subjectThemes,
    required this.showAllDetails,
    required this.roomNames,
  });

  /// Whether something is noted for [hour]. Nothing is noted for any of them
  /// on the calendar page, which dims none and marks none.
  bool _hasEntry(CalendarHour hour) =>
      highlightedSubjects == null ||
      highlightedSubjects!.contains(normalizeSubject(hour.subject));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
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
                  ? _tile(hours[n ~/ 2], isDark: isDark, scheme: scheme)
                  : const Divider(
                      height: 0,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// One lesson of the chunk.
  ///
  /// A lesson nothing is noted for steps back; one that carries an entry is
  /// tinted in the colour of its subject. With the colours switched off that
  /// tint is gone, and then the mark is what is left to tell the two apart
  /// (#260).
  Widget _tile(
    CalendarHour hour, {
    required bool isDark,
    required ColorScheme scheme,
  }) {
    final subject = normalizeSubject(hour.subject);
    final hasEntry = _hasEntry(hour);
    final theme = colorBackground ? subjectThemes[subject] : null;
    final marked = markEntries && hasEntry && highlightedSubjects != null;
    return HourWidget(
      hour: hour,
      dimmed: !hasEntry,
      // Only lessons that carry an entry lead anywhere; a dimmed one has
      // nothing to show.
      onEntryTap: hasEntry ? onEntryTap : null,
      subjectNicks: subjectNicks,
      showAllDetails: showAllDetails,
      roomNames: roomNames,
      day: day,
      marked: marked,
      isSelected: selectedHour == hour.fromHour,
      backgroundColor: theme != null
          ? Color(theme.color).withOpacity(isDark ? 0.4 : 0.25)
          : marked
              // Not a colour of a subject's own: it says no more than that
              // there is something here, and reads the same in both themes.
              ? scheme.secondaryContainer.withOpacity(isDark ? 0.45 : 0.7)
              : Colors.transparent,
      selectedBackgroundColor: theme != null
          ? Color(theme.color).withOpacity(isDark ? 0.65 : 0.5)
          : scheme.secondary.withAlpha(35),
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

  /// Whether a lesson that carries an entry is marked as such. What the
  /// colour says where there is one, and the only thing left to say it where
  /// there is not.
  final bool markEntries;
  final Map<String, SubjectTheme> subjectThemes;

  /// Whether the lesson tiles also name the room.
  final bool showAllDetails;

  /// Shortened room names, keyed by the name the register sends.
  final Map<String, String> roomNames;

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
    this.markEntries = false,
    required this.subjectThemes,
    this.showAllDetails = false,
    this.roomNames = const {},
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
                markEntries: markEntries,
                subjectThemes: subjectThemes,
                showAllDetails: showAllDetails,
                roomNames: roomNames,
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

  /// Marks the lesson as one that carries an entry. Set where the subject
  /// colours are switched off and the tint cannot say it (#260).
  final bool marked;

  /// Opens the day this lesson belongs to. Null falls back to selecting the
  /// lesson, which is what the calendar page does.
  final VoidCallback? onEntryTap;
  final CalendarDay day;
  final Map<String, String> subjectNicks;
  final bool isSelected;
  final Color backgroundColor;
  final Color selectedBackgroundColor;

  /// Whether the tile names the room, not only marks that there is one.
  final bool showAllDetails;

  /// Shortened room names, keyed by the name the register sends.
  final Map<String, String> roomNames;

  const HourWidget({
    super.key,
    required this.hour,
    this.dimmed = false,
    this.marked = false,
    this.onEntryTap,
    this.showAllDetails = false,
    this.roomNames = const {},
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
    final rooms = tileRooms(hour.rooms);
    final tile = InkWell(
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
          // Fills the tile, so the subject colour covers all of it rather
          // than just the width of the text.
          child: SizedBox.expand(
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _LessonLabel(
                    subject: subjectNicks[hour.subject.toLowerCase()] ??
                        hour.subject,
                    teachers: [
                      for (final teacher in hour.teachers) teacher.lastName,
                    ],
                    rooms: showAllDetails
                        ? [for (final room in rooms) roomNames[room] ?? room]
                        : const [],
                  ),
                ),
                // Whatever the setting: that the class is not in its own
                // room matters even where the tile has no line to spare.
                if (rooms.isNotEmpty)
                  const Positioned(top: 0, right: 0, child: RoomCorner()),
                // The bottom right corner, because the top right belongs to
                // the room and the left edge to the warning.
                if (marked)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                      semanticLabel: tr(context).weekLessonHasEntry,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (rooms.isEmpty) return tile;
    // The corner does not explain itself: a long press names the room, and
    // screen readers read the same.
    return Tooltip(
      message: rooms.length == 1
          ? tr(context).calendarRoomTooltip(rooms.single)
          : tr(context).calendarRoomsTooltip(rooms.join(", ")),
      child: tile,
    );
  }
}

/// The triangle in the top right corner of a lesson held outside the class's
/// own room.
///
/// A corner rather than an icon: it takes no width from the text, reads on
/// every subject colour and is told apart by its shape, not only its colour.
/// The left edge already belongs to the warning.
class RoomCorner extends StatelessWidget {
  const RoomCorner({super.key});

  static const size = 12.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(size),
      painter: _CornerPainter(Theme.of(context).colorScheme.tertiary),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  const _CornerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => oldDelegate.color != color;
}

/// Subject, teachers and, if asked for, the room of one lesson tile in the
/// week grid.
///
/// The subject keeps one size in every tile. The whole label used to sit in a
/// `FittedBox`, which shrank the subject along with however many teachers and
/// rooms came after it — three tiles in one row showed three sizes.
///
/// So now: the subject first at a fixed size, then up to two teachers in
/// italics and the room — as many lines as the tile has height for, four at
/// most (see [allotLessonLines]). To fit them all, teachers and room may
/// shrink a little; the subject never does. Without „Alle Details anzeigen“
/// the room is left to the detail view and [RoomCorner] only says there is
/// one: in a tile this narrow it pushes out what matters.
class _LessonLabel extends StatelessWidget {
  final String subject;
  final List<String> teachers;

  /// The rooms to name, already shortened. Empty leaves out the room line.
  final List<String> rooms;

  const _LessonLabel({
    required this.subject,
    required this.teachers,
    this.rooms = const [],
  });

  /// Room between text and tile edge, so names do not touch the border.
  static const padding = EdgeInsets.symmetric(horizontal: 4, vertical: 2);
  static const subjectSize = 13.0;
  static const teacherSize = 11.0;

  /// How far teachers and room may shrink to make room for the room line.
  static const minDetailSize = 10.0;

  /// Up to this many teacher lines below the subject.
  static const maxTeacherLines = 2;

  /// The teacher lines to show, at most [lines] of them. With more teachers
  /// than lines the last line says how many were left out.
  static List<String> teacherLines(List<String> teachers, int lines) {
    if (lines <= 0 || teachers.isEmpty) return const [];
    if (teachers.length <= lines) return teachers;
    // The last line names one more teacher, so it hides one fewer.
    final hidden = teachers.length - lines;
    return [
      ...teachers.take(lines - 1),
      "${teachers[lines - 1]} +$hidden",
    ];
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final subjectStyle =
        base.copyWith(fontSize: subjectSize, fontWeight: FontWeight.w500);
    final roomColor = Theme.of(context).colorScheme.tertiary;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // A single lesson is the shortest tile, so the line budget follows
        // the height actually there rather than a fixed count.
        final available = constraints.maxHeight -
            padding.vertical -
            _lineHeight(subjectStyle, scaler, direction);
        final hasRoom = rooms.isNotEmpty;
        final wanted =
            teachers.length.clamp(0, maxTeacherLines) + (hasRoom ? 1 : 0);

        var detailSize = teacherSize;
        var fitting = _linesFitting(
            available, base.copyWith(fontSize: detailSize), scaler, direction);
        if (hasRoom && fitting < wanted) {
          final smaller = _linesFitting(available,
              base.copyWith(fontSize: minDetailSize), scaler, direction);
          if (smaller > fitting) {
            detailSize = minDetailSize;
            fitting = smaller;
          }
        }
        final allotted = allotLessonLines(
          budget: fitting,
          teachers: teachers.length,
          hasRoom: hasRoom,
        );
        final lines = teacherLines(teachers, allotted.teachers);
        final teacherStyle = base.copyWith(
          fontSize: detailSize,
          fontStyle: FontStyle.italic,
        );
        final roomStyle = base.copyWith(fontSize: detailSize, color: roomColor);

        return Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: subjectStyle,
              ),
              for (final line in lines)
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: teacherStyle,
                ),
              if (allotted.room) _roomLine(roomStyle),
            ],
          ),
        );
      },
    );
  }

  /// The first room, and how many more there are. The count sits outside the
  /// ellipsis, so a long name cannot cut it off.
  Widget _roomLine(TextStyle style) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              rooms.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: style,
            ),
          ),
          if (rooms.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                "+${rooms.length - 1}",
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            ),
        ],
      );

  static int _linesFitting(
    double height,
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final line = _lineHeight(style, scaler, direction);
    return line <= 0 ? 0 : (height / line).floor();
  }

  static double _lineHeight(
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: "Hg", style: style),
      textScaler: scaler,
      textDirection: direction,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }
}

/// How the lines below the subject are shared out: [budget] lines for
/// [teachers] teachers and, if [hasRoom], one room.
///
/// The first teacher comes first, then the room, then the second teacher —
/// a second name adds less than knowing where the lesson takes place.
@visibleForTesting
({int teachers, bool room}) allotLessonLines({
  required int budget,
  required int teachers,
  required bool hasRoom,
}) {
  const maxTeachers = _LessonLabel.maxTeacherLines;
  if (budget <= 0) return (teachers: 0, room: false);
  if (!hasRoom) return (teachers: budget.clamp(0, maxTeachers), room: false);
  if (teachers == 0) return (teachers: 0, room: true);
  if (budget == 1) return (teachers: 1, room: false);
  return (teachers: (budget - 1).clamp(0, maxTeachers), room: true);
}

/// Words that name a piece of equipment rather than a place. The register
/// books a presentation camera like a room, but a lesson that has one has
/// not moved anywhere.
const _equipment = ['kamera'];

/// The rooms of a lesson that say where it takes place, without equipment.
///
/// The register only names a room when the class is not in its own, so any
/// room left means the lesson is held elsewhere.
List<String> tileRooms(Iterable<String> rooms) => [
      for (final room in rooms)
        if (room.trim().isNotEmpty &&
            !_equipment.any((word) => room.toLowerCase().contains(word)))
          room,
    ];

/// Display names for [rooms], without the words all of them start with.
///
/// The register puts the location in front of every room („Schlanders
/// Küche“, „Schlanders PC Raum“), which in a narrow tile leaves no space for
/// the part that differs. A single room keeps its name: with nothing to
/// compare it to, there is no telling where the location ends. Every room
/// keeps at least one word.
Map<String, String> shortRoomNames(Iterable<String> rooms) {
  final words = {
    for (final room in rooms) room: room.trim().split(RegExp(r"\s+")),
  };
  if (words.length < 2) return {for (final room in words.keys) room: room};

  final first = words.values.first;
  final limit = words.values
          .fold<int>(first.length, (a, w) => w.length < a ? w.length : a) -
      1;
  var common = 0;
  while (
      common < limit && words.values.every((w) => w[common] == first[common])) {
    common++;
  }
  return {
    for (final entry in words.entries)
      entry.key: common == 0 ? entry.key : entry.value.skip(common).join(" "),
  };
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
