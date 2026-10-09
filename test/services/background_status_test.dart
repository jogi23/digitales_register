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

import 'package:dr/services/background_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  final status = BackgroundStatus(
    finishedAt: DateTime.utc(2026, 10, 8, 12, 30),
    accounts: const [
      AccountCheckResult(
        label: 'Anna',
        outcome: AccountCheckOutcome.ok,
        unread: 3,
        fresh: 1,
      ),
      AccountCheckResult(
        label: 'Ben',
        outcome: AccountCheckOutcome.unreachable,
      ),
    ],
  );

  group('BackgroundStatus', () {
    test('round-trips through json', () {
      final back = BackgroundStatus.tryParse(
        jsonDecode(jsonEncode(status.toJson())),
      );
      expect(back, isNotNull);
      expect(back!.finishedAt.isAtSameMomentAs(status.finishedAt), isTrue);
      expect(back.accounts.map((a) => a.label), ['Anna', 'Ben']);
      expect(back.accounts[0].outcome, AccountCheckOutcome.ok);
      expect(back.accounts[0].unread, 3);
      expect(back.accounts[0].fresh, 1);
      expect(back.accounts[1].outcome, AccountCheckOutcome.unreachable);
      expect(back.accounts[1].unread, isNull);
    });

    test('tryParse gives null for anything that is not a status', () {
      expect(BackgroundStatus.tryParse(null), isNull);
      expect(BackgroundStatus.tryParse('text'), isNull);
      expect(BackgroundStatus.tryParse({'finishedAt': 5}), isNull);
      expect(
        BackgroundStatus.tryParse({
          'finishedAt': '2026-10-08T12:30:00.000Z',
          'accounts': [
            {'label': 'x', 'outcome': 'fromTheFuture'},
          ],
        }),
        isNull,
      );
    });
  });

  group('checkResultFor', () {
    test('an account the app is signed in with is skipped', () {
      final r = checkResultFor('Anna', appSignedIn: true);
      expect(r.outcome, AccountCheckOutcome.skippedAppSignedIn);
    });

    test('an account that could not be reached says so', () {
      final r = checkResultFor('Anna', reached: false);
      expect(r.outcome, AccountCheckOutcome.unreachable);
    });

    test('the first look at an account is a first run', () {
      final r = checkResultFor('Anna', firstRun: true, unread: 4);
      expect(r.outcome, AccountCheckOutcome.firstRun);
      expect(r.unread, 4);
    });

    test('otherwise it counts what is unread and what is new', () {
      final r = checkResultFor('Anna', unread: 5, fresh: 2);
      expect(r.outcome, AccountCheckOutcome.ok);
      expect(r.unread, 5);
      expect(r.fresh, 2);
    });
  });

  group('storage', () {
    test('the time comes back as local time, not UTC', () async {
      final prefs = await SharedPreferences.getInstance();
      final local = DateTime(2026, 10, 8, 12, 30);
      await writeBackgroundStatus(
        prefs,
        BackgroundStatus(finishedAt: local, accounts: const []),
      );
      final back = (await readBackgroundStatus())!.finishedAt;
      expect(back.isUtc, isFalse);
      expect(back.hour, 12);
      expect(back.minute, 30);
    });

    test('a written status is read back', () async {
      final prefs = await SharedPreferences.getInstance();
      await writeBackgroundStatus(prefs, status);
      final back = await readBackgroundStatus();
      expect(back?.finishedAt.isAtSameMomentAs(status.finishedAt), isTrue);
      expect(back?.accounts, hasLength(2));
    });

    test('without a run there is nothing', () async {
      expect(await readBackgroundStatus(), isNull);
    });

    test('broken stored json is nothing, not a crash', () async {
      SharedPreferences.setMockInitialValues(
        {backgroundStatusPrefsKey: '{kaputt'},
      );
      expect(await readBackgroundStatus(), isNull);
    });
  });
}
