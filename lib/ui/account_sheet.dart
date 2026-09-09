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

import 'dart:io';

import 'package:dr/providers/account_profile_provider.dart';
import 'package:dr/providers/config_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/util.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Drops the account card down from the top of the screen.
///
/// It belongs to the avatar in the app bar, so it comes from where that
/// avatar sits rather than from the far edge of the screen.
Future<void> showAccountSheet(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: tr(context).accountSheetClose,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => const AccountSheet(),
    transitionBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}

class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key});

  @override
  ConsumerState<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  late TextEditingController _aliasController;
  bool _saving = false;
  bool _editingAlias = false;

  @override
  void initState() {
    super.initState();
    final login = ref.read(loginProvider);
    final key = accountProfileKey(login.username ?? '', login.url ?? '');
    final profile = ref.read(accountProfileProvider)[key] ?? const AccountProfile();
    _aliasController = TextEditingController(text: profile.alias ?? '');
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  String get _currentKey {
    final login = ref.read(loginProvider);
    return accountProfileKey(login.username ?? '', login.url ?? '');
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/account_photos');
    await photosDir.create(recursive: true);

    // Sanitize key so it's safe as a filename on all platforms.
    final safeKey = _currentKey.replaceAll(RegExp(r'[^\w.-]'), '_');
    final ext = picked.path.split('.').last;
    final dest = '${photosDir.path}/$safeKey.$ext';
    await File(picked.path).copy(dest);

    await ref.read(accountProfileProvider.notifier).setPhoto(_currentKey, dest);
  }

  Future<void> _saveAlias(String value) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _editingAlias = false;
    });
    await ref
        .read(accountProfileProvider.notifier)
        .setAlias(_currentKey, value.trim().isEmpty ? null : value.trim());
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginProvider);
    final config = ref.watch(configProvider);
    final profiles = ref.watch(accountProfileProvider);
    final settings = ref.watch(settingsProvider);

    final username = login.username ?? '';
    final url = login.url ?? '';
    final key = accountProfileKey(username, url);
    final profile = profiles[key] ?? const AccountProfile();
    final displayName = config?.fullName ?? username;
    final canAddAccount = !settings.noPasswordSaving;

    final media = MediaQuery.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        // The keyboard, when the alias is being edited, must not push the
        // card off the top; it only limits how tall the card may get.
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCurrentAccountSection(context, profile, displayName),
                      const SizedBox(height: 16),
                      _buildAliasRow(context, profile),
                      if (login.otherAccounts.isNotEmpty) ...[
                        const Divider(height: 32),
                        _buildOtherAccountsList(context, login, profiles),
                      ],
                      const Divider(height: 32),
                      _buildAddAccountButton(context, canAddAccount),
                      const SizedBox(height: 16),
                      // At the bottom now: that is the edge the card can be
                      // pulled back towards.
                      _buildHandle(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildCurrentAccountSection(
    BuildContext context,
    AccountProfile profile,
    String displayName,
  ) =>
      Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildLargeAvatar(context, profile, displayName, radius: 40),
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.edit,
                      size: 13,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_saving)
            const SizedBox(
              height: 2,
              child: LinearProgressIndicator(),
            ),
        ],
      );

  Widget _buildAliasRow(BuildContext context, AccountProfile profile) {
    if (_editingAlias) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _aliasController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Alias',
                hintText: 'Kurzname für diesen Account',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: _saveAlias,
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final background = Theme.of(context).colorScheme.primary;
              return IconButton.filled(
                onPressed: () => _saveAlias(_aliasController.text),
                icon: const Icon(Icons.check),
                tooltip: tr(context).accountConfirmAlias,
                // Spelled out rather than left to the theme: the derived
                // pairing left the check mark barely visible on the accent.
                style: IconButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: readableOn(background),
                ),
              );
            },
          ),
        ],
      );
    }

    final aliasText = profile.alias;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            aliasText ?? 'Alias setzen',
            textAlign: TextAlign.center,
            style: aliasText != null
                ? Theme.of(context).textTheme.bodyLarge
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
          ),
        ),
        IconButton(
          onPressed: () {
            _aliasController.text = profile.alias ?? '';
            setState(() => _editingAlias = true);
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: tr(context).accountEditAlias,
        ),
      ],
    );
  }

  Widget _buildOtherAccountsList(
    BuildContext context,
    LoginState login,
    Map<String, AccountProfile> profiles,
  ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Andere Konten',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < login.otherAccounts.length; i++)
            _buildOtherAccountTile(context, login.otherAccounts[i], profiles, i),
        ],
      );

  Widget _buildOtherAccountTile(
    BuildContext context,
    OtherAccount account,
    Map<String, AccountProfile> profiles,
    int index,
  ) {
    final key = accountProfileKey(account.username, account.url);
    final profile = profiles[key] ?? const AccountProfile();
    final display = profile.alias ?? account.username;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _buildLargeAvatar(context, profile, account.username, radius: 18),
      title: Text(display),
      subtitle: display != account.username ? Text(account.username) : null,
      onTap: () {
        Navigator.pop(context);
        ref.read(loginProvider.notifier).selectAccount(index);
      },
    );
  }

  Widget _buildAddAccountButton(BuildContext context, bool canAddAccount) =>
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: canAddAccount
              ? () {
                  Navigator.pop(context);
                  ref.read(loginProvider.notifier).addAccount();
                }
              : null,
          icon: const Icon(Icons.person_add_outlined),
          label: Text(
            canAddAccount
                ? 'Konto hinzufügen'
                : 'Konto wechseln (Passwort-Speicherung deaktiviert)',
          ),
        ),
      );

  Widget _buildLargeAvatar(
    BuildContext context,
    AccountProfile profile,
    String fallbackName, {
    required double radius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    if (profile.photoPath != null) {
      final file = File(profile.photoPath!);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      }
    }
    final initials = accountInitials(profile.alias ?? fallbackName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.55,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}


