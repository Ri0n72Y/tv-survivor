# 堆料前门禁

## P0｜必须先做

1. 合并后 Godot 4.7.1 全量验证。
2. 修复任何 parse error、节点路径错误、暂停泄漏和双重扣费。
3. 确认地图改造与 BattleResult 回流兼容。

## P1｜内容规模扩大前

1. 删除奖励 Dictionary 兼容层。
2. 拆分 GridScene/BattleScene 编排。
3. 将当前 Buff 系统定位为通用 Effect 基础或同步专用组件。
4. 建立第一个可测试的 EffectDefinition/Instance/Host 案例。

## P2｜触发型内容扩大前

1. 显式事件阶段；
2. 稳定排序；
3. 事件 ID、root/parent ID、来源、目标、origin effect；
4. 最大因果深度和重复触发限制；
5. 可读取的调试 trace。
