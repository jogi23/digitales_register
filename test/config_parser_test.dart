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

import 'package:dr/config_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal HTML snippet that [ConfigParser.parse] can handle.
///
/// The [extra] parameter is inserted between the userId declaration and the
/// config block, so it can be used to inject optional flags such as
/// `var isStudentOrParent=0;` or `semesterWechsel=1`.
String _src({
  int userId = 1,
  String name = 'Test User',
  String imgUrl = 'https://example.com/pic.png',
  int autoLogout = 60,
  String extra = '',
}) =>
    'var currentUserId=$userId;'
    '$extra'
    'var config = { auto_logout_seconds: $autoLogout, };'
    'navigationProfilePicture" src="$imgUrl">$name</span>';

void main() {
  group('ConfigParser', () {
    test('parses userId', () {
      final config = ConfigParser.parse(_src(userId: 42));
      expect(config.userId, 42);
    });

    test('parses fullName', () {
      final config = ConfigParser.parse(_src(name: 'Anna Muster'));
      expect(config.fullName, 'Anna Muster');
    });

    test('parses imgSource', () {
      final config = ConfigParser.parse(
          _src(imgUrl: 'https://srv.example.com/avatar.jpg'));
      expect(config.imgSource, 'https://srv.example.com/avatar.jpg');
    });

    test('parses autoLogoutSeconds', () {
      final config = ConfigParser.parse(_src(autoLogout: 900));
      expect(config.autoLogoutSeconds, 900);
    });

    group('isStudentOrParent', () {
      test('true when flag absent', () {
        final config = ConfigParser.parse(_src());
        expect(config.isStudentOrParent, isTrue);
      });

      test('false when isStudentOrParent=0 present', () {
        final config =
            ConfigParser.parse(_src(extra: 'var isStudentOrParent=0;'));
        expect(config.isStudentOrParent, isFalse);
      });
    });

    group('currentSemesterMaybe', () {
      test('null when no semesterWechsel flag', () {
        final config = ConfigParser.parse(_src());
        expect(config.currentSemesterMaybe, isNull);
      });

      test('returns 2 when semesterWechsel=1', () {
        final config = ConfigParser.parse(_src(extra: 'semesterWechsel=1;'));
        expect(config.currentSemesterMaybe, 2);
      });

      test('returns 1 when semesterWechsel=2', () {
        final config = ConfigParser.parse(_src(extra: 'semesterWechsel=2;'));
        expect(config.currentSemesterMaybe, 1);
      });
    });
  });
}
