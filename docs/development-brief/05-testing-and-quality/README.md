# 05｜测试与质量

## 当前验证状态

### 已知已执行

用户曾在 Godot 4.7.1 上成功运行项目 import。随后运行烟测场景时，发现测试断言的字符串格式化错误；该错误已在 PR 中修复。

### 未验证

PR 与地图/Buff 改造完成组合合并后，尚未重新执行：

- Godot import；
- `ContentFoundationSmoke.tscn`；
- `tests/test_runner.tscn` 网格生成测试；
- 完整人工玩法回归。

因此当前 `main@c02a0f2` 的运行状态必须标记为待验证。

## 自动测试命令

```bash
git switch main
git pull --ff-only origin main
git rev-parse --short HEAD

godot --headless --path . --import
godot --headless --path . --scene res://tests/ContentFoundationSmoke.tscn
godot --headless --path . --scene res://tests/test_runner.tscn
```

期望：退出码 `0`，无 `ERROR`。烟测中两个故意构造非法 `BattleContext` 的 fallback warning 可以接受。
