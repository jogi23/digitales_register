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
import 'package:dr/ui/last_fetched_overlay.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

class AbsencesPage extends StatelessWidget {
  final AbsencesState state;
  final bool noInternet;

  const AbsencesPage({
    super.key,
    required this.state,
    required this.noInternet,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: Text(tr(context).absencesTitle),
        actions: [AccountAvatarButton()],
      ),
      body: LastFetchedOverlay(
        lastFetched: state.lastFetched,
        noInternet: noInternet,
        child: AbsencesBody(
          state: state,
          noInternet: noInternet,
        ),
      ),
    );
  }
}

class AbsencesBody extends StatelessWidget {
  final AbsencesState state;
  final bool noInternet;

  const AbsencesBody(
      {super.key, required this.state, required this.noInternet});

  @override
  Widget build(BuildContext context) {
    final altColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withOpacity(0.75);

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
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom),
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
                  FutureAbsenceWidget(
                    absence: state.futureAbsences[i],
                    tileColor: i.isEven ? altColor : null,
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
                  (n) => AbsenceGroupContainer(
                    group: state.absences.length - n - 1,
                    tileColor: n.isEven ? altColor : null,
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
