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

import 'dart:async';

import 'package:dr/debug_log.dart';
import 'package:dr/providers/network_protocol_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/diagnostics_export.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the diagnostics switch (#325) start and stop the recording of the
/// debug log and the network protocol from now on. Turning it off throws
/// away what was recorded; a debug build keeps recording either way.
///
/// Switching on also starts from an empty log: a background run that was
/// still going when the switch went off may have written to the file since.
///
/// The start sets [DebugLog.enabled] from the stored flag itself, before the
/// settings are loaded.
void keepDiagnosticsInSync(
  ProviderContainer container, {
  DebugLog? log,
  bool? debugBuild,
  DiagnosticsExport? exporter,
}) {
  final target = log ?? DebugLog.instance;
  final isDebugBuild = debugBuild ?? kDebugMode;
  container.listen<bool>(
    settingsProvider.select((s) => s.diagnosticsEnabled),
    (_, on) {
      target.enabled = isDebugBuild || on;
      if (isDebugBuild) return;
      unawaited(target.clear());
      if (on) return;
      container.read(networkProtocolProvider.notifier).reset();
      final DiagnosticsExport exports =
          exporter ?? container.read(diagnosticsExportProvider);
      unawaited(exports.deleteExports());
    },
  );
}
