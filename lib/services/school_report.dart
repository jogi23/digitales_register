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
import 'package:dr/config.dart';
import 'package:dr/util.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether a failed login means the school's address does not exist.
///
/// The server sends an unknown subdomain on to www.digitalesregister.it with
/// a 301. Dio does not follow a redirect for a POST, so the login ends in a
/// [DioException] instead — before the account was even looked at.
bool isSchoolNotFound(Object error) {
  if (error is! DioException) return false;
  if (error.type != DioExceptionType.badResponse) return false;
  final status = error.response?.statusCode;
  if (status == null) return false;
  return (status >= 300 && status < 400) || status == 404;
}

/// Why a school is worth a look in `assets/schools.json`.
enum SchoolReportKind {
  /// Signed in fine, but the school is not in the list.
  unlisted,

  /// In the list, but its address leads nowhere.
  unreachable,
}

/// The reporter the app uses, replaceable in tests.
SchoolReporter schoolReporter = SchoolReporter();

typedef SendSchoolReport = Future<void> Function(
  SchoolReportKind kind,
  String host,
);

/// Tells Sentry about schools the list lacks or has wrong, so it can be kept
/// up to date without anyone writing in.
///
/// Sends the host alone — never the user, the password or the account. Each
/// host and kind goes out once per install; a login from storage runs at
/// every start and would otherwise report the same school again and again.
class SchoolReporter {
  static const _reportedKey = 'school_reports_sent';

  final Future<Map<String, String>> Function() _schools;
  final SendSchoolReport _send;

  SchoolReporter({
    Future<Map<String, String>> Function()? schools,
    SendSchoolReport? send,
  })  : _schools = schools ?? loadSchools,
        _send = send ?? _sendToSentry;

  /// After a successful login: reports [url] if the list does not know it.
  Future<void> loggedIn(String url) =>
      _check(url, SchoolReportKind.unlisted, reportIfListed: false);

  /// After a login that found no school at [url]: reports it if the list
  /// offers that address.
  Future<void> notFound(String url) =>
      _check(url, SchoolReportKind.unreachable, reportIfListed: true);

  /// Never throws: a report must not get in the way of the login.
  Future<void> _check(
    String url,
    SchoolReportKind kind, {
    required bool reportIfListed,
  }) async {
    final host = _schoolHost(url);
    if (host == null) return;
    try {
      final schools = await _schools();
      final listed = schools.values.any((url) => _schoolHost(url) == host);
      if (listed != reportIfListed) return;

      final prefs = await SharedPreferences.getInstance();
      final sent = prefs.getStringList(_reportedKey) ?? const <String>[];
      final key = '${kind.name}:$host';
      if (sent.contains(key)) return;
      await _send(kind, host);
      await prefs.setStringList(_reportedKey, [...sent, key]);
    } catch (_) {
      // Nothing the user could do about it.
    }
  }
}

/// The host of a digitalesregister.it school, null for anything else.
///
/// Other servers stay private: a self-hosted or local test server is no
/// business of the school list.
String? _schoolHost(String url) {
  final uri = Uri.tryParse(fixupUrl(url.trim()));
  final host = uri?.host.toLowerCase();
  if (host == null || !host.endsWith('.digitalesregister.it')) return null;
  if (host == 'www.digitalesregister.it') return null;
  return host;
}

Future<void> _sendToSentry(SchoolReportKind kind, String host) async {
  final message = switch (kind) {
    SchoolReportKind.unlisted => 'Schule nicht in schools.json: $host',
    SchoolReportKind.unreachable =>
      'Schule aus schools.json nicht erreichbar: $host',
  };
  await Sentry.captureMessage(
    message,
    withScope: (scope) async {
      // One Sentry issue per school, however many installs report it.
      scope.fingerprint = ['school-report', kind.name, host];
      await scope.setTag('school_report', kind.name);
      await scope.setTag('school_host', host);
    },
  );
}
