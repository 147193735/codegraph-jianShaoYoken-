# 从原仓库合并上游代码

原仓库: `https://github.com/colbymchenry/codegraph.git`

## 首次设置
```bash
git remote add upstream https://github.com/colbymchenry/codegraph.git
```

## 日常同步
```bash
git fetch upstream
git merge upstream/main
git push origin main
```

## 注意事项
- 当前 fork 有独有改动，合并时可能产生冲突
- 使用 `git merge` 保留完整历史（非 rebase）
- 合并前建议先 `git log --oneline HEAD..upstream/main` 查看上游新增提交
