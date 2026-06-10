---
name: aftersales-sql
description: "从售后未激活 Excel 生成 INSERT SQL，插入 activation_records 表。触发条件：用户发送 Excel 文件并提及'生成品质sql'或'售后SQL'。自动完成 SN→型号映射、时间戳转换、SQL 生成。"
---

# 售后未激活数据 → INSERT SQL

## 流程概览

收到 Excel 后，按以下步骤处理：

1. **解析 Excel** — 提取 SN、激活时间、地区等字段
2. **SN→型号映射** — 用前缀匹配规则，输出 `COROS {型号}`
3. **时间戳转换** — 激活日期 → 按 Asia/Shanghai 当天 00:00:00 转秒级 Unix 时间戳（无偏移）
4. **生成 SQL** — INSERT INTO activation_records，带 WHERE NOT EXISTS 去重
5. **输出 .sql 文件** — 发送给用户

## 字段映射

### 海外表

| Excel 列 | SQL 字段 |
|-----------|----------|
| Device SN | retroid |
| History Activation Time | activatetime（需转换） |
| 型号（由 SN 匹配生成） | firmware_type |
| Server (US/EU) | country_code |

### 国内表

| Excel 列 | SQL 字段 |
|-----------|----------|
| 原始设备序列号 | retroid |
| 激活日期 | activatetime（需转换） |
| 型号（由 SN 匹配生成） | firmware_type |
| 固定 `CN` | country_code |

## SN 前缀 → 型号映射规则

读取 `references/sn-mapping.json`。匹配方式：SN 任意前几位匹配（优先匹配最长前缀），匹配后输出 `COROS {型号代码}`。

## 时间戳转换

**口径：把激活日期当作 Asia/Shanghai 时区的当天 00:00:00，转成秒级 Unix 时间戳。不加任何偏移。**

验证基准：`2025-12-21` → `1766246400`（= 2025-12-21 00:00:00 +08:00）

转换方式：
- **文本日期**（如 `2025-12-21` 或 `2025-12-21 00:00:00`）：按 Asia/Shanghai 解析该日期 00:00:00，取 Unix 秒。
- **Excel 日期序列号**（如 `45626`）：先还原为日期（Excel 序列号 = 从 1899-12-30 起的天数），再按上面文本日期的方式转 Asia/Shanghai 秒级。

Python 参考：
```python
import datetime, zoneinfo
tz = zoneinfo.ZoneInfo("Asia/Shanghai")
ts = int(datetime.datetime.strptime("2025-12-21", "%Y-%m-%d").replace(tzinfo=tz).timestamp())
# ts == 1766246400
```

PostgreSQL 参考（如直接在 SQL 里算）：
```sql
EXTRACT(EPOCH FROM ('2025-12-21'::date)::timestamp AT TIME ZONE 'Asia/Shanghai')::bigint
-- = 1766246400
```

## SQL 模板

```sql
INSERT INTO public.activation_records (retroid, activatetime, firmware_type, country_code)
SELECT v.retroid, v.activatetime, v.firmware_type, v.country_code
FROM (
  VALUES
  ('SN值', 时间戳, '型号', '地区'),
  ...
) AS v(retroid, activatetime, firmware_type, country_code)
WHERE NOT EXISTS (
  SELECT 1
  FROM public.activation_records ar
  WHERE ar.retroid = v.retroid
);
```

## 目标表结构

详见 `references/table-schema.sql`。

## 注意事项

- 未匹配的 SN 单独列出，提示用户确认是否需要补充映射规则
- 海外/国内分开生成 VALUES 块，合并到同一 SQL 文件
- 时间戳务必验证：用已知日期核对（`2025-12-21` 应为 `1766246400`），确认是 Asia/Shanghai 当天午夜、无偏移
