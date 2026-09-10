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

import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/course_content_provider.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWrapper extends Mock implements Wrapper {}

const _fach = CourseSubject(
  classId: 200,
  subjectId: 97,
  name: 'Mathematik',
);

void main() {
  late ProviderContainer container;

  setUp(() {
    wrapper = MockWrapper();
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  CourseContentState nachLaden() => container.read(courseContentProvider);

  group('a subject the server has no course for', () {
    setUp(() {
      when(() => wrapper.send(any(),
          args: any(named: 'args'),
          onError: any(named: 'onError'))).thenAnswer((_) async => null);
    });

    test('is reported as empty, not as broken', () async {
      await container.read(courseContentProvider.notifier).load(_fach);
      final state = nachLaden();
      expect(state.error, isNull);
      expect(state.course?.exists, isFalse);
    });
  });

  group('a request that never got an answer', () {
    setUp(() {
      // send swallows network errors and answers null, exactly as it does
      // for a subject without a course. Only the callback tells them apart.
      when(() => wrapper.send(any(),
          args: any(named: 'args'),
          onError: any(named: 'onError'))).thenAnswer((invocation) async {
        final onError = invocation.namedArguments[#onError]
            as void Function(Object)?;
        onError?.call(Exception('404'));
        return null;
      });
    });

    test('is reported as an error, not as an empty subject', () async {
      await container.read(courseContentProvider.notifier).load(_fach);
      final state = nachLaden();
      expect(
        state.error,
        isNotNull,
        reason: 'a failed call must not read as "no material"',
      );
      expect(state.error, contains('404'));
    });
  });
}
