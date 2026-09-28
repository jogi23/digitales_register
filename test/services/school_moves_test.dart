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
import 'dart:io';

import 'package:dr/api_client.dart';
import 'package:dr/middleware/middleware.dart'
    show escapeKey, getStorageKey, migrateMovedSchools, secureStorage;
import 'package:dr/providers/account_profile_provider.dart';
import 'package:dr/services/school_moves.dart';
import 'package:dr/util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_utils.dart';

const _old = 'https://gs-platt.digitalesregister.it';
const _new = 'https://gs-stleonhard.digitalesregister.it';

String _stateKey(String user, String url) => escapeKey(
      getStorageKey(user, ApiClient.loginAddressFor(fixupUrl(url))),
    );

void main() {
  group('movedSchoolUrl', () {
    test('sends a moved school to its new address', () {
      expect(movedSchoolUrl(_old), _new);
      expect(
        movedSchoolUrl('https://lbszuegg.digitalesregister.it'),
        'https://bbzzuegg.digitalesregister.it',
      );
    });

    test('keeps the rest of the address as it was stored', () {
      expect(
        movedSchoolUrl('https://hafling.digitalesregister.it/'),
        'https://gs-hafling.digitalesregister.it/',
      );
      expect(
        movedSchoolUrl('natz.digitalesregister.it'),
        'gsp-vahrn.digitalesregister.it',
      );
      expect(
        movedSchoolUrl('https://Sulden.digitalesregister.it'),
        'https://gs-prad.digitalesregister.it',
      );
    });

    test('leaves every other school alone', () {
      expect(movedSchoolUrl(_new), isNull);
      expect(
          movedSchoolUrl('https://vinzentinum.digitalesregister.it'), isNull);
      // Closed, or split into several addresses: nowhere to send them.
      expect(
          movedSchoolUrl('https://gs-verschneid.digitalesregister.it'), isNull);
      expect(
          movedSchoolUrl('https://gssklausen2.digitalesregister.it'), isNull);
      // Only the whole subdomain counts.
      expect(movedSchoolUrl('https://xnatz.digitalesregister.it'), isNull);
      expect(movedSchoolUrl('https://natz.example.com'), isNull);
    });
  });

  test('every new address is in the school list, no old one is', () {
    final schools =
        json.decode(File('assets/schools.json').readAsStringSync()) as Map;
    final listed = {
      for (final url in schools.values) Uri.parse(url as String).host,
    };
    for (final MapEntry(key: from, value: to) in movedSubdomains.entries) {
      expect(listed, contains('$to.digitalesregister.it'), reason: from);
      expect(listed, isNot(contains('$from.digitalesregister.it')));
    }
  });

  group('migrateStoredLogin', () {
    test('moves the account in use and the others', () {
      final result = migrateStoredLogin({
        'user': 'anna',
        'pass': 'geheim',
        'url': _old,
        'otherAccounts': [
          {
            'user': 'ben',
            'pass': 'x',
            'url': 'https://ms-moelten.digitalesregister.it'
          },
          {
            'user': 'cleo',
            'pass': 'y',
            'url': 'https://vinzentinum.digitalesregister.it'
          },
        ],
      })!;

      expect(result.login['url'], _new);
      expect(result.login['pass'], 'geheim');
      final others = result.login['otherAccounts']! as List;
      expect((others[0] as Map)['url'],
          'https://ms-tschoegglberg.digitalesregister.it');
      expect((others[1] as Map)['url'],
          'https://vinzentinum.digitalesregister.it');
      expect(result.moves, [
        (user: 'anna', from: _old, to: _new),
        (
          user: 'ben',
          from: 'https://ms-moelten.digitalesregister.it',
          to: 'https://ms-tschoegglberg.digitalesregister.it',
        ),
      ]);
    });

    test('moves the address kept after a logout, without a user', () {
      final result = migrateStoredLogin({'url': _old})!;

      expect(result.login['url'], _new);
      expect(result.moves, isEmpty);
    });

    test('is null when nothing moved', () {
      expect(
        migrateStoredLogin({
          'user': 'anna',
          'url': _new,
          'otherAccounts': [
            {'user': 'ben', 'url': 'https://vinzentinum.digitalesregister.it'},
          ],
        }),
        isNull,
      );
    });
  });

  group('migrateProfileKeys', () {
    test('files alias and photo under the new address', () {
      final result = migrateProfileKeys({
        'anna@$_old': {'alias': 'Anna'},
        'cleo@https://vinzentinum.digitalesregister.it': {'alias': 'Cleo'},
      });

      expect(result, {
        'cleo@https://vinzentinum.digitalesregister.it': {'alias': 'Cleo'},
        'anna@$_new': {'alias': 'Anna'},
      });
    });

    test('an entry already at the new address wins', () {
      final result = migrateProfileKeys({
        'anna@$_old': {'alias': 'alt'},
        'anna@$_new': {'alias': 'neu'},
      });

      expect(result, {
        'anna@$_new': {'alias': 'neu'},
      });
    });

    test('is null when nothing moved', () {
      expect(migrateProfileKeys({'anna@$_new': <String, Object?>{}}), isNull);
    });
  });

  group('migrateMovedSchools', () {
    late FakeSecureStorage storage;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        accountProfilesPrefsKey: json.encode({
          'anna@$_old': {'alias': 'Anna'},
        }),
      });
    });

    test('moves login, saved state and profile together', () async {
      storage = FakeSecureStorage(storage: {
        'login': json.encode({'user': 'anna', 'pass': 'geheim', 'url': _old}),
        _stateKey('anna', _old): '{"v":2}',
      });
      secureStorage = storage;

      await migrateMovedSchools();

      final login = json.decode(storage.storage['login']!) as Map;
      expect(login['url'], _new);
      expect(login['pass'], 'geheim');
      expect(storage.storage[_stateKey('anna', _new)], '{"v":2}');
      expect(storage.storage.containsKey(_stateKey('anna', _old)), isFalse);
      final prefs = await SharedPreferences.getInstance();
      final profiles =
          json.decode(prefs.getString(accountProfilesPrefsKey)!) as Map;
      expect(profiles.keys, ['anna@$_new']);
    });

    test('keeps a state the new address already has', () async {
      storage = FakeSecureStorage(storage: {
        'login': json.encode({'user': 'anna', 'pass': 'geheim', 'url': _old}),
        _stateKey('anna', _old): 'alt',
        _stateKey('anna', _new): 'neu',
      });
      secureStorage = storage;

      await migrateMovedSchools();

      expect(storage.storage[_stateKey('anna', _new)], 'neu');
    });

    test('touches nothing when no school moved', () async {
      final before = {
        'login': json.encode({'user': 'anna', 'pass': 'geheim', 'url': _new}),
        _stateKey('anna', _new): '{"v":2}',
      };
      storage = FakeSecureStorage(storage: {...before});
      secureStorage = storage;

      await migrateMovedSchools();

      expect(storage.storage, before);
    });
  });
}
