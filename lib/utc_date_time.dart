// Copyright (C) 2026 Johannes Feichter
class UtcDateTime extends DateTime {
  UtcDateTime(
    super.year, [
    super.month,
    super.day,
    super.hour,
    super.minute,
    super.second,
    super.millisecond,
    super.microsecond,
  ]) : super.utc();

  factory UtcDateTime.parse(String date) {
    final normalDate = DateTime.parse(date);
    return UtcDateTime.makeUtc(normalDate);
  }

  static UtcDateTime? tryParse(String date) {
    final normalDate = DateTime.tryParse(date);
    if (normalDate == null) {
      return null;
    }
    return UtcDateTime.makeUtc(normalDate);
  }

  factory UtcDateTime.makeUtc(DateTime date) {
    return UtcDateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
  factory UtcDateTime.now() {
    return UtcDateTime.makeUtc(DateTime.now());
  }

  @override
  UtcDateTime subtract(Duration duration) {
    return super.subtract(duration).makeUtc();
  }

  @override
  UtcDateTime add(Duration duration) {
    return super.add(duration).makeUtc();
  }

  /// The same wall-clock time as a real local [DateTime]. The fields hold the
  /// portal's local time, so [millisecondsSinceEpoch] is off by the device's
  /// UTC offset; anything handing an instant to the system needs this.
  DateTime toWallClock() => DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
        millisecond,
        microsecond,
      );

  UtcDateTime stripTime() {
    return UtcDateTime(
      year,
      month,
      day,
    );
  }
}

extension MakeUtc on DateTime {
  UtcDateTime makeUtc() {
    return UtcDateTime.makeUtc(this);
  }
}
