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
import 'package:dr/ui/sorted_grades_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SortedGradesContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradesState = ref.watch(gradesProvider);
    final settings = ref.watch(settingsProvider);
    final noInternet = ref.watch(noInternetProvider);
    return SortedGradesWidget(
      vm: SortedGradesViewModel(
        subjects: gradesState.subjects,
        semester: gradesState.semester,
        sortByType: settings.typeSorted,
        showCancelled: settings.showCancelled,
        noInternet: noInternet,
        ignoredSubjectsForAverage: settings.ignoreForGradesAverage,
      ),
      showCancelledCallback:
          ref.read(settingsProvider.notifier).setShowCancelledGrades,
      sortByTypeCallback:
          ref.read(settingsProvider.notifier).setGradesTypeSorted,
      showGradeCalculator: ref.read(appRouterProvider).showGradeCalculator,
      viewSubjectDetail: (s) => ref
          .read(gradesProvider.notifier)
          .loadDetails(s, gradesState.semester),
    );
  }
}

typedef ViewSubjectDetailCallback = void Function(Subject s);
typedef SetBoolCallback = void Function(bool byType);

class SortedGradesViewModel {
  final BuiltList<Subject> subjects;
  final BuiltList<String> ignoredSubjectsForAverage;
  final Semester semester;
  final bool sortByType;
  final bool? showCancelled;
  final bool noInternet;

  const SortedGradesViewModel({
    required this.subjects,
    required this.ignoredSubjectsForAverage,
    required this.semester,
    required this.sortByType,
    required this.showCancelled,
    required this.noInternet,
  });
}
