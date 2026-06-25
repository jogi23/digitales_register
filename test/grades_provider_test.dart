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

import 'fixtures/api_fixtures.dart';

// Subject ID 85 = Mathematik; grade ID 93810 belongs to subject 85.
// Both exist in assets/demo/capture.json.
const _subjectId = 85;
const _gradeId = 93810;

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

void main() {
  late MockWrapper mockWrapper;
  late ProviderContainer container;

  setUpAll(() async {
    await loadFixtures();
  });

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
    // Returns only the subject under test so that the background
    // ensureDetailDataForSubjects call triggered by _applyLoaded doesn't spawn
    // open futures that outlive the ProviderContainer.
    when(
      () => mockWrapper.send(
        'api/student/all_subjects',
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (_) async => {
        'subjects': [
          {
            'subject': {'id': _subjectId, 'name': 'Mathematik'},
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
            _subject(id: _subjectId, name: 'Mathematik'),
          ]),
      ),
    );

    when(
      () => mockWrapper.send(
        'api/student/subject_detail',
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (_) async => fixtureFor(
        'api/student/subject_detail',
        params: {'subjectId': _subjectId},
      ),
    );

    await notifier.requestSubjectDetail(_subjectId);

    expect(container.read(gradesProvider).pendingSubjectId, _subjectId);
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
            _subject(id: _subjectId, name: 'Mathematik'),
          ]),
      ),
    );

    when(
      () => mockWrapper.send(
        'api/student/entry/getGrade',
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (_) async => fixtureFor(
        'api/student/entry/getGrade',
        params: {'gradeId': _gradeId},
      ),
    );
    when(
      () => mockWrapper.send(
        'api/student/subject_detail',
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (_) async => fixtureFor(
        'api/student/subject_detail',
        params: {'subjectId': _subjectId},
      ),
    );

    await notifier.requestSubjectDetail(_gradeId);

    expect(container.read(gradesProvider).pendingSubjectId, _subjectId);
    expect(container.read(pendingGradeIdProvider), _gradeId);
  });
}
