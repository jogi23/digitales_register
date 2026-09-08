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

import 'package:dr/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// The app's changelog, replaceable in tests.
Changelog changelog = Changelog();

/// The first version that reached the Play Store.
///
/// Someone updating to a later one can only be coming from here — the earlier
/// releases were never published — so it stands in for the unknown "last seen"
/// the first time this feature runs. Once a version has been recorded, this is
/// no longer needed.
const firstPublishedVersion = '1.2.0';

/// The language the notes are written in when the device speaks none we ship.
const changelogFallbackLanguage = 'de';

/// One heading of a release and what belongs under it — new features,
/// improvements, fixes, internals.
class ChangelogSection {
  final String title;

  /// One line each, already worded for the reader.
  final List<String> items;

  const ChangelogSection({required this.title, required this.items});
}

/// What is new in one version.
class ChangelogEntry {
  final String version;

  /// When it was released, as written in the file.
  final String? date;

  final List<ChangelogSection> sections;

  const ChangelogEntry({
    required this.version,
    required this.sections,
    this.date,
  });

  /// Every line of the release, headings dropped — what the card shows, which
  /// has room for a handful of lines and none for structure.
  List<String> get points =>
      [for (final section in sections) ...section.items];
}

/// Compares two dotted versions the way their numbers read.
///
/// A plain string comparison would put 1.2.10 before 1.2.9. Missing parts
/// count as zero, so "1.2" and "1.2.0" are the same version.
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  for (var i = 0; i < (left.length > right.length ? left.length : right.length); i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

List<int> _parts(String version) {
  // A build number, as in "1.2.0+19", says nothing about what is new.
  final withoutBuild = version.split('+').first.trim();
  return withoutBuild
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
}

/// The versions worth showing: newer than [lastSeen], no newer than [current],
/// most recent first.
///
/// A null [lastSeen] means everything up to [current].
List<ChangelogEntry> entriesBetween({
  required List<ChangelogEntry> all,
  required String? lastSeen,
  required String current,
}) {
  final selected = all
      .where(
        (entry) =>
            compareVersions(entry.version, current) <= 0 &&
            (lastSeen == null || compareVersions(entry.version, lastSeen) > 0),
      )
      .toList()
    ..sort((a, b) => compareVersions(b.version, a.version));
  return selected;
}

/// Decides what the reader gets to see after an update, and remembers it.
class Changelog {
  static const _lastSeenKey = 'changelog_last_seen';
  static const _asset = 'assets/changelog.json';

  /// Both are read from the running build unless a test says otherwise.
  final String? _currentVersion;
  final bool? _freshInstall;

  Changelog({String? currentVersion, bool? freshInstall})
      : _currentVersion = currentVersion,
        _freshInstall = freshInstall;

  /// Computed once per app start: the card and the review prompt both wait on
  /// the same answer, so they cannot both go off on the same start.
  Future<List<ChangelogEntry>>? _pending;

  Future<List<ChangelogEntry>> pending() => _pending ??= _decide();

  @visibleForTesting
  void reset() => _pending = null;

  Future<List<ChangelogEntry>> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_lastSeenKey);
    final current = _currentVersion ?? appVersion;

    if (lastSeen == null && (_freshInstall ?? _installedButNeverUpdated)) {
      // Nothing to catch up on: the notes would be about versions this reader
      // never had.
      await prefs.setString(_lastSeenKey, current);
      return const [];
    }
    final from = lastSeen ?? firstPublishedVersion;
    if (compareVersions(current, from) <= 0) {
      // Same version, or an older one installed over a newer one.
      await prefs.setString(_lastSeenKey, current);
      return const [];
    }

    final entries = entriesBetween(
      all: await load(),
      lastSeen: from,
      current: current,
    );
    // Recorded as soon as it is decided, not when the card is dismissed:
    // otherwise the card returns at every start until someone closes it.
    await prefs.setString(_lastSeenKey, current);
    return entries;
  }

  /// Whether the app was installed rather than updated.
  ///
  /// Android reports when the app first arrived and when it was last replaced;
  /// as long as those match, no update has happened yet. Where the platform
  /// says nothing, an update is assumed — showing the notes once too often
  /// beats swallowing them.
  bool get _installedButNeverUpdated {
    try {
      final installed = packageInfo.installTime;
      final updated = packageInfo.updateTime;
      if (installed == null || updated == null) return false;
      return !updated.isAfter(installed);
    } catch (_) {
      return false;
    }
  }

  /// Every version the app ships notes for, newest first.
  ///
  /// In the device's language where we have it, in German otherwise.
  Future<List<ChangelogEntry>> load() async {
    final String raw;
    try {
      raw = await rootBundle.loadString(_asset);
    } catch (_) {
      // No notes shipped for this build: show nothing rather than an empty
      // card.
      return const [];
    }
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final language = PlatformDispatcher.instance.locale.languageCode;
    final entries = <ChangelogEntry>[];
    decoded.forEach((version, dynamic value) {
      final release = (value as Map).cast<String, dynamic>();
      final byLanguage = (release['points'] as Map).cast<String, dynamic>();
      final sections =
          byLanguage[language] ?? byLanguage[changelogFallbackLanguage];
      if (sections == null) return;
      entries.add(
        ChangelogEntry(
          version: version,
          date: release['date'] as String?,
          sections: [
            for (final dynamic section in sections as List)
              ChangelogSection(
                title: (section as Map)['title'] as String,
                items: (section['items'] as List).cast<String>(),
              ),
          ],
        ),
      );
    });
    entries.sort((a, b) => compareVersions(b.version, a.version));
    return entries;
  }
}
