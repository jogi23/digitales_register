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

import 'package:dr/providers/certificate_provider.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/last_fetched_overlay.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' show parse;
import 'package:responsive_scaffold/responsive_scaffold.dart';

// ─── Data model ──────────────────────────────────────────────────────────────

class _CertData {
  final String title;
  final List<String> semesterHeaders;
  final List<_CertRow> rows;

  const _CertData({
    required this.title,
    required this.semesterHeaders,
    required this.rows,
  });

  int get semesterCount => semesterHeaders.length;
}

class _CertRow {
  final bool isSectionHeader;
  final String label;
  final List<_CellData> cells;

  const _CertRow._({
    required this.isSectionHeader,
    required this.label,
    this.cells = const [],
  });

  factory _CertRow.section(String label) =>
      _CertRow._(isSectionHeader: true, label: label);

  factory _CertRow.data(String label, List<_CellData> cells) =>
      _CertRow._(isSectionHeader: false, label: label, cells: cells);
}

class _CellData {
  final String? grade;
  final String? description;

  const _CellData({this.grade, this.description});

  bool get isEmpty => grade == null && description == null;
}

class _Section {
  final String? header;
  final List<_CertRow> rows;
  const _Section({required this.header, required this.rows});
}

// ─── HTML parser ─────────────────────────────────────────────────────────────

_CertData _parseHtml(String html) {
  final doc = parse(html);
  final title = doc.querySelector('h2')?.text.trim() ?? '';

  final semHeaders = <String>[];
  final rows = <_CertRow>[];

  for (final tr in doc.querySelectorAll('tr')) {
    final ths = tr.querySelectorAll('th');
    final tds = tr.querySelectorAll('td');

    if (ths.isNotEmpty && tds.isEmpty) {
      if (ths.length == 1 && ths[0].attributes.containsKey('colspan')) {
        final text = ths[0].text.trim();
        if (text.isNotEmpty) rows.add(_CertRow.section(text));
      } else {
        for (final th in ths) {
          final text = th.text.trim();
          if (text.isNotEmpty) semHeaders.add(text);
        }
      }
    } else if (tds.isNotEmpty) {
      final label = tds[0].text.trim();
      if (label.isEmpty) continue;

      final cells = <_CellData>[];
      for (int i = 1; i < tds.length; i += 2) {
        final td = tds[i];
        final gradeSpan = td.querySelector('span.green');
        if (gradeSpan != null) {
          final grade = gradeSpan.text.trim();
          final full = td.text.trim();
          final sep = full.indexOf(' · ');
          final desc = sep != -1 ? full.substring(sep + 3).trim() : null;
          cells.add(_CellData(grade: grade, description: desc));
        } else {
          final text = td.text.trim();
          cells.add(_CellData(description: text.isEmpty ? null : text));
        }
      }
      rows.add(_CertRow.data(label, cells));
    }
  }

  return _CertData(
    title: title,
    semesterHeaders: semHeaders.length > 1 ? semHeaders.sublist(1) : semHeaders,
    rows: rows,
  );
}

// ─── Certificate page ─────────────────────────────────────────────────────────

class Certificate extends ConsumerWidget {
  const Certificate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certState = ref.watch(certificateProvider);
    final noInternet = ref.watch(noInternetProvider);
    return Scaffold(
      appBar: const ResponsiveAppBar(
        title: Text('Zeugnis'),
        actions: [AccountAvatarButton()],
      ),
      body: certState.html == null
          ? Center(
              child: noInternet
                  ? const NoInternet()
                  : const CircularProgressIndicator(),
            )
          : LastFetchedOverlay(
              lastFetched: certState.lastFetched,
              noInternet: noInternet,
              child: _CertificateView(html: certState.html!),
            ),
    );
  }
}

// ─── Certificate view ─────────────────────────────────────────────────────────

class _CertificateView extends StatelessWidget {
  final String html;
  const _CertificateView({required this.html});

  @override
  Widget build(BuildContext context) {
    final data = _parseHtml(html);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final labelWidth = _computeLabelWidth(context, data.rows, screenWidth);

        final altColor =
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.4);
        final headerBg = theme.colorScheme.surfaceContainerHighest;
        final gradeColor = theme.colorScheme.primary;

        // Label column is fixed; semester columns share remaining space equally.
        // Table handles row-height synchronisation natively — no IntrinsicHeight
        // or manual scroll sync needed.
        final columnWidths = <int, TableColumnWidth>{
          0: FixedColumnWidth(labelWidth),
          for (int i = 1; i <= data.semesterCount; i++)
            i: const FlexColumnWidth(1.0),
        };

        final border = TableBorder.all(
          color: theme.dividerColor,
          width: 0.5,
        );

        final sections = _splitSections(data.rows);
        final content = <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Text(
              data.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ];

        for (int s = 0; s < sections.length; s++) {
          final section = sections[s];

          if (section.header != null) {
            content.add(
              Container(
                width: double.infinity,
                color: headerBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Text(
                  section.header!,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          if (section.rows.isEmpty) continue;

          final tableRows = <TableRow>[];

          // Column headers only in the first section's table.
          if (s == 0) {
            tableRows.add(TableRow(
              decoration: BoxDecoration(color: headerBg),
              children: [
                _headerCell(context, 'Fach'),
                for (final h in data.semesterHeaders)
                  _headerCell(context, h),
              ],
            ));
          }

          for (int i = 0; i < section.rows.length; i++) {
            final row = section.rows[i];
            tableRows.add(TableRow(
              decoration: i.isEven
                  ? BoxDecoration(color: altColor)
                  : null,
              children: [
                _labelCell(context, row.label),
                for (int c = 0; c < data.semesterCount; c++)
                  _gradeCell(
                    context,
                    c < row.cells.length
                        ? row.cells[c]
                        : const _CellData(),
                    gradeColor,
                  ),
              ],
            ));
          }

          content.add(Table(
            columnWidths: columnWidths,
            border: border,
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: tableRows,
          ));
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content,
          ),
        );
      },
    );
  }

  static Widget _headerCell(BuildContext context, String text) {
    final style = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(text, style: style),
    );
  }

  static Widget _labelCell(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium,
        softWrap: true,
      ),
    );
  }

  static Widget _gradeCell(
      BuildContext context, _CellData cell, Color gradeColor) {
    if (cell.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cell.grade != null)
            Text(
              cell.grade!,
              style: TextStyle(
                  color: gradeColor, fontWeight: FontWeight.w500),
            ),
          if (cell.description != null)
            Padding(
              padding: EdgeInsets.only(top: cell.grade != null ? 4 : 0),
              child: Text(
                cell.description!,
                style: theme.textTheme.bodySmall,
                softWrap: true,
              ),
            ),
        ],
      ),
    );
  }

  static List<_Section> _splitSections(List<_CertRow> rows) {
    final sections = <_Section>[];
    String? currentHeader;
    List<_CertRow> currentRows = [];

    for (final row in rows) {
      if (row.isSectionHeader) {
        sections.add(_Section(header: currentHeader, rows: List.of(currentRows)));
        currentHeader = row.label;
        currentRows = [];
      } else {
        currentRows.add(row);
      }
    }
    sections.add(_Section(header: currentHeader, rows: List.of(currentRows)));
    return sections;
  }

  static double _computeLabelWidth(
      BuildContext context, List<_CertRow> rows, double screenWidth) {
    final style = Theme.of(context).textTheme.bodyMedium;
    double maxW = 0;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final row in rows) {
      if (row.isSectionHeader) continue;
      tp.text = TextSpan(text: row.label, style: style);
      tp.layout(maxWidth: double.infinity);
      if (tp.width > maxW) maxW = tp.width;
    }
    tp.dispose();
    return (maxW + 16).clamp(60.0, screenWidth / 3);
  }
}
