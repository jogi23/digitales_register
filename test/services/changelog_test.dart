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

import 'package:dr/services/changelog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ChangelogEntry _entry(String version) => ChangelogEntry(
      version: version,
      sections: [
        ChangelogSection(title: 'Neue Funktionen', items: ['Neu in $version']),
      ],
    );

Future<String?> _storedVersion() async =>
    (await SharedPreferences.getInstance()).getString('changelog_last_seen');

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('comparing versions', () {
    test('reads the numbers, not the letters', () {
      // The bug this guards: as strings, "1.2.10" sorts before "1.2.9".
      expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('treats missing parts as zero', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('ignores the build number', () {
      expect(compareVersions('1.2.1+20', '1.2.1'), 0);
    });

    test('orders both ways round', () {
      expect(compareVersions('1.2.0', '1.2.1'), lessThan(0));
      expect(compareVersions('1.2.1', '1.2.1'), 0);
    });
  });

  group('picking the versions to show', () {
    final all = [_entry('1.2.0'), _entry('1.2.1'), _entry('1.3.0')];

    test('takes what came after the last seen version', () {
      final entries =
          entriesBetween(all: all, lastSeen: '1.2.0', current: '1.3.0');
      expect(entries.map((e) => e.version), ['1.3.0', '1.2.1']);
    });

    test('leaves out versions that are not installed yet', () {
      final entries =
          entriesBetween(all: all, lastSeen: '1.2.0', current: '1.2.1');
      expect(entries.map((e) => e.version), ['1.2.1']);
    });

    test('takes everything when nothing was seen before', () {
      final entries = entriesBetween(all: all, lastSeen: null, current: '1.3.0');
      expect(entries, hasLength(3));
    });

    test('is empty when the last seen version is the current one', () {
      expect(
        entriesBetween(all: all, lastSeen: '1.3.0', current: '1.3.0'),
        isEmpty,
      );
    });
  });

  group('deciding what to show at startup', () {
    test('shows nothing on a fresh install', () async {
      // The notes would be about versions this reader never had.
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: true);
      expect(await changelog.pending(), isEmpty);
      expect(await _storedVersion(), '1.2.1');
    });

    test('an update without a stored version counts as coming from the store '
        'release', () async {
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: false);
      final entries = await changelog.pending();
      expect(entries.map((e) => e.version), ['1.2.1']);
      expect(await _storedVersion(), '1.2.1');
    });

    test('shows nothing when the version has not changed', () async {
      SharedPreferences.setMockInitialValues(
        {'changelog_last_seen': '1.2.1'},
      );
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: false);
      expect(await changelog.pending(), isEmpty);
    });

    test('shows nothing when an older version was installed over a newer one',
        () async {
      SharedPreferences.setMockInitialValues(
        {'changelog_last_seen': '1.3.0'},
      );
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: false);
      expect(await changelog.pending(), isEmpty);
      expect(await _storedVersion(), '1.2.1');
    });

    test('records the version right away, so it is shown once', () async {
      // Waiting for the card to be dismissed would bring it back at every
      // start until someone closes it.
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: false);
      expect(await changelog.pending(), isNotEmpty);

      final next = Changelog(currentVersion: '1.2.1', freshInstall: false);
      expect(await next.pending(), isEmpty);
    });

    test('decides once per start', () async {
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: false);
      final first = await changelog.pending();
      // The card and the review prompt both wait on this; a second decision
      // would find the version already recorded and come back empty.
      expect(await changelog.pending(), same(first));
    });
  });

  group('the notes shipped with the app', () {
    test('cover the version being released', () async {
      // A release without its own notes shows nothing at all, which is easy
      // to miss until it is too late.
      final changelog =
          Changelog(currentVersion: '1.2.1', freshInstall: false);
      final entries = await changelog.pending();
      expect(entries, hasLength(1));
      expect(entries.single.version, '1.2.1');
      expect(entries.single.points, isNotEmpty);
    });

    test('hold the whole history, newest first', () async {
      // The full list is read from the app itself, not fetched from GitHub.
      final entries = await Changelog().load();
      expect(entries.length, greaterThan(1));
      expect(entries.first.version, '1.2.1');
      expect(entries.last.version, '1.0.0');
      for (var i = 1; i < entries.length; i++) {
        expect(
          compareVersions(entries[i - 1].version, entries[i].version),
          greaterThan(0),
          reason: '${entries[i - 1].version} vor ${entries[i].version}',
        );
      }
    });

    test('give every version a date and at least one line', () async {
      for (final entry in await Changelog().load()) {
        expect(entry.points, isNotEmpty, reason: entry.version);
        expect(DateTime.tryParse(entry.date ?? ''), isNotNull,
            reason: entry.version);
      }
    });

    test('keep the headings the release notes were written under', () async {
      // "Neue Funktionen", "Fehlerbehebungen" and so on: the card drops them,
      // the full list keeps them.
      final entries = await Changelog().load();
      for (final entry in entries) {
        expect(entry.sections, isNotEmpty, reason: entry.version);
        for (final section in entry.sections) {
          expect(section.title, isNotEmpty, reason: entry.version);
          expect(section.items, isNotEmpty, reason: section.title);
        }
      }
      final headings = {
        for (final entry in entries)
          for (final section in entry.sections) section.title,
      };
      expect(headings, contains('Neue Funktionen'));
      expect(headings, contains('Fehlerbehebungen'));
    });

    test('flatten to plain lines for the card', () async {
      final entry = (await Changelog().load()).first;
      expect(
        entry.points,
        containsAll(entry.sections.first.items),
      );
      expect(entry.points.length,
          entry.sections.fold<int>(0, (n, s) => n + s.items.length));
    });
  });
}
