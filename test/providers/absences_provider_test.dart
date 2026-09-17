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

import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/absences_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/api_fixtures.dart';

class MockWrapper extends Mock implements Wrapper {}

const _absencesUrl = 'api/student/dashboard/absences';
const _reasonUrl = 'api/student/dashboard/absence_reason';
const _futureUrl = 'api/student/dashboard/absence_future';
const _removeFutureUrl = 'api/student/dashboard/remove_absence_future';

void main() {
  setUpAll(loadFixtures);

  late ProviderContainer container;
  final sent = <({String url, Map<String, Object?> args})>[];

  /// What the mocked register answers a write with. Verified against the real
  /// one: `absence_future` and `remove_absence_future` say `success`.
  late dynamic writeAnswer;

  AbsencesState read() => container.read(absencesProvider);

  /// The payload of the last request to [url].
  Map<String, dynamic> payload(String url, String key) {
    final request = sent.lastWhere((r) => r.url == url);
    return (request.args[key] as Map).cast<String, dynamic>();
  }

  setUp(() async {
    sent.clear();
    writeAnswer = <String, dynamic>{'success': true};
    wrapper = MockWrapper();
    when(() => wrapper.noInternet).thenReturn(false);
    when(() => wrapper.send(any(),
        args: any(named: 'args'),
        onError: any(named: 'onError'))).thenAnswer((invocation) async {
      final url = invocation.positionalArguments.first as String;
      final args =
          (invocation.namedArguments[#args] as Map<String, Object?>?) ??
              const <String, Object?>{};
      sent.add((url: url, args: args));
      if (url == _absencesUrl) return fixtureFor(_absencesUrl);
      return writeAnswer;
    });
    container = ProviderContainer();
    await container.read(absencesProvider.notifier).load();
  });

  tearDown(() => container.dispose());

  /// An absence the register has not settled — the only kind worth a reason.
  AbsenceGroup openGroup() => read().absences.firstWhere(
        (g) =>
            g.justified != AbsenceJustified.justified &&
            g.justified != AbsenceJustified.forSchool,
      );

  group('what loading brings along', () {
    test('the right to write and the school forms', () {
      expect(read().canEdit, isTrue);
      expect(read().selfDeclarations, hasLength(15));
      // The demo school has them switched off, but insists on one where they
      // are on.
      expect(read().selfDeclarationActive, isFalse);
      expect(read().selfDeclarationMandatory, isTrue);
      expect(read().activeSelfDeclarations, isEmpty);
    });

    test('a form knows whether it wants its own entry', () {
      final withInput =
          read().selfDeclarations.firstWhere((d) => d.inputMandatory);
      expect(withInput.title, isNotEmpty);
      expect(withInput.inputExplain, isNotNull);
    });

    test('every absence keeps the register\'s own copy', () {
      for (final group in read().absences) {
        expect(group.raw, isNotNull);
        expect(json.decode(group.raw!), isA<Map<String, dynamic>>());
      }
    });
  });

  group('giving a reason', () {
    test('posts the whole group back, with the reason filled in', () async {
      final group = openGroup();
      final done = await container.read(absencesProvider.notifier).saveReason(
            group,
            reason: 'Grippe',
            signature: 'Demo Elternteil',
          );
      expect(done, isTrue);

      final body = payload(_reasonUrl, 'absenceGroup');
      expect(body['reason'], 'Grippe');
      expect(body['reason_signature'], 'Demo Elternteil');
      expect(body['selfdecl_id'], 0);
      expect(body['selfdecl_input'], '');
      expect(DateTime.tryParse(body['reason_timestamp'] as String), isNotNull);
      // Everything the register sent is still there, the single absences
      // included.
      final original = json.decode(group.raw!) as Map<String, dynamic>;
      expect(body.keys.toSet(), containsAll(original.keys));
      expect(body['group'], original['group']);
    });

    test('carries the chosen form and its entry', () async {
      final declaration =
          read().selfDeclarations.firstWhere((d) => d.inputMandatory);
      await container.read(absencesProvider.notifier).saveReason(
            openGroup(),
            reason: 'Krank',
            signature: 'Demo Elternteil',
            selfDeclaration: declaration,
            selfDeclarationInput: 'Dr. Muster',
          );
      final body = payload(_reasonUrl, 'absenceGroup');
      expect(body['selfdecl_id'], declaration.id);
      expect(body['selfdecl_input'], 'Dr. Muster');
    });

    test('loads the absences again afterwards', () async {
      await container.read(absencesProvider.notifier).saveReason(
            openGroup(),
            reason: 'Grippe',
            signature: 'Demo Elternteil',
          );
      // Load on start, the reason, then the load that follows it.
      expect(sent.map((r) => r.url).toList(),
          [_absencesUrl, _reasonUrl, _absencesUrl]);
    });

    test('sends nothing without the register\'s own copy', () async {
      final done = await container.read(absencesProvider.notifier).saveReason(
            AbsenceGroup((b) => b
              ..justified = AbsenceJustified.notYetJustified
              ..hours = 1
              ..minutes = 0),
            reason: 'Grippe',
            signature: 'Demo Elternteil',
          );
      expect(done, isFalse);
      expect(sent.any((r) => r.url == _reasonUrl), isFalse);
    });
  });

  group('reporting an absence in advance', () {
    test('sends the days and the lesson numbers', () async {
      final done =
          await container.read(absencesProvider.notifier).addFutureAbsence(
                startDate: UtcDateTime(2026, 9, 21),
                endDate: UtcDateTime(2026, 9, 22),
                startHour: 3,
                endHour: 5,
                reason: 'Turnier',
                signature: 'Demo Elternteil',
                note: 'Abfahrt früh',
              );
      expect(done, isTrue);
      expect(payload(_futureUrl, 'futureAbsence'), {
        'startDate': '2026-09-21',
        'endDate': '2026-09-22',
        'startTime': 3,
        'endTime': 5,
        'reason': 'Turnier',
        'reason_signature': 'Demo Elternteil',
        'note': 'Abfahrt früh',
      });
    });

    test('loads the absences again afterwards', () async {
      await container.read(absencesProvider.notifier).addFutureAbsence(
            startDate: UtcDateTime(2026, 9, 21),
            endDate: UtcDateTime(2026, 9, 21),
            startHour: 1,
            endHour: 6,
            reason: 'Turnier',
            signature: 'Demo Elternteil',
          );
      expect(sent.last.url, _absencesUrl);
    });

    test('leaves an empty note out, the way the portal does', () async {
      await container.read(absencesProvider.notifier).addFutureAbsence(
            startDate: UtcDateTime(2026, 9, 21),
            endDate: UtcDateTime(2026, 9, 21),
            startHour: 1,
            endHour: 6,
            reason: 'Turnier',
            signature: 'Demo Elternteil',
          );
      expect(payload(_futureUrl, 'futureAbsence'), isNot(contains('note')));
    });
  });

  group('what the register says about a write', () {
    test('a refusal is a refusal, however the list looks', () async {
      writeAnswer = <String, dynamic>{'success': false};
      final done =
          await container.read(absencesProvider.notifier).addFutureAbsence(
                startDate: UtcDateTime(2026, 9, 21),
                endDate: UtcDateTime(2026, 9, 21),
                startHour: 1,
                endHour: 6,
                reason: 'Turnier',
                signature: 'Demo Elternteil',
              );
      expect(done, isFalse);
    });

    test('an error object counts as a refusal, not as success', () async {
      writeAnswer = <String, dynamic>{'error': 'unknown'};
      final done =
          await container.read(absencesProvider.notifier).addFutureAbsence(
                startDate: UtcDateTime(2026, 9, 21),
                endDate: UtcDateTime(2026, 9, 21),
                startHour: 1,
                endHour: 6,
                reason: 'Turnier',
                signature: 'Demo Elternteil',
              );
      // Nothing the register said can be taken for a yes, and the reloaded
      // fixture does not hold this report either.
      expect(done, isFalse);
    });

    test('reads success, refusal and silence apart', () {
      expect(wroteOk(<String, dynamic>{'success': true}), isTrue);
      expect(wroteOk(<String, dynamic>{'success': false}), isFalse);
      expect(wroteOk(<String, dynamic>{'error': 'unknown'}), isNull);
      expect(wroteOk(null), isNull);
      expect(wroteOk('nope'), isNull);
    });
  });

  group('taking a report back', () {
    FutureAbsence reported() => FutureAbsence(
          (b) => b
            ..raw = json.encode({
              'id': 4711,
              'startDate': '2026-09-21',
              'endDate': '2026-09-21',
              'startTime': 1,
              'endTime': 6,
              'reason': 'Turnier',
              'note': '',
              'justified': 1,
            })
            ..justified = AbsenceJustified.notYetJustified
            ..startDate = UtcDateTime(2026, 9, 21)
            ..endDate = UtcDateTime(2026, 9, 21)
            ..startHour = 1
            ..endHour = 6,
        );

    test('posts the report back the way it came', () async {
      final done = await container
          .read(absencesProvider.notifier)
          .removeFutureAbsence(reported());
      expect(done, isTrue);
      expect(payload(_removeFutureUrl, 'futureAbsence')['id'], 4711);
      expect(sent.last.url, _absencesUrl);
    });

    test('sends nothing without the register\'s own copy', () async {
      final done =
          await container.read(absencesProvider.notifier).removeFutureAbsence(
                FutureAbsence(
                  (b) => b
                    ..justified = AbsenceJustified.notYetJustified
                    ..startDate = UtcDateTime(2026, 9, 21)
                    ..endDate = UtcDateTime(2026, 9, 21)
                    ..startHour = 1
                    ..endHour = 6,
                ),
              );
      expect(done, isFalse);
      expect(sent.any((r) => r.url == _removeFutureUrl), isFalse);
    });
  });

  test('offline nothing is written', () async {
    when(() => wrapper.send(any(),
        args: any(named: 'args'),
        onError: any(named: 'onError'))).thenAnswer((_) async => null);
    final done = await container.read(absencesProvider.notifier).saveReason(
          openGroup(),
          reason: 'Grippe',
          signature: 'Demo Elternteil',
        );
    expect(done, isFalse);
  });
}
