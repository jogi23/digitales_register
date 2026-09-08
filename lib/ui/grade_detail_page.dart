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

import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/ui/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Which grade the detail page shows. Passed as the route's argument.
class GradeDetailArgs {
  final int subjectId;
  final int gradeId;

  const GradeDetailArgs({required this.subjectId, required this.gradeId});
}

/// Everything the register knows about a single grade.
///
/// The list can only show so much: the per-competence comments and the
/// "visible from" date have nowhere to go there.
class GradeDetailPage extends ConsumerStatefulWidget {
  final GradeDetailArgs args;

  const GradeDetailPage({super.key, required this.args});

  @override
  ConsumerState<GradeDetailPage> createState() => _GradeDetailPageState();
}

class _GradeDetailPageState extends ConsumerState<GradeDetailPage> {
  @override
  void initState() {
    super.initState();
    // The cancellation reason and the visibility date only come from
    // getGrade, so they are fetched when the grade is actually opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(gradesProvider);
      final grade = _find(state)?.grade;
      if (grade == null) return;
      unawaited(
        ref.read(gradesProvider.notifier).loadGradeDetail(
              grade,
              state.semester,
            ),
      );
    });
  }

  /// The grade and the subject it belongs to, or null once it is gone —
  /// a semester switch or a refresh can take it away while the page is open.
  ({Subject subject, GradeDetail grade})? _find(GradesState state) {
    for (final subject in state.subjects) {
      if (subject.id != widget.args.subjectId) continue;
      final entries = subject.detailEntries(state.semester);
      for (final entry in entries ?? const <DetailEntry>[]) {
        if (entry is GradeDetail && entry.id == widget.args.gradeId) {
          return (subject: subject, grade: entry);
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final found = _find(ref.watch(gradesProvider));
    return Scaffold(
      appBar: AppBar(title: Text(found?.subject.name ?? "Bewertung")),
      body: found == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Diese Bewertung ist nicht mehr verfügbar",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _GradeDetail(grade: found.grade),
    );
  }
}

class _GradeDetail extends StatelessWidget {
  final GradeDetail grade;

  const _GradeDetail({required this.grade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strikethrough = grade.cancelled
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 24,
      ),
      children: [
        ListTile(
          title: Text(
            grade.name,
            style: theme.textTheme.titleLarge?.merge(strikethrough),
          ),
          subtitle: Text(
            "${DateFormat("dd.MM.yyyy").format(grade.date)} · ${grade.type} · ${grade.weightPercentage}%",
          ),
          trailing: grade.grade == null
              ? null
              : Text(
                  grade.gradeFormatted,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: theme.colorScheme.primary)
                      .merge(strikethrough),
                ),
        ),
        if (!_isEmpty(grade.description)) ...[
          const Divider(),
          _Section(title: "Kommentar", child: Text(grade.description!)),
        ],
        if (grade.competences.isNotEmpty) ...[
          const Divider(),
          _Section(
            title: "Kompetenzen",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final competence in grade.competences)
                  _CompetenceDetail(competence: competence),
              ],
            ),
          ),
        ],
        const Divider(),
        _Section(
          title: "Eingetragen",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(grade.created),
              if (!_isEmpty(grade.visibleAtFormatted))
                Text(grade.visibleAtFormatted!),
            ],
          ),
        ),
        if (grade.cancelled) ...[
          const Divider(),
          _Section(
            title: "Gelöscht",
            child: Text(
              _isEmpty(grade.cancelledDescription)
                  ? "Diese Bewertung wurde gelöscht."
                  : grade.cancelledDescription!,
            ),
          ),
        ],
      ],
    );
  }

  static bool _isEmpty(String? text) => text == null || text.trim().isEmpty;
}

/// One competence with its stars and, if the teacher wrote one, its comment.
class _CompetenceDetail extends StatelessWidget {
  final Competence competence;

  const _CompetenceDetail({required this.competence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = competence.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            competence.typeName,
            // Set apart from its own comment right below it.
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          StarRow(filled: competence.grade, size: 20),
          if (description != null && description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
