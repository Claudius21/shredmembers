import 'package:intl/intl.dart';

extension DateTimeFormatWithOffset on DateTime {
  /// Formats the UTC DateTime in the timezone described by [offsetMinutes].
  ///
  /// This is useful for an international app: we store the timestamp as UTC
  /// but we also stored the original device timezone offset when the workout
  /// happened, so we can display the date/time exactly as it was for the user
  /// at that moment.
  String formatWithOffset(String pattern, int? offsetMinutes) {
    if (offsetMinutes == null) {
      return DateFormat(pattern).format(this);
    }
    final shifted = toUtc().add(Duration(minutes: offsetMinutes));
    return DateFormat(pattern).format(
      DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
        shifted.second,
      ),
    );
  }
}
