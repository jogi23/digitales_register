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

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'account_profiles';

class AccountProfile {
  final String? alias;
  final String? photoPath;

  const AccountProfile({this.alias, this.photoPath});

  AccountProfile copyWith({Object? alias = _s, Object? photoPath = _s}) =>
      AccountProfile(
        alias: alias == _s ? this.alias : alias as String?,
        photoPath: photoPath == _s ? this.photoPath : photoPath as String?,
      );

  Map<String, dynamic> toJson() => {
        if (alias != null) 'alias': alias,
        if (photoPath != null) 'photoPath': photoPath,
      };

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
        alias: json['alias'] as String?,
        photoPath: json['photoPath'] as String?,
      );
}

const _s = Object();

String accountProfileKey(String username, String url) => '$username@$url';

class AccountProfileNotifier
    extends Notifier<Map<String, AccountProfile>> {
  @override
  Map<String, AccountProfile> build() => {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final decoded = json.decode(raw) as Map<String, dynamic>;
    state = decoded.map(
      (k, v) => MapEntry(k, AccountProfile.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<void> setAlias(String key, String? alias) async {
    final current = state[key] ?? const AccountProfile();
    state = {...state, key: current.copyWith(alias: alias)};
    await _persist();
  }

  Future<void> setPhoto(String key, String? photoPath) async {
    final current = state[key] ?? const AccountProfile();
    state = {...state, key: current.copyWith(photoPath: photoPath)};
    await _persist();
  }

  AccountProfile profileFor(String key) =>
      state[key] ?? const AccountProfile();

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      json.encode(state.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}

final accountProfileProvider =
    NotifierProvider<AccountProfileNotifier, Map<String, AccountProfile>>(
  AccountProfileNotifier.new,
);
