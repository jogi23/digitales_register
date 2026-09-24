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
import 'dart:developer';
import 'dart:io';

import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/middleware/middleware.dart' show openFile, saveToDownloads;
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// The file types messages can be exported to.
enum MessageExportFormat {
  pdf('pdf', 'application/pdf'),
  text('txt', 'text/plain'),
  markdown('md', 'text/markdown');

  const MessageExportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

/// The list kinds Quill knows. Its checklists count as bullets.
enum DeltaList { bullet, ordered }

/// A run of text with one formatting, from a Quill delta.
@immutable
class DeltaSpan {
  final String text;
  final bool bold;
  final bool italic;
  final bool strike;
  final String? link;

  const DeltaSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.link,
  });
}

/// One line of a Quill delta, with the block formatting Quill keeps on the
/// line break that ends it.
@immutable
class DeltaLine {
  final List<DeltaSpan> spans;

  /// 1 to 6 for a heading, `null` for body text.
  final int? header;
  final DeltaList? list;
  final bool quote;

  const DeltaLine(this.spans, {this.header, this.list, this.quote = false});

  String get plainText => spans.map((s) => s.text).join();
}

/// Splits the Quill delta a message text is stored as into lines.
///
/// Inline formatting sits on the text, block formatting — heading, list,
/// quote — on the line break after it. Embeds such as images are left out:
/// they have no text to export. A text that is no delta at all is taken as
/// plain text.
List<DeltaLine> parseDelta(String source) {
  final Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return [
      for (final line in source.split('\n'))
        DeltaLine([if (line.isNotEmpty) DeltaSpan(line)]),
    ];
  }
  final ops = decoded is Map ? decoded['ops'] : null;
  final lines = <DeltaLine>[];
  var spans = <DeltaSpan>[];
  for (final op in ops is List ? ops : const <Object?>[]) {
    if (op is! Map) continue;
    final insert = op['insert'];
    // Embeds carry a map instead of text.
    if (insert is! String) continue;
    final attributes = switch (op['attributes']) {
      final Map attributes => attributes,
      _ => const <Object?, Object?>{},
    };
    final parts = insert.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(DeltaSpan(
          parts[i],
          bold: attributes['bold'] == true,
          italic: attributes['italic'] == true,
          strike: attributes['strike'] == true,
          link: switch (attributes['link']) {
            final String link => link,
            _ => null,
          },
        ));
      }
      if (i == parts.length - 1) continue;
      lines.add(DeltaLine(
        spans,
        header: switch (attributes['header']) {
          final int header => header,
          _ => null,
        },
        list: switch (attributes['list']) {
          'ordered' => DeltaList.ordered,
          String() => DeltaList.bullet,
          _ => null,
        },
        quote: attributes['blockquote'] == true,
      ));
      spans = <DeltaSpan>[];
    }
  }
  if (spans.isNotEmpty) lines.add(DeltaLine(spans));
  return lines;
}

/// The text of a Quill delta without its formatting, one line per line.
String plainTextOf(String source) =>
    parseDelta(source).map((line) => line.plainText).join('\n');

/// Turns messages into one file to share or keep: plain text, Markdown or
/// PDF.
///
/// Each message as the app shows it opened — subject, date, sender,
/// recipients, text and the names of its attachments — one after another,
/// in the order given.
class MessageExport {
  final L l;

  const MessageExport(this.l);

  static final _date = DateFormat("d.M.yy H:mm");

  /// A file name for [messages]: the subject of a single message, otherwise
  /// the page title with the date.
  String fileName(
    List<Message> messages,
    MessageExportFormat format,
    DateTime now,
  ) {
    final base = messages.length == 1
        ? messages.single.subject
        : '${l.messagesTitle} ${DateFormat('yyyy-MM-dd').format(now)}';
    var name = base.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
    if (name.length > 80) name = name.substring(0, 80).trim();
    return '${name.isEmpty ? l.messagesTitle : name}.${format.extension}';
  }

  Future<List<int>> bytes(
    List<Message> messages,
    MessageExportFormat format,
  ) async =>
      switch (format) {
        MessageExportFormat.pdf => await pdf(messages),
        MessageExportFormat.text => utf8.encode(text(messages)),
        MessageExportFormat.markdown => utf8.encode(markdown(messages)),
      };

  String text(List<Message> messages) =>
      '${messages.map(_textOf).join('\n\n${'-' * 40}\n\n')}\n';

  String markdown(List<Message> messages) =>
      '${messages.map(_markdownOf).join('\n\n---\n\n')}\n';

  Future<Uint8List> pdf(List<Message> messages) {
    final document = pw.Document(title: l.messagesTitle);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          for (final (i, message) in messages.indexed) ...[
            if (i > 0) pw.Divider(height: 32),
            ..._pdfOf(message),
          ],
        ],
      ),
    );
    return document.save();
  }

  String _textOf(Message message) {
    final out = StringBuffer()
      ..writeln(message.subject)
      ..writeln('${l.messagesSent}${_date.format(message.timeSent)}')
      ..writeln('${l.messagesFrom}${message.fromName}')
      ..writeln('${l.messagesTo}${message.recipientString}')
      ..writeln();
    var number = 0;
    for (final line in parseDelta(message.text)) {
      number = line.list == DeltaList.ordered ? number + 1 : 0;
      out.writeln('${_listPrefix(line, number)}${line.plainText}');
    }
    if (message.attachments.isNotEmpty) {
      out
        ..writeln()
        ..writeln('${_attachmentsLabel(message)} ${_attachmentNames(message)}');
    }
    return out.toString().trimRight();
  }

  String _markdownOf(Message message) {
    final out = StringBuffer()
      ..writeln('## ${_escape(message.subject)}')
      ..writeln()
      // Two trailing spaces: a line break without starting a new paragraph.
      ..writeln('**${l.messagesSent.trim()}** '
          '${_date.format(message.timeSent)}  ')
      ..writeln('**${l.messagesFrom.trim()}** ${_escape(message.fromName)}  ')
      ..writeln('**${l.messagesTo.trim()}** '
          '${_escape(message.recipientString)}')
      ..writeln();
    DeltaLine? previous;
    var number = 0;
    for (final line in parseDelta(message.text)) {
      if (line.spans.isEmpty) {
        previous = null;
        number = 0;
        continue;
      }
      number = line.list == DeltaList.ordered ? number + 1 : 0;
      // List items follow each other directly; anything else is a paragraph.
      if (previous != null) {
        out.write(previous.list != null && line.list != null ? '\n' : '\n\n');
      }
      out
        ..write(line.quote ? '> ' : '')
        // The subject is a second-level heading, so the text's own headings
        // start below it.
        ..write(line.header == null
            ? ''
            : '${'#' * (line.header! + 2).clamp(3, 6)} ')
        ..write(switch (line.list) {
          DeltaList.bullet => '- ',
          DeltaList.ordered => '$number. ',
          null => '',
        })
        ..write(line.spans.map(_markdownSpan).join());
      previous = line;
    }
    if (message.attachments.isNotEmpty) {
      out.write('\n\n**${_attachmentsLabel(message)}** '
          '${_escape(_attachmentNames(message))}');
    }
    return out.toString().trimRight();
  }

  List<pw.Widget> _pdfOf(Message message) {
    const bold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
    pw.Widget detail(String label, String value) => pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: label, style: bold),
            pw.TextSpan(text: value),
          ]),
        );

    final widgets = <pw.Widget>[
      pw.Text(
        message.subject,
        style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 6),
      detail(l.messagesSent, _date.format(message.timeSent)),
      detail(l.messagesFrom, message.fromName),
      detail(l.messagesTo, message.recipientString),
      pw.SizedBox(height: 10),
    ];
    var number = 0;
    for (final line in parseDelta(message.text)) {
      number = line.list == DeltaList.ordered ? number + 1 : 0;
      if (line.spans.isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }
      // RichText on its own, not wrapped: only then can a long paragraph
      // continue on the next page.
      widgets.add(pw.RichText(
        text: pw.TextSpan(
          style: line.header == null
              ? null
              : pw.TextStyle(
                  fontSize: 16.0 - line.header!.clamp(1, 4),
                  fontWeight: pw.FontWeight.bold,
                ),
          children: [
            pw.TextSpan(
              text: '${line.quote ? '> ' : ''}${_listPrefix(line, number)}',
            ),
            for (final span in line.spans)
              pw.TextSpan(
                text: span.text,
                style: pw.TextStyle(
                  fontWeight: span.bold ? pw.FontWeight.bold : null,
                  fontStyle: span.italic ? pw.FontStyle.italic : null,
                  decoration: span.strike
                      ? pw.TextDecoration.lineThrough
                      : span.link != null
                          ? pw.TextDecoration.underline
                          : null,
                ),
              ),
          ],
        ),
      ));
    }
    if (message.attachments.isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: 10))
        ..add(detail(
          '${_attachmentsLabel(message)} ',
          _attachmentNames(message),
        ));
    }
    return widgets;
  }

  String _attachmentsLabel(Message message) => message.attachments.length > 1
      ? l.messagesAttachments
      : l.messagesAttachment;

  static String _attachmentNames(Message message) =>
      message.attachments.map((a) => a.originalName).join(', ');

  static String _listPrefix(DeltaLine line, int number) =>
      switch (line.list) {
        DeltaList.bullet => '• ',
        DeltaList.ordered => '$number. ',
        null => '',
      };

  static String _markdownSpan(DeltaSpan span) {
    // Markers have to touch the text: "** bold**" is no emphasis.
    final match = RegExp(r'^(\s*)(.*?)(\s*)$', dotAll: true).firstMatch(span.text)!;
    var core = _escape(match[2]!);
    if (core.isEmpty) return span.text;
    if (span.link != null) core = '[$core](${span.link})';
    if (span.strike) core = '~~$core~~';
    final marker = '${span.bold ? '**' : ''}${span.italic ? '*' : ''}';
    return '${match[1]}$marker$core$marker${match[3]}';
  }

  static String _escape(String text) =>
      text.replaceAllMapped(RegExp(r'[\\`*_\[\]<>#]'), (m) => '\\${m[0]}');
}

/// Shares [messages] as one file, or saves it next to the downloaded
/// attachments and opens it.
///
/// Returns whether the file was written. Failures are reported on screen.
Future<bool> exportMessages(
  L l,
  List<Message> messages,
  MessageExportFormat format, {
  required bool share,
}) async {
  final export = MessageExport(l);
  final name = export.fileName(messages, format, DateTime.now());
  try {
    final bytes = await export.bytes(messages, format);
    if (share) {
      final file = File('${(await getTemporaryDirectory()).path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: format.mimeType)],
          subject:
              messages.length == 1 ? messages.single.subject : l.messagesTitle,
        ),
      );
    } else {
      final path = await saveToDownloads(name, bytes);
      showSnackBar(l.messagesExportSaved(path));
      await openFile(name);
    }
    return true;
  } catch (e) {
    log("failed to export messages: $e");
    showSnackBar(l.messagesExportFailed);
    return false;
  }
}
