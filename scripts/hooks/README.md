# Git Hooks

本目录下的 hook 脚本受版本控制，通过 `bash scripts/hooks/install.sh` 安装到 `.git/hooks/`（`.git/hooks/` 本身不受版本控制，克隆仓库后需手动安装一次）。

## prepare-commit-msg

自动根据提交信息类型更新版本号。

### 版本更新规则

| 提交类型 | 版本递增 | 示例 |
|---------|---------|------|
| `feat(scope):` | minor | 0.1.0 → 0.2.0 |
| `fix(scope):` | patch | 0.1.0 → 0.1.1 |
| `BREAKING CHANGE:` 或 `feat!:` | major | 0.1.0 → 1.0.0 |
| 其他 (chore/docs/refactor) | 不更新 | 保持不变 |

### 工作流程

1. 检测提交信息中的类型前缀
2. 根据规则更新 `pubspec.yaml` 中的版本号
3. 自动将 `pubspec.yaml` 添加到本次提交
4. 在提交信息末尾追加版本更新说明

### 示例

```bash
# 新功能提交
git commit -m "feat(api): 添加用户认证功能"
# 自动更新: 0.1.0 → 0.2.0

# 修复提交
git commit -m "fix(ui): 修复按钮点击无响应问题"
# 自动更新: 0.2.0 → 0.2.1

# 普通提交
git commit -m "docs: 更新 README"
# 版本保持不变
```

### 注意事项

- Hook 仅在普通 commit 时触发，merge、squash、amend（无论是否带 `-m`）均跳过
- 版本号格式：`major.minor.patch+build`
- Build number 保持不变，仅更新语义化版本部分
