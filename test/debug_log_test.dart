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
import 'dart:isolate';

import 'package:dr/debug_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dr_debug_log_test');
    file = File('${dir.path}/debug_log.jsonl');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('ring buffer', () {
    test('keeps only the newest entries', () {
      final log = DebugLog(capacity: 3);
      for (var i = 0; i < 5; i++) {
        log.add(LogCategory.start, 'Eintrag $i');
      }
      expect(
        log.entries.map((e) => e.message),
        ['Eintrag 2', 'Eintrag 3', 'Eintrag 4'],
      );
    });

    test('without a file readAll gives what is in memory', () async {
      final log = DebugLog()..add(LogCategory.login, 'nur im Speicher');
      expect((await log.readAll()).single.message, 'nur im Speicher');
    });
  });

  group('file', () {
    test('holds every entry, category, data and isolate included', () async {
      final log = DebugLog()..attachFile(file, isolate: 'Hintergrund');
      log.add(LogCategory.session, 'eins', data: 'Details');
      log.add(LogCategory.account, 'zwei');

      // A fresh log reads the same file: nothing depends on memory.
      final other = DebugLog()..attachFile(file);
      final read = await other.readAll();
      expect(read.map((e) => e.message), ['eins', 'zwei']);
      expect(read.first.category, LogCategory.session);
      expect(read.first.data, 'Details');
      expect(read.first.isolate, 'Hintergrund');
      expect(read.last.data, isNull);
    });

    test('takes along what was logged before it was attached', () async {
      final log = DebugLog()..add(LogCategory.start, 'vor der Datei');
      log.attachFile(file);
      log.add(LogCategory.start, 'danach');
      final read = await (DebugLog()..attachFile(file)).readAll();
      expect(read.map((e) => e.message), ['vor der Datei', 'danach']);
    });

    test('moves aside past the limit and keeps at most two files', () async {
      final log = DebugLog(maxFileBytes: 1000)..attachFile(file);
      for (var i = 0; i < 100; i++) {
        log.add(LogCategory.background, 'Eintrag $i');
      }
      final previous = File('${file.path}.1');
      expect(previous.existsSync(), isTrue);
      // Checked before each write, so a file ends at most one line past it.
      expect(file.lengthSync(), lessThan(1100));
      expect(previous.lengthSync(), lessThan(1100));

      final read = await log.readAll();
      expect(read, isNotEmpty);
      expect(read.last.message, 'Eintrag 99');
      // The oldest are gone, the rest in order.
      expect(read.first.message, isNot('Eintrag 0'));
      final numbers = [
        for (final e in read) int.parse(e.message.split(' ').last),
      ];
      expect(numbers, List.generate(numbers.length, (i) => numbers.first + i));
    });

    test('skips a line cut short by a crash', () async {
      final log = DebugLog()..attachFile(file);
      log.add(LogCategory.start, 'ganz');
      file.writeAsStringSync('{"t":"2026-09-2', mode: FileMode.append);
      log.add(LogCategory.start, 'auch ganz');
      // The broken line swallowed the start of the next one; everything else
      // is still read.
      final read = await log.readAll();
      expect(read.map((e) => e.message), ['ganz']);
    });

    test('clear empties memory and both files', () async {
      final log = DebugLog(maxFileBytes: 200)..attachFile(file);
      for (var i = 0; i < 20; i++) {
        log.add(LogCategory.start, 'Eintrag $i');
      }
      await log.clear();
      expect(log.entries, isEmpty);
      expect(file.existsSync(), isFalse);
      expect(File('${file.path}.1').existsSync(), isFalse);
      expect(await log.readAll(), isEmpty);
    });

    test('takes the entries of another isolate', () async {
      final log = DebugLog()..attachFile(file);
      log.add(LogCategory.start, 'App');
      final path = file.path;
      await Isolate.run(() {
        DebugLog()
          ..attachFile(File(path), isolate: 'Hintergrund')
          ..add(LogCategory.background, 'Lauf: 2 Konten');
      });
      log.add(LogCategory.start, 'App wieder');

      final read = await log.readAll();
      expect(read.map((e) => e.message), [
        'App',
        'Lauf: 2 Konten',
        'App wieder',
      ]);
      expect(read.map((e) => e.isolate), [null, 'Hintergrund', null]);
    });
  });

  group('export', () {
    test('newest first, isolate and data marked', () {
      final text = DebugLog.export([
        DebugLogEntry(
          timestamp: DateTime(2026, 9, 24, 10),
          category: LogCategory.start,
          message: 'zuerst',
        ),
        DebugLogEntry(
          timestamp: DateTime(2026, 9, 24, 11),
          category: LogCategory.background,
          message: 'danach',
          data: 'Details',
          isolate: 'Hintergrund',
        ),
      ]);
      expect(
        text,
        '[2026-09-24T11:00:00.000] [Hintergrund] [Abruf] danach\n'
        '--- data ---\nDetails\n--- end ---\n'
        '[2026-09-24T10:00:00.000] [Start] zuerst\n',
      );
    });
  });

  group('masking', () {
    test('accountTag names neither user nor school', () {
      final tag =
          accountTag('max.muster', 'https://vinzentinum.digitalesregister.it');
      expect(tag, startsWith('Konto '));
      expect(tag, isNot(contains('max')));
      expect(tag, isNot(contains('vinzentinum')));
    });

    test('accountTag is the same however the address is written', () {
      final tag = accountTag('max', 'https://schule.digitalesregister.it/');
      expect(accountTag('max', 'schule.digitalesregister.it'), tag);
      expect(accountTag('max', 'https://Schule.digitalesregister.it/v2/'), tag);
    });

    test('accountTag tells accounts apart', () {
      final tag = accountTag('max', 'https://schule.digitalesregister.it');
      expect(accountTag('moritz', 'https://schule.digitalesregister.it'),
          isNot(tag));
      expect(
          accountTag('max', 'https://andere.digitalesregister.it'), isNot(tag));
    });

    test('shorten says how much it left out', () {
      expect(shorten('kurz', 10), 'kurz');
      expect(shorten('0123456789abc', 10), '0123456789… (3 Zeichen gekürzt)');
    });

    test('debugLogError keeps the stack trace, shortened', () {
      final log = DebugLog.instance;
      final before = log.entries.length;
      debugLogError('Test', StateError('kaputt'), StackTrace.current);
      final entry = log.entries.last;
      expect(log.entries.length, before + 1);
      expect(entry.category, LogCategory.error);
      expect(entry.message, 'Test: StateError: Bad state: kaputt');
      expect(entry.data, isNotEmpty);
    });
  });
}
