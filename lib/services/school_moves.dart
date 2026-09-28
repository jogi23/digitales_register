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

import 'package:dr/util.dart';
import 'package:flutter/foundation.dart';

/// Schools whose register moved to another address: old subdomain → new one.
///
/// The old addresses lead nowhere any more (the server answers with a 301).
/// Every entry is backed by the link on the school's own website, as of
/// September 2026. Schools that closed or split into several addresses are
/// left out on purpose — there is no single place to send them.
@visibleForTesting
const movedSubdomains = <String, String>{
  // Schulsprengel St. Leonhard in Passeier: one register for all
  // Grundschulen.
  'gs-moos': 'gs-stleonhard',
  'gs-platt': 'gs-stleonhard',
  'gs-rabenstein': 'gs-stleonhard',
  'gs-stuls': 'gs-stleonhard',
  'gs-walten': 'gs-stleonhard',
  // SSP Tschögglberg: one register for both Mittelschulen.
  'ms-jenesien': 'ms-tschoegglberg',
  'ms-moelten': 'ms-tschoegglberg',
  // Sterzing III was dissolved in 2022; both Mittelschulen are SSP
  // Sterzing 2 now, its Grundschulen Sterzing I.
  'fischnaler': 'ms-sterzing',
  'schulsprengel-sterzing3': 'ms-sterzing',
  'sterzing1': 'gs-sterzing3',
  'natz': 'gsp-vahrn',
  'sulden': 'gs-prad',
  'hafling': 'gs-hafling',
  // The Landesberufsschulen are Berufsbildungszentren now.
  'lbs-schlanders': 'bzs',
  'lbszuegg': 'bbzzuegg',
};

const _domain = '.digitalesregister.it';

/// [url] at the school's new address, or null if the school did not move.
///
/// Only the host changes; whatever else the stored address looks like — a
/// scheme or not, a slash at the end — stays, so it still matches the keys
/// other data was filed under with it.
String? movedSchoolUrl(String url) {
  final host = Uri.tryParse(fixupUrl(url.trim()))?.host.toLowerCase();
  if (host == null || !host.endsWith(_domain)) return null;
  final target =
      movedSubdomains[host.substring(0, host.length - _domain.length)];
  if (target == null) return null;
  final start = url.toLowerCase().indexOf(host);
  return url.replaceRange(start, start + host.length, '$target$_domain');
}

/// An account whose school moved: [from] and [to] as stored.
typedef SchoolMove = ({String user, String from, String to});

/// The stored login (the `login` entry of the secure storage) with every
/// account of a moved school at its new address, and the accounts that
/// moved. Null when nothing moved.
({Map<String, Object?> login, List<SchoolMove> moves})? migrateStoredLogin(
  Map<String, Object?> login,
) {
  final moves = <SchoolMove>[];
  var changed = false;

  Map<String, Object?> migrateAccount(Map<String, Object?> account) {
    final url = account['url'];
    if (url is! String) return account;
    final moved = movedSchoolUrl(url);
    if (moved == null) return account;
    changed = true;
    final user = account['user'];
    if (user is String) moves.add((user: user, from: url, to: moved));
    return {...account, 'url': moved};
  }

  // A copy either way: the caller's map stays as it was.
  final migrated = {...migrateAccount(login)};
  final others = login['otherAccounts'];
  if (others is List) {
    migrated['otherAccounts'] = [
      for (final other in others)
        if (other is Map)
          migrateAccount(Map<String, Object?>.from(other))
        else
          other,
    ];
  }
  // A login without a user moves as well: after a logout only the address
  // is kept, and the form shows it.
  if (!changed) return null;
  return (login: migrated, moves: moves);
}

/// The account profiles (alias and photo, filed under `user@url`) with the
/// keys of moved schools rewritten. An entry already filed under the new
/// address wins. Null when nothing moved.
Map<String, Object?>? migrateProfileKeys(Map<String, Object?> profiles) {
  var changed = false;
  final result = <String, Object?>{};
  final moved = <String, Object?>{};
  for (final MapEntry(:key, :value) in profiles.entries) {
    final at = key.lastIndexOf('@');
    final newUrl = at < 0 ? null : movedSchoolUrl(key.substring(at + 1));
    if (newUrl == null) {
      result[key] = value;
    } else {
      changed = true;
      moved['${key.substring(0, at)}@$newUrl'] = value;
    }
  }
  if (!changed) return null;
  for (final MapEntry(:key, :value) in moved.entries) {
    result.putIfAbsent(key, () => value);
  }
  return result;
}
