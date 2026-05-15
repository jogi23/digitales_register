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
import 'package:dr/main.dart' show navigatorKey, showSnackBar;
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => ProfileState();

  void reset() {
    state = ProfileState();
  }

  Future<void> load() async {
    if (ref.read(noInternetProvider)) return;
    final dynamic result = await wrapper.send("api/profile/get");
    if (result == null) return;
    state = tryParse(getMap(result as Object)!, _parseProfile);
  }

  Future<void> setSendNotificationEmails(bool value) async {
    state = state.rebuild((b) => b..sendNotificationEmails = value);
    await wrapper.send(
      "api/profile/updateNotificationSettings",
      args: {"notificationsEnabled": value},
    );
  }

  Future<void> changeEmail(String pass, String email) async {
    final dynamic result = await wrapper.send(
      "api/profile/updateProfile",
      args: {"email": email, "password": pass},
    );
    if (result == null) return;
    if (result["error"] == null) {
      showSnackBar(result["message"] as String);
      navigatorKey?.currentState?.pop();
    } else {
      showSnackBar("[${result["error"]}]: ${result["message"]}");
    }
    await load();
  }

  ProfileState _parseProfile(Map data) {
    return ProfileState(
      (b) => b
        ..name = getString(data["name"])
        ..email = getString(data["email"])
        ..roleName = getString(data["roleName"])
        ..sendNotificationEmails = getBool(data["notificationsEnabled"])
        ..username = getString(data["username"]),
    );
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
