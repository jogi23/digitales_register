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

import 'package:dr/app_state.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/container/absence_group_container.dart';
import 'package:dr/data.dart';
import 'package:dr/ui/absence.dart';
import 'package:dr/ui/connection_status_button.dart';
import 'package:dr/ui/entry_card.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

class AbsencesPage extends StatelessWidget {
  final AbsencesState state;
  final bool noInternet;

  /// List or cards.
  final EntryDisplayMode displayMode;

  /// Loads the page again when it is pulled down from the top.
  final Future<void> Function() onRefresh;

  /// Reports an absence still to come; null leaves out the button, which is
  /// what an account without the right to edit gets.
  final VoidCallback? onReport;

  /// Takes a report back; null leaves out the button.
  final void Function(FutureAbsence absence)? onRemoveFuture;

  /// Gives a reason for one of the absences; null leaves out the button.
  final void Function(int group)? onJustify;

  const AbsencesPage({
    required this.onRefresh,
    super.key,
    required this.state,
    required this.noInternet,
    this.displayMode = EntryDisplayMode.list,
    this.onReport,
    this.onRemoveFuture,
    this.onJustify,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: Text(tr(context).absencesTitle),
        actions: <Widget>[
          if (onReport != null)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: tr(context).absenceReportTitle,
              onPressed: onReport,
            ),
          const ConnectionStatusButton(),
          const AccountAvatarButton(),
        ],
      ),
      body: PullToRefresh(
        onRefresh: onRefresh,
        child: AbsencesBody(
          state: state,
          noInternet: noInternet,
          displayMode: displayMode,
          onRemoveFuture: onRemoveFuture,
          onJustify: onJustify,
        ),
      ),
    );
  }
}

class AbsencesBody extends StatelessWidget {
  final AbsencesState state;
  final bool noInternet;
  final EntryDisplayMode displayMode;

  /// Takes a report back; null leaves out the button.
  final void Function(FutureAbsence absence)? onRemoveFuture;

  /// Gives a reason for one of the absences; null leaves out the button.
  final void Function(int group)? onJustify;

  const AbsencesBody({
    super.key,
    required this.state,
    required this.noInternet,
    this.displayMode = EntryDisplayMode.list,
    this.onRemoveFuture,
    this.onJustify,
  });

  @override
  Widget build(BuildContext context) {
    final altColor = alternateRowColor(context);

    // A row tinted every other time in the list, a card of its own otherwise.
    Widget entry(int i, Widget Function(Color? tileColor) build) =>
        displayMode == EntryDisplayMode.cards
            ? EntryCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: build(null),
              )
            : build(i.isEven ? altColor : null);

    return state.statistic != null
        ? state.absences.isEmpty && state.futureAbsences.isEmpty
            ? Center(
                child: Text(
                  tr(context).absencesEmpty,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                padding: context.systemInsets,
                children: <Widget>[
                AbsencesStatisticWidget(
                  stat: state.statistic!,
                ),
                const Divider(height: 0),
                if (state.futureAbsences.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 16),
                    child: Text(
                      tr(context).absencesPlanned,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                for (var i = 0; i < state.futureAbsences.length; i++)
                  entry(
                    i,
                    (tileColor) => FutureAbsenceWidget(
                      absence: state.futureAbsences[i],
                      tileColor: tileColor,
                      onDelete: onRemoveFuture == null
                          ? null
                          : () => onRemoveFuture!(state.futureAbsences[i]),
                    ),
                  ),
                if (state.absences.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 16),
                    child: Text(
                      tr(context).absencesTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ...List.generate(
                  state.absences.length,
                  (n) => entry(
                    n,
                    (tileColor) => AbsenceGroupContainer(
                      group: state.absences.length - n - 1,
                      tileColor: tileColor,
                      onJustify: onJustify,
                    ),
                  ),
                ),
              ])
        : noInternet
            ? const NoInternet()
            : const Center(
                child: CircularProgressIndicator(),
              );
  }
}

class AbsencesStatisticWidget extends StatelessWidget {
  final AbsenceStatistic stat;

  const AbsencesStatisticWidget({super.key, required this.stat});
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(tr(context).absencesStatistics),
      children: <Widget>[
        if (stat.counter != null)
          ListTile(
            title: Text(tr(context).absencesTitle),
            trailing: Text(stat.counter.toString()),
          ),
        if (stat.counterForSchool != null)
          ListTile(
            title: Text(tr(context).absencesForSchool),
            trailing: Text(stat.counterForSchool.toString()),
          ),
        if (stat.delayed != null)
          ListTile(
            title: Text(tr(context).absencesDelays),
            trailing: Text(stat.delayed.toString()),
          ),
        if (stat.justified != null)
          ListTile(
            title: Text(tr(context).absencesJustified),
            trailing: Text(stat.justified.toString()),
          ),
        if (stat.notJustified != null)
          ListTile(
            title: Text(tr(context).absencesNotJustified),
            trailing: Text(stat.notJustified.toString()),
          ),
        if (stat.percentage != null)
          ListTile(
            title: Text(tr(context).absencesAbsence),
            trailing: Text("${stat.percentage} %"),
          ),
      ],
    );
  }
}
