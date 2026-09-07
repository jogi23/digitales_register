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

import 'package:dr/util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isoWeekNumber', () {
    test('counts from the week holding the first Thursday', () {
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumber(DateTime(2026, 5, 11)), 20);
      expect(isoWeekNumber(DateTime(2026, 12, 31)), 53);
    });

    test('every day of one week shares its number', () {
      final numbers = <int>{
        for (var i = 0; i < 7; i++)
          isoWeekNumber(DateTime(2026, 5, 11).add(Duration(days: i))),
      };
      expect(numbers, {20});
    });

    test('early January can still belong to the year before', () {
      // 2027-01-01 is a Friday, so it belongs to week 53 of 2026.
      expect(isoWeekNumber(DateTime(2027, 1, 1)), 53);
    });

    test('late December can already be week 1 of the next year', () {
      // 2024-12-30 is a Monday whose Thursday falls into 2025.
      expect(isoWeekNumber(DateTime(2024, 12, 30)), 1);
    });
  });
}
