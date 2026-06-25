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
import 'package:dr/container/grades_page_container.dart';
import 'package:dr/container/sorted_grades_container.dart';
import 'package:dr/data.dart';
import 'package:dr/ui/animated_linear_progress_indicator.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef ViewSubjectDetailCallback = void Function(Subject s);
typedef SetBoolCallback = void Function(bool byType);

class SortedGradesWidget extends StatelessWidget {
  final SortedGradesViewModel vm;
  final ViewSubjectDetailCallback viewSubjectDetail;
  final SetBoolCallback sortByTypeCallback, showCancelledCallback;
  final VoidCallback showGradeCalculator;
  final int? pendingSubjectId;
  final int? pendingGradeId;
  final VoidCallback? clearPendingSubject;
  final VoidCallback? clearPendingGrade;

  const SortedGradesWidget({
    super.key,
    required this.vm,
    required this.viewSubjectDetail,
    required this.sortByTypeCallback,
    required this.showCancelledCallback,
    required this.showGradeCalculator,
    this.pendingSubjectId,
    this.pendingGradeId,
    this.clearPendingSubject,
    this.clearPendingGrade,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(vm.semester),
      children: <Widget>[
        SwitchListTile.adaptive(
          title: const Text("Noten nach Art sortieren"),
          onChanged: sortByTypeCallback,
          value: vm.sortByType,
        ),
        SwitchListTile.adaptive(
          title: const Text("Gelöschte Noten anzeigen"),
          onChanged: showCancelledCallback,
          value: vm.showCancelled!,
        ),
        const Divider(
          height: 0,
        ),
        for (final s in vm.subjects)
          SubjectWidget(
            subject: s,
            sortByType: vm.sortByType,
            viewSubjectDetail: () => viewSubjectDetail(s),
            showCancelled: vm.showCancelled!,
            semester: vm.semester,
            noInternet: vm.noInternet,
            ignoredForAverage: vm.ignoredSubjectsForAverage.any(
              (element) => element.toLowerCase() == s.name.toLowerCase(),
            ),
            pendingSubjectId: pendingSubjectId,
            pendingGradeId: pendingGradeId,
            clearPendingSubject: clearPendingSubject,
            clearPendingGrade: clearPendingGrade,
          ),
        if (vm.subjects.any(
          (s) => vm.ignoredSubjectsForAverage.any(
            (element) => element.toLowerCase() == s.name.toLowerCase(),
          ),
        ))
          const ListTile(
            title: Text(
              "* Du hast dieses Fach aus dem Notendurchschnitt ausgeschlossen",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListTile(
            title: const Row(
              children: [
                Text("Notenrechner"),
              ],
            ),
            subtitle:
                const Text("Berechne den Durchschnitt von beliebigen Noten"),
            onTap: showGradeCalculator,
          ),
        ),
      ],
    );
  }
}

class SubjectWidget extends StatefulWidget {
  final bool sortByType, showCancelled, noInternet, ignoredForAverage;
  final Subject subject;
  final Semester semester;
  final VoidCallback viewSubjectDetail;
  final int? pendingSubjectId;
  final int? pendingGradeId;
  final VoidCallback? clearPendingSubject;
  final VoidCallback? clearPendingGrade;

  const SubjectWidget(
      {super.key,
      required this.sortByType,
      required this.subject,
      required this.viewSubjectDetail,
      required this.showCancelled,
      required this.semester,
      required this.noInternet,
      required this.ignoredForAverage,
      this.pendingSubjectId,
      this.pendingGradeId,
      this.clearPendingSubject,
      this.clearPendingGrade});

  @override
  _SubjectWidgetState createState() => _SubjectWidgetState();
}

class _SubjectWidgetState extends State<SubjectWidget> {
  bool closed = true;
  final _controller = ExpansibleController();

  Widget _buildDetailEntry(DetailEntry entry, {Color? tileColor}) {
    if (entry is! GradeDetail) {
      return ObservationWidget(
          observation: entry as Observation, tileColor: tileColor);
    }
    final child = GradeWidget(grade: entry, tileColor: tileColor);
    if (widget.pendingGradeId == entry.id) {
      return PendingGradeTarget(
        onVisible: widget.clearPendingGrade,
        child: child,
      );
    }
    return child;
  }

  @override
  void didUpdateWidget(SubjectWidget oldWidget) {
    if (oldWidget.semester != widget.semester) closed = true;
    if (widget.pendingSubjectId != null &&
        widget.pendingSubjectId == widget.subject.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (closed) _controller.expand();
          widget.clearPendingSubject?.call();
        }
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget? _lastFetchedMessage() {
    if (closed || !widget.noInternet) {
      return null;
    }
    final formatted = formatTimeAgoPerSemester(
      noInternet: widget.noInternet,
      lastFetched: widget.subject.lastFetchedDetailed,
      semester: widget.semester,
    );
    if (formatted == null) {
      return null;
    }
    return Text(
      "$formatted.",
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.subject.detailEntries(widget.semester);
    final theme = Theme.of(context);
    final altColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);
    return AbsorbPointer(
      absorbing: widget.noInternet && entries == null,
      child: ExpansionTile(
        controller: _controller,
        key: ValueKey(widget.subject.id),
        title: Text.rich(
          TextSpan(
            text: widget.subject.name,
            style: TextStyle(color: theme.colorScheme.primary),
            children: [
              if (widget.ignoredForAverage)
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        subtitle: _lastFetchedMessage(),
        leading: Text.rich(
          TextSpan(
            text: 'Ø ',
            children: <TextSpan>[
              TextSpan(
                text: detectGradingMode([widget.subject], widget.semester) ==
                        GradingMode.stars
                    ? widget.subject.starAverageFormatted(widget.semester)
                    : widget.subject.averageFormatted(widget.semester),
              ),
            ],
          ),
        ),
        trailing:
            widget.noInternet && entries == null ? const SizedBox() : null,
        onExpansionChanged: (expansion) {
          setState(() {
            closed = !expansion;
            if (expansion) {
              widget.viewSubjectDetail();
            }
          });
        },
        initiallyExpanded: !closed,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (currentChild != null) currentChild,
                    for (final child in previousChildren)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: child,
                      ),
                  ],
                );
              },
              duration: const Duration(milliseconds: 200),
              child: entries != null
                  ? Column(
                      // we're using a UniqueKey here so that the framework
                      // detects a change on every rebuild. There would be no
                      // animations otherwise, as the Column as the direct child
                      // of the AnimatedSwitcher always stays the same (just different children).
                      key: UniqueKey(),
                      children: [
                        if (widget.sortByType)
                          ...Subject.sortByType(entries).entries.map(
                                (entry) => GradeTypeWidget(
                                  typeName: entry.key,
                                  entries: entry.value
                                      .where((g) =>
                                          widget.showCancelled || !g.cancelled)
                                      .toList(),
                                  pendingGradeId: widget.pendingGradeId,
                                  clearPendingGrade: widget.clearPendingGrade,
                                ),
                              )
                        else
                          for (final (i, entry) in entries
                              .where(
                                  (g) => widget.showCancelled || !g.cancelled)
                              .indexed)
                            _buildDetailEntry(
                              entry,
                              tileColor: i.isOdd ? altColor : null,
                            )
                      ],
                    )
                  : AnimatedLinearProgressIndicator(show: !widget.noInternet),
            ),
          ),
        ],
      ),
    );
  }
}

const lineThrough = TextStyle(decoration: TextDecoration.lineThrough);

class GradeWidget extends StatelessWidget {
  final GradeDetail grade;
  final Color? tileColor;

  const GradeWidget({super.key, required this.grade, this.tileColor});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          tileColor: tileColor,
          title: Text(
            grade.name,
            style: grade.cancelled ? lineThrough : null,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!grade.description.isNullOrEmpty)
                Text(
                  grade.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              Text(
                "${DateFormat("dd.MM.yy").format(grade.date)}: ${grade.type} - ${grade.weightPercentage}%",
                style: grade.cancelled ? lineThrough : null,
              ),
              Text(
                grade.created,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (!grade.cancelledDescription.isNullOrEmpty)
                Text(
                  grade.cancelledDescription!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          trailing: Text(
            grade.gradeFormatted,
            style: grade.cancelled ? lineThrough : null,
          ),
          isThreeLine: true,
        ),
        if (grade.competences.isNotEmpty)
          for (final c in grade.competences)
            CompetenceWidget(
              competence: c,
              cancelled: grade.cancelled,
            ),
      ],
    );
  }
}

class ObservationWidget extends StatelessWidget {
  final Observation observation;
  final Color? tileColor;

  const ObservationWidget({super.key, required this.observation, this.tileColor});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: tileColor,
      title: Text(
        observation.typeName,
        style: observation.cancelled ? lineThrough : null,
      ),
      subtitle: Text(
        "${DateFormat("dd.MM.yy").format(observation.date)}${observation.note.isNullOrEmpty ? "" : ": ${observation.note}"}\n${observation.created}",
        style: observation.cancelled ? lineThrough : null,
      ),
    );
  }
}

class CompetenceWidget extends StatelessWidget {
  final Competence competence;
  final bool cancelled;

  const CompetenceWidget(
      {super.key, required this.competence, required this.cancelled});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 16, right: 8),
      child: Wrap(
        children: <Widget>[
          Text(
            competence.typeName,
            style: cancelled ? lineThrough : null,
          ),
          Row(
            children: List.generate(
              6,
              (n) => Star(
                filled: n < competence.grade,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Star extends StatelessWidget {
  final bool filled;

  const Star({super.key, required this.filled});
  @override
  Widget build(BuildContext context) {
    return Icon(filled ? Icons.star : Icons.star_border);
  }
}

class GradeTypeWidget extends StatelessWidget {
  final String typeName;
  final List<DetailEntry> entries;
  final int? pendingGradeId;
  final VoidCallback? clearPendingGrade;

  const GradeTypeWidget(
      {super.key,
      required this.typeName,
      required this.entries,
      this.pendingGradeId,
      this.clearPendingGrade});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final altColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);
    final displayGrades = entries
        .indexed
        .map(
          ((int, DetailEntry) pair) {
            final (i, g) = pair;
            final bgColor = i.isOdd ? altColor : null;
            return g is GradeDetail
                ? (pendingGradeId == g.id
                    ? PendingGradeTarget(
                        onVisible: clearPendingGrade,
                        child: GradeWidget(grade: g, tileColor: bgColor),
                      )
                    : GradeWidget(grade: g, tileColor: bgColor))
                : ObservationWidget(
                    observation: g as Observation,
                    tileColor: bgColor,
                  );
          },
        )
        .toList();
    return displayGrades.isEmpty
        ? const SizedBox()
        : ExpansionTile(
            title: Text(
              typeName,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            initiallyExpanded: true,
            children: displayGrades,
          );
  }
}

class PendingGradeTarget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onVisible;

  const PendingGradeTarget({
    super.key,
    required this.child,
    this.onVisible,
  });

  @override
  State<PendingGradeTarget> createState() => _PendingGradeTargetState();
}

class _PendingGradeTargetState extends State<PendingGradeTarget> {
  bool _handled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(covariant PendingGradeTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleScroll();
  }

  void _scheduleScroll() {
    if (_handled) return;
    _handled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Scrollable.ensureVisible(context, alignment: 0.3);
      widget.onVisible?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
