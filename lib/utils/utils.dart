export 'constants/constants.dart';
export 'access_override.dart';
export 'offline_content_access.dart';
export 'init.dart';
export 'snackbar_utils.dart';
export 'share_utils.dart';
export 'navigation_utils.dart';
export 'image_picker_permissions.dart';
export 'labels.dart';
export 'ethiopian_time.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);

String toAgoDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) {
    return 'just now';
  } else if (diff.inHours < 1) {
    return '${diff.inMinutes}m';
  } else if (diff.inDays < 1) {
    return '${diff.inHours}h';
  } else {
    return '${diff.inDays}d';
  }
}
