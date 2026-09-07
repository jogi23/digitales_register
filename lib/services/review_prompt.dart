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

import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's prompt, replaceable in tests.
ReviewPrompt reviewPrompt = ReviewPrompt();

/// What is known about earlier attempts to ask for a review.
class ReviewHistory {
  /// How often the app was opened, this launch included.
  final int launches;

  /// When the app was opened for the very first time.
  final DateTime firstLaunch;

  /// When the dialog was last requested, null while it never was.
  final DateTime? lastAsked;

  const ReviewHistory({
    required this.launches,
    required this.firstLaunch,
    this.lastAsked,
  });
}

/// Asked no earlier than this, so the app has had a chance to prove useful.
const minimumLaunches = 5;
const minimumAge = Duration(days: 3);

/// Play grants roughly one dialog per user and month; asking again sooner
/// only burns the quota.
const askAgainAfter = Duration(days: 90);

/// Whether it is a good moment to ask for a review.
///
/// Deliberately a plain function: the dialog itself cannot be tested — Play
/// decides whether it appears and reports nothing back — but the decision to
/// request one can be.
bool shouldAskForReview(ReviewHistory history, DateTime now) {
  if (history.launches < minimumLaunches) return false;
  if (now.difference(history.firstLaunch) < minimumAge) return false;

  final lastAsked = history.lastAsked;
  if (lastAsked == null) return true;
  return now.difference(lastAsked) >= askAgainAfter;
}

/// Counts launches and asks Play for the review dialog when the time is right.
class ReviewPrompt {
  static const _launchesKey = 'review_launches';
  static const _firstLaunchKey = 'review_first_launch';
  static const _lastAskedKey = 'review_last_asked';

  final InAppReview _review;

  ReviewPrompt({InAppReview? review})
      : _review = review ?? InAppReview.instance;

  /// Records that the app was opened. Call once per start.
  Future<void> recordLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final launches = (prefs.getInt(_launchesKey) ?? 0) + 1;
    await prefs.setInt(_launchesKey, launches);
    if (!prefs.containsKey(_firstLaunchKey)) {
      await prefs.setString(
        _firstLaunchKey,
        DateTime.now().toIso8601String(),
      );
    }
  }

  Future<ReviewHistory> history() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getString(_firstLaunchKey);
    final lastAsked = prefs.getString(_lastAskedKey);
    return ReviewHistory(
      launches: prefs.getInt(_launchesKey) ?? 0,
      firstLaunch:
          firstLaunch != null ? DateTime.parse(firstLaunch) : DateTime.now(),
      lastAsked: lastAsked != null ? DateTime.parse(lastAsked) : null,
    );
  }

  /// Requests the dialog when the moment fits. Does nothing otherwise.
  ///
  /// Whether it is actually shown is Play's decision and stays unknown, so
  /// the attempt is recorded either way — that is what the interval counts.
  Future<void> maybeAsk({DateTime? now}) async {
    if (!shouldAskForReview(await history(), now ?? DateTime.now())) return;
    if (!await _review.isAvailable()) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastAskedKey,
      (now ?? DateTime.now()).toIso8601String(),
    );
    await _review.requestReview();
  }
}
