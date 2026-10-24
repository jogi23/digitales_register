import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter_test/flutter_test.dart';

AbsencesState _state({
  List<Absence> absences = const [],
  List<FutureAbsence> futureAbsences = const [],
  AbsenceJustified justified = AbsenceJustified.justified,
}) =>
    AbsencesState((b) => b
      ..absences = ListBuilder([
        if (absences.isNotEmpty)
          AbsenceGroup((g) => g
            ..justified = justified
            ..hours = absences.length
            ..minutes = 0
            ..absences = ListBuilder(absences)),
      ])
      ..futureAbsences = ListBuilder(futureAbsences));

Absence _absence(UtcDateTime date, int hour) => Absence((b) => b
  ..date = date
  ..hour = hour
  ..minutes = 50
  ..minutesCameTooLate = 0
  ..minutesLeftTooEarly = 0);

FutureAbsence _reported(
  UtcDateTime start,
  int startHour,
  UtcDateTime end,
  int endHour,
) =>
    FutureAbsence((b) => b
      ..justified = AbsenceJustified.notYetJustified
      ..startDate = start
      ..startHour = startHour
      ..endDate = end
      ..endHour = endHour);

void main() {
  final monday = UtcDateTime(2026, 2, 2);
  final tuesday = UtcDateTime(2026, 2, 3);
  final wednesday = UtcDateTime(2026, 2, 4);

  group('coversLesson', () {
    test('nothing recorded covers nothing', () {
      expect(_state().coversLesson(monday, 1, 2), isFalse);
    });

    test('a recorded absence covers the lesson holding its hour', () {
      final state = _state(absences: [_absence(monday, 3)]);
      expect(state.coversLesson(monday, 3, 3), isTrue);
      expect(state.coversLesson(monday, 2, 4), isTrue);
      expect(state.coversLesson(monday, 4, 5), isFalse);
      expect(state.coversLesson(tuesday, 3, 3), isFalse);
    });

    test('time away for the school is no absence', () {
      final state = _state(
        absences: [_absence(monday, 3)],
        justified: AbsenceJustified.forSchool,
      );
      expect(state.coversLesson(monday, 3, 3), isFalse);
    });

    test('a reported absence on one day covers its hours only', () {
      final state = _state(
        futureAbsences: [_reported(tuesday, 2, tuesday, 4)],
      );
      expect(state.coversLesson(tuesday, 1, 1), isFalse);
      expect(state.coversLesson(tuesday, 1, 2), isTrue);
      expect(state.coversLesson(tuesday, 4, 5), isTrue);
      expect(state.coversLesson(tuesday, 5, 6), isFalse);
      expect(state.coversLesson(monday, 2, 2), isFalse);
    });

    test('a reported absence over days holds its hours on the edge days', () {
      final state = _state(
        futureAbsences: [_reported(monday, 5, wednesday, 2)],
      );
      expect(state.coversLesson(monday, 1, 4), isFalse);
      expect(state.coversLesson(monday, 5, 5), isTrue);
      expect(state.coversLesson(tuesday, 1, 1), isTrue);
      expect(state.coversLesson(tuesday, 10, 10), isTrue);
      expect(state.coversLesson(wednesday, 2, 2), isTrue);
      expect(state.coversLesson(wednesday, 3, 4), isFalse);
    });
  });
}
