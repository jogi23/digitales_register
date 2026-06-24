// Copyright (C) 2021 Michael Debertol
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

part of 'middleware.dart';

Future<void> _doSaveNoPass(bool value) async {
  wrapper.safeMode = value;
  if (!providerContainer.read(loginProvider).loggedIn) return;
  if (!value) {
    await _doSavePass();
  } else {
    await _doDeletePass();
  }
}

Future<void> _doSavePass() async {
  if (wrapper.user == null || wrapper.pass == null || wrapper.safeMode) return;
  final rawOthers = await _readStoredOtherAccounts();
  // Remove any otherAccount entry that matches the account being saved as
  // current — prevents duplicates when a user re-logs-in with an existing account.
  final others = (rawOthers as List?)
      ?.where((dynamic a) =>
          !(a['user'] == wrapper.user && a['url'] == wrapper.url))
      .toList();
  await secureStorage.write(
    key: "login",
    value: json.encode(
      <String, Object?>{
        "user": wrapper.user,
        "pass": wrapper.pass,
        "url": wrapper.url,
        "otherAccounts": others,
      },
    ),
  );
}

Future<void> _doDeletePass() async {
  await secureStorage.write(
    key: "login",
    value: json.encode(
      <String, Object?>{
        "url": wrapper.url,
        "otherAccounts": await _readStoredOtherAccounts(),
      },
    ),
  );
}

Future<dynamic> _readStoredOtherAccounts() async {
  return json
      .decode(await secureStorage.read(key: "login") ?? "{}")["otherAccounts"];
}
