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

import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesPageContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesState = ref.watch(messagesProvider);
    final noInternet = ref.watch(noInternetProvider);
    return MessagesPage(
      state: messagesState,
      noInternet: noInternet,
      hasUnread: messagesState.messages.any((m) => m.timeRead == null),
      onOpenFile: (file) =>
          ref.read(messagesProvider.notifier).openMessageFile(file),
      onMarkAsRead: (message) =>
          ref.read(messagesProvider.notifier).markAsRead(message.id),
      onMarkAllAsRead: () =>
          ref.read(messagesProvider.notifier).markAllAsRead(),
      onRefresh: () => noInternet
          ? ref.read(noInternetProvider.notifier).refresh()
          : ref.read(messagesProvider.notifier).load(),
    );
  }
}
