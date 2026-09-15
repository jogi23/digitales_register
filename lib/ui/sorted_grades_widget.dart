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
import 'package:dr/container/sorted_grades_container.dart';
import 'package:dr/data.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/animated_linear_progress_indicator.dart';
import 'package:dr/ui/entry_card.dart';
import 'package:dr/ui/star_rating.dart';
import 'package:dr/util.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

typedef ViewSubjectDetailCallback = void Function(Subject s);
typedef SetBoolCallback = void Function(bool byType);

class SortedGradesWidget extends StatelessWidget {
  final SortedGradesViewModel vm;
  final ViewSubjectDetailCallback viewSubjectDetail;
  final SetBoolCallback sortByTypeCallback, showCancelledCallback;
  final SetBoolCallback markedOnlyCallback;
  final void Function(int gradeId) toggleMark;
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
    required this.markedOnlyCallback,
    required this.toggleMark,
    required this.showGradeCalculator,
    this.pendingSubjectId,
    this.pendingGradeId,
    this.clearPendingSubject,
    this.clearPendingGrade,
  });

  /// Whether a marked grade of the shown semester belongs to [subject]. Only
  /// loaded grades count — a grade can only be marked once it was loaded.
  bool _hasMarked(Subject subject) =>
      subject
          .detailEntries(vm.semester)
          ?.any((e) => e is GradeDetail && vm.marked.contains(e.id)) ??
      false;

  @override
  Widget build(BuildContext context) {
    final subjects =
        vm.markedOnly ? vm.subjects.where(_hasMarked).toList() : vm.subjects;
    return Column(
      key: ValueKey(vm.semester),
      children: <Widget>[
        SwitchListTile.adaptive(
          title: Text(tr(context).gradesGroupByType),
          onChanged: sortByTypeCallback,
          value: vm.sortByType,
        ),
        SwitchListTile.adaptive(
          title: Text(tr(context).gradesShowCancelled),
          onChanged: showCancelledCallback,
          value: vm.showCancelled!,
        ),
        SwitchListTile.adaptive(
          title: Text(tr(context).gradesMarkedOnly),
          onChanged: markedOnlyCallback,
          value: vm.markedOnly,
        ),
        const Divider(
          height: 0,
        ),
        if (vm.markedOnly && subjects.isEmpty)
          ListTile(title: Text(tr(context).gradesNoneMarked)),
        for (final s in subjects)
          SubjectWidget(
            // The filter moves subjects up the list; without a key an opened
            // subject would hand its state to whichever one took its place.
            key: ValueKey(s.id ?? s.name),
            subject: s,
            marked: vm.marked.asSet(),
            markedOnly: vm.markedOnly,
            onToggleMark: toggleMark,
            sortByType: vm.sortByType,
            cards: vm.displayMode == EntryDisplayMode.cards,
            showAverage: vm.showSubjectAverage,
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
          ListTile(
            title: Text(
              tr(context).gradesExcludedHint,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListTile(
            title: Row(
              children: [
                Text(tr(context).gradesCalculator),
              ],
            ),
            subtitle:
                Text(tr(context).gradesCalculatorSubtitle),
            onTap: showGradeCalculator,
          ),
        ),
      ],
    );
  }
}

class SubjectWidget extends StatefulWidget {
  final bool sortByType, showCancelled, noInternet, ignoredForAverage;

  /// Every grade and observation in a card of its own rather than a row.
  final bool cards;

  /// Whether the subject's own average is shown next to its name.
  final bool showAverage;
  final Subject subject;
  final Semester semester;
  final VoidCallback viewSubjectDetail;
  final int? pendingSubjectId;
  final int? pendingGradeId;
  final VoidCallback? clearPendingSubject;
  final VoidCallback? clearPendingGrade;

  /// Ids of the grades the reader marked.
  final Set<int> marked;

  /// Whether only marked grades are shown.
  final bool markedOnly;

  /// Marks or unmarks a grade; null leaves out the button.
  final void Function(int gradeId)? onToggleMark;

  const SubjectWidget(
      {super.key,
      this.marked = const {},
      this.markedOnly = false,
      this.onToggleMark,
      required this.sortByType,
      required this.showAverage,
      required this.subject,
      required this.viewSubjectDetail,
      required this.showCancelled,
      required this.semester,
      required this.noInternet,
      required this.ignoredForAverage,
      this.cards = false,
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
    final Widget child;
    if (entry is! GradeDetail) {
      child = ObservationWidget(
          observation: entry as Observation, tileColor: tileColor);
    } else {
      final grade = GradeWidget(
        grade: entry,
        tileColor: tileColor,
        subjectId: widget.subject.id,
        marked: widget.marked.contains(entry.id),
        onToggleMark: widget.onToggleMark == null
            ? null
            : () => widget.onToggleMark!(entry.id),
      );
      child = widget.pendingGradeId == entry.id
          ? PendingGradeTarget(
              onVisible: widget.clearPendingGrade,
              child: grade,
            )
          : grade;
    }
    return widget.cards
        ? EntryCard(padding: EdgeInsets.zero, child: child)
        : child;
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

  /// "17 Bewertungen · 18 Kompetenzen · 2 Beobachtungen", leaving out what a
  /// subject does not have. Null while nothing has been fetched yet.
  ///
  /// The numbers come with the subject list, so they are here before a
  /// subject has ever been expanded.
  Widget? _countsMessage() {
    final counts = widget.subject.counts(widget.semester);
    if (counts == null || counts.isEmpty) return null;
    final parts = [
      _plural(counts.grades, tr(context).countGrade, tr(context).countGrades),
      _plural(counts.competences, tr(context).countCompetence, tr(context).countCompetences),
      _plural(counts.observations, tr(context).countObservation, tr(context).countObservations),
    ].nonNulls;
    return Text(
      parts.join(" · "),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Null for an empty count — nothing worth its own part of the line.
  static String? _plural(int count, String one, String many) {
    if (count == 0) return null;
    return "$count ${count == 1 ? one : many}";
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.subject.detailEntries(widget.semester);
    final theme = Theme.of(context);
    // Null while nothing is graded yet — then there is no average to show.
    final average = widget.showAverage
        ? widget.subject.formattedAverage(widget.semester)
        : null;
    final altColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.75);
    // Observations cannot be marked, so the filter leaves them out.
    bool shown(DetailEntry e) =>
        (widget.showCancelled || !e.cancelled) &&
        (!widget.markedOnly ||
            e is GradeDetail && widget.marked.contains(e.id));
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
              if (average != null)
                TextSpan(
                  text: " (Ø $average)",
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              if (widget.ignoredForAverage)
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
        subtitle: _countsMessage(),
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
                                  cards: widget.cards,
                                  entries: entry.value.where(shown).toList(),
                                  subjectId: widget.subject.id,
                                  marked: widget.marked,
                                  onToggleMark: widget.onToggleMark,
                                  pendingGradeId: widget.pendingGradeId,
                                  clearPendingGrade: widget.clearPendingGrade,
                                ),
                              )
                        else
                          for (final (i, entry) in entries.where(shown).indexed)
                            _buildDetailEntry(
                              entry,
                              // A card sets itself apart; tinting it as well
                              // would only stripe the cards.
                              tileColor:
                                  widget.cards || i.isEven ? null : altColor,
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

class GradeWidget extends ConsumerWidget {
  final GradeDetail grade;
  final Color? tileColor;

  /// Which subject the grade belongs to; without it there is nothing to
  /// open, so the tile stays inert.
  final int? subjectId;

  /// Whether the reader marked this grade.
  final bool marked;

  /// Marks or unmarks the grade; null leaves out the button.
  final VoidCallback? onToggleMark;

  const GradeWidget({
    super.key,
    required this.grade,
    this.tileColor,
    this.subjectId,
    this.marked = false,
    this.onToggleMark,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          onTap: subjectId == null
              ? null
              : () => ref.read(appRouterProvider).showGrade(
                    subjectId: subjectId!,
                    gradeId: grade.id,
                  ),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                grade.gradeFormatted,
                style: grade.cancelled ? lineThrough : null,
              ),
              if (onToggleMark != null)
                MarkGradeButton(marked: marked, onPressed: onToggleMark!),
            ],
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
    if (tileColor != null) {
      // Material statt ColoredBox: Das ListTile zeichnet sein Tippkringel auf
      // die nächste Material-Fläche darüber, und eine ColoredBox übermalt die
      // — antippen zeigte dann keine Rückmeldung. Flutter meldet das seit 3.47
      // als Zusicherung.
      return Material(color: tileColor!, child: column);
    }
    return column;
  }
}

/// The bookmark that marks a grade.
///
/// A bookmark rather than a star as on the messages: on the grades page the
/// stars are the competence ratings, and one more star read as another one.
class MarkGradeButton extends StatelessWidget {
  final bool marked;
  final VoidCallback onPressed;

  const MarkGradeButton({
    super.key,
    required this.marked,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        marked ? Icons.bookmark : Icons.bookmark_border,
        color: marked ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: marked ? tr(context).gradeUnmark : tr(context).gradeMark,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
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

  const CompetenceWidget({
    super.key,
    required this.competence,
    required this.cancelled,
  });
  @override
  Widget build(BuildContext context) {
    // A column, not a wrap: a short name used to leave the stars beside it
    // while a long one pushed them below, so no two rows lined up.
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 16, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            competence.typeName,
            style: cancelled ? lineThrough : null,
          ),
          StarRow(filled: competence.grade),
        ],
      ),
    );
  }
}

class GradeTypeWidget extends StatelessWidget {
  final String typeName;
  final List<DetailEntry> entries;
  final int? subjectId;
  final int? pendingGradeId;
  final VoidCallback? clearPendingGrade;

  /// Ids of the grades the reader marked.
  final Set<int> marked;

  /// Marks or unmarks a grade; null leaves out the button.
  final void Function(int gradeId)? onToggleMark;

  /// Every grade and observation in a card of its own rather than a row.
  final bool cards;

  const GradeTypeWidget(
      {super.key,
      required this.typeName,
      required this.entries,
      this.marked = const {},
      this.onToggleMark,
      this.subjectId,
      this.pendingGradeId,
      this.clearPendingGrade,
      this.cards = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final altColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.75);
    final displayGrades = entries
        .indexed
        .map(
          ((int, DetailEntry) pair) {
            final (i, g) = pair;
            final bgColor = cards || i.isEven ? null : altColor;
            if (g is! GradeDetail) {
              return ObservationWidget(
                observation: g as Observation,
                tileColor: bgColor,
              );
            }
            final gradeWidget = GradeWidget(
              grade: g,
              tileColor: bgColor,
              subjectId: subjectId,
              marked: marked.contains(g.id),
              onToggleMark:
                  onToggleMark == null ? null : () => onToggleMark!(g.id),
            );
            return pendingGradeId == g.id
                ? PendingGradeTarget(
                    onVisible: clearPendingGrade,
                    child: gradeWidget,
                  )
                : gradeWidget;
          },
        )
        .map<Widget>(
          (w) => cards ? EntryCard(padding: EdgeInsets.zero, child: w) : w,
        )
        .toList();
    return displayGrades.isEmpty
        ? const SizedBox()
        // Indented and quieter than the subject above it, so the grouping
        // reads as a level below the subject rather than as another subject.
        : ExpansionTile(
            tilePadding: const EdgeInsets.only(left: 32, right: 16),
            childrenPadding: const EdgeInsets.only(left: 16),
            title: Text(
              typeName,
              // A label, not a smaller entry: weight and letter spacing keep
              // it from reading as a de-emphasised version of the rows below.
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
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
