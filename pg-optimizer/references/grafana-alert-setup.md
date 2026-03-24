# Grafana + 飞书告警配置步骤

## 前置条件

- Prometheus + postgres_exporter 已部署
- Grafana 已部署
- 飞书群已创建

## 第 1 步：创建飞书群机器人

1. 飞书群 → 设置 → 机器人 → 添加机器人 → 自定义机器人
2. 复制 Webhook 地址

## 第 2 步：验证 Webhook

```bash
curl -X POST '飞书webhook地址' \
  -H 'Content-Type: application/json' \
  -d '{
    "msg_type": "interactive",
    "card": {
      "header": {
        "title": {"tag": "plain_text", "content": "🧪 测试告警"},
        "template": "green"
      },
      "elements": [
        {"tag": "markdown", "content": "测试成功 ✅"}
      ]
    }
  }'
```

## 第 3 步：Grafana Contact Point

Alerting → Contact points → + Add contact point

| 字段 | 值 |
|---|---|
| Name | feishu-alert |
| Integration | Webhook |
| URL | 飞书 webhook 地址 |

如果 Grafana 支持 Custom Payload，填入飞书卡片模板。
否则部署转换服务（见下方 Docker 部署）。

## 第 4 步：Notification Policy

Alerting → Notification policies → 编辑默认策略
Default contact point → 选 feishu-alert

## 第 5 步：创建告警规则

Alerting → Alert rules → + New alert rule（不是 Recording rule）

**注意：** 数据源选 **Prometheus**（不是 PostgreSQL）。

### 5 条告警规则

#### 长事务 > 5s
- Query: `pg_stat_activity_max_tx_duration{datname="DB"}`
- Threshold: IS ABOVE 5
- Pending: 1m
- severity: warning

#### 慢查询 > 10s  
- Query: `pg_stat_activity_max_tx_duration{datname="DB"}`
- Threshold: IS ABOVE 10
- Pending: 30s
- severity: critical

#### 连接数过高
- Query: `pg_stat_activity_count{datname="DB"}`
- Threshold: IS ABOVE 150（按最大连接数 75% 设定）
- Pending: 2m
- severity: warning

#### 死锁
- Query: `increase(pg_stat_database_deadlocks{datname="DB"}[5m])`
- Threshold: IS ABOVE 0
- Pending: 0s
- severity: critical

#### 缓存命中率低
- Query A: `pg_stat_database_blks_hit{datname="DB"}`
- Query B: `pg_stat_database_blks_read{datname="DB"}`
- Math: `$A / ($A + $B)`
- Threshold: IS BELOW 0.95
- Pending: 5m
- severity: warning

## 第 6 步：测试

```sql
BEGIN;
SELECT pg_sleep(15);
-- 等 1-2 分钟，群里应收到告警
ROLLBACK;
-- 再等 1-2 分钟，应收到恢复通知
```

## 转换服务 Docker 部署（可选）

当 Grafana 不支持 Custom Payload 时使用：

```python
# app.py - 飞书 Webhook 格式转换服务
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, urllib.request, os

FEISHU_WEBHOOK = os.environ.get("FEISHU_WEBHOOK", "你的webhook地址")

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        for alert in body.get("alerts", []):
            status = alert.get("status", "firing")
            labels = alert.get("labels", {})
            annotations = alert.get("annotations", {})
            template = "red" if status == "firing" else "green"
            title = "🔴 告警" if status == "firing" else "✅ 恢复"
            content = f"**{labels.get('alertname','')}**\n{annotations.get('summary','')}"
            card = {"msg_type":"interactive","card":{"header":{"title":{"tag":"plain_text","content":title},"template":template},"elements":[{"tag":"markdown","content":content}]}}
            req = urllib.request.Request(FEISHU_WEBHOOK, data=json.dumps(card).encode(), headers={"Content-Type":"application/json"})
            urllib.request.urlopen(req)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'ok')

HTTPServer(("0.0.0.0", 9095), Handler).serve_forever()
```

```bash
docker run -d --name grafana-feishu --restart always -p 9095:9095 \
  -v ./app.py:/app/app.py -e FEISHU_WEBHOOK=你的地址 \
  python:3.11-slim python /app/app.py
```

Grafana Contact Point URL 填 `http://localhost:9095`。
