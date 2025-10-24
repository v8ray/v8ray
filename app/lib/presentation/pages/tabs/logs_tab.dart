/// V8Ray 日志查看标签页
///
/// 显示应用日志，支持过滤和搜索

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/responsive.dart';

/// 日志级别枚举
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}

/// 日志查看标签页
class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({super.key});

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  LogLevel? _filterLevel;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  // 模拟日志数据
  final List<LogEntry> _logs = [
    LogEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      level: LogLevel.info,
      message: 'Application started successfully',
    ),
    LogEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      level: LogLevel.info,
      message: 'Loading configuration from file',
    ),
    LogEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      level: LogLevel.debug,
      message: 'Initializing Xray Core',
    ),
    LogEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      level: LogLevel.warning,
      message: 'Connection timeout, retrying...',
    ),
    LogEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      level: LogLevel.error,
      message: 'Failed to connect to server: Connection refused',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 过滤日志
    var filteredLogs = _logs;
    
    if (_filterLevel != null) {
      filteredLogs = filteredLogs.where((log) => log.level == _filterLevel).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) {
        return log.message.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Column(
      children: [
        // 工具栏
        _buildToolbar(context, l10n),
        
        // 日志列表
        Expanded(
          child: filteredLogs.isEmpty
              ? _buildEmptyState(context, l10n)
              : _buildLogList(context, l10n, filteredLogs),
        ),
      ],
    );
  }

  /// 构建工具栏
  Widget _buildToolbar(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(
        Responsive(context).valueWhen(
          mobile: UIConstants.defaultPadding,
          tablet: UIConstants.largePadding,
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 搜索框和操作按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _logs.clear();
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: Text(l10n.clearLogs),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  // TODO: 实现导出日志功能
                },
                icon: const Icon(Icons.download),
                label: Text(l10n.exportLogs),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 日志级别过滤
          Row(
            children: [
              Text(
                '${l10n.logLevel}: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              SegmentedButton<LogLevel?>(
                segments: [
                  ButtonSegment(value: null, label: Text(l10n.all)),
                  const ButtonSegment(value: LogLevel.debug, label: Text('DEBUG')),
                  const ButtonSegment(value: LogLevel.info, label: Text('INFO')),
                  const ButtonSegment(value: LogLevel.warning, label: Text('WARN')),
                  const ButtonSegment(value: LogLevel.error, label: Text('ERROR')),
                ],
                selected: {_filterLevel},
                onSelectionChanged: (Set<LogLevel?> newSelection) {
                  setState(() {
                    _filterLevel = newSelection.first;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No logs available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建日志列表
  Widget _buildLogList(
    BuildContext context,
    AppLocalizations l10n,
    List<LogEntry> logs,
  ) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(
        Responsive(context).valueWhen(
          mobile: UIConstants.defaultPadding,
          tablet: UIConstants.largePadding,
        ),
      ),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogItem(context, log);
      },
    );
  }

  /// 构建日志项
  Widget _buildLogItem(BuildContext context, LogEntry log) {
    final levelColor = _getLogLevelColor(context, log.level);
    final levelText = _getLogLevelText(log.level);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: levelColor,
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  levelText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: levelColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatTimestamp(log.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  /// 获取日志级别颜色
  Color _getLogLevelColor(BuildContext context, LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  /// 获取日志级别文本
  String _getLogLevelText(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

