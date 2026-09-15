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

import 'dart:convert';

import 'package:badges/badges.dart' as badge;
import 'package:dr/app_state.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/data.dart';
import 'package:dr/providers/messages_provider.dart'
    show MessageListView, MessageSort;
import 'package:dr/services/message_export.dart' show MessageExportFormat;
import 'package:dr/ui/animated_linear_progress_indicator.dart';
import 'package:dr/ui/connection_status_button.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:dr/ui/pull_to_refresh.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:dr/util.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:quill_delta_viewer/quill_delta_viewer.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

class MessagesPage extends StatefulWidget {
  final MessagesState? state;

  /// Folder, order and filters; the list shows what this lets through.
  final MessageListView view;
  final ValueChanged<MessageCategory> onCategory;
  final ValueChanged<MessageSort> onSort;
  final ValueChanged<bool> onUnreadOnly;
  final ValueChanged<bool> onStarredOnly;

  /// The colour a set star is drawn in.
  final Color starColor;
  final void Function(Message message) onToggleStar;

  /// Shares the messages as one file, or saves it with `share` false.
  final Future<void> Function(
    List<Message> messages,
    MessageExportFormat format, {
    required bool share,
  }) onExport;

  /// Moves the messages into the archive, or back out with `archived` false.
  /// False means not every move went through.
  final Future<bool> Function(List<Message> messages, {required bool archived})
      onArchive;
  final bool noInternet;
  final bool hasUnread;
  final void Function(MessageAttachmentFile message) onOpenFile;
  final void Function(Message message) onMarkAsRead;
  /// Answers a message; false means the answer did not reach the server.
  final Future<bool> Function(Message message,
      {String? response, String? signature}) onReply;
  final VoidCallback onMarkAllAsRead;
  final Future<void> Function() onRefresh;

  /// The name last signed with, filled into the field so it is not typed
  /// again, and handed back whenever a new one is used.
  final String? signature;
  final void Function(String signature) onSignature;

  const MessagesPage({
    super.key,
    required this.state,
    required this.view,
    required this.onCategory,
    required this.onSort,
    required this.onUnreadOnly,
    required this.onStarredOnly,
    required this.starColor,
    required this.onToggleStar,
    required this.onExport,
    required this.onArchive,
    required this.noInternet,
    required this.hasUnread,
    required this.onOpenFile,
    required this.onMarkAsRead,
    required this.onReply,
    required this.onMarkAllAsRead,
    required this.onRefresh,
    required this.signature,
    required this.onSignature,
  });

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  /// The ids picked for a common action. The page is in selection mode while
  /// any of them is in the list.
  var _selected = <int>{};

  @override
  void didUpdateWidget(MessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.view;
    final now = widget.view;
    // Another folder or filter shows other messages: an action would reach
    // ones the reader no longer sees.
    if (now.category != before.category ||
        now.unreadOnly != before.unreadOnly ||
        now.starredOnly != before.starredOnly) {
      _selected = {};
    }
  }

  void _toggle(Message message) => setState(() {
        if (!_selected.remove(message.id)) _selected.add(message.id);
      });

  void _endSelection() => setState(() => _selected = {});

  Future<void> _export(
    List<Message> messages,
    MessageExportFormat format, {
    required bool share,
  }) async {
    _endSelection();
    await widget.onExport(messages, format, share: share);
  }

  Future<void> _archive(
    List<Message> messages, {
    required bool archived,
  }) async {
    final failed = tr(context).messagesArchiveFailed;
    _endSelection();
    if (!await widget.onArchive(messages, archived: archived)) {
      showSnackBar(failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final visible = state == null
        ? const <Message>[]
        : widget.view.apply(state.messages, state.starred);
    // Only what is in the list counts: a message archived or filtered away
    // drops out of the selection.
    final selected = [
      for (final message in visible)
        if (_selected.contains(message.id)) message,
    ];
    return PopScope(
      // Back ends a selection before it leaves the page.
      canPop: selected.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelection();
      },
      child: Scaffold(
        appBar: selected.isEmpty
            ? _appBar(context)
            : _selectionBar(context, visible, selected),
        body: PullToRefresh(
          onRefresh: widget.onRefresh,
          child: state == null
              ? widget.noInternet
                  ? const NoInternet()
                  : const Center(child: CircularProgressIndicator())
              : _list(
                  context,
                  state,
                  visible,
                  selecting: selected.isNotEmpty,
                ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return ResponsiveAppBar(
      title: Text(tr(context).messagesTitle),
      actions: [
        PopupMenuButton<MessageSort>(
          icon: const Icon(Icons.sort),
          tooltip: tr(context).messagesSort,
          initialValue: widget.view.sort,
          onSelected: widget.onSort,
          itemBuilder: (context) => [
            for (final sort in MessageSort.values)
              CheckedPopupMenuItem(
                value: sort,
                checked: sort == widget.view.sort,
                child: Text(switch (sort) {
                  MessageSort.newest => tr(context).messagesSortNewest,
                  MessageSort.oldest => tr(context).messagesSortOldest,
                  MessageSort.sender => tr(context).messagesSortSender,
                }),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: tr(context).messagesMarkAllRead,
          onPressed: widget.hasUnread ? widget.onMarkAllAsRead : null,
        ),
        const ConnectionStatusButton(),
        const AccountAvatarButton(),
      ],
    );
  }

  PreferredSizeWidget _selectionBar(
    BuildContext context,
    List<Message> visible,
    List<Message> selected,
  ) {
    final l = tr(context);
    Widget exportMenu({required bool share}) =>
        PopupMenuButton<MessageExportFormat>(
          icon: Icon(share ? Icons.share : Icons.download),
          tooltip: share ? l.commonShare : l.commonSave,
          onSelected: (format) => _export(selected, format, share: share),
          itemBuilder: (context) => [
            for (final format in MessageExportFormat.values)
              PopupMenuItem(
                value: format,
                child: Text(switch (format) {
                  MessageExportFormat.pdf => l.messagesExportPdf,
                  MessageExportFormat.text => l.messagesExportText,
                  MessageExportFormat.markdown => l.messagesExportMarkdown,
                }),
              ),
          ],
        );
    return ResponsiveAppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l.messagesEndSelection,
        onPressed: _endSelection,
      ),
      title: Text(l.messagesSelected(selected.length)),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: l.messagesSelectAll,
          onPressed: selected.length == visible.length
              ? null
              : () => setState(() => _selected = {for (final m in visible) m.id}),
        ),
        exportMenu(share: true),
        exportMenu(share: false),
        // Only the moves a picked message allows. Both go to the server.
        if (selected.any((m) => m.canArchive))
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: l.messagesArchive,
            onPressed: widget.noInternet
                ? null
                : () => _archive(selected, archived: true),
          ),
        if (selected.any((m) => m.canRestore))
          IconButton(
            icon: const Icon(Icons.unarchive_outlined),
            tooltip: l.messagesRestore,
            onPressed: widget.noInternet
                ? null
                : () => _archive(selected, archived: false),
          ),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    MessagesState state,
    List<Message> visible, {
    required bool selecting,
  }) {
    final altColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageListBar(
          view: widget.view,
          onCategory: widget.onCategory,
          onUnreadOnly: widget.onUnreadOnly,
          onStarredOnly: widget.onStarredOnly,
        ),
        const Divider(),
        Expanded(
          child: Stack(
            children: <Widget>[
              AnimatedLinearProgressIndicator(
                show: state.showMessage != null &&
                    !state.messages.any((m) => m.id == state.showMessage),
              ),
              if (visible.isEmpty)
                Center(
                  child: Text(
                    state.messages.isEmpty
                        ? tr(context).messagesEmpty
                        : tr(context).messagesCategoryEmpty,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: context.systemInsets,
                itemCount: visible.length,
                itemBuilder: (context, i) {
                  final message = visible[i];
                  return MessageWidget(
                    // Keyed by id: switching folders moves messages to other
                    // rows, and each tile keeps whether it started open.
                    key: ValueKey(message.id),
                    message: message,
                    selecting: selecting,
                    selected: _selected.contains(message.id),
                    onSelect: () => _toggle(message),
                    starred: state.starred.contains(message.id),
                    starColor: widget.starColor,
                    onToggleStar: () => widget.onToggleStar(message),
                    onOpenFile: widget.onOpenFile,
                    onMarkAsRead: widget.onMarkAsRead,
                    onReply: widget.onReply,
                    signature: widget.signature,
                    onSignature: widget.onSignature,
                    noInternet: widget.noInternet,
                    expand: message.id == state.showMessage,
                    tileColor: i.isOdd ? altColor : null,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Picks the folder the message list shows, the way the portal sorts its
/// messages, and narrows it to unread or starred ones.
class MessageListBar extends StatelessWidget {
  final MessageListView view;
  final ValueChanged<MessageCategory> onCategory;
  final ValueChanged<bool> onUnreadOnly;
  final ValueChanged<bool> onStarredOnly;

  const MessageListBar({
    super.key,
    required this.view,
    required this.onCategory,
    required this.onUnreadOnly,
    required this.onStarredOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final category in MessageCategory.values)
            ChoiceChip(
              label: Text(_label(context, category)),
              selected: category == view.category,
              showCheckmark: false,
              onSelected: (_) => onCategory(category),
            ),
          // Filters apply on top of the folder; their icons set them apart
          // from the folders, of which only one can be picked.
          FilterChip(
            avatar: const Icon(Icons.mark_email_unread_outlined),
            label: Text(tr(context).messagesFilterUnread),
            selected: view.unreadOnly,
            showCheckmark: false,
            onSelected: onUnreadOnly,
          ),
          FilterChip(
            avatar: const Icon(Icons.star_border),
            label: Text(tr(context).messagesFilterStarred),
            selected: view.starredOnly,
            showCheckmark: false,
            onSelected: onStarredOnly,
          ),
        ],
      ),
    );
  }

  static String _label(BuildContext context, MessageCategory category) =>
      switch (category) {
        MessageCategory.incoming => tr(context).messagesCategoryIncoming,
        MessageCategory.outgoing => tr(context).messagesCategoryOutgoing,
        MessageCategory.archived => tr(context).messagesCategoryArchived,
        MessageCategory.all => tr(context).messagesCategoryAll,
      };
}

class MessageWidget extends StatefulWidget {
  final Message message;

  /// While messages are being picked, a tap picks this one instead of
  /// opening it.
  final bool selecting;
  final bool selected;

  /// Picks or unpicks the message; a long press starts picking.
  final VoidCallback onSelect;
  final bool starred;
  final Color starColor;
  final VoidCallback onToggleStar;
  final void Function(MessageAttachmentFile message) onOpenFile;
  final void Function(Message message) onMarkAsRead;
  final Future<bool> Function(Message message,
      {String? response, String? signature}) onReply;
  final String? signature;
  final void Function(String signature) onSignature;
  final bool noInternet;
  final bool expand;
  final Color? tileColor;

  const MessageWidget({
    super.key,
    required this.message,
    required this.selecting,
    required this.selected,
    required this.onSelect,
    required this.starred,
    required this.starColor,
    required this.onToggleStar,
    required this.onOpenFile,
    required this.noInternet,
    required this.onMarkAsRead,
    required this.onReply,
    required this.signature,
    required this.onSignature,
    required this.expand,
    this.tileColor,
  });

  @override
  _MessageWidgetState createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  late final bool initiallyExpanded;
  final ExpansibleController _controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
    initiallyExpanded = widget.expand;
    if (initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) widget.onMarkAsRead(widget.message); },
      );
    }
  }

  @override
  void didUpdateWidget(MessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expand && !oldWidget.expand) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.expand();
        widget.onMarkAsRead(widget.message);
      });
    }
  }

  Widget _title(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            widget.message.subject,
            // Italic and a size down for one's own messages: under "All"
            // they should not catch the eye like the ones received.
            style: (widget.message.outgoing
                    ? textTheme.titleSmall
                        ?.copyWith(fontStyle: FontStyle.italic)
                    : textTheme.titleMedium)
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        // Sent and received looked alike, so one's own message read as
        // something to act on.
        if (widget.message.outgoing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: MessageSentChip(),
          ),
        // Visible while the tile is closed: the section below is only
        // built once it opens, so nothing said the message wanted anything.
        if (widget.message.responseInfo?.openAction case final action?
            when action != MessageAction.none)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MessageActionChip(action: action),
          ),
        if (widget.message.isNew)
          badge.Badge(
            badgeStyle: badge.BadgeStyle(
              shape: badge.BadgeShape.square,
              borderRadius: BorderRadius.circular(20),
            ),
            badgeContent: const Text(
              "neu",
              style: TextStyle(color: Colors.white),
            ),
          ),
        // In the title rather than the opened message: marking should not
        // take opening, and so marking as read, first.
        IconButton(
          icon: Icon(
            widget.starred ? Icons.star : Icons.star_border,
            color: widget.starred ? widget.starColor : null,
          ),
          tooltip: widget.starred
              ? tr(context).messageUnstar
              : tr(context).messageStar,
          visualDensity: VisualDensity.compact,
          onPressed: widget.onToggleStar,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selecting) {
      // While picking, a tap picks: the tile neither opens nor marks the
      // message read.
      return ListTile(
        tileColor: widget.tileColor,
        selected: widget.selected,
        leading: Checkbox(
          value: widget.selected,
          onChanged: (_) => widget.onSelect(),
        ),
        title: _title(context),
        onTap: widget.onSelect,
        onLongPress: widget.onSelect,
      );
    }
    return ExpansionTile(
      controller: _controller,
      initiallyExpanded: initiallyExpanded,
      backgroundColor: widget.tileColor,
      collapsedBackgroundColor: widget.tileColor,
      onExpansionChanged: (expanded) {
        if (expanded && widget.message.isNew) {
          widget.onMarkAsRead(widget.message);
        }
      },
      // A long press starts picking messages for a common action; a tap still
      // reaches the tile and opens it.
      title: GestureDetector(
        onLongPress: widget.onSelect,
        child: _title(context),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ).copyWith(
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr(context).messagesSent,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                        text: DateFormat("d.M.yy H:mm")
                            .format(widget.message.timeSent))
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr(context).messagesFrom,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.message.fromName)
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tr(context).messagesTo,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.message.recipientString)
                  ],
                ),
              ),
              const Divider(),
              renderMessage(widget.message.text, context),
              if (widget.message.attachments.isNotEmpty) ...[
                const Divider(),
                Text(
                  widget.message.attachments.length > 1
                      ? tr(context).messagesAttachments
                      : tr(context).messagesAttachment,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
              ...[
                for (final attachment in widget.message.attachments)
                  [
                    Text(
                      attachment.originalName,
                    ),
                    AnimatedLinearProgressIndicator(
                      show: attachment.downloading,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed:
                            !attachment.fileAvailable && widget.noInternet
                                ? null
                                : () {
                                    widget.onOpenFile(attachment);
                                  },
                        child: const Text("Öffnen"),
                      ),
                    ),
                  ]
              ].intersperse(const Divider()),
              if (widget.message.responseInfo case final info?) ...[
                const Divider(),
                MessageResponseSection(
                  info: info,
                  noInternet: widget.noInternet,
                  signature: widget.signature,
                  onSignature: widget.onSignature,
                  onReply: ({String? response, String? signature}) =>
                      widget.onReply(
                    widget.message,
                    response: response,
                    signature: signature,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Renders the confirmation a message asks for: two buttons, a signature
/// field, or both.
///
/// Mirrors the portal: the buttons hang off the response type, the signature
/// field off [MessageResponseInfo.signatureRequired], and an empty signature
/// blocks sending.
class MessageResponseSection extends StatefulWidget {
  final MessageResponseInfo info;
  final bool noInternet;
  final Future<bool> Function({String? response, String? signature}) onReply;

  /// The name signed with last time, prefilled here.
  final String? signature;
  final void Function(String signature) onSignature;

  const MessageResponseSection({
    super.key,
    required this.info,
    required this.noInternet,
    required this.onReply,
    required this.signature,
    required this.onSignature,
  });

  @override
  State<MessageResponseSection> createState() => _MessageResponseSectionState();
}

class _MessageResponseSectionState extends State<MessageResponseSection> {
  late final TextEditingController _signature =
      TextEditingController(text: widget.signature ?? '');

  /// True while the answer is on its way. It goes back to false when the
  /// answer did not arrive: the earlier version left the button disabled
  /// either way, so a failure looked exactly like a confirmation.
  bool _sending = false;
  bool _sent = false;
  bool _failed = false;

  @override
  void dispose() {
    _signature.dispose();
    super.dispose();
  }

  bool get _canSend {
    if (_sending || _sent || widget.noInternet) return false;
    // The portal only checks for a non-empty name, it does not match it
    // against the account.
    return !widget.info.showSignatureField ||
        _signature.text.trim().isNotEmpty;
  }

  Future<void> _send(String? response) async {
    final signature =
        widget.info.showSignatureField ? _signature.text.trim() : null;
    setState(() {
      _sending = true;
      _failed = false;
    });
    final answered = await widget.onReply(
      response: response,
      signature: signature,
    );
    if (signature != null && signature.isNotEmpty && answered) {
      widget.onSignature(signature);
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = answered;
      _failed = !answered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final theme = Theme.of(context);

    if (info.answered) {
      return _Hint(info.historyText ?? info.badge ?? tr(context).messageAlreadyConfirmed);
    }
    if (info.parentSignatureRequired) {
      return _Hint(tr(context).messageParentOnly);
    }
    if (info.unsupported) {
      return _Hint(tr(context).messageUnsupported);
    }

    // Set apart from the message text: this is the one place on the page
    // that asks for something, and it looked like the rest of it.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _controls(context, info, theme),
      ),
    );
  }

  Widget _controls(
    BuildContext context,
    MessageResponseInfo info,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info.badge != null)
          Text(info.badge!, style: theme.textTheme.labelLarge),
        if (_failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tr(context).messageReplyFailed,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (info.showSignatureField) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _signature,
            enabled: !_sent && !_sending,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: tr(context).messageSignaturePrompt,
              // Says why the button below is still grey.
              helperText: _signature.text.trim().isEmpty
                  ? tr(context).messageSignatureHelper
                  : null,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 8),
        if (info.showAgreeButtons)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _canSend
                    ? () => _send(MessageResponseInfo.answerNotAgree)
                    : null,
                child: Text(tr(context).messageDisagree),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _canSend
                    ? () => _send(MessageResponseInfo.answerAgree)
                    : null,
                child: Text(tr(context).messageAgree),
              ),
            ],
          )
        else
          // Full width with an icon: the button that binds the reader should
          // not weigh the same as any other on the page.
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                textStyle: theme.textTheme.titleMedium,
              ),
              onPressed: _canSend ? () => _send(null) : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.draw),
                  const SizedBox(width: 8),
                  Text(tr(context).messageConfirm),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Marks a message that still waits for its reader, visible with the tile
/// closed.
///
/// Two looks for the two things a message can ask: a name to sign with, or a
/// yes or no. One shared "action needed" mark would leave the reader guessing
/// which until the message is opened. Colour is not the only difference —
/// icon and wording differ too — and the tile background stays free for the
/// alternating rows.
class MessageActionChip extends StatelessWidget {
  final MessageAction action;

  const MessageActionChip({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label, background, foreground) = switch (action) {
      MessageAction.confirm => (
          Icons.draw_outlined,
          tr(context).messageActionConfirm,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      MessageAction.agree => (
          Icons.thumbs_up_down_outlined,
          tr(context).messageActionAgree,
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
        ),
      MessageAction.none => (null, null, null, null),
    };
    if (icon == null || label == null) return const SizedBox.shrink();

    return _LabelChip(
      icon: icon,
      label: label,
      background: background,
      foreground: foreground,
    );
  }
}

/// Marks a message this account sent, so it does not pass for one received.
///
/// A chip beside the subject like the other marks, rather than a tile colour:
/// the background already alternates between rows.
class MessageSentChip extends StatelessWidget {
  const MessageSentChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _LabelChip(
      icon: Icons.outbox_outlined,
      label: tr(context).messageOutgoing,
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
    );
  }
}

/// The small rounded label the message list marks tiles with.
class _LabelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? background;
  final Color? foreground;

  const _LabelChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
    );
  }
}

Widget renderMessage(String msg, BuildContext context) {
  return QuillDeltaViewer(
      delta: Delta.fromJson(jsonDecode(msg)["ops"] as List));
}
