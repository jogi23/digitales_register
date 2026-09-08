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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Every version the app knows about, newest first.
///
/// The notes ship with the app rather than being fetched, so this works
/// without a connection and says the same thing as the card in the dashboard.
class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  late final Future<List<ChangelogEntry>> _entries = changelog.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Neuerungen")),
      body: FutureBuilder<List<ChangelogEntry>>(
        future: _entries,
        builder: (context, snapshot) {
          final entries = snapshot.data;
          if (entries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return const Center(child: Text("Keine Einträge"));
          }
          return ListView.builder(
            padding: EdgeInsets.only(
              top: 8,
              bottom: MediaQuery.of(context).viewPadding.bottom + 24,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) => _Release(entry: entries[index]),
          );
        },
      ),
    );
  }
}

class _Release extends StatelessWidget {
  final ChangelogEntry entry;

  const _Release({required this.entry});

  /// "11. Juli 2026", or nothing when the file carries no date.
  String? get _date {
    final date = entry.date;
    if (date == null) return null;
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    return DateFormat.yMMMMd("de").format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = _date;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                entry.version,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              if (date != null) ...[
                const SizedBox(width: 8),
                Text(
                  date,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
          for (final section in entry.sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 2),
              child: Text(
                section.title,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: theme.textTheme.bodyMedium),
                    Expanded(
                      child: Text(item, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
