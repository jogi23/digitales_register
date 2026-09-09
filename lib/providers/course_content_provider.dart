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
import 'dart:developer';

import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ein Fach, für das sich Material anfragen lässt.
@immutable
class CourseSubject {
  final int classId;
  final int subjectId;
  final String name;

  const CourseSubject({
    required this.classId,
    required this.subjectId,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      other is CourseSubject &&
      other.classId == classId &&
      other.subjectId == subjectId;

  @override
  int get hashCode => Object.hash(classId, subjectId);
}

@immutable
class CourseContentState {
  final bool loading;

  /// Die rohe Antwort des Servers, solange ihre Form nicht feststeht.
  final dynamic raw;

  /// Was schiefging - vor allem, falls der Endpunkt einem Eltern- oder
  /// Schülerkonto nicht offensteht.
  final String? error;

  const CourseContentState({this.loading = false, this.raw, this.error});
}

class CourseContentNotifier extends Notifier<CourseContentState> {
  @override
  CourseContentState build() => const CourseContentState();

  /// Fragt das Material eines Fachs an.
  ///
  /// Der Endpunkt stammt aus der Weboberfläche (`api/courseContent/getCourse`,
  /// POST mit classId und subjectId). Ob ihn ein Eltern- oder Schülerkonto
  /// aufrufen darf, ist nicht belegt - deshalb wird der Fehlerfall
  /// ausdrücklich behandelt statt durchgereicht.
  Future<void> load(CourseSubject subject) async {
    state = const CourseContentState(loading: true);
    try {
      final dynamic antwort = await wrapper.send(
        "api/courseContent/getCourse",
        args: <String, Object?>{
          "classId": subject.classId,
          "subjectId": subject.subjectId,
        },
      );
      log("courseContent/getCourse für ${subject.name}: "
          "${json.encode(antwort)}");
      state = CourseContentState(raw: antwort);
    } catch (e, trace) {
      log("courseContent/getCourse fehlgeschlagen", error: e, stackTrace: trace);
      state = CourseContentState(error: e.toString());
    }
  }
}

final courseContentProvider =
    NotifierProvider<CourseContentNotifier, CourseContentState>(
  CourseContentNotifier.new,
);
