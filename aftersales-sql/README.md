# 🔧 Aftersales SQL — 售后未激活数据 SQL 生成器

从售后未激活 Excel 自动生成 `INSERT INTO activation_records` SQL，支持海外/国内两种表格格式。

## 🎯 能做什么

| 功能 | 说明 |
|---|---|
| SN→型号映射 | 根据设备 SN 前缀自动匹配产品型号（COROS XXX） |
| 时间戳转换 | Excel 日期 → 自定义 Unix 时间戳（+1462 天偏移） |
| SQL 生成 | 批量 INSERT，带 WHERE NOT EXISTS 去重 |

## 🚀 快速开始

把 `aftersales-sql/` 目录放到你的 OpenClaw workspace 的 `skills/` 下即可自动识别。

然后发送 Excel 文件 + 说一句：
- "生成品质sql"
- "售后SQL"
- "生成售后插入SQL"

## 📁 目录结构

```
aftersales-sql/
├── SKILL.md                          # Skill 定义（AI 读这个）
├── README.md                         # 人类读这个
└── references/
    ├── sn-mapping.json               # SN 前缀→型号映射规则（20条）
    └── table-schema.sql              # activation_records 表结构
```

## 📋 支持的 Excel 格式

### 海外表
必需列：`Device SN`、`History Activation Time`、`Server`（US/EU）

### 国内表
必需列：`原始设备序列号`、`激活日期`，地区固定为 `CN`

## ⏱ 时间戳公式

```
activatetime = 标准 Unix 时间戳 + 126316800（即 +1462 天）
```

验证基准：`2025-12-21` → `1892592000`

## ⚠️ 注意事项

- 未匹配的 SN 会单独列出，需确认是否补充映射规则
- 新增映射规则后需更新 `references/sn-mapping.json`
