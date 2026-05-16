# Harness Kit

[English](README.md) · **简体中文**

![version](https://img.shields.io/badge/version-0.9.1-blue) ![verify_all](https://img.shields.io/badge/verify__all-19%2F19-brightgreen) ![test-init](https://img.shields.io/badge/test--init-108%2F108-brightgreen) ![integration](https://img.shields.io/badge/integration-78%2F78-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> **Claude Code 的 Harness Engineering 工具包** — 一个 Claude Code Plugin（4 个 skills + 项目模板），把"有纪律的 AI 驱动开发"带到全栈和后端项目里。
>
> **目标**：人工只做"描述需求"和"AI 做不到时介入"；其他全部 — 7-Agent 流水线、验证闸门、结构化文档 — 自动运行。

## 包含什么

这是一个 Claude Code Plugin 包，给任何项目装上 4 个 AI skill：

- `/harness-kit:harness-init` — 新项目从零生成 Harness 骨架（问 5 个问题，~30 秒生成 `.harness/` + `.claude/` + docs）
- `/harness-kit:harness-adopt` — 给现有项目无侵入接入 Harness（侦察栈、提取约定、用户确认后再 apply）
- `/harness-kit:harness-verify` — 跑总验证（编译 + 测试 + 规则扫描 + 基线对比）
- `/harness-kit:harness-status` — 健康度快照（哪些资产存在、基线、最近 verify 状态、活动任务）

init 之后，每个非琐碎任务流经 **7-Agent 流水线**：PM Orchestrator → Requirement Analyst → Solution Architect → Gate Reviewer → Developer（或分区 `dev-*`）→ Code Reviewer → QA Tester → 交付。

## 谁适合用

- 任何能从有纪律的 AI 驱动开发中受益的项目。**全栈**（前端 + 后端 + DB）和**纯后端**（API 服务）有**一等公民预设**。其他栈（CLI、库、移动端、ML 流水线、嵌入式、WPF/Unity/桌面、纯前端）走 **Other / Generic** 路径 — `.harness/` 骨架默认就有；首次使用时 PM 和 AI 会根据你的项目实际情况裁剪 rules / 分区 agents / `verify_all`。
- 主用 **Claude Code**（也支持 GitHub Copilot 共存 / 切换）。
- 想让 AI 处理有纪律的部分（需求、设计、代码、评审、测试、文档），自己专注方向。

## 安装

### 方式 1 — Claude Code Plugin Marketplace（推荐）

在任何 Claude Code 会话内：

```
/plugin marketplace add Alan-IFT/harness-kit
/plugin install harness-kit@harness-kit-marketplace
```

官方路径、版本化、可审计。装完后命令带 namespace：`/harness-kit:harness-init` 等。

### 方式 2 — 一行 curl / PowerShell

不用 Plugin 系统的用户，或全局安装：

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.sh | sh
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/Alan-IFT/harness-kit/main/install.ps1 | iex
```

脚本自包含：克隆 repo 到临时目录，把 skills 复制到 `~/.claude/skills/`。命令路径变成 `/harness-init` 等（无 namespace）。

### 方式 3 — 本地 clone（开发模式）

```bash
git clone https://github.com/Alan-IFT/harness-kit ~/harness-kit
~/harness-kit/install.sh                  # 或 install.ps1
~/harness-kit/install.sh --project .      # 项目级安装
~/harness-kit/install.sh --dry-run        # 仅预览
~/harness-kit/install.sh --uninstall      # 卸载
```

## 快速开始

```bash
mkdir my-app && cd my-app
claude
```

在 Claude Code 里：

```
/harness-kit:harness-init
```

5 个问题（`AskUserQuestion` 弹窗）：
1. 项目类型 — Fullstack / Backend / Other-Generic（CLI、库、移动、ML、嵌入式 等）
2. 技术栈 — 自由文本（如 "Next.js + NestJS + Postgres"、"Rust CLI tool"、"PyTorch 训练流水线"）
3. 启用 `verify_all` Stop hook — Yes / No
4. Developer 分区 — Partitioned（默认）/ Single（Other-Generic 跳过此问题，首次任务时 AI 分析后再决定）
5. 项目输出语言 — English（默认）/ 中文

~30 秒后你的项目里就有：
- `.harness/`（工具无关真相源：agents、rules、skills）
- `.claude/`（生成的 Claude Code binding）
- `.github/copilot-instructions.md`（生成的 Copilot binding）
- `CLAUDE.md`（生成的项目规则，Claude Code 读）
- `docs/`（workflow、dev-map、tasks、spec）
- `scripts/`（verify_all、harness-sync、baseline）
- `evals/`（金标准回归任务）

然后描述任务：

```
Take this task: 在订单页加 CSV 导出按钮。
```

PM Orchestrator 接手，跑完 7 个 stage，在 `docs/features/<slug>/` 下产出 6 份阶段文档，写代码、跑 verify_all，最后给你一个完成的 feature。

## 核心特性

### 工具无关真相源

```
.harness/rules/*.md     ← 你只编辑这里（单一真相源）
       │
       │  harness-sync 自动生成 ↓
       │
       ├──> CLAUDE.md                            (Claude Code 读)
       └──> .github/copilot-instructions.md      (Copilot 读)
```

你编辑一个地方，两个 binding 自动同步。`verify_all` 检测漂移，drift 时 FAIL。

**v0.9+：连 sync 都不用自己跑。** Stop hook（在 `.claude/settings.json`）会在每次 Claude Code session 结束时自动跑 `harness-sync`。更进一步：让 AI 帮你编辑 `.harness/` — "加一条规则：禁止用 `MessageBox.Show`"、"为 `apps/mobile/` 加一个 Developer 分区" — AI 选对文件、编辑，Stop hook 同步。你只在想编辑时才编辑。

### 项目级语言策略

中文团队 init 时选 `中文` — 项目里 AI 全程中文输出：对话回复、agent 间交接、阶段文档、状态报告、错误消息。即使你用其他语言提问，AI 也用中文回答。机制：CLAUDE.md 顶部的 `Output language` 章节。

英文项目同理 — 不会有别的语言混入。

### Developer 分区

全栈：`dev-frontend` / `dev-backend` / `dev-db` agents，每个有 owned-paths glob。Solution Architect 产出 partition assignment 表；PM 按依赖顺序派发（默认 db → backend → frontend）。越界改动报 `BLOCKED ON PARTITION`，PM 重新路由。

后端：同样思路，三层 — `dev-api` / `dev-services` / `dev-db`。

小项目可选 single developer 模式。

### 跨工具切换（Claude Code ↔ Copilot）

Claude Code 5 小时额度用完？切到 VS Code + GitHub Copilot 继续，额度恢复后切回。任务状态全部持久化在文件里（`docs/tasks.md`、`docs/features/<task>/`、`PM_LOG.md`），不在会话记忆里 — resume 只需要读这些文件。两个工具的 binding 都包含 `.harness/rules/60-tool-handoff.md` 定义的切换协议。

### 三层回归测试

- `verify_all`（19 项检查）— 仓库本身健康度
- `test-init`（108 断言）— init 模板逻辑（空目录）
- `test-real-project`（78 断言）— 真实 fixture 上 overlay（todo-fullstack、todo-backend）

每个 commit 必须三套都过。`test-init` 和 `test-real-project` 端到端走通生成项目的结构，离线秒级跑。

### Dogfood

本仓库自己用 Harness Kit 开发。同样的 7-agent 流水线既给用户也管理本仓库的工作。同一份 `.harness/rules/` 也生成本仓库的 `CLAUDE.md` 和 `.github/copilot-instructions.md`。如果我们自己用不下去，就不该 ship。

## 仓库布局

```
harness-kit/
├── skills/                       Claude Code Skills（产品）
│   ├── harness-init/             Bootstrap skill + 模板
│   │   └── templates/
│   │       ├── common/           共享资产（7 agents、基础规则、docs、evals）
│   │       ├── fullstack/        全栈 overlay（分区 agents、overlay rules）
│   │       ├── backend/          后端 overlay
│   │       └── i18n/zh/          中文翻译 overlay
│   ├── harness-adopt/
│   ├── harness-verify/
│   └── harness-status/
│
├── .claude-plugin/               Claude Code plugin manifests
│   ├── plugin.json
│   └── marketplace.json
│
├── .harness/                     本仓库 SOT（dogfood）
│   ├── agents/                   与 templates/common/.harness/agents/ byte 一致
│   └── rules/                    本仓库特定规则
├── .claude/                      生成（不要编辑）
├── CLAUDE.md                     生成（不要编辑）
├── .github/copilot-instructions.md  生成（不要编辑）
│
├── scripts/
│   ├── verify_all.{ps1,sh}       总验证
│   ├── harness-sync.{ps1,sh}     .harness/ → CLAUDE.md + .github/copilot-instructions.md
│   ├── sync-self.{ps1,sh}        templates/common/ → 本仓库 SOT
│   ├── test-init.{ps1,sh}        init 回归
│   └── test-real-project.{ps1,sh}  集成回归
│
├── tests/fixtures/               最小真实形态项目（用于集成测试）
│
├── docs/
│   ├── getting-started.md
│   ├── concepts.md
│   ├── workflow.md
│   ├── dev-map.md
│   ├── walkthrough.html          可视化流程演示
│   └── manual-e2e-test.md
│
├── architecture.html             架构可视化
├── install.ps1 / install.sh      一行命令安装
├── README.md                     英文（默认）
├── README.zh-CN.md               中文（本文件）
├── CHANGELOG.md
├── CONTRIBUTING.md
├── MIGRATION.md                  v0.1.x → v0.5+ 升级
└── LICENSE                       MIT
```

## 文档

浏览器打开效果最佳：

- **[architecture.html](architecture.html)** — 可视化架构、设计决策、演化历史
- **[docs/walkthrough.html](docs/walkthrough.html)** — 完整用户流程演示，用真实 todo-list 例子贯穿，每个 stage 都展示

Markdown 文档：

- [docs/getting-started.md](docs/getting-started.md) — 快速上手
- [docs/concepts.md](docs/concepts.md) — 各个组件为什么存在
- [docs/workflow.md](docs/workflow.md) — 完整 7-agent 流水线
- [docs/manual-e2e-test.md](docs/manual-e2e-test.md) — 手动端到端测试清单
- [CONTRIBUTING.md](CONTRIBUTING.md) — 贡献者开发流程
- [MIGRATION.md](MIGRATION.md) — 老版本 harness-engineering 项目升级路径

## 路线图

| 版本 | 状态 | 重点 |
|---|---|---|
| 0.1.0 | 已交付 | MVP：4 skills、7 agents、dogfood |
| 0.2.0 | 已交付 | 工具无关 `.harness/` SOT 层 |
| 0.3.0 | 已交付 | `/harness-adopt` 自动 apply |
| 0.4.x | 已交付 | 全栈 Developer 分区 |
| 0.5.0 | 已交付 | 后端 Developer 分区 |
| 0.6.x | 已交付 | 改名 harness-kit；Plugin marketplace 打包 |
| 0.7.x | 已交付 | i18n（en/zh）+ 项目级输出语言策略；Copilot rules binding |
| 0.8.x | 已交付 | 跨工具切换协议；生成文件可见 warning |
| 0.9.0 | 已交付 | 自动 sync via Stop hook（无需手动跑 `harness-sync`）；"Other / Generic" 项目类型，任何栈现在都能用 |
| 0.10 | 规划中 | **AI 原生 init**：AI 读项目描述（和已有代码，如果有的话）后生成自定义 overlay — 不用预设选项、不用预设分区形态 |
| 0.11+ | 规划中 | Copilot 自定义 agent binding；`/harness-handoff` 和 `/harness-resume` 自动化；adopt 中的语义规则提取 |

## 设计原则

1. **不重造平台机制** — Sandbox、Hooks、Sub-agents、MCP、Memory 是 Claude Code 的事
2. **机制 vs 内容** — 平台给机制，本仓库给内容
3. **工具无关 SOT vs binding 层** — `.harness/` 是真相；`.claude/`、`CLAUDE.md`、`.github/copilot-instructions.md` 是生成的
4. **演化式交付** — MVP → Hardening → Scale，不是大爆炸
5. **基线只升不降** — 测试数、规则覆盖永远不悄悄退步
6. **发现者不修** — Reviewer 不能改代码，Gate 不能改需求
7. **下游不能改上游** — 只能通过 PM 提阻塞回退
8. **PM 只路由** — 永不给专业判断

## 贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)。欢迎 PR 和 issue。

## License

[MIT](LICENSE)
