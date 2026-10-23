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

import 'package:shared_preferences/shared_preferences.dart';

/// Runs [send] unless [key] is already listed under [prefsKey] in the shared
/// preferences, then lists it. A send that throws stays unlisted, so the next
/// run tries again; the error goes to the caller.
Future<void> reportOncePerInstall(
  String prefsKey,
  String key,
  Future<void> Function() send,
) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getStringList(prefsKey)?.contains(key) ?? false) return;
  await send();
  // Read again: another report may have been listed during the send.
  await prefs.setStringList(prefsKey, [...?prefs.getStringList(prefsKey), key]);
}
