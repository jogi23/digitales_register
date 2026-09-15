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

// Keeps the notes of released versions the way they were published.
//
// A version is closed once pubspec.yaml has moved past it: its notes were read
// in the app and in the store. `tools/changelog.lock.json` holds a fingerprint
// of each closed version's date and notes, one per language, and
// `test/services/changelog_test.dart` fails as soon as the notes no longer
// match. Only the version pubspec.yaml is at stays open.
//
// The lock lives here rather than next to `assets/changelog.json`, because
// everything under `assets/` is bundled into the app.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const lockPath = 'tools/changelog.lock.json';

/// Fingerprints per closed version, then per language.
typedef ChangelogLock = Map<String, Map<String, String>>;

/// The version pubspec.yaml is at, without its build number — the one whose
/// notes may still change.
String pubspecVersion() {
  final line = File('pubspec.yaml')
      .readAsLinesSync()
      .firstWhere((line) => line.startsWith('version:'));
  return line.split(':')[1].split('+').first.trim();
}

/// Whether [version] was released before [current] and its notes are final.
bool isClosed(String version, String current) =>
    compareVersions(version, current) < 0;

/// One fingerprint per language of a release in `assets/changelog.json`: its
/// date together with that language's headings and lines.
///
/// Taken over the decoded notes, so re-indenting the file changes nothing.
Map<String, String> fingerprints(Map<String, dynamic> release) {
  final points = release['points'] as Map<String, dynamic>;
  return {
    for (final MapEntry(key: language, value: sections) in points.entries)
      language: sha256
          .convert(utf8.encode(
            jsonEncode({'date': release['date'], 'sections': sections}),
          ))
          .toString(),
  };
}

ChangelogLock readLock() {
  final file = File(lockPath);
  if (!file.existsSync()) return {};
  return {
    for (final MapEntry(key: version, value: languages)
        in (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
            .entries)
      version: (languages as Map<String, dynamic>).cast<String, String>(),
  };
}

/// Newest release first and languages in a fixed order, so that a new lock
/// shows in the diff as exactly the versions it adds.
void writeLock(ChangelogLock lock) {
  final versions = lock.keys.toList()..sort((a, b) => compareVersions(b, a));
  final sorted = {
    for (final version in versions)
      version: {
        for (final language in lock[version]!.keys.toList()..sort())
          language: lock[version]![language],
      },
  };
  File(lockPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
  );
}

/// Compares two dotted versions the way their numbers read, so that 1.2.10
/// sorts after 1.2.9. Mirrors `compareVersions` in `lib/services/changelog.dart`.
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l < r ? -1 : 1;
  }
  return 0;
}

List<int> _parts(String version) =>
    version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
