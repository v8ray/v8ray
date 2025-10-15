/// V8Ray 应用更新检查组件
///
/// 提供版本检查和更新功能的UI组件

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/app_update_provider.dart';
import '../../core/providers/xray_core_update_provider.dart';

/// 应用更新检查组件
class AppUpdateChecker extends ConsumerStatefulWidget {
  const AppUpdateChecker({super.key});

  @override
  ConsumerState<AppUpdateChecker> createState() => _AppUpdateCheckerState();
}

class _AppUpdateCheckerState extends ConsumerState<AppUpdateChecker> {
  @override
  void initState() {
    super.initState();
    // 监听更新状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 监听应用更新
      ref.listenManual(appUpdateProvider, (previous, next) {
        // 当检测到有更新时，显示对话框
        if (previous?.status != UpdateStatus.available &&
            next.status == UpdateStatus.available) {
          _showAppUpdateDialog(next);
        }
        // 当下载完成时，显示安装提示
        else if (previous?.status != UpdateStatus.downloaded &&
            next.status == UpdateStatus.downloaded) {
          _showAppInstallDialog(next);
        }
        // 当安装完成时，显示重启提示
        else if (previous?.status != UpdateStatus.installed &&
            next.status == UpdateStatus.installed) {
          _showAppRestartDialog(next);
        }
        // 当安装失败时，显示错误提示
        else if (previous?.status != UpdateStatus.installFailed &&
            next.status == UpdateStatus.installFailed) {
          _showAppInstallFailedDialog(next);
        }
      });

      // 监听 Xray Core 更新
      ref.listenManual(xrayCoreUpdateProvider, (previous, next) {
        // 当检测到有更新时，显示对话框
        if (previous?.status != XrayCoreUpdateStatus.available &&
            next.status == XrayCoreUpdateStatus.available) {
          _showXrayCoreUpdateDialog(next);
        }
        // 当下载完成时，显示成功提示
        else if (previous?.status != XrayCoreUpdateStatus.downloaded &&
            next.status == XrayCoreUpdateStatus.downloaded) {
          _showXrayCoreInstallSuccessDialog(next);
        }
      });
    });
  }

  void _showAppUpdateDialog(UpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AppUpdateDialog(
            updateInfo: updateInfo,
            onUpdate: () {
              Navigator.of(context).pop();
              ref.read(appUpdateProvider.notifier).downloadUpdate();
            },
            onLater: () {
              Navigator.of(context).pop();
            },
          ),
    );
  }

  void _showAppInstallDialog(UpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(l10n.updateDownloaded),
              ],
            ),
            content: Text(l10n.restartToUpdate),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.later),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(appUpdateProvider.notifier).installUpdate();
                },
                child: Text(l10n.installUpdate),
              ),
            ],
          ),
    );
  }

  void _showAppRestartDialog(UpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(l10n.updateInstalled),
              ],
            ),
            content: Text(l10n.restartToApplyUpdate),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  exit(0);
                },
                child: Text(l10n.restartNow),
              ),
            ],
          ),
    );
  }

  void _showAppInstallFailedDialog(UpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Text(l10n.updateInstallFailed),
              ],
            ),
            content: Text(updateInfo.errorMessage ?? l10n.unknownError),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.close),
              ),
            ],
          ),
    );
  }

  void _showXrayCoreUpdateDialog(XrayCoreUpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => XrayCoreUpdateDialog(
            updateInfo: updateInfo,
            onUpdate: () {
              Navigator.of(context).pop();
              ref
                  .read(xrayCoreUpdateProvider.notifier)
                  .downloadAndInstallUpdate();
            },
            onLater: () {
              Navigator.of(context).pop();
            },
          ),
    );
  }

  void _showXrayCoreInstallSuccessDialog(XrayCoreUpdateInfo updateInfo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(l10n.xrayCoreUpdateInstalled),
              ],
            ),
            content: Text(
              '${l10n.xrayCoreCurrentVersion}: ${updateInfo.currentVersion}',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUpdateInfo = ref.watch(appUpdateProvider);
    final xrayCoreUpdateInfo = ref.watch(xrayCoreUpdateProvider);
    final l10n = AppLocalizations.of(context)!;

    // 如果任一有更新，显示徽章
    final hasAnyUpdate =
        appUpdateInfo.hasUpdate || xrayCoreUpdateInfo.hasUpdate;

    return PopupMenuButton<String>(
      icon: Badge(
        isLabelVisible: hasAnyUpdate,
        backgroundColor: Colors.red,
        child: const Icon(Icons.system_update),
      ),
      tooltip: l10n.checkUpdate,
      onSelected: (value) {
        switch (value) {
          case 'check_app':
            ref.read(appUpdateProvider.notifier).checkForUpdates();
            break;
          case 'download_app':
            _showAppUpdateDialog(appUpdateInfo);
            break;
          case 'install_app':
            ref.read(appUpdateProvider.notifier).installUpdate();
            break;
          case 'check_xray':
            ref.read(xrayCoreUpdateProvider.notifier).checkForUpdates();
            break;
          case 'download_xray':
            _showXrayCoreUpdateDialog(xrayCoreUpdateInfo);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        // ========== 应用版本信息 ==========
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'V8Ray ${l10n.version}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );

        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.currentVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  appUpdateInfo.currentVersion,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (appUpdateInfo.latestVersion != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.latestVersion,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appUpdateInfo.latestVersion!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          appUpdateInfo.hasUpdate
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        // 根据应用更新状态显示不同的选项
        switch (appUpdateInfo.status) {
          case UpdateStatus.idle:
          case UpdateStatus.upToDate:
          case UpdateStatus.checkFailed:
            items.add(
              PopupMenuItem<String>(
                value: 'check_app',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.checkUpdate),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.checking:
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.checkingUpdate),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.available:
            items.add(
              PopupMenuItem<String>(
                value: 'download_app',
                child: Row(
                  children: [
                    const Icon(Icons.download, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.downloadUpdate),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.downloading:
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.downloading),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: appUpdateInfo.downloadProgress,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(appUpdateInfo.downloadProgress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.downloaded:
            items.add(
              PopupMenuItem<String>(
                value: 'install_app',
                child: Row(
                  children: [
                    const Icon(Icons.install_desktop, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.installUpdate),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.installed:
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.updateInstalled),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.installFailed:
            items.add(
              PopupMenuItem<String>(
                value: 'install_app',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.installUpdate),
                  ],
                ),
              ),
            );
            break;

          case UpdateStatus.downloadFailed:
            items.add(
              PopupMenuItem<String>(
                value: 'download_app',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.downloadUpdate),
                  ],
                ),
              ),
            );
            break;
        }

        // 应用更新错误消息
        if (appUpdateInfo.errorMessage != null) {
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                appUpdateInfo.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        // ========== Xray Core 版本信息 ==========
        items.add(const PopupMenuDivider());

        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Text(
              l10n.xrayCoreVersion,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );

        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.xrayCoreCurrentVersion,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  xrayCoreUpdateInfo.currentVersion,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (xrayCoreUpdateInfo.latestVersion != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.xrayCoreLatestVersion,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    xrayCoreUpdateInfo.latestVersion!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          xrayCoreUpdateInfo.hasUpdate
                              ? Theme.of(context).colorScheme.primary
                              : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        // 根据 Xray Core 更新状态显示不同的选项
        switch (xrayCoreUpdateInfo.status) {
          case XrayCoreUpdateStatus.idle:
          case XrayCoreUpdateStatus.upToDate:
          case XrayCoreUpdateStatus.checkFailed:
            items.add(
              PopupMenuItem<String>(
                value: 'check_xray',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.checkXrayCoreUpdate),
                  ],
                ),
              ),
            );
            break;

          case XrayCoreUpdateStatus.checking:
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.checkingXrayCoreUpdate),
                  ],
                ),
              ),
            );
            break;

          case XrayCoreUpdateStatus.available:
            items.add(
              PopupMenuItem<String>(
                value: 'download_xray',
                child: Row(
                  children: [
                    const Icon(Icons.download, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.downloadXrayCoreUpdate),
                  ],
                ),
              ),
            );
            break;

          case XrayCoreUpdateStatus.downloading:
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n.downloadingXrayCore),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: xrayCoreUpdateInfo.downloadProgress,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(xrayCoreUpdateInfo.downloadProgress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
            break;

          case XrayCoreUpdateStatus.downloaded:
            items.add(
              PopupMenuItem<String>(
                enabled: false,
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.xrayCoreUpdateInstalled),
                  ],
                ),
              ),
            );
            break;

          case XrayCoreUpdateStatus.downloadFailed:
          case XrayCoreUpdateStatus.installFailed:
            items.add(
              PopupMenuItem<String>(
                value: 'download_xray',
                child: Row(
                  children: [
                    const Icon(Icons.refresh, size: 20),
                    const SizedBox(width: 12),
                    Text(l10n.downloadXrayCoreUpdate),
                  ],
                ),
              ),
            );
            break;
        }

        // Xray Core 更新错误消息
        if (xrayCoreUpdateInfo.errorMessage != null) {
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                xrayCoreUpdateInfo.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}

/// 应用更新对话框
class AppUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(l10n.updateAvailable),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentVersion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      updateInfo.currentVersion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.latestVersion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      updateInfo.latestVersion ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 发布说明
            if (updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 24),
              Text(
                l10n.releaseNotes,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  updateInfo.releaseNotes!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onLater, child: Text(l10n.later)),
        FilledButton(onPressed: onUpdate, child: Text(l10n.updateNow)),
      ],
    );
  }
}

/// Xray Core 更新对话框
class XrayCoreUpdateDialog extends StatelessWidget {
  final XrayCoreUpdateInfo updateInfo;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const XrayCoreUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(l10n.xrayCoreUpdateAvailable),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 版本信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.xrayCoreCurrentVersion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      updateInfo.currentVersion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.xrayCoreLatestVersion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      updateInfo.latestVersion ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: onLater, child: Text(l10n.later)),
        FilledButton(onPressed: onUpdate, child: Text(l10n.updateNow)),
      ],
    );
  }
}
