# 索引设计模式

## 模式 1：等值查询

```sql
-- SQL: WHERE status = 'active'
CREATE INDEX CONCURRENTLY idx_xxx ON table(status);
```

## 模式 2：等值 + 排序 + LIMIT

```sql
-- SQL: WHERE user_id = 1 ORDER BY created_at DESC LIMIT 1
CREATE INDEX CONCURRENTLY idx_xxx ON table(user_id, created_at DESC);
```

列顺序：等值条件在前，排序列在后，方向匹配 SQL。

## 模式 3：JSONB 字段

```sql
-- SQL: WHERE data->>'field' = 'value'
CREATE INDEX CONCURRENTLY idx_xxx ON table((data->>'field'));

-- SQL: WHERE LOWER(data->>'field') = LOWER('value')
CREATE INDEX CONCURRENTLY idx_xxx ON table(LOWER(data->>'field'));

-- SQL: WHERE data->'nested'->>'field' = 'value'
CREATE INDEX CONCURRENTLY idx_xxx ON table((data->'nested'->>'field'));
```

表达式必须与 SQL 完全一致，LOWER 版本和非 LOWER 版本是两个不同索引。

## 模式 4：复合索引（多条件 + 排序）

```sql
-- SQL: WHERE a IN (...) AND b = 'x' ORDER BY c DESC LIMIT 1
CREATE INDEX CONCURRENTLY idx_xxx ON table(a, b, c DESC);
```

最常用模式。列顺序：过滤条件 → 匹配条件 → 排序。

## 模式 5：LIKE 前缀查询

```sql
-- SQL: WHERE field LIKE 'abc%'
CREATE INDEX CONCURRENTLY idx_xxx ON table(field text_pattern_ops);

-- JSONB 版本
CREATE INDEX CONCURRENTLY idx_xxx ON table((data->>'field') text_pattern_ops);
```

## 模式 6：OR 条件

OR 条件 PG 难以同时走多个索引。两种方案：

**方案 A：每个分支建独立索引，依赖 BitmapOr（不改 SQL）**

```sql
CREATE INDEX CONCURRENTLY idx_a ON table(col_a);
CREATE INDEX CONCURRENTLY idx_b ON table(col_b);
```

PG 可能选也可能不选，取决于优化器估算。

**方案 B：改 SQL 为 UNION ALL（推荐，一定走索引）**

```sql
(SELECT * FROM t WHERE col_a = 'x' ORDER BY time DESC LIMIT 1)
UNION ALL
(SELECT * FROM t WHERE col_b = 'x' ORDER BY time DESC LIMIT 1)
ORDER BY time DESC LIMIT 1;
```

## 模式 7：IN 子查询优化

PG 对 IN (子查询) 可能估算不准导致不选索引。

**验证方法：** 把 IN (子查询) 替换为 IN (常量值)，如果走索引说明是子查询估算问题。

**解决：**
1. ANALYZE 更新统计信息
2. 改为 JOIN
3. 直接用常量值（适合值固定不变的情况）

## 模式 8：值过长（超过 B-Tree 行大小限制）

报错 `index row size exceeds btree version maximum`：

- 用 Hash 索引：`CREATE INDEX ... USING hash (expression);`
- 截断：`CREATE INDEX ... ON table(left(field, 250));`
- md5：`CREATE INDEX ... ON table(md5(field));`（需改查询）

## 安全规则

- 生产环境永远 `CREATE INDEX CONCURRENTLY`
- 一条一条执行
- 建完 `EXPLAIN ANALYZE` 验证
- 删索引也用 `DROP INDEX CONCURRENTLY`
- CONCURRENTLY 失败会留 INVALID 索引，需手动删除重建
