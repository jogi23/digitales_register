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

import 'package:dio/dio.dart';
import 'package:dr/services/school_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DioException _badResponse(int status) {
  final options = RequestOptions(path: 'https://x.digitalesregister.it');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: options,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('isSchoolNotFound', () {
    test('a redirect or 404 means there is no school at the address', () {
      expect(isSchoolNotFound(_badResponse(301)), isTrue);
      expect(isSchoolNotFound(_badResponse(302)), isTrue);
      expect(isSchoolNotFound(_badResponse(404)), isTrue);
    });

    test('a server error or a dropped connection does not', () {
      expect(isSchoolNotFound(_badResponse(500)), isFalse);
      expect(
        isSchoolNotFound(
          DioException.connectionError(
            requestOptions: RequestOptions(),
            reason: 'offline',
          ),
        ),
        isFalse,
      );
      expect(isSchoolNotFound(Exception('anything')), isFalse);
    });
  });

  group('SchoolReporter', () {
    const listed = 'https://known.digitalesregister.it';
    late List<(SchoolReportKind, String)> sent;
    late SchoolReporter sut;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sent = [];
      sut = SchoolReporter(
        schools: () async => {'Known School': listed},
        send: (kind, host) async => sent.add((kind, host)),
      );
    });

    test('reports a school missing from the list, host only', () async {
      await sut.loggedIn('https://New-School.digitalesregister.it/');

      expect(sent, [
        (SchoolReportKind.unlisted, 'new-school.digitalesregister.it'),
      ]);
    });

    test('stays quiet about a school the list knows', () async {
      await sut.loggedIn('$listed/v2/login');

      expect(sent, isEmpty);
    });

    test('reports each school once per install', () async {
      await sut.loggedIn('https://new.digitalesregister.it');
      await sut.loggedIn('https://new.digitalesregister.it');

      expect(sent, hasLength(1));
    });

    test('reports a listed school that leads nowhere', () async {
      await sut.notFound(listed);

      expect(sent, [
        (SchoolReportKind.unreachable, 'known.digitalesregister.it'),
      ]);
    });

    test('a typo that leads nowhere is no news for the list', () async {
      await sut.notFound('https://knwon.digitalesregister.it');

      expect(sent, isEmpty);
    });

    test('never reports a server outside digitalesregister.it', () async {
      await sut.loggedIn('https://192.168.1.10:8080');
      await sut.loggedIn('https://register.example.com');
      await sut.loggedIn('https://www.digitalesregister.it');

      expect(sent, isEmpty);
    });

    test('a failing report does not reach the login', () async {
      sut = SchoolReporter(
        schools: () async => const {},
        send: (_, __) async => throw Exception('Sentry down'),
      );

      await expectLater(
        sut.loggedIn('https://new.digitalesregister.it'),
        completes,
      );
    });

    test('a failed report is tried again next time', () async {
      var attempts = 0;
      sut = SchoolReporter(
        schools: () async => const {},
        send: (_, __) async {
          attempts++;
          if (attempts == 1) throw Exception('Sentry down');
        },
      );

      await sut.loggedIn('https://new.digitalesregister.it');
      await sut.loggedIn('https://new.digitalesregister.it');
      await sut.loggedIn('https://new.digitalesregister.it');

      expect(attempts, 2);
    });
  });
}
