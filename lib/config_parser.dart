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

import 'package:dr/app_state.dart';

/// Thrown when the page is not the home page of a logged-in account — a login
/// or redirect page, for instance.
class ConfigParseException implements Exception {
  /// The text that was expected on the page but not found.
  final String missing;

  const ConfigParseException(this.missing);

  @override
  String toString() =>
      "ConfigParseException: '$missing' not found on the home page";
}

/// Parses the server's HTML home page to extract user configuration.
///
/// All methods are pure/static — no network calls, no side effects.
class ConfigParser {
  ConfigParser._();

  /// Throws [ConfigParseException] if [source] lacks any of the values.
  static Config parse(String source) {
    final id = _readUserId(source);
    final fullName = _readFullName(source);
    final imgSource = _readImgSource(source);
    final autoLogout = _readAutoLogoutSeconds(source);
    final currentSemesterMaybe = _readCurrentSemester(source);
    final isStudentOrParent = _readIsStudentOrParent(source);
    return Config(
      (b) => b
        ..userId = id
        ..autoLogoutSeconds = autoLogout
        ..fullName = fullName
        ..imgSource = imgSource
        ..currentSemesterMaybe = currentSemesterMaybe
        ..isStudentOrParent = isStudentOrParent,
    );
  }

  static bool _readIsStudentOrParent(String source) {
    return !source.contains("var isStudentOrParent=0;");
  }

  static int? _readCurrentSemester(String source) {
    if (source.contains("semesterWechsel=1")) return 2;
    if (source.contains("semesterWechsel=2")) {
      return 1;
    } else {
      return null;
    }
  }

  static int _readAutoLogoutSeconds(String source) =>
      _readInt(source, "auto_logout_seconds: ", ",");

  static int _readUserId(String source) =>
      _readInt(source, "currentUserId=", ";");

  static String _readAfterImgId(String source) =>
      _after(source, "navigationProfilePicture").trim();

  static String _readFullName(String source) =>
      _between(_readAfterImgId(source), ">", "<").trim();

  static String _readImgSource(String source) =>
      _between(_readAfterImgId(source), 'src="', '"').trim();

  static int _readInt(String source, String marker, String end) {
    final text = _between(source, marker, end).trim();
    return int.tryParse(text) ?? (throw ConfigParseException(marker));
  }

  /// Everything after [marker]. Searching blindly used to cut at index -1
  /// and hand whatever came out to `int.parse`.
  static String _after(String source, String marker) {
    final start = source.indexOf(marker);
    if (start == -1) throw ConfigParseException(marker);
    return source.substring(start + marker.length);
  }

  static String _between(String source, String marker, String end) {
    final rest = _after(source, marker);
    final stop = rest.indexOf(end);
    if (stop == -1) throw ConfigParseException(end);
    return rest.substring(0, stop);
  }
}
