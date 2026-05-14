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

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/ui/homework_filter.dart';
import 'package:flutter/material.dart' hide Builder;
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'homework_filter_container.g.dart';

class HomeworkFilterContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blacklist = ref.watch(dashboardProvider.select((s) => s.blacklist!));
    final notifier = ref.read(dashboardProvider.notifier);
    return HomeworkFilter(
      vm: HomeworkFilterVM(
        (b) => b
          ..currentBlacklist = blacklist.toBuilder()
          ..allTypes = HomeworkType.values.toBuilder(),
      ),
      callback: (list) => notifier.updateBlacklist(list.build()),
    );
  }
}

abstract class HomeworkFilterVM
    implements Built<HomeworkFilterVM, HomeworkFilterVMBuilder> {
  BuiltList<HomeworkType> get currentBlacklist;
  BuiltSet<HomeworkType> get allTypes;

  factory HomeworkFilterVM([void Function(HomeworkFilterVMBuilder)? updates]) =
      _$HomeworkFilterVM;
  HomeworkFilterVM._();
}
