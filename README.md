# Harness Engineering for Claude Code

![version](https://img.shields.io/badge/version-0.5.0-blue) ![verify_all](https://img.shields.io/badge/verify__all-19%2F19-brightgreen) ![test-init](https://img.shields.io/badge/test--init-104%2F104-brightgreen) ![integration](https://img.shields.io/badge/integration-76%2F76-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> 一套把 AI 自动开发架构落到 Claude Code 的 Skills 包。
>
> 目标：**人工只做"提需求"和"AI 做不到时介入"**，其他由 7-Agent 流水线 + 验证闭环自动完成。
>
> **当前版本**：v0.5.0（Developer 分区完整覆盖 fullstack + backend；init 和 adopt 都支持）。从 v0.1.x 升级见 [MIGRATION.md](MIGRATION.md)。

## 这是什么

把 Harness Engineering（Rule / Skill / Script / Multi-Agent / 验证闭环 / 知识库 / 演化）方法论
封装成 Claude Code 可直接调用的 Skills，让你能在任何全栈或后端项目里：

- `/harness-init` — 给新项目从零生成 Harness 骨架 ✅
- `/harness-adopt` — 给现有项目无侵入接入 Harness ✅ **v0.3 自动 apply**
- `/harness-verify` — 跑总验证脚本（编译 + 测试 + 规则扫描 + 基线对比） ✅
- `/harness-status` — 查看项目当前 Harness 健康度 ✅

### 两层模型（v0.2+）

项目里有两层资产：

```
.harness/        ← 你编辑这里（工具无关源真相）
  agents/        ← 7 个 sub-agent 角色契约
  rules/         ← 拆分的规则片段（00-core / 50-overlay …）
  skills/        ← 编译/测试/验证标准操作
     │
     │ scripts/harness-sync 同步
     ▼
.claude/         ← 自动生成（Claude Code 绑定层）
CLAUDE.md        ← 自动合成（不要直接编辑）
```

**核心规矩**：编辑 `.harness/`，不编辑 `.claude/` 或 `CLAUDE.md`。后者由 `harness-sync` 重新生成，
`verify_all` 自动检查一致性。

**好处**：项目知识不再绑定 Claude Code。未来你想换 IDE / 加 Cursor binding，只需写新 binding，
内容不动。

## 谁适合用

- 主要写 **全栈** 或 **纯后端** 项目
- 主要用 **Claude Code** 做 AI 辅助开发
- 想最大化 AI 自主完成度，但又要可控、可维护

暂不支持：WPF / Unity / 纯前端 / 数据 ML 流水线。

## 安装

### 全局安装（推荐）

```powershell
# Windows PowerShell
git clone https://github.com/<your>/harness-engineering ~/harness-engineering
& ~/harness-engineering/install.ps1
```

```bash
# macOS / Linux
git clone https://github.com/<your>/harness-engineering ~/harness-engineering
~/harness-engineering/install.sh
```

装完后所有 skill 出现在 `~/.claude/skills/`，所有项目可用。

### 项目级安装

```powershell
& ~/harness-engineering/install.ps1 -Project .
```

只安装到当前项目的 `.claude/skills/`。

## 快速上手

```
# 在 Claude Code 内
/harness-init
```

Skill 会问你：
1. 项目类型？（全栈 / 后端）
2. 技术栈？（如：Next.js + NestJS + Postgres）
3. 是否启用 verify_all hook？

然后自动：
1. 在 `.harness/` 生成 7 个 agent、规则片段、skills
2. 把 `.claude/settings.json` 写入（Claude Code binding glue）
3. 跑 `scripts/harness-sync` 生成 `.claude/agents/` `.claude/skills/` 和 `CLAUDE.md`
4. 创建 `docs/`（workflow / spec / dev-map / tasks）+ `evals/` + `scripts/`（verify_all、baseline）

下一步直接和 PM Orchestrator 派活：

```
Take this task: Add CSV export to the orders page.
```

详细使用见 [docs/getting-started.md](docs/getting-started.md)。

**完整流程 + 真实例子**（todo-list CSV 导出，贯穿 7 个 stage，可视化）：浏览器打开 [docs/walkthrough.html](docs/walkthrough.html)。

## 架构

完整架构设计：[architecture.html](architecture.html)（浏览器打开查看可视化）

核心思路：

```
人 → 提需求
    ↓
Layer 2（项目工具无关层，本仓库提供模板）
  .harness/{agents, rules, skills}
    ↓ harness-sync
Layer 1（Claude Code 绑定层，生成）
  .claude/{agents, skills, settings.json} + CLAUDE.md
    ↓
Layer 0（Claude Code 平台机制，已就绪）
  Permission · Sub-agents · Hooks · MCP · Memory · Skills · Auto-compaction · /cost
```

详见 [docs/concepts.md](docs/concepts.md)。

## 仓库结构

```
harness-engineering/
├── skills/                     # Claude Code Skills（核心产物）
│   ├── harness-init/
│   │   ├── SKILL.md
│   │   └── templates/         # 项目模板：common / fullstack / backend
│   ├── harness-adopt/
│   ├── harness-verify/
│   └── harness-status/
├── .harness/                  # 本仓库自身的工具无关 SOT（dogfood）
│   ├── agents/                # 与 templates/common/.harness/agents/ 一致
│   └── rules/                 # 本仓库规则片段
├── .claude/                   # 生成（不要编辑）
├── CLAUDE.md                  # 生成（不要编辑）
├── scripts/
│   ├── verify_all.{ps1,sh}    # 总验证
│   ├── harness-sync.{ps1,sh}  # .harness/ → .claude/ + CLAUDE.md
│   ├── sync-self.{ps1,sh}     # templates/ → 本仓库 SOT
│   ├── test-init.{ps1,sh}     # init 自动化回归（86 断言）
│   └── baseline.json
├── docs/                       # 文档
│   ├── getting-started.md
│   ├── workflow.md
│   ├── dev-map.md
│   └── concepts.md
├── architecture.html           # 完整架构设计（HTML 可视化）
├── install.ps1                 # Windows 安装脚本
├── install.sh                  # Unix 安装脚本
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

## 设计原则

1. **不重造 Claude Code 已有的能力**（Sandbox / Hooks / Sub-agents / MCP / Memory）
2. **机制层 vs 内容层分离**：平台给机制，本仓库给内容
3. **工具无关层 vs 绑定层分离**：`.harness/` 是真相源，`.claude/` 是生成产物
4. **演化式落地**：MVP → Hardening → Scale，不一次到位
5. **基线只升不降**：测试数量、规则覆盖率永远不准退步
6. **发现问题的人不能修问题**：Reviewer 不改代码，Gate 不改需求
7. **下游不能改上游文档**：只能提阻塞回退给 PM
8. **PM 只做路由，不做专业判断**

## 贡献 & 反馈

issues / PRs 欢迎。详见 [CONTRIBUTING.md](CONTRIBUTING.md) 和 [CHANGELOG.md](CHANGELOG.md)。

## License

MIT
