
## 1.1.2

### Improvements
- Sidebar: swipe from left to open
- Calendar: "Current week" button is now always visible; disabled when already on the current week
- Notifications: "Open message" button now opens the specific message directly instead of the message list
- About screen: "What's new" link opens this changelog

## 1.1.1

### Bug Fixes
- Messages: messages were shown as unread again after restart, screen switch, or account switch — fixed

### New Features
- Messages: "Mark all as read" button in the AppBar
- Messages: pull down to refresh; when offline, pull down to attempt reconnection

## 1.1.0

### Internal Changes
- State management fully migrated to Riverpod (Redux removed)
- Settings and subject themes simplified internally (built_value partially removed)

## 1.0.2

### Changes
- Certificate view internally migrated to Riverpod

## 1.0.1

### Bug Fixes
- Homework tab in the sidebar is now visible on all platforms (including Android)
- Calendar: subject colors now display correctly (crash on missing theme fixed)
- Grades: page title unified

## 1.0.0

This app is a continuation of the original project by Michael Debertol and Simon Wachtler.
Many thanks for the great work!

### Changes
- App accent color can now be customized in settings
- Sidebar: "Hausaufgaben" renamed to "Merkheft"
- Sidebar: "Noten" renamed to "Bewertungen"
- Feedback button now opens an email directly
- Calendar: overflow error in landscape mode fixed
- Calendar: loading indicator is now accessible (screen reader label)
- Calendar view: attachment button is now labelled for accessibility
- Absences: colors now adapt to the selected theme
- Home screen: FAB colors and tooltips updated for better accessibility
- Error messages and "No internet" display now use theme colors instead of hardcoded red
- `WillPopScope` replaced with `PopScope` (Flutter deprecation resolved)
