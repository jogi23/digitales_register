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

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirrors the Redux `AppState.isDemo` flag so Riverpod widgets can react
/// without depending on the Redux store.
///
/// Updated by the login middleware whenever the logged-in user changes.
final isDemoProvider = StateProvider<bool>((ref) => false);
