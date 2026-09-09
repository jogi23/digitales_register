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

import 'package:dr/services/changelog.dart';
import 'package:dr/ui/changelog_page.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Sits above the dashboard after an update and says what is new.
///
/// Takes no room at all when there is nothing to report, which is every start
/// but the first one after an update.
class ChangelogCard extends StatefulWidget {
  const ChangelogCard({super.key});

  /// At most this many lines per version — the card must not push the day
  /// list out of view.
  static const maxPoints = 3;

  /// Only the newest two versions are spelled out; anything older is what the
  /// full list is for.
  static const maxVersions = 2;

  @override
  State<ChangelogCard> createState() => _ChangelogCardState();
}

class _ChangelogCardState extends State<ChangelogCard> {
  late final Future<List<ChangelogEntry>> _entries = changelog.pending();
  bool _dismissed = false;

  /// With several versions the card cannot name a single one: it holds
  /// exactly what this reader has not seen, and the versions are spelled out
  /// inside.
  String _title(List<ChangelogEntry> entries) => entries.length == 1
      ? "Neu in Version ${entries.first.version}"
      : tr(context).changelogSinceLastUpdate;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return FutureBuilder<List<ChangelogEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null || entries.isEmpty) return const SizedBox.shrink();
        return _Card(
          title: _title(entries),
          entries: entries.take(ChangelogCard.maxVersions).toList(),
          showVersionHeadings: entries.length > 1,
          onDismiss: () => setState(() => _dismissed = true),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<ChangelogEntry> entries;
  final bool showVersionHeadings;
  final VoidCallback onDismiss;

  const _Card({
    required this.title,
    required this.entries,
    required this.showVersionHeadings,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      color: scheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final entry in entries) ...[
                        if (showVersionHeadings)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Text(
                              entry.version,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        for (final point
                            in entry.points.take(ChangelogCard.maxPoints))
                          _Point(text: point),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  color: scheme.onPrimaryContainer,
                  tooltip: tr(context).changelogDismiss,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: TextButton(
                onPressed: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ChangelogPage(),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tr(context).changelogAll),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final String text;

  const _Point({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
