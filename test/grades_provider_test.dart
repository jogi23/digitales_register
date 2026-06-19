// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements Wrapper {}

Subject _subject({required int id, required String name}) {
  return Subject(
    (b) => b
      ..id = id
      ..name = name
      ..gradesAll = MapBuilder()
      ..grades = MapBuilder()
      ..observations = MapBuilder(),
  );
}

Map<String, dynamic> _subjectDetailResponse({required int gradeId}) {
  return {
    "grades": [
      {
        "id": gradeId,
        "grade": "9.00",
        "weight": 100,
        "typeName": "Test",
        "name": "Kapiteltest",
        "description": "",
        "date": "2022-10-11",
        "cancelled": 0,
        "created": "Von Test am 17.10.2022 eingetragen",
        "competences": [],
      }
    ],
    "observations": [],
  };
}

void main() {
  late MockWrapper mockWrapper;
  late ProviderContainer container;

  setUp(() {
    mockWrapper = MockWrapper();
    wrapper = mockWrapper;
    when(() => mockWrapper.config).thenReturn(
      Config(
        (b) => b
          ..userId = 1
          ..autoLogoutSeconds = 1
          ..fullName = 'Test User'
          ..imgSource = ''
          ..isStudentOrParent = true,
      ),
    );
    when(
      () => mockWrapper.send('?semesterWechsel=1'),
    ).thenAnswer((_) async => null);
    when(
      () => mockWrapper.send(
        'api/student/all_subjects',
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (_) async => {
        'subjects': [
          {
            'subject': {'id': 17, 'name': 'Mathematik'},
            'grades': [],
          }
        ],
      },
    );
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('requestSubjectDetail keeps subject ids as subject targets', () async {
    final notifier = container.read(gradesProvider.notifier);
    notifier.restore(
      GradesState(
        (b) => b
          ..semester = Semester.first.toBuilder()
          ..subjects = ListBuilder([
            _subject(id: 17, name: 'Mathematik'),
          ]),
      ),
    );

    when(
      () => mockWrapper.send(
        'api/student/subject_detail',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => _subjectDetailResponse(gradeId: 1202));

    await notifier.requestSubjectDetail(17);

    expect(container.read(gradesProvider).pendingSubjectId, 17);
    expect(container.read(pendingGradeIdProvider), isNull);
  });

  test('requestSubjectDetail resolves grade ids to subject and grade target',
      () async {
    final notifier = container.read(gradesProvider.notifier);
    notifier.restore(
      GradesState(
        (b) => b
          ..semester = Semester.first.toBuilder()
          ..subjects = ListBuilder([
            _subject(id: 17, name: 'Mathematik'),
          ]),
      ),
    );

    when(
      () => mockWrapper.send(
        'api/student/entry/getGrade',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => {
          'subjectId': 17,
          'cancelledDescription': null,
        });
    when(
      () => mockWrapper.send(
        'api/student/subject_detail',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => _subjectDetailResponse(gradeId: 1202));

    await notifier.requestSubjectDetail(1202);

    expect(container.read(gradesProvider).pendingSubjectId, 17);
    expect(container.read(pendingGradeIdProvider), 1202);
  });
}