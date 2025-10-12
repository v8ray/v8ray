/// V8Ray 订阅管理组件
///
/// 提供订阅配置和更新功能

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/utils/validators.dart';

/// 订阅管理组件
class SubscriptionInput extends ConsumerWidget {
  const SubscriptionInput({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final updateState = ref.watch(subscriptionUpdateProvider);
    final subscriptionUrl = ref.watch(subscriptionUrlProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 两个按钮
            Row(
              children: [
                // 订阅配置按钮
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConfigDialog(context, ref),
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.subscriptionConfig),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 更新订阅按钮
                Expanded(
                  child: FilledButton.icon(
                    onPressed: updateState.isUpdating || subscriptionUrl.isEmpty
                        ? null
                        : () => _updateSubscription(context, ref),
                    icon: updateState.isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(l10n.updateSubscription),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),

            // 更新进度
            if (updateState.isUpdating) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: updateState.progress,
              ),
            ],

            // 更新结果
            if (updateState.lastUpdateTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.updateSuccess} - ${updateState.nodeCount} nodes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],

            // 错误消息
            if (updateState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.error,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      updateState.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 显示配置对话框
  void _showConfigDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _SubscriptionConfigDialog(),
    );
  }

  /// 更新订阅
  Future<void> _updateSubscription(BuildContext context, WidgetRef ref) async {
    final url = ref.read(subscriptionUrlProvider);

    if (url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseEnterUrl),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // 更新订阅
    await ref.read(subscriptionUpdateProvider.notifier).updateSubscription(url);

    if (context.mounted) {
      final updateState = ref.read(subscriptionUpdateProvider);
      if (updateState.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.updateSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }
}

/// 订阅配置对话框
class _SubscriptionConfigDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SubscriptionConfigDialog> createState() =>
      _SubscriptionConfigDialogState();
}

class _SubscriptionConfigDialogState
    extends ConsumerState<_SubscriptionConfigDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // 加载保存的订阅URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final url = ref.read(subscriptionUrlProvider);
      if (url.isNotEmpty) {
        _controller.text = url;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.subscriptionConfig),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 输入框
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: l10n.subscriptionUrl,
                  hintText: l10n.subscriptionUrlHint,
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 粘贴按钮
                      IconButton(
                        icon: const Icon(Icons.content_paste),
                        tooltip: l10n.paste,
                        onPressed: _pasteFromClipboard,
                      ),
                      // 清空按钮
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l10n.clear,
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterUrl;
                  }
                  if (!Validators.isValidSubscriptionUrl(value)) {
                    return l10n.invalidUrl;
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
                maxLines: 3,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      ),
      actions: [
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        // 保存按钮
        FilledButton(
          onPressed: _saveConfig,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      _controller.text = data.text!;
      setState(() {});
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final url = _controller.text.trim();

    // 保存URL
    await ref.read(subscriptionUrlProvider.notifier).setSubscriptionUrl(url);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveSuccess),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
