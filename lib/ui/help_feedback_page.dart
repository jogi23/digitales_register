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

import 'package:dr/app_links.dart';
import 'package:dr/ui/help_page.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/util.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context).helpTitle),
      ),
      body: ListView(
        padding: context.systemInsets,
        children: [
          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: Text(tr(context).helpOfflineFaq),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpPage()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(tr(context).helpWriteEmail),
            trailing: const Icon(Icons.open_in_new),
            onTap: () async {
              await launchUrl(AppLinks.feedbackMail(appVersion));
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(tr(context).helpFaq),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              AppLinks.faq,
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(tr(context).helpSuggestFeature),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              AppLinks.suggestFeature,
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(tr(context).helpReportBug),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => launchUrl(
              AppLinks.reportBug,
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}
