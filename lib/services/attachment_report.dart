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
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Attachments the app cannot show yet, audio above all (#339). The portal
// sends them in `*Submissions` lists; which kinds exist is only known from
// what schools actually send.

/// File types the app already opens without trouble.
const _knownTypeNames = {
  'PDF', 'JPG', 'JPEG', 'PNG', 'GIF', //
  'DOC', 'DOCX', 'ODT', 'XLS', 'XLSX', 'PPT', 'PPTX', 'TXT',
};

/// What tells an attachment's kind apart — and nothing that names it: no
/// title, file name, link or text.
Map<String, String> attachmentShape(Map<dynamic, dynamic> s) {
  final name = s['originalName'];
  final dot = name is String ? name.lastIndexOf('.') : -1;
  final suffix = dot < 0 ? null : (name as String).substring(dot + 1);
  final extension = suffix == null
      ? '-'
      // Anything longer is part of a name, not an extension.
      : RegExp(r'^[A-Za-z0-9]{1,5}$').hasMatch(suffix)
          ? suffix
          : '?';
  return {
    'type': '${s['type']}',
    'typeName': '${s['typeName']}',
    'extension': extension,
    'isDownloadable': '${s['isDownloadable']}',
    'filled': [
      for (final key in const ['title', 'link', 'file', 'text'])
        if (s[key] != null && s[key] != '') key,
    ].join(', '),
    'fields': s.keys.join(', '),
  };
}

/// Whether the app shows [s] the way it should: a file of a common type.
bool isKnownAttachment(Map<dynamic, dynamic> s) =>
    s['type'] == 'file' && _knownTypeNames.contains(s['typeName']);

/// The reporter the app uses, replaceable in tests.
AttachmentReporter attachmentReporter = AttachmentReporter();

/// Describes the attachments in [submissions] in the debug log and reports
/// the kinds the app does not know. Parsers call this; it never throws.
void noteAttachments(String where, List<dynamic>? submissions) =>
    attachmentReporter.note(where, submissions);

typedef SendAttachmentReport = Future<void> Function(
  String where,
  Map<String, String> shape,
);

/// Logs each attachment once per run and tells Sentry about each unknown
/// kind once per install, so new kinds turn up without anyone writing in.
class AttachmentReporter {
  static const _reportedKey = 'attachment_reports_sent';

  final SendAttachmentReport _send;
  final bool Function() _enabled;
  final _logged = <String>{};

  /// Kinds already looked up this run, so a reload costs no storage access.
  final _checked = <String>{};

  AttachmentReporter({SendAttachmentReport? send, bool Function()? enabled})
      : _send = send ?? _sendToSentry,
        _enabled = enabled ?? (() => Sentry.isEnabled);

  Future<void> note(String where, List<dynamic>? submissions) async {
    for (final s in submissions ?? const <dynamic>[]) {
      if (s is! Map) continue;
      final shape = attachmentShape(s);
      if (_logged.add('$where ${s['id']}')) {
        debugLog(
          LogCategory.attachments,
          '$where ${s['id']}: type=${shape['type']}, '
          'typeName=${shape['typeName']}, Endung=${shape['extension']}, '
          'isDownloadable=${shape['isDownloadable']}, '
          'belegt=[${shape['filled']}]',
          data: 'Felder: ${shape['fields']}',
        );
      }
      if (!isKnownAttachment(s)) await _report(where, shape);
    }
  }

  Future<void> _report(String where, Map<String, String> shape) async {
    // The background isolate has no Sentry; marking the kind as sent there
    // would keep the app from ever reporting it.
    if (!_enabled()) return;
    final key = '$where:${shape['type']}:${shape['typeName']}';
    if (!_checked.add(key)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final sent = prefs.getStringList(_reportedKey) ?? const <String>[];
      if (sent.contains(key)) return;
      await _send(where, shape);
      await prefs.setStringList(_reportedKey, [...sent, key]);
    } catch (_) {
      // Nothing the user could do about it.
    }
  }
}

Future<void> _sendToSentry(String where, Map<String, String> shape) async {
  await Sentry.captureMessage(
    'Unbekannter Anhang: $where, ${shape['type']}/${shape['typeName']}',
    withScope: (scope) async {
      // The shape alone: breadcrumbs carry printed log lines.
      await scope.clearBreadcrumbs();
      // One Sentry issue per kind, however many installs and places send it.
      scope.fingerprint = [
        'attachment-report',
        shape['type']!,
        shape['typeName']!,
      ];
      await scope.setTag('attachment_report', where);
      await scope.setContexts('attachment', shape);
    },
  );
}
