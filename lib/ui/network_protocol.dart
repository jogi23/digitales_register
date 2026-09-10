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
import 'package:dr/main.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NetworkProtocol extends StatelessWidget {
  final List<NetworkProtocolItem> items;

  const NetworkProtocol({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    return items.isEmpty
        ? Center(
            child: Text(tr(context).networkNothing),
          )
        : ListView.builder(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _Item(
                item: items[index],
              );
            },
          );
  }
}

class _Item extends StatelessWidget {
  final NetworkProtocolItem item;

  static final _time = DateFormat("HH:mm:ss");

  const _Item({required this.item});
  @override
  Widget build(BuildContext context) {
    final error = item.error;
    return ExpansionTile(
      title: Text(item.address),
      // The time is what lets a reader line an entry up with what they just
      // did; without it the log cannot answer "did that tap send anything?".
      subtitle: Text(_time.format(item.timestamp)),
      children: <Widget>[
        if (error != null)
          _Detail(type: tr(context).networkError, content: error),
        _Detail(
          type: tr(context).networkParameters,
          content: item.parameters,
        ),
        _Detail(
          type: tr(context).networkResponse,
          content: item.response,
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  final String type;
  final String? content;

  const _Detail({required this.type, this.content});
  @override
  Widget build(BuildContext context) {
    final content = this.content ?? tr(context).networkNoneOfType(type);
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(type),
              IconButton(
                icon: const Icon(Icons.assignment),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: content));
                  showSnackBar(tr(context).networkCopied);
                },
              )
            ],
          ),
          Text(content),
        ],
      ),
    );
  }
}
