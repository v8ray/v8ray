#!/bin/bash
# 运行 V8Ray 需要管理员权限

# 保存当前用户的 DISPLAY 和 XAUTHORITY
CURRENT_DISPLAY="${DISPLAY}"
CURRENT_XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

# 允许 root 访问 X11 显示
xhost +local:root > /dev/null 2>&1

# 使用 sudo 运行，显式传递 DISPLAY 和 XAUTHORITY
sudo DISPLAY="${CURRENT_DISPLAY}" XAUTHORITY="${CURRENT_XAUTHORITY}" \
     ./build/linux/x64/debug/bundle/v8ray

# 恢复 X11 访问控制
xhost -local:root > /dev/null 2>&1

