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
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

class Certificate extends ConsumerWidget {
  const Certificate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certState = ref.watch(certificateProvider);
    final noInternet = ref.watch(noInternetProvider);
    return Scaffold(
      appBar: const ResponsiveAppBar(
        title: Text("Zeugnis"),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Available width for the table (padding of 8 on each side).
                  final tableWidth = constraints.maxWidth - 16;
                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: HtmlWidget(
                          _prepareHtml(certState.html!, tableWidth),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// Preprocesses the server-rendered certificate HTML before passing it to
// HtmlWidget. Three transformations are applied:
//
// 1. % column widths on <th> → absolute px widths.
//    flutter_widget_from_html_core uses FractionColumnWidth for % values, which
//    requires a BOUNDED parent maxWidth. Inside a horizontal SingleChildScrollView
//    the maxWidth is ∞, so percentages break. Absolute px widths work regardless.
//
// 2. white-space:nowrap on header columns (≥ 10 %).
//    Prevents "Fach", "1. Semester", "2. Semester" from breaking across lines.
//
// 3. Grade badge + description text in Verhalten cell → separated by <br>.
//    The server uses `· ` as inline separator; we put the description on its own line.
String _prepareHtml(String html, double tableWidth) {
  var result = html;

  // Transform style="width: N%..." on <th> elements.
  result = result.replaceAllMapped(
    RegExp(r'(<th\b[^>]*)style="width:\s*(\d+(?:\.\d+)?)%[^"]*"([^>]*>)'),
    (m) {
      final pct = double.parse(m.group(2)!);
      // Keep tiny spacer columns at a fixed 4 px; compute all others from tableWidth.
      final px = pct < 5 ? 4 : (tableWidth * pct / 100).round();
      // Prevent text wrap on visible header columns (Fach, 1./2. Semester).
      final nowrap = pct >= 10 ? ' white-space: nowrap;' : '';
      return '${m.group(1)}style="width: ${px}px;$nowrap"${m.group(3)}';
    },
  );

  // Verhalten row: grade badge is inline with the description text, separated
  // by " · ". Replace with a line break so the description starts on a new line.
  result = result.replaceAll('</span> &middot; ', '</span><br>');

  return result;
}
