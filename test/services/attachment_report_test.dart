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

import 'package:dr/debug_log.dart';
import 'package:dr/providers/dashboard_parser.dart';
import 'package:dr/services/attachment_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _audio = {
  'id': 9001,
  'type': 'file',
  'typeName': 'M4A',
  'originalName': 'Aufnahme Max Muster.m4a',
  'title': 'Lesen üben',
  'link': null,
  'text': null,
  'file': 'f_1_abc.m4a',
  'isDownloadable': true,
};

const _link = {
  'id': 9002,
  'type': 'link',
  'typeName': 'Link',
  'originalName': null,
  'link': 'https://youtube.com/watch?v=geheim',
  'isDownloadable': true,
};

void main() {
  group('attachmentShape', () {
    test('tells the kind apart, never names, links or texts', () {
      final shape = attachmentShape(_audio);
      expect(shape, {
        'type': 'file',
        'typeName': 'M4A',
        'extension': 'm4a',
        'isDownloadable': 'true',
        'filled': 'title, file',
        'fields':
            'id, type, typeName, originalName, title, link, text, file, isDownloadable',
      });
      final all = '${attachmentShape(_audio)}${attachmentShape(_link)}';
      expect(all, isNot(contains('Max Muster')));
      expect(all, isNot(contains('Lesen')));
      expect(all, isNot(contains('geheim')));
      expect(all, isNot(contains('f_1_abc')));
      expect(attachmentShape(_link)['filled'], 'link');
      expect(attachmentShape(_link)['extension'], '-');
    });

    test('keeps a name after the last dot out', () {
      final shape = attachmentShape(
        {'type': 'file', 'originalName': 'Aufnahme.Max Muster'},
      );
      expect(shape['extension'], '?');
    });
  });

  group('isKnownAttachment', () {
    test('files the app opens every day are known', () {
      for (final typeName in ['PDF', 'JPG', 'JPEG', 'PNG', 'DOCX']) {
        expect(
          isKnownAttachment({'type': 'file', 'typeName': typeName}),
          isTrue,
          reason: typeName,
        );
      }
    });

    test('audio, links and anything new are not', () {
      expect(isKnownAttachment(_audio), isFalse);
      expect(isKnownAttachment(_link), isFalse);
      expect(isKnownAttachment({'type': 'video', 'typeName': 'MP4'}), isFalse);
    });
  });

  group('noteAttachments', () {
    late List<(String, Map<String, String>)> sent;
    late AttachmentReporter sut;

    List<DebugLogEntry> logged() => DebugLog.instance.entries
        .where((e) => e.category == LogCategory.attachments)
        .toList();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sent = [];
      sut = AttachmentReporter(
        enabled: () => true,
        send: (where, shape) async => sent.add((where, shape)),
      );
      attachmentReporter = sut;
    });

    test('logs every attachment once per run', () async {
      final before = logged().length;
      await sut.note('Kalender', [
        {
          'id': 9101,
          'type': 'file',
          'typeName': 'PDF',
          'originalName': 'a.pdf'
        },
      ]);
      await sut.note('Kalender', [
        {
          'id': 9101,
          'type': 'file',
          'typeName': 'PDF',
          'originalName': 'a.pdf'
        },
      ]);
      final entries = logged().sublist(before);
      expect(entries, hasLength(1));
      expect(
        entries.single.message,
        'Kalender 9101: type=file, typeName=PDF, Endung=pdf, '
        'isDownloadable=null, belegt=[]',
      );
    });

    test('reports an unknown kind once per install, known ones never',
        () async {
      await sut.note('Merkheft', [
        _audio,
        {'id': 1, 'type': 'file', 'typeName': 'PDF'},
      ]);
      await sut.note('Merkheft', [
        {..._audio, 'id': 9003},
      ]);
      await AttachmentReporter(
        enabled: () => true,
        send: (where, shape) async => sent.add((where, shape)),
      ).note('Merkheft', [_audio]);

      expect(sent, hasLength(1));
      expect(sent.single.$1, 'Merkheft');
      expect(sent.single.$2['typeName'], 'M4A');
    });

    test('the same kind somewhere else is a report of its own', () async {
      await sut.note('Merkheft', [_link]);
      await sut.note('Kalender Unterrichtsinhalt', [_link]);
      expect(sent.map((s) => s.$1), ['Merkheft', 'Kalender Unterrichtsinhalt']);
    });

    test('without Sentry nothing is marked as sent', () async {
      await AttachmentReporter(
        enabled: () => false,
        send: (where, shape) async => sent.add((where, shape)),
      ).note('Merkheft', [_audio]);
      expect(sent, isEmpty);

      await sut.note('Merkheft', [
        {..._audio, 'id': 9004}
      ]);
      expect(sent, hasLength(1));
    });

    test('copes with null and garbage', () async {
      await sut.note('Mitteilung', null);
      await sut.note('Mitteilung', ['kein Map', 3]);
      expect(sent, isEmpty);
    });

    test('the Merkheft parser hands its attachments over', () async {
      parseHomework({
        'id': 1,
        'title': 'Italienisch',
        'subtitle': 'Lessico',
        'type': 'gradeGroup',
        'gradeGroupSubmissions': [
          {'id': 9301, 'type': 'file', 'typeName': 'MP3'},
        ],
      });
      await pumpEventQueue();
      expect(logged().last.message, startsWith('Merkheft 9301:'));
      expect(sent.single.$2['typeName'], 'MP3');
    });
  });
}
