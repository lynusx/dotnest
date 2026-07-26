#!/bin/bash
# 安装项目共享的 Git Hooks
# 用法：在仓库根目录执行 bash scripts/hooks/install.sh

set -e

REPO_ROOT=$(git rev-parse --show-toplevel)
SRC_DIR="$REPO_ROOT/scripts/hooks"
DEST_DIR="$REPO_ROOT/.git/hooks"

for hook in "$SRC_DIR"/*; do
    name=$(basename "$hook")
    # 跳过本安装脚本和文档
    if [ "$name" = "install.sh" ] || [ "$name" = "README.md" ]; then
        continue
    fi
    cp "$hook" "$DEST_DIR/$name"
    chmod +x "$DEST_DIR/$name"
    echo "已安装 hook: $name"
done

echo "Git hooks 安装完成"
