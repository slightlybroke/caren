import 'package:intl/intl.dart';

/// Clean date and time formatters for wellness logging.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _relativeDayFormat = DateFormat('EEEE, MMM d');

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);
  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);
  static String formatDayHeader(DateTime dateTime) => _relativeDayFormat.format(dateTime);

  static String formatDurationMinutes(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String formatTimer(int seconds) => formatDurationMinutes(seconds);
}

