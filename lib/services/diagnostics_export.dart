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
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum DiagnosticsExportResult { shared, empty }

/// Hands everything the diagnostic log recorded (#325) to the share sheet:
/// the debug log as text and the network protocol as JSON.
class DiagnosticsExport {
  DiagnosticsExport({
    DebugLog? log,
    Future<Directory> Function()? tempDir,
    Future<void> Function(ShareParams)? share,
  })  : _log = log ?? DebugLog.instance,
        _tempDir = tempDir ?? getTemporaryDirectory,
        _share = share ?? ((params) => SharePlus.instance.share(params));

  final DebugLog _log;
  final Future<Directory> Function() _tempDir;
  final Future<void> Function(ShareParams) _share;

  /// Shares the log and the [items] of the network protocol, leaving out
  /// whichever of the two has nothing in it.
  Future<DiagnosticsExportResult> share(List<NetworkProtocolItem> items) async {
    final entries = await _log.readAll();
    if (entries.isEmpty && items.isEmpty) return DiagnosticsExportResult.empty;

    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final dir = await _tempDir();
    final files = <XFile>[];
    if (entries.isNotEmpty) {
      final file = File('${dir.path}/dr_debug_log_$stamp.txt');
      await file.writeAsString(DebugLog.export(entries));
      files.add(XFile(file.path, mimeType: 'text/plain'));
    }
    if (items.isNotEmpty) {
      final file = File('${dir.path}/dr_network_$stamp.json');
      await file.writeAsString(networkProtocolJson(items));
      files.add(XFile(file.path, mimeType: 'application/json'));
    }
    await _share(
      ShareParams(files: files, subject: 'DigiReg Diagnose-Protokoll'),
    );
    return DiagnosticsExportResult.shared;
  }
}

/// Every recorded item as one JSON document. Parameters and response are
/// decoded back into JSON where they were JSON, so the file doubles as test
/// fixtures.
String networkProtocolJson(List<NetworkProtocolItem> items) =>
    const JsonEncoder.withIndent('  ').convert([
      for (final item in items)
        {
          'timestamp': item.timestamp.toIso8601String(),
          'address': item.address,
          'parameters': _decodeMaybeJson(item.parameters),
          'response': _decodeMaybeJson(item.response),
          if (item.error != null) 'error': item.error,
        },
    ]);

/// The decoded JSON in [raw], or [raw] itself when it is not JSON, such as
/// an HTML page.
Object? _decodeMaybeJson(String raw) {
  try {
    return json.decode(raw);
  } on FormatException {
    return raw;
  }
}
