# 索引健康检查 SQL

## 索引使用统计

```sql
SELECT indexrelname AS name, 
       idx_scan AS 使用次数,
       pg_size_pretty(pg_relation_size(indexrelid)) AS 大小
FROM pg_stat_user_indexes
WHERE relname = '表名'
ORDER BY idx_scan ASC;
```

## 检查无效索引

```sql
SELECT indexrelname FROM pg_stat_user_indexes 
JOIN pg_index ON pg_index.indexrelid = pg_stat_user_indexes.indexrelid
WHERE relname = '表名' AND NOT pg_index.indisvalid;
```

## 检查 UUID 冲突（重复值）

```sql
SELECT uuid, array_agg(retroid), count(*)
FROM 表名
WHERE bind_status = 1 AND uuid IS NOT NULL
GROUP BY uuid
HAVING count(DISTINCT retroid) > 1;
```

## 表大小统计

```sql
SELECT pg_size_pretty(pg_total_relation_size('schema.表名')) AS total_size,
       pg_size_pretty(pg_relation_size('schema.表名')) AS data_size,
       pg_size_pretty(pg_indexes_size('schema.表名')) AS index_size;
```

## 当前活跃长事务

```sql
SELECT pid, now() - xact_start AS duration, state, query
FROM pg_stat_activity
WHERE state != 'idle' AND xact_start IS NOT NULL
ORDER BY duration DESC LIMIT 20;
```

## 锁等待检查

```sql
SELECT blocked.pid AS blocked_pid,
       blocked.query AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.query AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_locks bl ON bl.pid = blocked.pid
JOIN pg_locks kl ON kl.locktype = bl.locktype
  AND kl.database IS NOT DISTINCT FROM bl.database
  AND kl.relation IS NOT DISTINCT FROM bl.relation
  AND kl.pid != bl.pid
JOIN pg_stat_activity blocking ON kl.pid = blocking.pid
WHERE NOT bl.granted;
```

## 统计信息更新

```sql
ANALYZE schema.表名;
```
