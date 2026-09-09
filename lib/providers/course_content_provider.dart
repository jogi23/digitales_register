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

import 'dart:developer';

import 'package:dr/middleware/middleware.dart'
    show canOpenFile, downloadFile, openFile, wrapper;
import 'package:dr/util.dart';
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

/// Was hinter einem Eintrag steckt.
///
/// Die drei Arten stammen aus der Weboberfläche
/// (`courseContentItemTypes = {file, link, text}`).
enum CourseEntryType {
  file,
  link,
  text,
  unknown;

  static CourseEntryType fromName(String? name) =>
      CourseEntryType.values.asNameMap()[name] ?? CourseEntryType.unknown;
}

@immutable
class CourseEntry {
  final int id;
  final String title;
  final CourseEntryType type;

  /// Nur bei [CourseEntryType.text] gefüllt.
  final String? text;

  /// Ob die Datei schon heruntergeladen ist; nur bei [CourseEntryType.file].
  final bool fileAvailable;

  const CourseEntry({
    required this.id,
    required this.title,
    required this.type,
    this.text,
    this.fileAvailable = false,
  });

  /// Der Name, unter dem die Datei lokal liegt.
  ///
  /// Wie bei den übrigen Anhängen aus id und Titel zusammengesetzt, damit
  /// zwei gleichnamige Dateien aus verschiedenen Kursen sich nicht
  /// überschreiben.
  String get uniqueName => "course_${id}_$title";

  CourseEntry copyWith({bool? fileAvailable}) => CourseEntry(
        id: id,
        title: title,
        type: type,
        text: text,
        fileAvailable: fileAvailable ?? this.fileAvailable,
      );
}

@immutable
class CourseTopic {
  final int id;
  final String title;
  final List<CourseEntry> entries;

  const CourseTopic({
    required this.id,
    required this.title,
    required this.entries,
  });
}

@immutable
class Course {
  final int id;
  final String title;
  final List<CourseTopic> topics;

  const Course({
    required this.id,
    required this.title,
    required this.topics,
  });

  /// Der Server antwortet mit `id: 0`, wenn für Klasse und Fach nichts
  /// angelegt ist - kein Fehler, nur nichts da.
  bool get exists => id != 0;
}

@immutable
class CourseContentState {
  final CourseSubject? subject;
  final bool loading;
  final Course? course;
  final String? error;

  const CourseContentState({
    this.subject,
    this.loading = false,
    this.course,
    this.error,
  });
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
    state = CourseContentState(subject: subject, loading: true);
    try {
      final antwort = getMap(await wrapper.send(
        "api/courseContent/getCourse",
        args: <String, Object?>{
          "classId": subject.classId,
          "subjectId": subject.subjectId,
        },
      ));
      state = CourseContentState(
        subject: subject,
        course: _parseCourse(antwort),
      );
    } catch (e, trace) {
      log("courseContent/getCourse fehlgeschlagen", error: e, stackTrace: trace);
      state = CourseContentState(subject: subject, error: e.toString());
    }
  }

  Course _parseCourse(Map? antwort) {
    final id = getInt(antwort?["id"]) ?? 0;
    if (id == 0) {
      return const Course(id: 0, title: '', topics: []);
    }
    return Course(
      id: id,
      title: getString(getMap(antwort?["course"])?["title"]) ?? '',
      topics: [
        for (final dynamic topic in getList(antwort?["topics"]) ?? const [])
          CourseTopic(
            id: getInt(topic["id"]) ?? 0,
            title: getString(topic["title"]) ?? '',
            entries: [
              for (final dynamic entry
                  in getList(topic["entries"]) ?? const [])
                CourseEntry(
                  id: getInt(entry["id"]) ?? 0,
                  title: getString(entry["title"]) ?? '',
                  type: CourseEntryType.fromName(getString(entry["type"])),
                  text: getString(entry["text"]),
                ),
            ],
          ),
      ],
    );
  }

  /// Lädt die Datei eines Eintrags herunter und öffnet sie.
  ///
  /// Nutzt denselben Weg wie die übrigen Anhänge, also auch dieselbe
  /// Rückfrage beim Überschreiben und denselben Ordner.
  Future<void> openEntry(CourseEntry entry) async {
    final course = state.course;
    if (course == null || entry.type != CourseEntryType.file) return;
    if (!await canOpenFile(entry.uniqueName)) {
      _setAvailable(entry, false);
      final erfolg = await downloadFile(
        "${wrapper.baseAddress}api/courseContent/download",
        entry.uniqueName,
        <String, dynamic>{"course": course.id, "entry": entry.id},
      );
      if (!erfolg) return;
    }
    _setAvailable(entry, true);
    await openFile(entry.uniqueName);
  }

  void _setAvailable(CourseEntry entry, bool verfuegbar) {
    final course = state.course;
    if (course == null) return;
    state = CourseContentState(
      subject: state.subject,
      course: Course(
        id: course.id,
        title: course.title,
        topics: [
          for (final topic in course.topics)
            CourseTopic(
              id: topic.id,
              title: topic.title,
              entries: [
                for (final e in topic.entries)
                  if (e.id == entry.id)
                    e.copyWith(fileAvailable: verfuegbar)
                  else
                    e,
              ],
            ),
        ],
      ),
    );
  }
}

final courseContentProvider =
    NotifierProvider<CourseContentNotifier, CourseContentState>(
  CourseContentNotifier.new,
);
