// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

import 'dart:convert';

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
    when(() => mockWrapper.ensureLoggedIn()).thenAnswer((_) async => true);
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('grades without a loaded configuration load nothing and do not crash',
      () async {
    // Loaded before a login had filled in the configuration, this threw a
    // LateInitializationError from a lock nobody awaited.
    when(() => mockWrapper.config).thenReturn(null);

    final notifier = container.read(gradesProvider.notifier);
    await notifier.load(Semester.first);
    await pumpEventQueue();

    verifyNever(
      () => mockWrapper.send(
        'api/student/all_subjects',
        args: any(named: 'args'),
      ),
    );
    expect(container.read(gradesProvider).loading, isFalse);
  });

  test('grades are not requested while the login fails', () async {
    when(() => mockWrapper.ensureLoggedIn()).thenAnswer((_) async => false);

    final notifier = container.read(gradesProvider.notifier);
    await notifier.load(Semester.first);
    await pumpEventQueue();

    verifyNever(
      () => mockWrapper.send(
        'api/student/all_subjects',
        args: any(named: 'args'),
      ),
    );
    expect(container.read(gradesProvider).loading, isFalse);
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

  test('the subject list carries the counts for the overview', () async {
    // Against the recorded response, so the field names stay honest: the
    // counts arrive with the subject list, before any detail is fetched.
    when(
      () => mockWrapper.send(
        'api/student/all_subjects',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => fixtureFor('api/student/all_subjects'));
    // Keeps the background detail prefetch from filling in the entries.
    when(
      () => mockWrapper.send(
        'api/student/subject_detail',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => null);

    final notifier = container.read(gradesProvider.notifier);
    // load() hands the request to the semester lock without awaiting it.
    await notifier.load(Semester.first);
    await pumpEventQueue();

    final subject = container
        .read(gradesProvider)
        .subjects
        .firstWhere((s) => s.id == _subjectId);
    final counts = subject.counts(Semester.first)!;
    expect(counts.competences, 18);
    expect(counts.observations, 2);
    // This class is graded in competences only, so the list reports no grades.
    expect(counts.grades, 0);
  });

  group('stored details against a fresh subject list (#314)', () {
    setUp(() {
      when(
        () => mockWrapper.send(
          'api/student/all_subjects',
          args: any(named: 'args'),
        ),
      ).thenAnswer((_) async => fixtureFor('api/student/all_subjects'));
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
      when(
        () => mockWrapper.send(
          'api/student/entry/getGrade',
          args: any(named: 'args'),
        ),
      ).thenAnswer((_) async => null);
    });

    Future<void> loadFirst() async {
      // load() hands the request to the semester lock without awaiting it.
      await container.read(gradesProvider.notifier).load(Semester.first);
      await pumpEventQueue();
    }

    Subject mathematik() => container
        .read(gradesProvider)
        .subjects
        .firstWhere((s) => s.id == _subjectId);

    test('details that miss what the list reports are fetched again', () async {
      // Stored from an earlier visit, before the subject had anything: the
      // list now reports competences the stored details know nothing of.
      container.read(gradesProvider.notifier).restore(
            GradesState(
              (b) => b
                ..semester = Semester.first.toBuilder()
                ..subjects = ListBuilder([
                  _subject(id: _subjectId, name: 'Mathematik').rebuild(
                    (s) => s
                      ..grades[Semester.first] = BuiltList<GradeDetail>()
                      ..observations[Semester.first] = BuiltList<Observation>(),
                  ),
                ]),
            ),
          );

      await loadFirst();

      verify(
        () => mockWrapper.send(
          'api/student/subject_detail',
          args: any(named: 'args', that: containsPair('subjectId', _subjectId)),
        ),
      ).called(1);
      // The overview shows them without the subject being opened.
      expect(mathematik().counts(Semester.first)!.competences, 18);
      expect(mathematik().starAverage(Semester.first), isNotNull);
    });

    test('details that match the list are not fetched again', () async {
      await loadFirst();
      expect(mathematik().hasDetailData(Semester.first), isTrue);
      clearInteractions(mockWrapper);

      await loadFirst();

      verifyNever(
        () => mockWrapper.send(
          'api/student/subject_detail',
          args: any(named: 'args', that: containsPair('subjectId', _subjectId)),
        ),
      );
    });
  });

  test('the subject detail carries a comment per competence', () async {
    // They were parsed away before, and they are the reason the detail page
    // exists — the list has nowhere to put them.
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
    when(
      () => mockWrapper.send(
        'api/student/entry/getGrade',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => null);

    await notifier.loadDetails(
      container.read(gradesProvider).subjects.first,
      Semester.first,
    );
    await pumpEventQueue();

    final competences = container
        .read(gradesProvider)
        .subjects
        .first
        .grades[Semester.first]!
        .expand((g) => g.competences);
    expect(competences, isNotEmpty);
    expect(
      competences.any((c) => c.description?.isNotEmpty == true),
      isTrue,
    );
  });

  test('a competence rated in halves keeps its half (#293)', () async {
    // Schools that allow it send "3.50"; cutting it to a whole number drew
    // three stars for three and a half.
    // The portal answers with the detail as a JSON string.
    final raw = fixtureFor(
      'api/student/subject_detail',
      params: {'subjectId': _subjectId},
    );
    final detail = json.decode(raw is String ? raw : json.encode(raw));
    var halved = false;
    void halve(Object? node) {
      if (halved) return;
      if (node is Map) {
        final competences = node['competences'];
        if (competences is List && competences.isNotEmpty) {
          (competences.first as Map)['grade'] = '3.50';
          halved = true;
          return;
        }
        node.values.forEach(halve);
      } else if (node is List) {
        node.forEach(halve);
      }
    }

    halve(detail);
    expect(halved, isTrue, reason: 'the fixture carries competences');

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
    ).thenAnswer((_) async => raw is String ? json.encode(detail) : detail);
    when(
      () => mockWrapper.send(
        'api/student/entry/getGrade',
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => null);

    await notifier.loadDetails(
      container.read(gradesProvider).subjects.first,
      Semester.first,
    );
    await pumpEventQueue();

    final grades = container
        .read(gradesProvider)
        .subjects
        .first
        .grades[Semester.first]!
        .expand((g) => g.competences.map((c) => c.grade));
    expect(grades, contains(3.5));
  });

  test('opening a grade adds what only getGrade reports', () async {
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
    when(
      () => mockWrapper.send(
        'api/student/entry/getGrade',
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (_) async => fixtureFor(
        'api/student/entry/getGrade',
        params: {'gradeId': 13278},
      ),
    );

    await notifier.loadDetails(
      container.read(gradesProvider).subjects.first,
      Semester.first,
    );
    await pumpEventQueue();

    // A grade that both fixtures know: the subject detail lists it and
    // getGrade has a recorded answer for it.
    const gradeId = 13278;
    GradeDetail grade() => container
        .read(gradesProvider)
        .subjects
        .first
        .grades[Semester.first]!
        .firstWhere((g) => g.id == gradeId);

    expect(grade().visibleAtFormatted, isNull);
    await notifier.loadGradeDetail(grade(), Semester.first);
    await pumpEventQueue();
    expect(grade().visibleAtFormatted, startsWith('Bewertung sichtbar ab'));
  });
}
