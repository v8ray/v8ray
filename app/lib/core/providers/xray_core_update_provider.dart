import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v8ray/core/ffi/bridge/api.dart' as api;
import 'package:v8ray/core/utils/index.dart';

/// Xray Core 更新状态
enum XrayCoreUpdateStatus {
  /// 空闲状态
  idle,

  /// 正在检查更新
  checking,

  /// 有可用更新
  available,

  /// 已是最新版本
  upToDate,

  /// 正在下载
  downloading,

  /// 下载完成
  downloaded,

  /// 检查失败
  checkFailed,

  /// 下载失败
  downloadFailed,

  /// 安装失败
  installFailed,
}

/// Xray Core 更新信息
class XrayCoreUpdateInfo {
  /// 当前版本
  final String currentVersion;

  /// 最新版本
  final String? latestVersion;

  /// 更新状态
  final XrayCoreUpdateStatus status;

  /// 下载进度 (0.0 到 1.0)
  final double downloadProgress;

  /// 错误消息
  final String? errorMessage;

  /// 下载 URL
  final String? downloadUrl;

  const XrayCoreUpdateInfo({
    required this.currentVersion,
    this.latestVersion,
    required this.status,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.downloadUrl,
  });

  /// 是否有更新
  bool get hasUpdate =>
      status == XrayCoreUpdateStatus.available &&
      latestVersion != null &&
      latestVersion != currentVersion &&
      currentVersion != 'not installed' &&
      currentVersion != 'unknown';

  /// 复制并修改
  XrayCoreUpdateInfo copyWith({
    String? currentVersion,
    String? latestVersion,
    XrayCoreUpdateStatus? status,
    double? downloadProgress,
    String? errorMessage,
    String? downloadUrl,
  }) {
    return XrayCoreUpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
      downloadUrl: downloadUrl ?? this.downloadUrl,
    );
  }
}

/// Xray Core 更新状态管理
class XrayCoreUpdateNotifier extends StateNotifier<XrayCoreUpdateInfo> {
  XrayCoreUpdateNotifier()
    : super(
        const XrayCoreUpdateInfo(
          currentVersion: 'unknown',
          status: XrayCoreUpdateStatus.idle,
        ),
      );

  /// 检查更新
  Future<void> checkForUpdates() async {
    state = state.copyWith(
      status: XrayCoreUpdateStatus.checking,
      errorMessage: null,
    );

    try {
      appLogger.info('Checking for Xray Core updates...');

      final updateInfo = await api.checkXrayCoreUpdate();

      appLogger.info(
        'Xray Core update check result: current=${updateInfo.currentVersion}, '
        'latest=${updateInfo.latestVersion}, hasUpdate=${updateInfo.hasUpdate}',
      );

      state = state.copyWith(
        currentVersion: updateInfo.currentVersion,
        latestVersion: updateInfo.latestVersion,
        status:
            updateInfo.hasUpdate
                ? XrayCoreUpdateStatus.available
                : XrayCoreUpdateStatus.upToDate,
        downloadUrl: updateInfo.downloadUrl,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      appLogger.error('Failed to check for Xray Core updates', e, stackTrace);
      state = state.copyWith(
        status: XrayCoreUpdateStatus.checkFailed,
        errorMessage: e.toString(),
      );
    }
  }

  /// 下载并安装更新
  Future<void> downloadAndInstallUpdate() async {
    if (state.latestVersion == null) {
      appLogger.warning('No latest version available for download');
      return;
    }

    state = state.copyWith(
      status: XrayCoreUpdateStatus.downloading,
      downloadProgress: 0.0,
      errorMessage: null,
    );

    try {
      appLogger.info('Downloading Xray Core update: ${state.latestVersion}');

      // 启动下载进度监控
      _startProgressMonitoring();

      // 下载并安装
      await api.updateXrayCore(version: state.latestVersion!);

      appLogger.info('Xray Core update installed successfully');

      state = state.copyWith(
        status: XrayCoreUpdateStatus.downloaded,
        downloadProgress: 1.0,
        currentVersion: state.latestVersion,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to download/install Xray Core update',
        e,
        stackTrace,
      );
      state = state.copyWith(
        status: XrayCoreUpdateStatus.downloadFailed,
        errorMessage: e.toString(),
      );
    }
  }

  /// 监控下载进度
  void _startProgressMonitoring() {
    // 启动一个定时器来定期查询下载进度
    Future.doWhile(() async {
      if (state.status != XrayCoreUpdateStatus.downloading) {
        return false; // 停止循环
      }

      try {
        final progress = await api.getXrayCoreUpdateProgress();
        state = state.copyWith(downloadProgress: progress);
      } catch (e) {
        appLogger.warning('Failed to get download progress: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
      return state.status == XrayCoreUpdateStatus.downloading;
    });
  }

  /// 重置状态
  void reset() {
    state = XrayCoreUpdateInfo(
      currentVersion: state.currentVersion,
      status: XrayCoreUpdateStatus.idle,
    );
  }
}

/// Xray Core 更新 Provider
final xrayCoreUpdateProvider =
    StateNotifierProvider<XrayCoreUpdateNotifier, XrayCoreUpdateInfo>((ref) {
      return XrayCoreUpdateNotifier();
    });
