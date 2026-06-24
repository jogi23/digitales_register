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
        // Section header (colspan="5") or empty spacer row
        final text = ths[0].text.trim();
        if (text.isNotEmpty) rows.add(_CertRow.section(text));
      } else {
        // Column header row: Fach | 1. Semester | (spacer) | 2. Semester | (spacer)
        for (final th in ths) {
          final text = th.text.trim();
          if (text.isNotEmpty) semHeaders.add(text);
        }
      }
    } else if (tds.isNotEmpty) {
      final label = tds[0].text.trim();
      if (label.isEmpty) continue;

      final cells = <_CellData>[];
      // Odd indices 1, 3, … are grade columns; even indices 2, 4, … are 1 %-spacers.
      for (int i = 1; i < tds.length; i += 2) {
        final td = tds[i];
        final gradeSpan = td.querySelector('span.green');
        if (gradeSpan != null) {
          final grade = gradeSpan.text.trim();
          final full = td.text.trim();
          // Format: "grade · description" — U+00B7 MIDDLE DOT
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
    // First semHeader is "Fach" (label column) — drop it
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

class _CertificateView extends StatefulWidget {
  final String html;
  const _CertificateView({required this.html});

  @override
  State<_CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<_CertificateView> {
  late _CertData _data;
  // One controller for the sticky header + one per data row (null for section headers).
  // All are kept in sync so horizontal scrolling moves all grade columns together.
  late final ScrollController _headerCtrl;
  late final List<ScrollController?> _rowCtrls;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _data = _parseHtml(widget.html);
    _headerCtrl = _makeCtrl();
    _rowCtrls =
        _data.rows.map((r) => r.isSectionHeader ? null : _makeCtrl()).toList();
  }

  ScrollController _makeCtrl() {
    final c = ScrollController();
    c.addListener(() => _onScroll(c));
    return c;
  }

  // Propagates a scroll offset change to every other grade-area ScrollView.
  void _onScroll(ScrollController source) {
    if (_syncing) return;
    _syncing = true;
    final offset = source.offset;
    void sync(ScrollController? c) {
      if (c != null && c != source && c.hasClients && c.offset != offset) {
        c.jumpTo(offset);
      }
    }

    sync(_headerCtrl);
    for (final c in _rowCtrls) sync(c);
    _syncing = false;
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _rowCtrls) c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final labelWidth = _computeLabelWidth(context, screenWidth);
        // Each semester column fills the remaining screen space; with two columns
        // the grade area is 2 × gradeColWidth → horizontal scroll reveals column 2.
        final gradeColWidth = screenWidth - labelWidth;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(context),
              _buildHeader(context, labelWidth, gradeColWidth),
              const Divider(height: 1, thickness: 1),
              ..._buildRows(context, labelWidth, gradeColWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitle(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Text(
          _data.title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildHeader(
      BuildContext context, double labelWidth, double gradeColWidth) {
    final theme = Theme.of(context);
    final style =
        theme.textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold);

    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('Fach', style: style),
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              child: _data.semesterCount <= 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Text(
                        _data.semesterHeaders.isEmpty
                            ? ''
                            : _data.semesterHeaders.first,
                        style: style,
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _headerCtrl,
                      child: Row(
                        children: [
                          for (final h in _data.semesterHeaders)
                            SizedBox(
                              width: gradeColWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: Text(h, style: style),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows(
      BuildContext context, double labelWidth, double gradeColWidth) {
    final theme = Theme.of(context);
    final altColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.35);

    final widgets = <Widget>[];
    int dataIdx = 0;

    for (int i = 0; i < _data.rows.length; i++) {
      final row = _data.rows[i];
      if (row.isSectionHeader) {
        widgets.add(_buildSectionHeader(context, row.label));
        dataIdx = 0;
      } else {
        widgets.add(_buildDataRow(
          context,
          row,
          _rowCtrls[i],
          labelWidth,
          gradeColWidth,
          dataIdx.isEven ? altColor : null,
        ));
        dataIdx++;
      }
    }

    return widgets;
  }

  Widget _buildSectionHeader(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    _CertRow row,
    ScrollController? ctrl,
    double labelWidth,
    double gradeColWidth,
    Color? bgColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      color: bgColor,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed label column
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  row.label,
                  style: theme.textTheme.bodyMedium,
                  softWrap: true,
                ),
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            // Grade area — single column fills Expanded, two columns scroll horizontally
            Expanded(
              child: _data.semesterCount <= 1
                  ? _buildCell(
                      context,
                      row.cells.isNotEmpty ? row.cells[0] : const _CellData(),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: ctrl,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < _data.semesterCount; i++)
                            SizedBox(
                              width: gradeColWidth,
                              child: _buildCell(
                                context,
                                i < row.cells.length
                                    ? row.cells[i]
                                    : const _CellData(),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, _CellData cell) {
    if (cell.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SizedBox.shrink(),
      );
    }

    final gradeColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cell.grade != null)
            Text(
              cell.grade!,
              style: TextStyle(color: gradeColor, fontWeight: FontWeight.w500),
            ),
          if (cell.description != null)
            Padding(
              padding: EdgeInsets.only(top: cell.grade != null ? 4 : 0),
              child: Text(
                cell.description!,
                style: Theme.of(context).textTheme.bodySmall,
                softWrap: true,
              ),
            ),
        ],
      ),
    );
  }

  // Measures the widest label text and caps it at 1/3 of the available screen width.
  double _computeLabelWidth(BuildContext context, double screenWidth) {
    final style = Theme.of(context).textTheme.bodyMedium;
    double maxW = 0;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final row in _data.rows) {
      if (row.isSectionHeader) continue;
      tp.text = TextSpan(text: row.label, style: style);
      tp.layout(maxWidth: double.infinity);
      if (tp.width > maxW) maxW = tp.width;
    }
    tp.dispose();
    return (maxW + 16).clamp(60.0, screenWidth / 3); // +16 for 8 dp padding each side
  }
}
