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

void main() {
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
