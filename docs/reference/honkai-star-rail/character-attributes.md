# 《崩坏：星穹铁道》角色属性参考

> 类型：外部参考资料。
>
> 用途：记录《崩坏：星穹铁道》的属性名词与关键公式，供本项目选择性改造。本文不是项目 Game Design 权威。

## 1. 基础属性

《崩坏：星穹铁道》角色基础属性中与本项目最相关的包括：

- 生命值
- 攻击力
- 防御力
- 速度

其中速度决定行动值与行动频率。

原作基础行动值：

```text
基础行动值 = 10000 / 速度
```

速度越高，行动值越低，单位下一次行动越快。

参考：
- https://honkai-star-rail.fandom.com/wiki/Speed
- https://hsr.keqingmains.com/misc/speed-guide/

## 2. 战斗派生属性

与本项目当前设计相关的原作属性包括：

- 暴击率
- 暴击伤害
- 效果命中
- 效果抵抗
- 击破特攻
- 能量恢复效率
- 物理属性伤害提高
- 火属性伤害提高
- 冰属性伤害提高
- 雷属性伤害提高
- 风属性伤害提高
- 量子属性伤害提高
- 虚数属性伤害提高

参考：
- https://honkai-star-rail.fandom.com/wiki/Effect_Hit_Rate
- https://honkai-star-rail.fandom.com/wiki/Break_Effect
- https://honkai-star-rail.fandom.com/wiki/Energy_Regeneration_Rate
- https://honkai-star-rail.fandom.com/wiki/Relic/Stats

## 3. 效果命中

原作中，效果命中提高具有基础概率的负面效果实际施加成功率。

原作实际概率结构为：

```text
实际概率
= 基础概率
× (1 + 攻击方效果命中)
× (1 - 目标效果抵抗)
× (1 - 目标对应负面效果抵抗)
```

本项目可以借用“效果命中提高负面效果施加概率”的语义，但不必复制完整抵抗公式。

参考：
- https://honkai-star-rail.fandom.com/wiki/Effect_Hit_Rate

## 4. 韧性与击破特攻

原作敌人具有韧性。韧性被削减至 0 时进入弱点击破状态，并产生对应属性的击破效果。

击破特攻会强化击破伤害、部分击破持续伤害，以及量子/虚数击破造成的行动延后。

参考：
- https://honkai-star-rail.fandom.com/wiki/Toughness
- https://honkai-star-rail.fandom.com/wiki/Break_Effect

原作七属性典型击破异常：

| 属性 | 击破异常 |
|---|---|
| 物理 | 裂伤 |
| 火 | 灼烧 |
| 冰 | 冻结 |
| 雷 | 触电 |
| 风 | 风化 |
| 量子 | 纠缠 |
| 虚数 | 禁锢 |

本项目是否完全复刻每种异常的原作公式另行设计。

## 5. 能量恢复效率

原作能量恢复效率提高角色从可受该属性影响的来源获得的能量：

```text
实际恢复能量 = 基础恢复能量 × 能量恢复效率
```

原作中击败敌人也是能量来源之一。

本项目会保留“提高战斗资源恢复效率”的思路，但会扩展到自己的战技点与终结技能量资源，不直接照搬原作范围。

参考：
- https://honkai-star-rail.fandom.com/wiki/Energy_Regeneration_Rate
- https://honkai-star-rail.fandom.com/wiki/Energy

## 6. 与本项目的关键差异

- 玩家生存资源使用同步值，不使用传统生命值条；
- 原作速度作用于回合行动值，本项目把速度映射为实时攻击间隔；
- 本项目另有独立移动速度；
- 本项目保留效果命中，但当前不采用玩家效果抵抗属性；
- 敌人使用生命值 + 韧性值双条；
- 本项目拥有实时类幸存者专属属性，例如范围倍率、拾取范围、经验获取倍率和资源获取倍率；
- 七属性伤害提高先作为设计预留，不代表当前版本已经实现属性克制。
