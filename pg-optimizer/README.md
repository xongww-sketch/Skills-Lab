# 🐘 PG Optimizer — PostgreSQL 数据库性能优化工具包

一套面向 AI Agent 的 PostgreSQL 性能优化 Skill，覆盖**索引治理、慢查询调优、监控告警**三大场景。

## 🎯 能做什么

| 子命令 | 功能 | 典型场景 |
|---|---|---|
| `index-health` | 索引健康检查 | 找出废索引、冗余索引，释放磁盘空间 |
| `index-recommend` | 慢 SQL 索引推荐 | 分析慢查询，自动推荐最佳复合索引 |
| `alert-setup` | Grafana 告警配置 | 一键配置长事务/死锁/连接数等告警 → 飞书群通知 |

## 🚀 快速开始

把 `pg-optimizer/` 目录放到你的 OpenClaw workspace 的 `skills/` 下即可自动识别。

然后对 AI 说：
- "帮我检查 machine_data 表的索引健康状况"
- "这条 SQL 很慢，帮我推荐索引"
- "帮我配置 Grafana 数据库告警到飞书群"

## 📁 目录结构

```
pg-optimizer/
├── SKILL.md                          # Skill 定义（AI 读这个）
├── README.md                         # 人类读这个
├── references/
│   ├── sql-index-health.md           # 索引健康检查 SQL 参考
│   ├── index-patterns.md             # 索引设计模式参考
│   └── grafana-alert-setup.md        # Grafana 告警配置步骤
└── scripts/                          # 自动化脚本（如有）
```

## ⚠️ 安全原则

- 所有索引操作使用 `CONCURRENTLY`（不锁表）
- `ANALYZE` 只读不写，安全无影响
- 删索引前确认使用统计
- 建议在业务低峰期操作

## 📋 适用环境

- PostgreSQL 10+
- 可选：Prometheus + Grafana（告警功能）
- 可选：飞书群 Webhook（告警通知）
