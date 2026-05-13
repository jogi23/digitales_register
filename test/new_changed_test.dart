// Copyright (C) 2021 Michael Debertol
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

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestDashboardNotifier extends DashboardNotifier {
  _TestDashboardNotifier(this._initialState);
  final DashboardState _initialState;
  @override
  DashboardState build() => _initialState;
}

void main() {
  test('new entries are marked', () {
    mockNow = UtcDateTime(2020, 1, 10);
    final initialState = DashboardState(
      (b) => b
        ..allDays = ListBuilder(
          [
            Day(
              (b) => b
                ..date = UtcDateTime(2020, 1, 5)
                ..lastRequested = UtcDateTime(2020)
                ..deletedHomework = ListBuilder()
                ..homework = ListBuilder(
                  [
                    Homework(
                      (b) => b
                        ..checkable = true
                        ..checked = false
                        ..deleteable = false
                        ..deleted = false
                        ..firstSeen = UtcDateTime(2020)
                        ..id = 1
                        ..isChanged = false
                        ..isNew = false
                        ..label = "Fach"
                        ..lastNotSeen = UtcDateTime(2019, 12, 24)
                        ..subtitle = "Untertitel"
                        ..title = "Titel"
                        ..type = HomeworkType.lessonHomework,
                    ),
                  ],
                ),
            ),
          ],
        ),
    );
    final container = ProviderContainer(
      overrides: [
        dashboardProvider
            .overrideWith(() => _TestDashboardNotifier(initialState)),
      ],
    );
    addTearDown(container.dispose);
    container.read(dashboardProvider.notifier).testApplyLoaded(
      [
        {
          "items": [
            {
              "id": 1,
              "type": "lessonHomework",
              "title": "Neuer Titel",
              "subtitle": "Neuer Untertitel",
              "label": "Fach",
              "warning": false,
              "checkable": true,
              "checked": false,
              "deleteable": false
            },
          ],
          "date": "2020-01-05",
        }
      ],
      false,
      true,
      false,
    );
    expect(
      container.read(dashboardProvider).allDays!.single.homework.single,
      Homework(
        (b) => b
          ..checkable = true
          ..checked = false
          ..deleteable = false
          ..deleted = false
          ..firstSeen = now
          ..id = 1
          ..isChanged = true
          ..isNew = false
          ..label = "Fach"
          ..lastNotSeen = UtcDateTime(2020)
          ..subtitle = "Neuer Untertitel"
          ..title = "Neuer Titel"
          ..type = HomeworkType.lessonHomework
          ..previousVersion = (HomeworkBuilder()
            ..checkable = true
            ..checked = false
            ..deleteable = false
            ..deleted = false
            ..firstSeen = UtcDateTime(2020)
            ..id = 1
            ..isChanged = false
            ..isNew = false
            ..label = "Fach"
            ..lastNotSeen = UtcDateTime(2019, 12, 24)
            ..subtitle = "Untertitel"
            ..title = "Titel"
            ..type = HomeworkType.lessonHomework),
      ),
    );
  });
}
