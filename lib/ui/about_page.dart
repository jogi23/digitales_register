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
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/changelog_page.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Version, who makes the app, independence note, legal texts and licenses.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.menuAbout)),
      body: ListView(
        padding: context.systemInsets,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/index.png',
              width: 100,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'DigiReg ST',
            style: text.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(l.aboutVersion(appVersion)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colors.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.aboutIndependent)),
                  ],
                ),
              ),
            ),
          ),
          _Header(l.aboutDevelopers),
          for (final (name, uri) in AppLinks.developers)
            _LinkTile(
              icon: Icons.person_outline,
              title: name,
              subtitle: uri.host,
              onTap: () => _open(uri),
            ),
          const Divider(),
          _LinkTile(
            icon: Icons.new_releases_outlined,
            title: l.changelogTitle,
            internal: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChangelogPage()),
            ),
          ),
          _LinkTile(
            icon: Icons.code,
            title: l.aboutSourceCode,
            subtitle: l.aboutFreeSoftware,
            onTap: () => _open(AppLinks.source),
          ),
          _LinkTile(
            icon: Icons.description_outlined,
            title: l.aboutLicenses,
            internal: true,
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'DigiReg ST',
              applicationVersion: appVersion,
              applicationLegalese: _legalese,
            ),
          ),
          _Header(l.aboutLegal),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l.aboutPrivacyShort,
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          _LinkTile(
            icon: Icons.policy_outlined,
            title: l.aboutPrivacy,
            onTap: () => _open(AppLinks.privacy),
          ),
          _LinkTile(
            icon: Icons.badge_outlined,
            title: l.aboutImprint,
            onTap: () => _open(AppLinks.imprint),
          ),
          _LinkTile(
            icon: Icons.gavel,
            title: l.aboutTerms,
            onTap: () => _open(AppLinks.terms),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _legalese,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  static const _legalese =
      '© 2026 Johannes Feichter\n© 2019–2022 Michael Debertol, Simon Wachtler';

  static Future<bool> _open(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

/// A row that opens a page in the app ([internal]) or in the browser.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.internal = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool internal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Icon(internal ? Icons.chevron_right : Icons.open_in_new),
      onTap: onTap,
    );
  }
}
