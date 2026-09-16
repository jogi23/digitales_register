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

import 'package:dr/demo.dart';
import 'package:flutter_test/flutter_test.dart';

const _absencesUrl = 'api/student/dashboard/absences';

Future<Map<String, dynamic>> _absences() async =>
    (await getDemoResponse(_absencesUrl, const <String, Object?>{}))
        as Map<String, dynamic>;

Future<Map<String, dynamic>> _firstGroup() async =>
    ((await _absences())['absences'] as List).first as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the demo account may write absences', () async {
    final absences = await _absences();
    expect(absences['canEdit'], isTrue);
    expect(absences['futureAbsences'], isEmpty);
  });

  test('a reason given in demo mode sticks for the session', () async {
    final group = await _firstGroup();
    final entries = (group['group'] as List).cast<Map<String, dynamic>>();
    final answer = await getDemoResponse(
      'api/student/dashboard/absence_reason',
      {
        'absenceGroup': {
          ...group,
          'reason': 'Zahnarzt',
          'reason_signature': 'Demo Elternteil',
          'selfdecl_id': 0,
          'selfdecl_input': '',
        },
      },
    );
    expect(answer, {'success': true});

    final again = await _firstGroup();
    expect(again['reason'], 'Zahnarzt');
    expect(again['reason_signature'], 'Demo Elternteil');
    // Nobody at the school has approved it yet.
    expect(again['justified'], 1);
    // The register repeats the reason on every single absence of the group.
    expect(
      (again['group'] as List).cast<Map<String, dynamic>>().first['reason'],
      'Zahnarzt',
    );
    expect(entries, isNotEmpty);
  });

  test('a report shows up in the list and can be taken back', () async {
    await getDemoResponse('api/student/dashboard/absence_future', {
      'futureAbsence': {
        'startDate': '2026-09-21',
        'endDate': '2026-09-21',
        'startTime': 1,
        'endTime': 6,
        'reason': 'Turnier',
        'reason_signature': 'Demo Elternteil',
        'note': '',
      },
    });

    final reported = ((await _absences())['futureAbsences'] as List)
        .cast<Map<String, dynamic>>();
    expect(reported, hasLength(1));
    expect(reported.first['reason'], 'Turnier');
    expect(reported.first['justified'], 1);

    await getDemoResponse(
      'api/student/dashboard/remove_absence_future',
      {'futureAbsence': reported.first},
    );
    expect((await _absences())['futureAbsences'], isEmpty);
  });
}
