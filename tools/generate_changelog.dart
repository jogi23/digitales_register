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

// Writes CHANGELOG.md from the notes the app itself shows.
//
// `assets/changelog.json` is the single source: what a release changed is
// written once, for the reader in the app, and the repository's changelog is
// derived from it. Run after editing that file:
//
//     dart tools/generate_changelog.dart
//
// `--check` writes nothing and exits non-zero when the file on disk differs
// from what the notes would produce — for a release check or CI.

import 'dart:convert';
import 'dart:io';

/// The language the repository's changelog is written in.
const language = 'de';

const jsonPath = 'assets/changelog.json';
const markdownPath = 'CHANGELOG.md';

void main(List<String> args) {
  final check = args.contains('--check');

  final source = File(jsonPath);
  if (!source.existsSync()) {
    stderr.writeln('$jsonPath not found — run from the project root.');
    exit(2);
  }

  final markdown = render(
    jsonDecode(source.readAsStringSync()) as Map<String, dynamic>,
  );

  final target = File(markdownPath);
  if (check) {
    final current = target.existsSync() ? target.readAsStringSync() : null;
    if (current == markdown) {
      stdout.writeln('$markdownPath is up to date.');
      return;
    }
    stderr.writeln(
      '$markdownPath is out of date — run `dart tools/generate_changelog.dart`.',
    );
    exit(1);
  }

  target.writeAsStringSync(markdown);
  stdout.writeln('Wrote $markdownPath.');
}

/// The whole file: newest release first, headings as written in the notes.
String render(Map<String, dynamic> entries) {
  final versions = entries.keys.toList()..sort((a, b) => compareVersions(b, a));

  const header = '# Änderungen\n\n'
      'Erzeugt aus `$jsonPath` mit `dart tools/generate_changelog.dart` — '
      'Änderungen bitte dort eintragen, nicht hier.';
  final blocks = <String>[header];

  for (final version in versions) {
    final entry = entries[version] as Map<String, dynamic>;
    final date = entry['date'] as String?;
    final block = StringBuffer('## $version${date == null ? '' : ' — $date'}');

    final sections = (entry['points'] as Map<String, dynamic>)[language];
    if (sections == null) {
      block.write('\n\n_Keine Notizen in „$language“._');
    } else {
      for (final section in (sections as List).cast<Map<String, dynamic>>()) {
        block.write('\n\n### ${section['title']}\n');
        for (final item in (section['items'] as List).cast<String>()) {
          block.write('\n- $item');
        }
      }
    }
    blocks.add(block.toString());
  }

  return '${blocks.join('\n\n')}\n';
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
