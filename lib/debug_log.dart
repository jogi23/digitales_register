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

import 'package:flutter/foundation.dart';

class DebugLogEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final String? data;

  const DebugLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.data,
  });
}

/// App-wide in-memory debug log. All writes are no-ops in release builds.
///
/// Use the top-level [debugLog] function to add entries from anywhere.
class DebugLog {
  DebugLog._();
  static final DebugLog instance = DebugLog._();

  final List<DebugLogEntry> _entries = [];

  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  void add(String category, String message, {String? data}) {
    if (!kDebugMode) return;
    _entries.add(DebugLogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      data: data,
    ));
  }

  void clear() => _entries.clear();

  String export() {
    final buf = StringBuffer();
    for (final e in _entries.reversed) {
      buf.writeln('[${e.timestamp.toIso8601String()}] [${e.category}] ${e.message}');
      if (e.data != null) {
        buf.writeln('--- data ---');
        buf.writeln(e.data);
        buf.writeln('--- end ---');
      }
    }
    return buf.toString();
  }
}

void debugLog(String category, String message, {String? data}) =>
    DebugLog.instance.add(category, message, data: data);
