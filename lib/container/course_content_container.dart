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

import 'dart:convert';

import 'package:dr/app_state.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/course_content_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

/// Die Fächer, für die sich Material anfragen lässt.
///
/// Klasse und Fachnummer stehen in jeder Kalenderstunde; ein Fach ohne beide
/// lässt sich nicht anfragen und bleibt weg.
List<CourseSubject> courseSubjects(CalendarState calendar) {
  final gefunden = <CourseSubject>{};
  for (final day in calendar.days.values) {
    for (final hour in day.hours) {
      final classId = hour.classId;
      final subjectId = hour.subjectId;
      if (classId == null || subjectId == null) continue;
      gefunden.add(CourseSubject(
        classId: classId,
        subjectId: subjectId,
        name: hour.subject,
      ));
    }
  }
  final liste = gefunden.toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  return liste;
}

class CourseContentContainer extends ConsumerWidget {
  const CourseContentContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(calendarProvider);
    final appearance = ref.watch(subjectAppearanceProvider);
    final state = ref.watch(courseContentProvider);
    final subjects = courseSubjects(calendar);

    return Scaffold(
      appBar: ResponsiveAppBar(
        title: Text(tr(context).menuCourseContent),
        actions: const [AccountAvatarButton()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final subject in subjects)
                  ActionChip(
                    label: Text(
                      appearance.nickFor(subject.name) ?? subject.name,
                    ),
                    tooltip: subject.name,
                    onPressed: () => ref
                        .read(courseContentProvider.notifier)
                        .load(subject),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: switch (state) {
              CourseContentState(loading: true) =>
                const Center(child: CircularProgressIndicator()),
              CourseContentState(error: final String fehler) =>
                _Meldung(text: fehler),
              CourseContentState(raw: null) =>
                _Meldung(text: tr(context).courseContentPickSubject),
              _ => SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(state.raw),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _Meldung extends StatelessWidget {
  final String text;

  const _Meldung({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}
