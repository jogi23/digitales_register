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

import 'package:dr/services/app_sharing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('store links', () {
    test('point at the released app, not the debug build', () {
      // Debug builds carry a ".debug" suffix; that listing does not exist.
      expect(playStorePackage, 'io.wertwerk.digitalesregister');
      expect(playStoreWebUri.toString(), isNot(contains('.debug')));
      expect(playStoreAppUri.toString(), isNot(contains('.debug')));
    });

    test('offer both the store app and the web listing', () {
      expect(playStoreAppUri.scheme, 'market');
      expect(playStoreAppUri.queryParameters['id'], playStorePackage);

      expect(playStoreWebUri.scheme, 'https');
      expect(playStoreWebUri.host, 'play.google.com');
      expect(playStoreWebUri.queryParameters['id'], playStorePackage);
    });
  });

  group('invitation', () {
    test('carries a link someone can actually open', () {
      // A share that only names the app is useless in a chat.
      expect(invitationText, contains(playStoreWebUri.toString()));
      expect(invitationText, contains('https://'));
    });

    test('says what the app is for', () {
      expect(invitationText, contains('Digitale'));
      expect(invitationText.trim(), isNotEmpty);
    });

    test('stays short enough for a chat message', () {
      expect(invitationText.length, lessThan(300));
    });
  });
}
