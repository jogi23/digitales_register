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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/services/message_export.dart';
import 'package:dr/ui/messages.dart';
import 'package:dr/ui/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesPageContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesState = ref.watch(messagesProvider);
    final noInternet = ref.watch(noInternetProvider);
    final signature =
        ref.watch(settingsProvider.select((s) => s.messageSignature));
    final view = ref.watch(messageListProvider);
    final list = ref.read(messageListProvider.notifier);
    return MessagesPage(
      state: messagesState,
      view: view,
      onCategory: list.showCategory,
      onSort: list.sortBy,
      onUnreadOnly: list.showUnreadOnly,
      onStarredOnly: list.showStarredOnly,
      // The same colour as the stars of the competence ratings.
      starColor: resolveStarColor(
        context,
        ref.watch(settingsProvider.select((s) => s.starColor)),
      ),
      onToggleStar: (message) =>
          ref.read(messagesProvider.notifier).toggleStar(message.id),
      onExport: (messages, format, {required bool share}) =>
          exportMessages(tr(context), messages, format, share: share),
      onArchive: (messages, {required bool archived}) => ref
          .read(messagesProvider.notifier)
          .setArchived(messages.map((m) => m.id), archived: archived),
      noInternet: noInternet,
      hasUnread: messagesState.messages.any((m) => m.isNew),
      onOpenFile: (file) =>
          ref.read(messagesProvider.notifier).openMessageFile(file),
      onMarkAsRead: (message) =>
          ref.read(messagesProvider.notifier).markAsRead(message.id),
      onReply: (message, {String? response, String? signature}) =>
          ref.read(messagesProvider.notifier).reply(
                message.id,
                response: response,
                signature: signature,
              ),
      signature: signature,
      onSignature: (name) =>
          ref.read(settingsProvider.notifier).setMessageSignature(name),
      onMarkAllAsRead: () =>
          ref.read(messagesProvider.notifier).markAllAsRead(),
      // Offline the pull restores the connection first (PullToRefresh).
      onRefresh: ref.read(messagesProvider.notifier).load,
    );
  }
}
