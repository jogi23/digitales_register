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

import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hilfe & Feedback"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("Email schreiben"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              await launchUrl(
                Uri(
                  scheme: 'mailto',
                  path: 'hallo@wertwerk.io',
                  queryParameters: {
                    'subject': 'Feedback DigiReg ST $appVersion',
                  },
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("FAQ"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse(
                "https://wertwerk.io/projekte/digitale-register-app/#faq",
              ),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: const Text("Feature/Idee vorschlagen"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse("https://tally.so/r/Y5xKgv"),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text("Bug/Fehler melden"),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              Uri.parse("https://tally.so/r/yPdpP6"),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
