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

/// Parses the server's HTML home page to extract user configuration.
///
/// All methods are pure/static — no network calls, no side effects.
class ConfigParser {
  ConfigParser._();

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

  static int _readAutoLogoutSeconds(String source) {
    final substringFromId = source.substring(
        source.indexOf("auto_logout_seconds: ") +
            "auto_logout_seconds: ".length);
    return int.parse(
        substringFromId.substring(0, substringFromId.indexOf(",")).trim());
  }

  static int _readUserId(String source) {
    final substringFromId = source
        .substring(source.indexOf("currentUserId=") + "currentUserId=".length);
    return int.parse(
        substringFromId.substring(0, substringFromId.indexOf(";")).trim());
  }

  static String _readAfterImgId(String source) {
    return source
        .substring(source.indexOf("navigationProfilePicture") +
            "navigationProfilePicture".length)
        .trim();
  }

  static String _readFullName(String source) {
    final afterImgId = _readAfterImgId(source);
    return afterImgId
        .substring(afterImgId.indexOf(">") + 1, afterImgId.indexOf("<"))
        .trim();
  }

  static String _readImgSource(String source) {
    final afterImgId = _readAfterImgId(source);
    final afterStart =
        afterImgId.substring(afterImgId.indexOf('src="') + "src='".length);
    return afterStart.substring(0, afterStart.indexOf('"')).trim();
  }
}
