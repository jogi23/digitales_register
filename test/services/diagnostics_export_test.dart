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

import 'package:dr/app_state.dart';
import 'package:dr/debug_log.dart';
import 'package:dr/services/diagnostics_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

NetworkProtocolItem _item({String response = '{"a":1}'}) =>
    NetworkProtocolItem((b) => b
      ..address = 'https://school.example/v2/api/x'
      ..response = response
      ..parameters = '{"k":"v"}'
      ..timestamp = DateTime(2026, 10, 8, 12));

/// The file's own name; `XFile.name` keeps the directory on Windows.
String _name(XFile f) => f.path.split(RegExp(r'[\/]')).last;

void main() {
  late Directory dir;
  late DebugLog log;
  late List<ShareParams> shared;
  late DiagnosticsExport export;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('dr_diagnostics_export');
    log = DebugLog(enabled: true);
    shared = [];
    export = DiagnosticsExport(
      log: log,
      tempDir: () async => dir,
      share: (params) async => shared.add(params),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  List<XFile> files() => shared.single.files!;

  test('returns empty and shares nothing when both sources are empty',
      () async {
    expect(await export.share(const []), DiagnosticsExportResult.empty);
    expect(shared, isEmpty);
  });

  test('shares both files when both have data', () async {
    log.add(LogCategory.start, 'App-Start');
    expect(await export.share([_item()]), DiagnosticsExportResult.shared);

    final byName = {for (final f in files()) _name(f): f};
    expect(byName.keys, hasLength(2));
    final debugLog =
        byName.entries.singleWhere((e) => e.key.startsWith('dr_debug_log_'));
    final network =
        byName.entries.singleWhere((e) => e.key.startsWith('dr_network_'));
    expect(debugLog.key, endsWith('.txt'));
    expect(debugLog.value.mimeType, 'text/plain');
    expect(await debugLog.value.readAsString(), contains('App-Start'));
    expect(network.key, endsWith('.json'));
    expect(network.value.mimeType, 'application/json');
    expect(shared.single.subject, 'DigiReg Diagnose-Protokoll');
  });

  test('shares only the debug log when the protocol is empty', () async {
    log.add(LogCategory.start, 'App-Start');
    await export.share(const []);
    expect(files().map(_name), [startsWith('dr_debug_log_')]);
  });

  test('shares only the network file when the log is empty', () async {
    await export.share([_item()]);
    expect(files().map(_name), [startsWith('dr_network_')]);
  });

  test('the network file decodes json responses and keeps the rest', () async {
    await export.share([_item(), _item(response: '<html>no json</html>')]);
    final decoded =
        jsonDecode(await files().single.readAsString()) as List<dynamic>;
    expect(decoded, hasLength(2));
    expect((decoded[0] as Map)['response'], {'a': 1});
    expect((decoded[0] as Map)['parameters'], {'k': 'v'});
    expect((decoded[1] as Map)['response'], '<html>no json</html>');
    expect((decoded[0] as Map)['address'], 'https://school.example/v2/api/x');
  });
}
