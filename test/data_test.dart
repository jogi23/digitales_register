import 'package:dr/data.dart';
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

void main() {
  group('formatGradeFromString', () {
    test('null returns keine Note eingetragen', () {
      expect(formatGradeFromString(null), 'keine Note eingetragen');
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
        id: 1,
        type: HomeworkType.gradeGroup,
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
        id: 1,
        type: HomeworkType.gradeGroup,
        label: 'Schularbeit 1',
        subtitle: 'Kapitel 3',
      );
      expect(gradeEntry.isSuccessorOf(gradeGroupEntry), false);
    });

    test('identical but subtitle is prefix of other → true', () {
      final amended = _hw(
        id: 1,
        type: HomeworkType.gradeGroup,
        label: 'L1',
        subtitle: 'Kapitel 3 - Zusatzaufgaben',
      );
      final original = _hw(
        id: 1,
        type: HomeworkType.gradeGroup,
        label: 'L1',
        subtitle: 'Kapitel 3',
      );
      expect(amended.isSuccessorOf(original), true);
    });

    test('completely different entries → false', () {
      final hw1 = _hw(id: 1, title: 'Mathe', subtitle: 'A', label: 'X');
      final hw2 = _hw(id: 2, title: 'Deutsch', subtitle: 'B', label: 'Y');
      expect(hw1.isSuccessorOf(hw2), false);
    });

    test('gradeGroup does not replace grade → false', () {
      final gradeGroupEntry = _hw(
        id: 2,
        type: HomeworkType.gradeGroup,
        label: 'SA1',
        subtitle: 'Sub',
      );
      final gradeEntry = _hw(
        id: 1,
        type: HomeworkType.grade,
        label: 'SA1',
        subtitle: 'Sub',
      );
      // gradeGroup replacing grade is not a successor pattern
      expect(gradeGroupEntry.isSuccessorOf(gradeEntry), false);
    });
  });
}
