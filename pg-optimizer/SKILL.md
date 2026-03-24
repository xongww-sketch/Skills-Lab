---
name: pg-optimizer
description: |
  PostgreSQL 数据库性能优化工具包。包含索引健康检查、慢 SQL 索引推荐、Grafana 告警配置三个子功能。
  使用场景：(1) 检查数据库索引使用情况，识别废索引和冗余索引 (2) 分析慢 SQL 并推荐最佳索引
  (3) 一键配置 Grafana + 飞书群告警。触发词：索引优化、慢SQL、数据库性能、索引健康检查、
  Grafana告警、数据库监控、pg优化、PostgreSQL优化。
---

# PG Optimizer

PostgreSQL 数据库性能优化 Skill，三个子命令。

## 子命令

### 1. index-health — 索引健康检查

分析指定表的所有索引使用情况，输出保留/删除/新建建议。

**流程：**

1. 获取用户提供的数据库连接信息和表名
2. 让用户执行 `references/sql-index-health.md` 中的 SQL
3. 分析结果，按以下规则分类：
   - `idx_scan = 0` → 废索引，建议删除
   - `idx_scan < 100` 且有其他索引覆盖相同字段 → 冗余，建议删除
   - 多个索引覆盖相同字段组合 → 保留使用次数最高的
4. 输出清理方案（DROP INDEX CONCURRENTLY 语句）

**输出格式：**

```
🗑️ 建议删除（X 个，释放 Y GB）
| 索引名 | 大小 | 使用次数 | 删除原因 |

✅ 建议保留（X 个）
| 索引名 | 大小 | 使用次数 | 用途 |
```

### 2. index-recommend — 慢 SQL 索引推荐

分析慢 SQL，推荐最佳复合索引。

**流程：**

1. 获取用户的慢 SQL 语句
2. 解析 SQL 结构，识别：
   - WHERE 条件中的列（含 JSONB 表达式、LOWER 等函数）
   - JOIN / IN 子查询涉及的列
   - ORDER BY 列和方向
   - LIMIT 存在与否
3. 按以下规则生成索引：
   - 等值条件列放前面
   - 排序列放最后，方向匹配 SQL
   - JSONB 字段用表达式索引 `((data->>'field'))`
   - 有 LOWER() 必须建 LOWER 版本
   - OR 条件：每个分支建独立索引
4. 让用户执行 EXPLAIN ANALYZE 验证
5. 对比前后耗时

**索引模式参考：** 见 `references/index-patterns.md`

**关键规则：**
- 生产环境永远用 `CREATE INDEX CONCURRENTLY`
- 一条一条执行，等上一条完成再下一条
- 建完验证 → EXPLAIN ANALYZE 看到 `Index Scan` = 成功
- OR 条件 PG 难以同时走两个索引，考虑建议用户改 UNION ALL

### 3. alert-setup — Grafana 告警配置

配置 Prometheus + Grafana + 飞书群告警。

**流程：**

1. 获取信息：Grafana 地址、飞书群 Webhook、数据库名
2. 指导配置 Contact Point（Webhook → 飞书）
3. 创建 5 条告警规则：

| 告警 | PromQL | 阈值 |
|---|---|---|
| 长事务 | `pg_stat_activity_max_tx_duration{datname="DB"}` | > 5s |
| 慢查询 | `pg_stat_activity_max_tx_duration{datname="DB"}` | > 10s |
| 连接数 | `pg_stat_activity_count{datname="DB"}` | > 75% max |
| 死锁 | `increase(pg_stat_database_deadlocks{datname="DB"}[5m])` | > 0 |
| 缓存命中率 | `blks_hit / (hit + read)` | < 95% |

4. 测试验证（pg_sleep 模拟长事务）

**详细配置步骤：** 见 `references/grafana-alert-setup.md`

## 安全原则

- 所有索引操作使用 CONCURRENTLY（不锁表）
- ANALYZE 只读不写，安全无影响
- 删索引前确认使用统计
- 建议在业务低峰期操作
- `SET LOCAL` 只影响当前事务，ROLLBACK 恢复
