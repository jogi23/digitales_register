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

import 'package:built_collection/built_collection.dart';
import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/services/message_export.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

String _delta(List<Map<String, Object?>> ops) => jsonEncode({'ops': ops});

Message _message({
  String subject = 'Ausflug',
  required String text,
  List<String> attachments = const [],
}) =>
    Message(
      (b) => b
        ..id = 1
        ..subject = subject
        ..text = text
        ..fromName = 'Anna Berger'
        ..recipientString = '1A Erziehungsberechtigte'
        ..timeSent = UtcDateTime.parse('2026-09-14 08:05:00')
        ..attachments = ListBuilder<MessageAttachmentFile>([
          for (final (i, name) in attachments.indexed)
            MessageAttachmentFile(
              (b) => b
                ..id = i
                ..messageId = 1
                ..originalName = name
                ..file = 'file$i'
                ..downloading = false
                ..fileAvailable = false,
            ),
        ]),
    );

void main() {
  group('parseDelta', () {
    test('splits the text at line breaks', () {
      final lines = parseDelta(_delta([
        {'insert': 'Erste\nZweite\n'},
      ]));
      expect(lines.map((l) => l.plainText), ['Erste', 'Zweite']);
    });

    test('keeps inline formatting on its text', () {
      final spans = parseDelta(_delta([
        {'insert': 'fett', 'attributes': {'bold': true}},
        {'insert': ' und '},
        {'insert': 'kursiv', 'attributes': {'italic': true}},
        {'insert': '\n'},
      ])).single.spans;
      expect(spans.map((s) => (s.text, s.bold, s.italic)), [
        ('fett', true, false),
        (' und ', false, false),
        ('kursiv', false, true),
      ]);
    });

    test('reads block formatting off the line break', () {
      final lines = parseDelta(_delta([
        {'insert': 'Titel'},
        {'insert': '\n', 'attributes': {'header': 2}},
        {'insert': 'Punkt'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Schritt'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Erledigt'},
        {'insert': '\n', 'attributes': {'list': 'checked'}},
      ]));
      expect(lines.map((l) => (l.header, l.list)), [
        (2, null),
        (null, DeltaList.bullet),
        (null, DeltaList.ordered),
        (null, DeltaList.bullet),
      ]);
    });

    test('leaves out embeds', () {
      final lines = parseDelta(_delta([
        {'insert': 'Bild:'},
        {
          'insert': {'image': 'bild.png'},
        },
        {'insert': '\n'},
      ]));
      expect(lines.single.plainText, 'Bild:');
    });

    test('takes a text that is no delta as plain text', () {
      expect(
        parseDelta('Hallo\nWelt').map((l) => l.plainText),
        ['Hallo', 'Welt'],
      );
    });
  });

  group('MessageExport', () {
    final export = MessageExport(lookupL(const Locale('de')));
    final formatted = _message(
      text: _delta([
        {'insert': 'Das ist '},
        {'insert': 'fett ', 'attributes': {'bold': true}},
        {'insert': 'mit '},
        {'insert': 'Seite', 'attributes': {'link': 'https://example.org'}},
        {'insert': ' und a*b\nEins'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Zwei'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Punkt'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ]),
      attachments: ['Plan.pdf', 'Karte.png'],
    );

    group('as text', () {
      late final text = export.text([formatted]);

      test('opens with subject, date, sender and recipients', () {
        expect(
          text,
          startsWith('Ausflug\n'
              'Gesendet: 14.9.26 8:05\n'
              'Von: Anna Berger\n'
              'An: 1A Erziehungsberechtigte\n\n'),
        );
      });

      test('numbers ordered lists and marks bullets', () {
        expect(text, contains('\n1. Eins\n2. Zwei\n• Punkt\n'));
      });

      test('names the attachments', () {
        expect(text, contains('Anhänge: Plan.pdf, Karte.png'));
      });

      test('separates messages', () {
        expect(
          export.text([formatted, _message(subject: 'Zweite', text: 'x')]),
          contains('\n\n${'-' * 40}\n\nZweite\n'),
        );
      });
    });

    group('as Markdown', () {
      late final markdown = export.markdown([formatted]);

      test('makes the subject a heading and the details bold labels', () {
        expect(
          markdown,
          startsWith('## Ausflug\n\n'
              '**Gesendet:** 14.9.26 8:05  \n'
              '**Von:** Anna Berger  \n'
              '**An:** 1A Erziehungsberechtigte\n\n'),
        );
      });

      test('keeps the markers next to the text they format', () {
        expect(markdown, contains('Das ist **fett** mit'));
      });

      test('writes links and escapes Markdown characters', () {
        expect(
          markdown,
          contains('[Seite](https://example.org) und a\\*b'),
        );
      });

      test('writes list items on consecutive lines', () {
        expect(markdown, contains('\n\n1. Eins\n2. Zwei\n- Punkt'));
      });

      test('names the attachments', () {
        expect(markdown, endsWith('**Anhänge:** Plan.pdf, Karte.png\n'));
      });
    });

    group('as PDF', () {
      test('is a PDF document', () async {
        final bytes = await export.pdf([formatted]);
        expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      });

      test('carries a long text over several pages', () async {
        final long = _message(
          text: _delta([
            {'insert': '${List.filled(400, 'Zeile mit etwas Text').join('\n')}\n'},
          ]),
        );
        expect(await export.pdf([long]), isNotEmpty);
      });

      test('does not fail on characters the built-in font lacks', () async {
        final emoji = _message(text: _delta([
          {'insert': 'Schönen Tag 😀\n'},
        ]));
        expect(await export.pdf([emoji]), isNotEmpty);
      });
    });

    group('file name', () {
      final now = DateTime(2026, 9, 15);

      test('is the subject of a single message, without path characters',
          () {
        expect(
          export.fileName(
            [_message(subject: 'Ausflug: 1/2', text: 'x')],
            MessageExportFormat.pdf,
            now,
          ),
          'Ausflug_ 1_2.pdf',
        );
      });

      test('is the page title and the date for several', () {
        expect(
          export.fileName(
            [formatted, formatted],
            MessageExportFormat.markdown,
            now,
          ),
          'Mitteilungen 2026-09-15.md',
        );
      });
    });
  });
}
