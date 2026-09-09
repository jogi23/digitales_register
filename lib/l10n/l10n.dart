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

import 'package:dr/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:dr/l10n/app_localizations.dart' show L;

/// The languages the app is translated into.
///
/// German is the template the other two are translated from, so it is also
/// what an unsupported device language falls back to.
const supportedLanguages = <String>['de', 'it', 'en'];

/// What each language calls itself, for the picker in the settings.
const languageNames = <String, String>{
  'de': 'Deutsch',
  'it': 'Italiano',
  'en': 'English',
};

/// The translations, for widgets that have a [BuildContext].
L tr(BuildContext context) => L.of(context);

/// The translations for code that has none — middleware and providers that
/// put a message on the screen without ever touching the widget tree.
///
/// Set once the app is built and kept up to date when the language changes.
late L trGlobal;

/// Remembers the translations for [trGlobal]. Called from the app's builder.
void rememberTranslations(BuildContext context) {
  trGlobal = L.of(context);
}
