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
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/grades_page.dart';
import 'package:dr/ui/last_fetched_overlay.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GradesPageContainer extends ConsumerWidget {
  const GradesPageContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesState = ref.watch(gradesProvider);
    final settings = ref.watch(settingsProvider);
    final noInternet = ref.watch(noInternetProvider);
    return GradesPage(
      vm: GradesPageViewModel(
        showSemester: gradesState.semester,
        loading: gradesState.loading,
        allSubjectsAverage: calculateAllSubjectsAverage(
          gradesState.subjects,
          gradesState.semester,
          settings.ignoreForGradesAverage,
        ),
        hasData: gradesState.subjects.any(
          (s) => gradesState.semester != Semester.all
              ? s.gradesAll.containsKey(gradesState.semester)
              : s.gradesAll.isNotEmpty,
        ),
        noInternet: noInternet,
        showGradesDiagram: settings.showGradesDiagram,
        showAllSubjectsAverage: settings.showAllSubjectsAverage,
        lastFetchedMessage: _lastFetchedMessage(gradesState, noInternet),
      ),
      changeSemester: ref.read(gradesProvider.notifier).setSemester,
      showGradesSettings:
          ref.read(appRouterProvider).showEditGradesAverageSettings,
    );
  }
}

class GradesPageViewModel {
  final Semester showSemester;
  final String allSubjectsAverage;
  final String? lastFetchedMessage;
  final bool loading;
  final bool showGradesDiagram;
  final bool showAllSubjectsAverage;
  final bool hasData;
  final bool noInternet;

  const GradesPageViewModel({
    required this.showSemester,
    required this.allSubjectsAverage,
    required this.lastFetchedMessage,
    required this.loading,
    required this.showGradesDiagram,
    required this.showAllSubjectsAverage,
    required this.hasData,
    required this.noInternet,
  });
}

String calculateAllSubjectsAverage(
  BuiltList<Subject> subjects,
  Semester semester,
  List<String> ignoreForGradesAverage,
) {
  var sum = 0;
  var n = 0;
  for (final subject in subjects) {
    final average = subject.average(semester);
    if (average != null &&
        !ignoreForGradesAverage.any(
          (element) => element.toLowerCase() == subject.name.toLowerCase(),
        )) {
      sum += average;
      n++;
    }
  }
  if (n == 0) {
    return "/";
  } else {
    return gradeAverageFormat.format(sum / n / 100.0);
  }
}

String? _lastFetchedMessage(GradesState gradesState, bool noInternet) {
  if (gradesState.subjects.isEmpty) {
    return null;
  }
  final timeAgoString = formatTimeAgoPerSemester(
    noInternet: noInternet,
    lastFetched: gradesState.subjects.first.lastFetchedBasic,
    semester: gradesState.semester,
  );
  if (timeAgoString == null) {
    return null;
  }
  return "Offline-Modus aktiv. $timeAgoString.";
}

String? formatTimeAgoPerSemester({
  required bool noInternet,
  required BuiltMap<Semester, UtcDateTime>? lastFetched,
  required Semester semester,
}) {
  if (lastFetched == null || !noInternet) {
    return null;
  }
  final String lastFetchedFormatted;
  if (semester == Semester.all) {
    final first = lastFetched[Semester.first];
    final second = lastFetched[Semester.second];
    if (first == null || second == null) {
      return null;
    }
    final firstFormatted = formatTimeAgo(first);
    final secondFormatted = formatTimeAgo(second);
    if (firstFormatted != secondFormatted) {
      return "Zuletzt synchronisiert $firstFormatted (1. Semester) / $secondFormatted (2. Semester)";
    }
    lastFetchedFormatted = firstFormatted;
  } else {
    final last = lastFetched[semester];
    if (last == null) {
      return null;
    }
    lastFetchedFormatted = formatTimeAgo(last);
  }
  return "Zuletzt synchronisiert $lastFetchedFormatted";
}
