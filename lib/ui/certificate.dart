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
      appBar: const ResponsiveAppBar(title: Text("Zeugnis")),
      body: certState.html == null
          ? Center(
              child: noInternet
                  ? const NoInternet()
                  : const CircularProgressIndicator(),
            )
          : LastFetchedOverlay(
              lastFetched: certState.lastFetched,
              noInternet: noInternet,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: HtmlWidget(certState.html!),
                ),
              ),
            ),
    );
  }
}
