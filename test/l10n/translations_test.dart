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
import 'dart:io';

import 'package:dr/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// The texts of one language, headings and metadata left out.
Map<String, String> _texts(String language) {
  final raw = File('lib/l10n/app_$language.arb').readAsStringSync();
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return {
    for (final entry in decoded.entries)
      if (!entry.key.startsWith('@')) entry.key: entry.value as String,
  };
}

/// The names between braces, which every language has to keep.
Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  final german = _texts('de');

  test('German is the template every language is measured against', () {
    expect(supportedLanguages.first, 'de');
    expect(german, isNotEmpty);
  });

  for (final language in supportedLanguages.where((l) => l != 'de')) {
    group('$language', () {
      final texts = _texts(language);

      test('knows every text', () {
        // A missing key falls back to German, which reads as a half
        // translated app rather than as an error.
        expect(texts.keys.toSet(), german.keys.toSet());
      });

      test('carries no text the template does not have', () {
        expect(texts.keys.toSet().difference(german.keys.toSet()), isEmpty);
      });

      test('keeps the placeholders of every text', () {
        // A dropped {week} would throw at runtime, and a renamed one would
        // not compile.
        for (final entry in german.entries) {
          final translated = texts[entry.key];
          if (translated == null) continue;
          expect(
            _placeholders(translated),
            _placeholders(entry.value),
            reason: entry.key,
          );
        }
      });

      test('leaves nothing empty', () {
        for (final entry in texts.entries) {
          expect(entry.value.trim(), isNotEmpty, reason: entry.key);
        }
      });

      test('is not simply the German text', () {
        // Not every text has to differ — "Demo" and "FAQ" do not — but a
        // wholesale copy would mean the language was never translated.
        final same = texts.entries
            .where((e) => e.value == german[e.key])
            .length;
        expect(same / texts.length, lessThan(0.2));
      });
    });
  }
}
