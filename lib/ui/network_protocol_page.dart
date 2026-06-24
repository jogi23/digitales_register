// Copyright (C) 2021 Michael Debertol
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
import 'package:dr/container/network_protocol_container.dart';
import 'package:dr/main.dart';
import 'package:dr/providers/network_protocol_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class NetworkProtocolPage extends ConsumerWidget {
  const NetworkProtocolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Netzwerkprotokoll"),
        actions: <Widget>[
          // Debug-only: lets developers capture all recorded responses to a
          // single JSON file for use as test fixtures / demo data. Tree-shaken
          // out of release and profile builds.
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Alle Antworten exportieren",
              onPressed: () =>
                  _exportProtocol(ref.read(networkProtocolProvider)),
            ),
        ],
      ),
      body: const NetworkProtocolContainer(),
    );
  }
}

/// Serializes every recorded [NetworkProtocolItem] into one JSON file and shows
/// where it was written. Each item's `parameters`/`response` are decoded back
/// into nested JSON when possible, so the file is directly usable as fixtures.
Future<void> _exportProtocol(List<NetworkProtocolItem> items) async {
  if (items.isEmpty) {
    showSnackBar("Nichts zu exportieren");
    return;
  }

  final export = [
    for (final item in items)
      {
        "address": item.address,
        "parameters": _decodeMaybeJson(item.parameters),
        "response": _decodeMaybeJson(item.response),
      },
  ];
  final jsonString = const JsonEncoder.withIndent("  ").convert(export);

  try {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(":", "-")
        .replaceAll(".", "-");
    final file = File("${dir.path}/dr_network_capture_$timestamp.json");
    await file.writeAsString(jsonString);

    final navContext = navigatorKey?.currentContext;
    if (navContext == null) return;
    await showDialog<void>(
      // ignore: use_build_context_synchronously
      context: navContext,
      builder: (context) => AlertDialog(
        title: const Text("Export abgeschlossen"),
        content: SelectableText(
          "${items.length} Antworten gespeichert unter:\n\n${file.path}",
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: file.path));
              showSnackBar("Pfad in die Zwischenablage kopiert");
            },
            child: const Text("Pfad kopieren"),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              showSnackBar("JSON in die Zwischenablage kopiert");
            },
            child: const Text("JSON kopieren"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  } catch (e) {
    showSnackBar("Export fehlgeschlagen: $e");
  }
}

/// Tries to decode [raw] as JSON; returns the decoded value or the raw string
/// if it is not valid JSON (e.g. an HTML certificate response).
dynamic _decodeMaybeJson(String raw) {
  try {
    return json.decode(raw);
  } catch (_) {
    return raw;
  }
}
