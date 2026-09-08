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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/container/grades_chart_container.dart';
import 'package:dr/data.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _Selection {
  final String text;
  final Color color;

  _Selection(this.text, this.color);
}

/// One subject's grades over time, ready to be drawn.
class _SubjectLine {
  final String name;
  final Color color;
  final double width;

  /// Sorted by date, which is what the axis and the tick maths assume.
  final List<MapEntry<UtcDateTime, GradeChartPoint>> points;

  const _SubjectLine({
    required this.name,
    required this.color,
    required this.width,
    required this.points,
  });
}

class GradesChart extends StatefulWidget {
  final VoidCallback? goFullscreen;
  final bool isFullscreen;
  final GradingMode gradingMode;
  final Map<SubjectGrades, SubjectTheme> graphs;

  const GradesChart({
    super.key,
    required this.graphs,
    required this.gradingMode,
    this.goFullscreen,
    required this.isFullscreen,
  });

  @override
  State<GradesChart> createState() => _GradesChartState();
}

class _GradesChartState extends State<GradesChart> {
  /// One day in milliseconds — the axis works in epoch milliseconds, and this
  /// is the step between two possible date labels.
  static const _dayMs = 86400000.0;

  /// What the reader last tapped on, if anything.
  (UtcDateTime, BuiltList<_Selection>)? _selection;

  late List<_SubjectLine> _lines = _buildLines();

  @override
  void didUpdateWidget(GradesChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _lines = _buildLines();
    _selection = null;
  }

  List<_SubjectLine> _buildLines() {
    return widget.graphs.entries
        .where((entry) => entry.value.thick != 0)
        .map(
          (entry) => _SubjectLine(
            name: entry.key.name,
            color: Color(entry.value.color),
            width: entry.value.thick.toDouble(),
            points: entry.key.grades.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key)),
          ),
        )
        .toList();
  }

  /// The dates that should carry a label.
  ///
  /// Preferably the 15th of every month; if the first date is later than that,
  /// the tick moves to it so no month goes unlabelled. A range inside a single
  /// month gets its first and last date instead.
  List<UtcDateTime> _tickDates() {
    UtcDateTime? first;
    UtcDateTime? last;
    for (final line in _lines) {
      if (line.points.isEmpty) continue;
      final firstOfLine = line.points.first.key;
      final lastOfLine = line.points.last.key;
      if (first == null || firstOfLine.isBefore(first)) first = firstOfLine;
      if (last == null || lastOfLine.isAfter(last)) last = lastOfLine;
    }
    if (first == null || last == null) return [];

    final dates = [
      UtcDateTime(first.year, first.month, first.day < 15 ? 15 : first.day),
    ];
    while (true) {
      final next = UtcDateTime(dates.last.year, dates.last.month + 1, 15);
      if (last.isBefore(next)) break;
      dates.add(next);
    }
    if (dates.last.month != last.month) dates.add(last);
    if (dates.length > 1) return dates;
    return first == last ? [first] : [first, last];
  }

  /// Tick position in epoch milliseconds to the label it carries.
  Map<double, String> _domainTicks(Locale locale) {
    final dates = _tickDates();
    // Inside a single month the day matters, across months it does not.
    final format = dates.length > 2
        ? DateFormat.MMM(locale.toLanguageTag())
        : DateFormat.MMMd(locale.toLanguageTag());
    return {
      for (final date in dates)
        date.millisecondsSinceEpoch.toDouble(): format.format(date),
    };
  }

  /// First and last position of the axis, in epoch milliseconds.
  ///
  /// A little padding on both ends keeps the outermost points off the edge.
  (double, double)? _domainRange() {
    DateTime? first;
    DateTime? last;
    for (final line in _lines) {
      for (final point in line.points) {
        if (first == null || point.key.isBefore(first)) first = point.key;
        if (last == null || point.key.isAfter(last)) last = point.key;
      }
    }
    if (first == null || last == null) return null;
    final padding = Duration(hours: last.difference(first).inHours ~/ 100);
    return (
      first.subtract(padding).millisecondsSinceEpoch.toDouble(),
      last.add(padding).millisecondsSinceEpoch.toDouble(),
    );
  }

  /// The grades the axis is scaled to: stars go from 1 to 6, marks from 3 to
  /// 10 — below 3 nothing is ever awarded.
  List<int> get _measureTicks => widget.gradingMode == GradingMode.stars
      ? const [1, 2, 3, 4, 5, 6]
      : const [3, 4, 5, 6, 7, 8, 9, 10];

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    final spots = response?.lineBarSpots;
    if (spots == null || spots.isEmpty) return;
    // The spots arrive sorted by distance: the nearest one decides which date
    // is being read, and the other lines only join in on that same date.
    final touchedX = spots.first.x;
    final date = _lines[spots.first.barIndex].points[spots.first.spotIndex].key;
    final selections = <_Selection>[];
    for (final spot in spots) {
      if (spot.x != touchedX) continue;
      final line = _lines[spot.barIndex];
      final point = line.points[spot.spotIndex].value;
      selections.add(
        _Selection(formatChartSelectionText(line.name, point), line.color),
      );
    }
    if (selections.isEmpty) return;
    setState(() => _selection = (date, selections.toBuiltList()));
  }

  /// Which spot of [line] the indicator is drawn on, if any.
  List<int> _shownIndicators(_SubjectLine line) {
    final date = _selection?.$1;
    if (date == null) return const [];
    final index = line.points.indexWhere((point) => point.key == date);
    return index == -1 ? const [] : [index];
  }

  LineChartBarData _bar(_SubjectLine line) {
    return LineChartBarData(
      spots: [
        for (final point in line.points)
          FlSpot(
            point.key.millisecondsSinceEpoch.toDouble(),
            point.value.value,
          ),
      ],
      isCurved: false,
      color: line.color,
      barWidth: line.width,
      isStrokeCapRound: true,
      showingIndicators: _shownIndicators(line),
      dotData: FlDotData(
        show: widget.isFullscreen,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          // Wide enough to stay visible on top of the line itself.
          radius: line.width / 2 + 2,
          color: line.color,
          strokeWidth: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final darkMode = theme.brightness == Brightness.dark;
    final labelStyle = TextStyle(
      fontSize: 10,
      color: darkMode ? Colors.white : Colors.black,
    );
    final range = _domainRange();
    final ticks = _domainTicks(Localizations.localeOf(context));

    return GestureDetector(
      onTap: widget.isFullscreen ? null : widget.goFullscreen,
      child: Stack(
        children: [
          Hero(
            tag: 1337,
            child: Padding(
              // Room for the topmost grade label and for the line not to end
              // flush against the edge.
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: LineChart(
                LineChartData(
                  minX: range?.$1,
                  maxX: range?.$2,
                  minY: _measureTicks.first.toDouble(),
                  maxY: _measureTicks.last.toDouble(),
                  lineBarsData: [for (final line in _lines) _bar(line)],
                  clipData: const FlClipData.all(),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          if (!_measureTicks.contains(value.round()) ||
                              value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 4,
                            child: Text('${value.round()}', style: labelStyle),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        // fl_chart puts ticks on a fixed grid instead of at
                        // given positions. A step of one day, counted from the
                        // epoch, lands exactly on the midnights the grades carry
                        // — so the days that should be labelled can be picked
                        // out and the rest left blank.
                        interval: _dayMs,
                        // Enough for a 10px label plus its small gap; more
                        // would only take height away from the chart.
                        reservedSize: 18,
                        getTitlesWidget: (value, meta) {
                          final label = ticks[value];
                          if (label == null) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: 2,
                            // Keeps the outermost labels from hanging over the
                            // edge of the chart.
                            fitInside:
                                SideTitleFitInsideData.fromTitleMeta(meta),
                            child: Text(label, style: labelStyle),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: widget.isFullscreen,
                    touchCallback: _onTouch,
                    // A tap anywhere picks the nearest grade, rather than only
                    // one within a few pixels — the chart is read by tapping
                    // roughly at a date, not by hitting a dot.
                    touchSpotThreshold: double.maxFinite,
                    // The selection stays until the next tap. fl_chart's own
                    // handling would clear it the moment the finger lifts, and
                    // it overwrites showingIndicators while it is on.
                    handleBuiltInTouches: false,
                    getTouchedSpotIndicator: (bar, indexes) => [
                      for (final _ in indexes)
                        TouchedSpotIndicatorData(
                          FlLine(
                            color: theme.dividerColor,
                            strokeWidth: 1,
                            dashArray: const [4, 4],
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: barData.color ?? Colors.grey,
                              strokeWidth: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.isFullscreen)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: SelectionWidget(
                  date: _selection?.$1,
                  selections: _selection?.$2,
                ),
              ),
            ),
          if (!widget.isFullscreen)
            const Positioned(
              right: 20,
              bottom: 20,
              child: Icon(Icons.fullscreen),
            ),
        ],
      ),
    );
  }
}

String formatStarValue(double value) =>
    '${gradeAverageFormat.format(value)}/6★';

String formatChartSelectionText(String subject, GradeChartPoint point) {
  if (point.mode == GradingMode.numeric) {
    return "$subject – ${point.type}: ${formatGradeFromInt(point.numericGrade)}";
  }
  return [
    "$subject – ${point.type}: ${formatStarValue(point.value)}",
    if (point.competences?.isNotEmpty == true)
      ...point.competences!.map(
        (c) => "${c.typeName}: ${c.grade}★",
      ),
  ].join("\n");
}

class SelectionWidget extends StatelessWidget {
  final UtcDateTime? date;
  final BuiltList<_Selection>? selections;

  const SelectionWidget({super.key, this.date, this.selections});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      layoutBuilder: (currentChild, previousChildren) => AnimatedSize(
        alignment: Alignment.topCenter,
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
      ),
      duration: const Duration(milliseconds: 150),
      child: date != null && selections?.isNotEmpty == true
          ? Column(
              key: ValueKey(selections),
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.black,
                  ),
                  child: Text(
                    DateFormat.MMMMd("de").format(date!),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                for (final selection in selections!)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: selection.color,
                    ),
                    child: Text(
                      selection.text,
                      style: TextStyle(color: readableOn(selection.color)),
                    ),
                  ),
              ],
            )
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade700,
              ),
              child: const Text(
                "Tippe auf das Diagramm, um Details zu sehen",
                style: TextStyle(color: Colors.white),
              ),
            ),
    );
  }
}
