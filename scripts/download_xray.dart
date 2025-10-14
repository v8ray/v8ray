#!/usr/bin/env dart
/// Download Xray Core binary
///
/// This script downloads the Xray Core binary for the target platform
/// during Flutter build process.
///
/// Usage:
///   dart download_xray.dart [--target-dir <dir>] [--force] [--build-mode <debug|release>]

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  print('=== Xray Core Download Script ===');

  // 解析命令行参数
  String? targetDir;
  bool forceDownload = false;
  String buildMode = 'debug';

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--target-dir' && i + 1 < args.length) {
      targetDir = args[i + 1];
      i++;
    } else if (args[i] == '--force') {
      forceDownload = true;
    } else if (args[i] == '--build-mode' && i + 1 < args.length) {
      buildMode = args[i + 1];
      i++;
    }
  }

  // 读取下载信息
  final infoFile = File('../core/bin/.xray_download_info');
  if (!infoFile.existsSync()) {
    print('Error: Download info file not found at ${infoFile.path}');
    print('Please run cargo build first to generate download information.');
    exit(1);
  }

  final downloadInfo = jsonDecode(await infoFile.readAsString());
  final url = downloadInfo['url'] as String;
  final binaryName = downloadInfo['binary_name'] as String;
  final extension = downloadInfo['extension'] as String;
  final version = downloadInfo['version'] as String;

  print('Xray Core version: $version');
  print('Download URL: $url');
  print('Binary name: $binaryName');
  print('Build mode: $buildMode');

  // 确定目标目录
  Directory binDir;
  if (targetDir != null) {
    binDir = Directory(targetDir);
  } else {
    // 默认下载到 Flutter 构建输出目录
    final platform = Platform.operatingSystem;
    final bundlePath = platform == 'windows'
        ? '../app/build/windows/x64/runner/${buildMode == 'release' ? 'Release' : 'Debug'}'
        : platform == 'macos'
            ? '../app/build/macos/Build/Products/${buildMode == 'release' ? 'Release' : 'Debug'}/v8ray.app/Contents/MacOS'
            : '../app/build/linux/x64/$buildMode/bundle';

    binDir = Directory('$bundlePath/bin');
  }

  print('Target directory: ${binDir.path}');

  // 检查是否已存在
  final binaryPath = File('${binDir.path}/$binaryName');

  if (binaryPath.existsSync()) {
    print('Xray Core binary already exists at ${binaryPath.path}');

    // 检查是否强制更新
    if (!forceDownload) {
      print('Skipping download. Use --force to force update.');
      return;
    }

    print('Force update requested, re-downloading...');
  }

  // 创建 bin 目录
  if (!binDir.existsSync()) {
    binDir.createSync(recursive: true);
  }

  // 下载文件
  print('Downloading Xray Core...');
  final client = HttpClient();
  
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      print('Error: Failed to download Xray Core (HTTP ${response.statusCode})');
      exit(1);
    }

    // 保存到临时文件
    final tempFile = File('${binDir.path}/xray_temp$extension');
    final sink = tempFile.openWrite();
    
    var downloadedBytes = 0;
    await for (var chunk in response) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      // 每 1MB 打印一次进度
      if (downloadedBytes % (1024 * 1024) == 0) {
        print('Downloaded: ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      }
    }
    
    await sink.close();
    print('Download complete: ${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB');

    // 解压文件
    print('Extracting Xray Core...');
    
    if (extension == '.zip') {
      await extractZip(tempFile, binDir, binaryName);
    } else {
      print('Error: Unsupported archive format: $extension');
      exit(1);
    }

    // 删除临时文件
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }

    // 设置可执行权限 (Unix 系统)
    if (!Platform.isWindows) {
      print('Setting executable permission...');
      final result = await Process.run('chmod', ['+x', binaryPath.path]);
      if (result.exitCode != 0) {
        print('Warning: Failed to set executable permission');
        print(result.stderr);
      }
    }

    print('✓ Xray Core downloaded successfully to ${binaryPath.path}');
  } catch (e, stackTrace) {
    print('Error: Failed to download Xray Core: $e');
    print(stackTrace);
    exit(1);
  } finally {
    client.close();
  }
}

/// Extract ZIP archive
Future<void> extractZip(File zipFile, Directory targetDir, String binaryName) async {
  if (Platform.isWindows) {
    // Windows: 使用 PowerShell 解压
    final result = await Process.run(
      'powershell',
      [
        '-Command',
        'Expand-Archive -Path "${zipFile.path}" -DestinationPath "${targetDir.path}" -Force'
      ],
    );
    
    if (result.exitCode != 0) {
      print('Error: Failed to extract ZIP file');
      print(result.stderr);
      exit(1);
    }
  } else {
    // Unix: 使用 unzip
    final result = await Process.run(
      'unzip',
      ['-o', zipFile.path, '-d', targetDir.path],
    );
    
    if (result.exitCode != 0) {
      print('Error: Failed to extract ZIP file');
      print(result.stderr);
      exit(1);
    }
  }
  
  print('Extraction complete');
}

