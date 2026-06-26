// Copyright (C) 2021 Michael Debertol
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

import 'dart:convert';

import 'package:dr/providers/absences_provider.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/api_fixtures.dart';

void main() {
  setUpAll(() async {
    await loadFixtures();
  });

  test('parse absences', () {
    final absences = fixtureFor('api/student/dashboard/absences')
        as Map<String, dynamic>;
    // should not throw for all three input forms the parser accepts
    parseAbsencesFromJson(absences);
    parseAbsencesFromJson(json.encode(absences));
    parseAbsencesFromJson(json.decode(json.encode(absences)));
  });

  test('parse calendar', () {
    final calendar =
        fixtureFor('api/calendar/student') as Map<String, dynamic>;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // should not throw for both raw and re-encoded forms
    container.read(calendarProvider.notifier).parseLoaded(calendar);
    container.read(calendarProvider.notifier).parseLoaded(
        json.decode(json.encode(calendar)) as Map<String, dynamic>);
  });
}
