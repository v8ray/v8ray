#!/bin/bash
# WSL X11 显示问题诊断和修复脚本

echo "=========================================="
echo "WSL X11 显示问题诊断"
echo "=========================================="
echo ""

# 1. 检查 WSL 版本
echo "1. WSL 版本信息:"
wsl.exe --version 2>/dev/null || echo "无法获取 WSL 版本（可能是 WSL1）"
echo ""

# 2. 检查 DISPLAY 环境变量
echo "2. 显示环境变量:"
echo "   DISPLAY=$DISPLAY"
echo "   WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "   XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo ""

# 3. 检查 X11 连接
echo "3. 测试 X11 连接:"
if xdpyinfo > /dev/null 2>&1; then
    echo "   ✓ X11 连接正常"
    xdpyinfo | head -5
else
    echo "   ✗ X11 连接失败"
fi
echo ""

# 4. 检查 WSLg 进程
echo "4. WSLg 相关进程:"
ps aux | grep -E "weston|Xwayland|wslg" | grep -v grep || echo "   未找到 WSLg 进程"
echo ""

# 5. 检查 /tmp/.X11-unix
echo "5. X11 socket 文件:"
ls -la /tmp/.X11-unix/ 2>/dev/null || echo "   /tmp/.X11-unix/ 不存在"
echo ""

# 6. 检查 /mnt/wslg
echo "6. WSLg 挂载点:"
ls -la /mnt/wslg/ 2>/dev/null || echo "   /mnt/wslg/ 不存在"
echo ""

echo "=========================================="
echo "尝试修复方案"
echo "=========================================="
echo ""

# 方案 1: 重启 WSL
echo "方案 1: 重启 WSL (在 Windows PowerShell 中执行)"
echo "   wsl --shutdown"
echo "   然后重新打开 WSL"
echo ""

# 方案 2: 更新 WSL
echo "方案 2: 更新 WSL 到最新版本 (在 Windows PowerShell 中执行)"
echo "   wsl --update"
echo ""

# 方案 3: 使用 VcXsrv 或 X410
echo "方案 3: 如果是 WSL1 或 WSLg 不可用，使用第三方 X Server"
echo "   1. 下载并安装 VcXsrv: https://sourceforge.net/projects/vcxsrv/"
echo "   2. 启动 XLaunch，选择 'Multiple windows'，Display number: 0"
echo "   3. 在 WSL 中设置:"
echo "      export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'):0"
echo "      export LIBGL_ALWAYS_INDIRECT=1"
echo ""

# 方案 4: 检查 Windows 防火墙
echo "方案 4: 检查 Windows 防火墙是否阻止了 X11 连接"
echo "   在 Windows 防火墙中允许 VcXsrv 或 WSLg 的连接"
echo ""

# 方案 5: 使用 systemd (WSL2)
echo "方案 5: 启用 systemd (WSL2)"
echo "   编辑 /etc/wsl.conf:"
echo "   [boot]"
echo "   systemd=true"
echo "   然后重启 WSL: wsl --shutdown"
echo ""

echo "=========================================="
echo "快速测试"
echo "=========================================="
echo ""

# 测试简单的 X11 应用
echo "测试 xeyes (如果安装了):"
if command -v xeyes > /dev/null 2>&1; then
    timeout 2 xeyes 2>&1 &
    XEYES_PID=$!
    sleep 1
    if ps -p $XEYES_PID > /dev/null 2>&1; then
        echo "   ✓ xeyes 启动成功！窗口应该已经显示"
        kill $XEYES_PID 2>/dev/null
    else
        echo "   ✗ xeyes 启动失败"
    fi
else
    echo "   xeyes 未安装，跳过测试"
fi
echo ""

echo "=========================================="
echo "推荐操作"
echo "=========================================="
echo ""
echo "如果您使用的是 WSL2，最简单的解决方案是："
echo "1. 在 Windows PowerShell (管理员) 中执行: wsl --update"
echo "2. 在 Windows PowerShell 中执行: wsl --shutdown"
echo "3. 重新打开 WSL Ubuntu"
echo "4. 测试: xclock"
echo ""
echo "如果问题仍然存在，请查看上面的其他方案。"
echo ""

