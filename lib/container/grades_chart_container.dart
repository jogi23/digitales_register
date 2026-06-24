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
import 'package:dr/data.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/grades_chart.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GradesChartContainer extends ConsumerWidget {
  final bool isFullscreen;

  const GradesChartContainer({super.key, required this.isFullscreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesState = ref.watch(gradesProvider);
    final settings = ref.watch(settingsProvider);
    final gradingMode = detectGradingMode(
      gradesState.subjects,
      gradesState.semester,
    );

    SubjectGrades getKey(Subject subject) {
      if (gradingMode == GradingMode.stars) {
        final grades = subject
                .detailEntries(gradesState.semester)
                ?.whereType<GradeDetail>()
                .where(
                    (grade) => !grade.cancelled && grade.competences.isNotEmpty)
                .toList() ??
            [];
        return SubjectGrades(
          {
            for (final grade in grades)
              grade.date: GradeChartPoint(
                value: grade.competences
                        .map((c) => c.grade)
                        .reduce((a, b) => a + b) /
                    grade.competences.length,
                type: grade.type,
                mode: GradingMode.stars,
                competences: grade.competences,
              ),
          },
          subject.name,
          GradingMode.stars,
        );
      }

      final grades = gradesState.semester == Semester.all
          ? (subject.gradesAll.values.fold<List<GradeAll>>(
              <GradeAll>[], (a, b) => <GradeAll>[...a, ...b])
            ..sort((GradeAll a, GradeAll b) => a.date.compareTo(b.date)))
          : subject.gradesAll[gradesState.semester]?.toList() ?? [];
      grades.removeWhere((grade) => grade.cancelled || grade.grade == null);
      return SubjectGrades(
        {
          for (final grade in grades)
            grade.date: GradeChartPoint(
              value: grade.grade! / 100,
              type: grade.type,
              mode: GradingMode.numeric,
              numericGrade: grade.grade,
            ),
        },
        subject.name,
        GradingMode.numeric,
      );
    }

    SubjectTheme getValue(Subject subject) {
      return settings.subjectThemes[subject.name]!;
    }

    final graphs = {
      for (final subject in gradesState.subjects)
        if (settings.subjectThemes.containsKey(subject.name))
          getKey(subject): getValue(subject)
    };

    return GradesChart(
      graphs: graphs,
      gradingMode: gradingMode,
      isFullscreen: isFullscreen,
      goFullscreen: ref.read(appRouterProvider).showGradesChart,
    );
  }
}

class GradeChartPoint {
  final double value;
  final String type;
  final GradingMode mode;
  final int? numericGrade;
  final BuiltList<Competence>? competences;

  const GradeChartPoint({
    required this.value,
    required this.type,
    required this.mode,
    this.numericGrade,
    this.competences,
  });
}

class SubjectGrades {
  final Map<UtcDateTime, GradeChartPoint> grades;
  final String name;
  final GradingMode mode;

  SubjectGrades(this.grades, this.name, this.mode);
}
