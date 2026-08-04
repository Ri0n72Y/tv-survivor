# 04｜内容生产

## 当前内容库存

### 武器

- `projectile`
- `aura`
- `shape`
- `beam`

### 被动

- `move_speed`
- `damage_bonus`
- `cooldown_bonus`
- `pickup_bonus`
- `sync_bonus`
- `gold_bonus`

## 静态资源路径

```text
content/weapons/*.tres
content/passives/*.tres
```

Catalog 递归发现 `.tres/.res`，按 `sort_order` 和稳定 ID 排序。

## 新普通武器

需要：

1. 一个 `WeaponDefinition` Resource；
2. 唯一 ID、展示名、最大等级和每级说明；
3. 实现 `setup(player, enemy_provider, level)` 的运行时脚本/场景；
4. Catalog 校验和烟测覆盖。

不需要修改 `WeaponManager` 的 ID 分支。

## 新普通数值被动

如果只修改现有属性，只需新增 `PassiveDefinition` Resource。增加新属性时必须同时提供基础值、边界、运行时消费者、UI 规则和测试。
