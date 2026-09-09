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
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/course_content_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/ui/course_content_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: CourseContentPage(
        subjects: subjects,
        state: state,
        subjectLabel: (subject) => appearance.nickFor(subject) ?? subject,
        onSubjectSelected:
            ref.read(courseContentProvider.notifier).load,
        onEntrySelected: (entry) => switch (entry.type) {
          CourseEntryType.text => showCourseText(context, entry),
          CourseEntryType.file =>
            ref.read(courseContentProvider.notifier).openEntry(entry),
          // Ein Link führt aus der App hinaus; ihn im Browser zu öffnen ist
          // der einzige Weg, der die Anmeldung mitnimmt.
          CourseEntryType.link => launchUrl(
              Uri.parse("${wrapper.baseAddress}api/courseContent/downloadLink"
                  "?course=${state.course?.id}&entry=${entry.id}"),
              mode: LaunchMode.externalApplication,
            ),
          CourseEntryType.unknown => Future<void>.value(),
        },
      ),
    );
  }
}
