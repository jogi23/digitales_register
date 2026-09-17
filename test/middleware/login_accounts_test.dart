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

import 'package:dr/middleware/middleware.dart' show accountsWithCurrent;
import 'package:dr/util.dart' show credentialsComplete;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('what may be sent as a login', () {
    test('name and password have to carry something', () {
      expect(credentialsComplete('anna', 'geheim'), isTrue);
      expect(credentialsComplete('', 'geheim'), isFalse);
      expect(credentialsComplete('anna', ''), isFalse);
      expect(credentialsComplete('   ', 'geheim'), isFalse);
    });
  });

  group('the account list', () {
    test('keeps the account in use in front', () {
      final accounts = accountsWithCurrent({
        'user': 'anna',
        'pass': 'geheim',
        'url': 'https://schule.digitalesregister.it',
        'otherAccounts': [
          {
            'user': 'ben',
            'pass': 'x',
            'url': 'https://schule.digitalesregister.it'
          },
        ],
      });
      expect(accounts, hasLength(2));
      expect((accounts.first as Map)['user'], 'anna');
    });

    test('keeps an account whose password is gone', () {
      // This is the case that lost the account: an empty login attempt used
      // to wipe the saved password, and without one the account was dropped.
      final accounts = accountsWithCurrent({
        'user': 'anna',
        'pass': null,
        'url': 'https://schule.digitalesregister.it',
        'otherAccounts': <Object?>[],
      });
      expect(accounts, hasLength(1));
      expect((accounts.first as Map)['user'], 'anna');
      expect((accounts.first as Map)['pass'], isNull);
    });

    test('does not list the same account twice', () {
      final accounts = accountsWithCurrent({
        'user': 'anna',
        'pass': 'geheim',
        'url': 'https://schule.digitalesregister.it',
        'otherAccounts': [
          {
            'user': 'anna',
            'pass': 'geheim',
            'url': 'https://schule.digitalesregister.it',
          },
        ],
      });
      expect(accounts, hasLength(1));
    });

    test('without an account in use it stays as it was', () {
      final accounts = accountsWithCurrent({
        'url': 'https://schule.digitalesregister.it',
        'otherAccounts': [
          {
            'user': 'ben',
            'pass': 'x',
            'url': 'https://schule.digitalesregister.it'
          },
        ],
      });
      expect(accounts, hasLength(1));
      expect((accounts.first as Map)['user'], 'ben');
    });

    test('an empty storage gives an empty list', () {
      expect(accountsWithCurrent(<String, Object?>{}), isEmpty);
    });
  });
}
