// Copyright (C) 2021 Michael Debertol
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

import 'package:dr/actions/app_actions.dart';
import 'package:dr/app_state.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/ui/notifications_page.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_built_redux/flutter_built_redux.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPageContainer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final noInternet = ref.watch(noInternetProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    return StoreConnection<AppState, AppActions, void>(
      connect: (_) {},
      builder: (context, _, actions) => NotificationPage(
        notifications: state.notifications,
        noInternet: noInternet,
        deleteNotification: notifier.delete,
        deleteAllNotifications: notifier.deleteAll,
        goToMessage: actions.routingActions.showMessage.call,
        lastFetched: state.lastFetched,
      ),
    );
  }
}
