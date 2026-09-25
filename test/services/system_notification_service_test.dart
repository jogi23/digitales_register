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

import 'package:dr/providers/login_provider.dart';
import 'package:dr/services/system_notification_service.dart';
import 'package:dr/system_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isCurrentAccount', () {
    const target = SystemNotificationTarget(
      user: 'anna',
      url: 'https://schule.digitalesregister.it',
      id: 7,
      type: 'message',
      objectId: 42,
    );

    test('knows the account in use before it has signed in online (#284)', () {
      // After a start by the tap only the login state knows the account:
      // the session has no user until the online login is through.
      const login = LoginState(
        loggedIn: true,
        username: 'anna',
        url: 'https://schule.digitalesregister.it/',
      );
      expect(isCurrentAccount(login, target), isTrue);
    });

    test('not another user on the same school', () {
      const login = LoginState(
        loggedIn: true,
        username: 'ben',
        url: 'https://schule.digitalesregister.it',
      );
      expect(isCurrentAccount(login, target), isFalse);
    });

    test('not the same user on another school', () {
      const login = LoginState(
        loggedIn: true,
        username: 'anna',
        url: 'https://andere.digitalesregister.it',
      );
      expect(isCurrentAccount(login, target), isFalse);
    });
  });
}
