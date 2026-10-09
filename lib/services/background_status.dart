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

import 'package:shared_preferences/shared_preferences.dart';

// What the last round of the background check found (#319), kept so the
// settings can show it — in release builds too, where there is no debug log.
// Only counts and a label go in: no password, no user name, no message text.

const backgroundStatusPrefsKey = 'background_check_status';

enum AccountCheckOutcome { ok, unreachable, skippedAppSignedIn, firstRun }

/// How the check went for one account.
class AccountCheckResult {
  const AccountCheckResult({
    required this.label,
    required this.outcome,
    this.unread,
    this.fresh,
  });

  /// The alias of the account, or its short tag when it has none.
  final String label;
  final AccountCheckOutcome outcome;

  /// What is unread, and what of it is new; null where the account was not
  /// looked at.
  final int? unread;
  final int? fresh;

  Map<String, Object?> toJson() => {
        'label': label,
        'outcome': outcome.name,
        if (unread != null) 'unread': unread,
        if (fresh != null) 'fresh': fresh,
      };

  static AccountCheckResult? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final label = raw['label'];
    final outcome = AccountCheckOutcome.values
        .where((o) => o.name == raw['outcome'])
        .firstOrNull;
    if (label is! String || outcome == null) return null;
    return AccountCheckResult(
      label: label,
      outcome: outcome,
      unread: raw['unread'] as int?,
      fresh: raw['fresh'] as int?,
    );
  }
}

/// The result of one round: when it ended, and for each account how it went.
class BackgroundStatus {
  const BackgroundStatus({required this.finishedAt, required this.accounts});

  final DateTime finishedAt;
  final List<AccountCheckResult> accounts;

  Map<String, Object?> toJson() => {
        'finishedAt': finishedAt.toUtc().toIso8601String(),
        'accounts': [for (final a in accounts) a.toJson()],
      };

  /// The status in [raw], or null when it is not one — nothing, damaged, or
  /// written by another version.
  static BackgroundStatus? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final finishedAt = raw['finishedAt'];
    final accounts = raw['accounts'];
    if (finishedAt is! String || accounts is! List) return null;
    final time = DateTime.tryParse(finishedAt);
    final parsed = [for (final a in accounts) AccountCheckResult.tryParse(a)];
    if (time == null || parsed.contains(null)) return null;
    return BackgroundStatus(
      finishedAt: time,
      accounts: parsed.whereType<AccountCheckResult>().toList(),
    );
  }
}

/// How the check went for the account called [label].
AccountCheckResult checkResultFor(
  String label, {
  bool appSignedIn = false,
  bool reached = true,
  bool firstRun = false,
  int unread = 0,
  int fresh = 0,
}) {
  if (appSignedIn) {
    return AccountCheckResult(
      label: label,
      outcome: AccountCheckOutcome.skippedAppSignedIn,
    );
  }
  if (!reached) {
    return AccountCheckResult(
      label: label,
      outcome: AccountCheckOutcome.unreachable,
    );
  }
  return AccountCheckResult(
    label: label,
    outcome: firstRun ? AccountCheckOutcome.firstRun : AccountCheckOutcome.ok,
    unread: unread,
    fresh: firstRun ? null : fresh,
  );
}

Future<void> writeBackgroundStatus(
  SharedPreferences prefs,
  BackgroundStatus status,
) =>
    prefs.setString(backgroundStatusPrefsKey, json.encode(status.toJson()));

/// The latest round's status, read fresh — the background isolate wrote it.
Future<BackgroundStatus?> readBackgroundStatus() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getString(backgroundStatusPrefsKey);
  if (raw == null) return null;
  try {
    return BackgroundStatus.tryParse(json.decode(raw));
  } on FormatException {
    return null;
  }
}
