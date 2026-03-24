# 流程图/架构图 HTML 样式规范

## 通用样式

```css
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  background: #fff;
  font-family: -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
  padding: 40px;
  width: 1200px;
}
```

## 标题

```css
.title {
  font-size: 24px;
  font-weight: 700;
  text-align: center;
  margin-bottom: 30px;
  color: #1a1a1a;
}
```

## 步骤卡片

横向排列，每个步骤一个彩色圆角卡片：

```css
.row { display: flex; align-items: flex-start; gap: 12px; justify-content: center; }
.step { display: flex; flex-direction: column; align-items: center; }
.box {
  color: white;
  border-radius: 12px;
  padding: 18px 16px;
  text-align: center;
  min-width: 130px;
  font-size: 14px;
  line-height: 1.7;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
.arrow { display: flex; align-items: center; font-size: 24px; color: #bbb; padding-top: 16px; }
.label { font-size: 11px; color: #999; text-align: center; margin-top: 8px; }
```

## 推荐色板

| 用途 | 颜色 | 场景 |
|---|---|---|
| 数据源/取数 | `#4A90D9` | MES、WMS、数据库查询 |
| 匹配/处理 | `#52B788` | 数据匹配、转换、校验 |
| 分批/拆分 | `#E8913A` | 分页、分批、拆文件 |
| 生成/输出 | `#7C5CBF` | 生成Excel、PDF、报表 |
| 上传/外部 | `#D94F4F` | RPA上传、API调用、外部系统 |
| 日志/记录 | `#607D8B` | 写日志、截图存档 |
| 通知/告警 | `#E8913A` | 飞书通知、邮件告警 |

## 底部规则卡片

流程图底部加规则提示：

```css
.rules { display: flex; gap: 16px; margin-top: 28px; justify-content: center; }
.rule-card {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  padding: 14px 18px;
  border-radius: 10px;
  font-size: 13px;
  flex: 1;
  line-height: 1.6;
}
.rule-card strong { display: block; margin-bottom: 4px; color: #333; }
```

左边框颜色用 `border-left: 3px solid {色板颜色}` 区分类型。

## 泳道图（多角色协作）

用 HTML table 实现：

```css
table.swim { width: 100%; border-collapse: collapse; }
table.swim th {
  background: #f5f6fa;
  padding: 14px;
  font-size: 14px;
  font-weight: 600;
  border: 1px solid #e0e0e0;
  text-align: center;
}
table.swim td {
  border: 1px solid #e0e0e0;
  padding: 12px;
  vertical-align: top;
  font-size: 13px;
  line-height: 1.8;
  text-align: center;
}
.badge {
  display: inline-block;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  margin: 2px;
}
```

## 架构图

用 flexbox 布局，模块用带边框的圆角卡片：

```css
.arch { display: flex; gap: 24px; justify-content: center; align-items: stretch; }
.col { display: flex; flex-direction: column; gap: 16px; justify-content: center; }
.module {
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  font-size: 14px;
  line-height: 1.8;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  min-width: 150px;
}
.conn { display: flex; align-items: center; font-size: 20px; color: #bbb; padding: 0 4px; }
```

## 生成命令

```bash
npx playwright screenshot --full-page --viewport-size="1200,800" "file:///tmp/diagram.html" "/tmp/diagram.png"
```
