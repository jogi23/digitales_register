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

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// What happened in the app, for tests and for finding faults — in debug
// builds only. The log gets shared, so nothing goes in that must not leave
// the device: no passwords, cookies, tokens or codes, no message texts, and
// accounts only by [accountTag]. Requests and answers belong in the network
// protocol, not here.

/// The categories entries are filed under; the log page filters by them.
abstract final class LogCategory {
  static const start = 'Start';
  static const login = 'Anmeldung';
  static const session = 'Sitzung';
  static const account = 'Konto';
  static const background = 'Abruf';
  static const systemNotification = 'Systembenachrichtigung';
  static const messages = 'Mitteilungen';
  static const notifications = 'Benachrichtigungen';
  static const absences = 'Absenzen';
  static const certificate = 'Zeugnis';
  static const error = 'Fehler';

  static const values = [
    start,
    login,
    session,
    account,
    background,
    systemNotification,
    messages,
    notifications,
    absences,
    certificate,
    error,
  ];
}

class DebugLogEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final String? data;

  /// Which isolate wrote the entry; null for the app's own.
  final String? isolate;

  const DebugLogEntry({
    required this.timestamp,
    required this.category,
    required this.message,
    this.data,
    this.isolate,
  });

  Map<String, Object?> toJson() => {
        't': timestamp.toIso8601String(),
        'c': category,
        'm': message,
        if (data != null) 'd': data,
        if (isolate != null) 'i': isolate,
      };

  static DebugLogEntry? tryParse(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return DebugLogEntry(
        timestamp: DateTime.parse(json['t'] as String),
        category: json['c'] as String,
        message: json['m'] as String,
        data: json['d'] as String?,
        isolate: json['i'] as String?,
      );
    } on Object {
      // A line cut short by a crash is the last one; the rest still counts.
      return null;
    }
  }
}

/// App-wide debug log. All writes are no-ops in release builds.
///
/// Keeps the latest [capacity] entries in memory and, once [attachFile] was
/// called, appends every entry to a file as well. The file outlives a crash
/// or a restart, and it is where the background isolate's entries meet the
/// app's: each isolate has a log of its own in memory, but they share the
/// file. Past [maxFileBytes] the file moves aside and a new one starts, so
/// at most twice that stays on the device.
///
/// Use the top-level [debugLog] function to add entries from anywhere.
class DebugLog {
  DebugLog({this.capacity = 1000, this.maxFileBytes = 512 * 1024});

  static final DebugLog instance = DebugLog();

  final int capacity;
  final int maxFileBytes;

  final _entries = ListQueue<DebugLogEntry>();
  File? _file;
  String? _isolate;

  /// The entries written here since the start, oldest first.
  List<DebugLogEntry> get entries => List.unmodifiable(_entries);

  /// Writes to `debug_log.jsonl` in the app's support directory from now on.
  /// [isolate] marks the entries of an isolate other than the app's.
  Future<void> init({String? isolate}) async {
    if (!kDebugMode) return;
    try {
      final dir = await getApplicationSupportDirectory();
      attachFile(File('${dir.path}/debug_log.jsonl'), isolate: isolate);
    } on Object catch (e) {
      // Without a file the log still works, in memory.
      debugPrint('[DebugLog] no log file: $e');
    }
  }

  /// Writes to [file] from now on, and what came before as well — the start
  /// logs a few things before the file is known.
  @visibleForTesting
  void attachFile(File file, {String? isolate}) {
    _file = file;
    _isolate = isolate;
    for (final entry in _entries) {
      _append(entry);
    }
  }

  void add(String category, String message, {String? data}) {
    if (!kDebugMode) return;
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      category: category,
      message: message,
      data: data,
      isolate: _isolate,
    );
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
    debugPrint('[${_isolate ?? 'app'}] [$category] $message');
    if (_file != null) _append(entry);
  }

  File get _previousFile => File('${_file!.path}.1');

  void _append(DebugLogEntry entry) {
    final file = _file!;
    try {
      if (file.existsSync() && file.lengthSync() >= maxFileBytes) {
        file.renameSync(_previousFile.path);
      }
      // Synchronous and flushed: an entry right before a crash is the one
      // that matters most. One short line per write, appended — two isolates
      // writing at once do not tear each other's lines.
      file.writeAsStringSync(
        '${jsonEncode(entry.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      );
    } on FileSystemException catch (e) {
      debugPrint('[DebugLog] could not write: $e');
    }
  }

  /// Everything there is, from every isolate, oldest first: the file when
  /// there is one, otherwise what this isolate holds in memory.
  Future<List<DebugLogEntry>> readAll() async {
    final file = _file;
    if (file == null) return entries;
    try {
      final out = <DebugLogEntry>[];
      for (final f in [_previousFile, file]) {
        if (!await f.exists()) continue;
        for (final line in await f.readAsLines()) {
          final entry = DebugLogEntry.tryParse(line);
          if (entry != null) out.add(entry);
        }
      }
      // Two isolates append in the order they get to it; close enough, but
      // the page reads better strictly by time. The sort is stable.
      mergeSort(out, compare: (a, b) => a.timestamp.compareTo(b.timestamp));
      return out;
    } on FileSystemException {
      return entries;
    }
  }

  Future<void> clear() async {
    _entries.clear();
    final file = _file;
    if (file == null) return;
    for (final f in [file, _previousFile]) {
      try {
        if (await f.exists()) await f.delete();
      } on FileSystemException {
        // Gone already, or the other isolate holds it; the next clear tries
        // again.
      }
    }
  }

  /// [entries] as plain text, newest first.
  static String export(Iterable<DebugLogEntry> entries) {
    final buf = StringBuffer();
    for (final e in entries.toList().reversed) {
      final isolate = e.isolate == null ? '' : ' [${e.isolate}]';
      buf.writeln(
        '[${e.timestamp.toIso8601String()}]$isolate [${e.category}] ${e.message}',
      );
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

/// Logs an error that got this far, stack trace included.
void debugLogError(String where, Object? error, [StackTrace? stack]) => debugLog(
      LogCategory.error,
      '$where: ${error.runtimeType}: ${shorten('$error', 300)}',
      data: stack == null ? null : shorten('$stack', 4000),
    );

/// A short stand-in for an account: the same for the same user on the same
/// school, but naming neither.
String accountTag(String? user, String? url) {
  if (user == null) return 'Konto ?';
  final host = url == null
      ? ''
      : (Uri.tryParse(url.contains('://') ? url : 'https://$url')?.host ?? url)
          .toLowerCase();
  // FNV-1a, 32 bit: stable across isolates and runs, unlike hashCode.
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode('$user@$host')) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return 'Konto ${hash.toRadixString(16).padLeft(8, '0').substring(0, 6)}';
}

/// [text] cut to [max] characters, saying how much was left out.
String shorten(String text, int max) => text.length <= max
    ? text
    : '${text.substring(0, max)}… (${text.length - max} Zeichen gekürzt)';
