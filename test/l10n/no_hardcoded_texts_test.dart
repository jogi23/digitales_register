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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ein Umlaut oder ein typisch deutsches Wort in einer Zeichenkette.
///
/// Grob, aber wirksam: Es geht nicht darum, jede denkbare deutsche
/// Zeichenkette zu finden, sondern darum, dass ein neuer Dialogtext nicht
/// unbemerkt an den Übersetzungen vorbeigeht.
final _deutsch = RegExp(r'[äöüßÄÖÜ]');
final _woerter = RegExp(
  r'\b(Die|Der|Das|Bitte|Datei|Fehler|wurde|nicht|kann|bereits)\b',
);

/// Zeichenketten in doppelten Anführungszeichen, ohne Escapes.
final _text = RegExp(r'"([^"\\]{6,})"');

/// Was keine Benutzertexte sind und deshalb nicht stört.
bool _istAusnahme(String zeile) {
  final t = zeile.trimLeft();
  return t.startsWith('//') ||
      t.startsWith('///') ||
      t.startsWith('import ') ||
      // Protokollausgaben gehen an Entwickler, nicht an Benutzer.
      t.startsWith('log(') ||
      t.contains('debugPrint(');
}

List<String> _fundstellen(Directory ordner) {
  final treffer = <String>[];
  for (final datei in ordner.listSync(recursive: true).whereType<File>()) {
    if (!datei.path.endsWith('.dart')) continue;
    final zeilen = datei.readAsLinesSync();
    for (var i = 0; i < zeilen.length; i++) {
      final zeile = zeilen[i];
      if (_istAusnahme(zeile)) continue;
      for (final m in _text.allMatches(zeile)) {
        final text = m.group(1)!;
        if (_deutsch.hasMatch(text) || _woerter.hasMatch(text)) {
          treffer.add('${datei.path}:${i + 1}  $text');
        }
      }
    }
  }
  return treffer;
}

void main() {
  test('the middleware carries no German text of its own', () {
    // Die Schicht hat keinen BuildContext zur Hand und wurde bei der
    // Lokalisierung deshalb übersehen; für den Fall gibt es trGlobal.
    expect(
      _fundstellen(Directory('lib/middleware')),
      isEmpty,
      reason: 'Diese Texte gehören in die ARB-Dateien',
    );
  });

  test('the services carry no German text of their own', () {
    expect(_fundstellen(Directory('lib/services')), isEmpty);
  });
}
