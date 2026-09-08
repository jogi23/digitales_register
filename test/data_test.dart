// Copyright (C) 2026 Johannes Feichter
import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart' show Semester;
import 'package:dr/data.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

Homework _hw({
  int id = 1,
  String title = 'Test',
  String subtitle = 'subtitle',
  String? label,
  HomeworkType type = HomeworkType.gradeGroup,
}) {
  return Homework((b) => b
    ..id = id
    ..title = title
    ..subtitle = subtitle
    ..label = label
    ..type = type
    ..checked = false);
}

Subject _subject({
  String name = 'Fach',
  List<GradeAll>? basicGrades,
  List<GradeDetail>? detailGrades,
}) {
  return Subject(
    (b) => b
      ..name = name
      ..gradesAll = MapBuilder({
        if (basicGrades != null)
          Semester.first: BuiltList<GradeAll>(basicGrades),
      })
      ..grades = MapBuilder({
        if (detailGrades != null)
          Semester.first: BuiltList<GradeDetail>(detailGrades),
      })
      ..observations = MapBuilder({
        Semester.first: BuiltList<Observation>([]),
      }),
  );
}


GradeDetail _gradeDetail({
  int id = 1,
  bool cancelled = false,
  List<Competence> competences = const [],
}) {
  return GradeDetail(
    (b) => b
      ..id = id
      ..name = 'Bewertung'
      ..type = 'Schularbeit'
      ..created = ''
      ..weightPercentage = 100
      ..cancelled = cancelled
      ..date = UtcDateTime(2026, 5, 11)
      ..competences = ListBuilder(competences),
  );
}

Observation _observation({bool cancelled = false}) {
  return Observation(
    (b) => b
      ..typeName = 'Beobachtung'
      ..created = ''
      ..note = ''
      ..cancelled = cancelled
      ..date = UtcDateTime(2026, 5, 11),
  );
}

Competence _competence() => Competence(
      (b) => b
        ..typeName = 'Kompetenz'
        ..grade = 5,
    );

/// A subject as it looks after a fetch: [reported] are the register's own
/// counts, [detailGrades]/[observations] the entries once they are loaded.
Subject _counted({
  Map<Semester, int> reportedObservations = const {},
  Map<Semester, int> reportedCompetences = const {},
  List<GradeAll>? basicGrades,
  List<GradeDetail>? detailGrades,
  List<Observation>? observations,
}) {
  final semester = Semester.first;
  return Subject(
    (b) => b
      ..name = 'Fach'
      ..gradesAll = MapBuilder({
        if (basicGrades != null) semester: BuiltList<GradeAll>(basicGrades),
      })
      ..grades = MapBuilder({
        if (detailGrades != null) semester: BuiltList<GradeDetail>(detailGrades),
      })
      ..observations = MapBuilder({
        if (observations != null) semester: BuiltList<Observation>(observations),
      })
      ..observationCounts = MapBuilder(reportedObservations)
      ..competenceCounts = MapBuilder(reportedCompetences),
  );
}

void main() {

  group('Subject.counts', () {
    test('are unknown before anything was fetched', () {
      expect(_counted().counts(Semester.first), isNull);
    });

    test("uses the register's own numbers before the details arrive", () {
      // They come with the subject list, which is the whole point: the
      // overview can show them without expanding a subject first.
      final subject = _counted(
        basicGrades: [],
        reportedCompetences: {Semester.first: 18},
        reportedObservations: {Semester.first: 2},
      );
      final counts = subject.counts(Semester.first)!;
      expect(counts.competences, 18);
      expect(counts.observations, 2);
    });

    test('counts the loaded entries once they are there', () {
      // Classes graded in competences report an empty grade list in the
      // overview, so the grade count has to come from the details.
      final subject = _counted(
        basicGrades: [],
        reportedCompetences: {Semester.first: 18},
        reportedObservations: {Semester.first: 2},
        detailGrades: [
          _gradeDetail(id: 1, competences: [_competence(), _competence()]),
          _gradeDetail(id: 2, competences: [_competence()]),
        ],
        observations: [_observation()],
      );
      final counts = subject.counts(Semester.first)!;
      expect(counts.grades, 2);
      expect(counts.competences, 3);
      expect(counts.observations, 1);
    });

    test('leaves cancelled entries out', () {
      final subject = _counted(
        basicGrades: [],
        detailGrades: [
          _gradeDetail(id: 1, competences: [_competence()]),
          _gradeDetail(id: 2, cancelled: true, competences: [_competence()]),
        ],
        observations: [_observation(), _observation(cancelled: true)],
      );
      final counts = subject.counts(Semester.first)!;
      expect(counts.grades, 1);
      expect(counts.competences, 1);
      expect(counts.observations, 1);
    });

    test('adds up both halves for the whole year', () {
      // The register reports per semester and has no total of its own.
      final subject = _counted(
        basicGrades: [],
        reportedCompetences: {Semester.first: 4, Semester.second: 3},
        reportedObservations: {Semester.first: 1, Semester.second: 2},
      );
      final counts = subject.counts(Semester.all)!;
      expect(counts.competences, 7);
      expect(counts.observations, 3);
    });

    test('is empty for a subject without any entries', () {
      final counts = _counted(basicGrades: []).counts(Semester.first)!;
      expect(counts.isEmpty, isTrue);
    });
  });

  group('Subject.formattedAverage', () {
    GradeAll _basic(int grade) => GradeAll(
          (b) => b
            ..grade = grade
            ..weightPercentage = 100
            ..cancelled = false
            ..date = UtcDateTime(2026, 5, 11)
            ..type = 'Schularbeit',
        );

    test('is null while nothing has been graded', () {
      // "Ø /" next to a subject says nothing worth the space.
      expect(_counted(basicGrades: []).formattedAverage(Semester.first),
          isNull);
    });

    test('is null before the grades were fetched', () {
      expect(_counted().formattedAverage(Semester.first), isNull);
    });

    test('formats the numeric average', () {
      final subject = _counted(basicGrades: [_basic(700), _basic(800)]);
      expect(subject.formattedAverage(Semester.first), '7,5');
    });

    test('formats the star average out of six', () {
      final subject = _counted(
        basicGrades: [],
        detailGrades: [
          _gradeDetail(competences: [_competence(), _competence()]),
        ],
        observations: [],
      );
      expect(subject.formattedAverage(Semester.first), '5/6');
    });
  });

  group('formatGradeFromString', () {
    test('null returns ohne Note', () {
      expect(formatGradeFromString(null), 'ohne Note');
    });

    test('"7.00" formats to "7"', () {
      expect(formatGradeFromString('7.00'), '7');
    });

    test('"7.25" formats to "7+"', () {
      expect(formatGradeFromString('7.25'), '7+');
    });

    test('"7.50" formats to "7/8"', () {
      expect(formatGradeFromString('7.50'), '7/8');
    });

    test('"7.75" formats to "8-"', () {
      expect(formatGradeFromString('7.75'), '8-');
    });

    test('unknown decimals pass through unchanged', () {
      expect(formatGradeFromString('5.33'), '5.33');
    });

    test('"1.00" formats to "1"', () {
      expect(formatGradeFromString('1.00'), '1');
    });

    test('"10.50" formats to "10/11"', () {
      expect(formatGradeFromString('10.50'), '10/11');
    });
  });

  group('Homework.isSuccessorOf', () {
    test('grade replaces gradeGroup with same label and subtitle → true', () {
      final gradeEntry = _hw(
        id: 2,
        type: HomeworkType.grade,
        label: 'Schularbeit 1',
        subtitle: 'Kapitel 3',
      );
      final gradeGroupEntry = _hw(
        label: 'Schularbeit 1',
        subtitle: 'Kapitel 3',
      );
      expect(gradeEntry.isSuccessorOf(gradeGroupEntry), true);
    });

    test('grade replaces gradeGroup with different label → false', () {
      final gradeEntry = _hw(
        id: 2,
        type: HomeworkType.grade,
        label: 'Schularbeit 2',
        subtitle: 'Kapitel 3',
      );
      final gradeGroupEntry = _hw(
        label: 'Schularbeit 1',
        subtitle: 'Kapitel 3',
      );
      expect(gradeEntry.isSuccessorOf(gradeGroupEntry), false);
    });

    test('identical but subtitle is prefix of other → true', () {
      final amended = _hw(
        label: 'L1',
        subtitle: 'Kapitel 3 - Zusatzaufgaben',
      );
      final original = _hw(
        label: 'L1',
        subtitle: 'Kapitel 3',
      );
      expect(amended.isSuccessorOf(original), true);
    });

    test('completely different entries → false', () {
      final hw1 = _hw(title: 'Mathe', subtitle: 'A', label: 'X');
      final hw2 = _hw(id: 2, title: 'Deutsch', subtitle: 'B', label: 'Y');
      expect(hw1.isSuccessorOf(hw2), false);
    });

    test('gradeGroup does not replace grade → false', () {
      final gradeGroupEntry = _hw(
        id: 2,
        label: 'SA1',
        subtitle: 'Sub',
      );
      final gradeEntry = _hw(
        type: HomeworkType.grade,
        label: 'SA1',
        subtitle: 'Sub',
      );
      // gradeGroup replacing grade is not a successor pattern
      expect(gradeGroupEntry.isSuccessorOf(gradeEntry), false);
    });
  });

  group('grading mode helpers', () {
    test('detectGradingMode returns numeric for numeric grades', () {
      final subject = _subject(
        basicGrades: [
          GradeAll(
            (b) => b
              ..cancelled = false
              ..date = UtcDateTime(2026, 1, 2)
              ..grade = 750
              ..type = 'Test'
              ..weightPercentage = 100,
          ),
        ],
      );

      expect(detectGradingMode([subject], Semester.first), GradingMode.numeric);
    });

    test('detectGradingMode returns stars for competence-only grades', () {
      final subject = _subject(
        detailGrades: [
          GradeDetail(
            (b) => b
              ..id = 1
              ..name = 'Sterne'
              ..created = 'created'
              ..date = UtcDateTime(2026, 1, 2)
              ..type = 'Üben'
              ..weightPercentage = 100
              ..cancelled = false
              ..competences = ListBuilder([
                Competence((b) => b
                  ..typeName = 'A'
                  ..grade = 5),
              ]),
          ),
        ],
      );

      expect(detectGradingMode([subject], Semester.first), GradingMode.stars);
    });

    test('starAverageFormatted returns weighted star average out of 6', () {
      final subject = _subject(
        detailGrades: [
          GradeDetail(
            (b) => b
              ..id = 1
              ..name = 'Sterne 1'
              ..created = 'created'
              ..date = UtcDateTime(2026, 1, 2)
              ..type = 'Üben'
              ..weightPercentage = 100
              ..cancelled = false
              ..competences = ListBuilder([
                Competence((b) => b
                  ..typeName = 'A'
                  ..grade = 5),
                Competence((b) => b
                  ..typeName = 'B'
                  ..grade = 5),
              ]),
          ),
          GradeDetail(
            (b) => b
              ..id = 2
              ..name = 'Sterne 2'
              ..created = 'created'
              ..date = UtcDateTime(2026, 1, 3)
              ..type = 'Üben'
              ..weightPercentage = 100
              ..cancelled = false
              ..competences = ListBuilder([
                Competence((b) => b
                  ..typeName = 'A'
                  ..grade = 6),
              ]),
          ),
        ],
      );

      expect(subject.starAverageFormatted(Semester.first), '5,5/6');
    });
  });
}
