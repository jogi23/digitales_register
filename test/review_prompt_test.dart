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

import 'package:dr/services/review_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 7);

ReviewHistory _history({
  int launches = 10,
  Duration age = const Duration(days: 30),
  Duration? sinceLastAsked,
}) {
  return ReviewHistory(
    launches: launches,
    firstLaunch: _now.subtract(age),
    lastAsked: sinceLastAsked == null ? null : _now.subtract(sinceLastAsked),
  );
}

void main() {
  group('shouldAskForReview', () {
    test('not before the app had a chance to prove useful', () {
      expect(shouldAskForReview(_history(launches: 1), _now), isFalse);
      expect(shouldAskForReview(_history(launches: 4), _now), isFalse);
      expect(shouldAskForReview(_history(launches: 5), _now), isTrue);
    });

    test('not right after installing, however often it was opened', () {
      expect(
        shouldAskForReview(
          _history(launches: 50, age: const Duration(days: 1)),
          _now,
        ),
        isFalse,
      );
      expect(
        shouldAskForReview(
          _history(launches: 50, age: const Duration(days: 3)),
          _now,
        ),
        isTrue,
      );
    });

    test('never on the very first start', () {
      expect(
        shouldAskForReview(
          _history(launches: 1, age: Duration.zero),
          _now,
        ),
        isFalse,
      );
    });

    test('asks again only after a long pause', () {
      // Play grants about one dialog per user and month; asking sooner just
      // burns the quota.
      expect(
        shouldAskForReview(
          _history(sinceLastAsked: const Duration(days: 30)),
          _now,
        ),
        isFalse,
      );
      expect(
        shouldAskForReview(
          _history(sinceLastAsked: const Duration(days: 89)),
          _now,
        ),
        isFalse,
      );
      expect(
        shouldAskForReview(
          _history(sinceLastAsked: const Duration(days: 90)),
          _now,
        ),
        isTrue,
      );
    });

    test('all conditions have to hold together', () {
      expect(
        shouldAskForReview(
          _history(
            launches: 4,
            age: const Duration(days: 365),
            sinceLastAsked: const Duration(days: 365),
          ),
          _now,
        ),
        isFalse,
      );
    });
  });
}
