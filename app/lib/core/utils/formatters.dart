/// V8Ray 格式化工具
///
/// 提供各种数据格式化功能

/// 格式化工具类
class Formatters {
  Formatters._();

  /// 格式化字节大小
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final value = bytes / (1 << (i * 10));

    return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// 格式化速度（字节/秒）
  static String formatSpeed(int bytesPerSecond, {int decimals = 2}) {
    if (bytesPerSecond <= 0) return '0 B/s';

    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    final i = (bytesPerSecond.bitLength - 1) ~/ 10;
    final value = bytesPerSecond / (1 << (i * 10));

    return '${value.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// 格式化延迟（毫秒）
  static String formatLatency(int milliseconds) {
    if (milliseconds < 0) return '∞';
    if (milliseconds == 0) return '-';
    return '${milliseconds}ms';
  }

  /// 格式化时长
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// 格式化百分比
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// 格式化日期时间
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.day.toString().padLeft(2, '0')} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 截断字符串
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

