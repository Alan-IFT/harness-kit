# Harness Kit

[English](README.md) · **简体中文**

![version](https://img.shields.io/badge/version-0.17.0-blue) ![verify_all](https://img.shields.io/badge/verify__all-30%2F30-brightgreen) ![test-init](https://img.shields.io/badge/test--init-227%2F227-brightgreen) ![integration](https://img.shields.io/badge/integration-82%2F82-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> **Claude Code 的 Harness Engineering 工具包** — 一个 Claude Code Plugin（10 个 skills + 项目模板），把"有纪律的 AI 驱动开发"带到全栈和后端项目里。
>
> **目标**：人工只做"描述需求"和"AI 做不到时介入"；其他全部 — 7-Agent 流水线、验证闸门、结构化文档 — 自动运行。

## 包含什么

这是一个 Claude Code Plugin 包，给任何项目装上 10 个 AI skill：

**流水线类**（4 种任务形态，AI 根据你的自然语言自动挑对应那条）
- `/harness-kit:harness` — 完整 7-stage 流水线（RA → SA → GR → Dev → CR → QA → 交付）。用于真正的功能 / bug / 重构。
- `/harness-kit:harness-plan` — 只做设计：跑 RA + SA + GR，给出判决后停止，**不写代码**。用于"投入工程时间前先验证设计"。
- `/harness-kit:harness-explore` — 调研/可行性：轻量 RA + 一份带引用的 `findings.md`。**不做设计、不写代码**。用于"这事儿到底能不能做？"
- `/harness-kit:harness-goal` — 开放式 Dev + QA 循环，由可量化的成功标准 + 预算限定。用于"持续改进直到覆盖率 > 80%"这类任务。

**安装类**
- `/harness-kit:harness-init` — 新项目从零生成 Harness 骨架（问 5 个问题，~30 秒生成 `.harness/` + `.claude/` + `AI-GUIDE.md` + stub CLAUDE.md / copilot-instructions.md）
- `/harness-kit:harness-adopt` — 给现有项目无侵入接入 Harness（侦察栈、提取约定、用户确认后再 apply）

**运维类**
- `/harness-kit:harness-verify` — 跑总验证（编译 + 测试 + 规则扫描 + 基线对比）
- `/harness-kit:harness-status` — 健康度快照（哪些资产存在、基线、最近 verify 状态、活动任务）
- `/harness-kit:harness-intervene` — 给正在跑的流水线发"软 Ctrl-C"：写一个 `STOP` / `REDIRECT` / `SKIP` / `NOTE` 信号文件，PM 在下一次阶段切换时消费
- `/harness-kit:harness-supervise` — 旁观者辅助 skill（v0.17+）：读取进行中或归档的任务文件夹，产出 `SUPERVISION_REPORT.md`，标注 anti-pattern（rollback 比率、阶段文档过薄、缺 intervention check、缺 archive 调用），分 `INFO`/`WARN`/`ALERT`，最后一行给出 `HEALTHY`/`WATCH`/`INTERVENE` 判决

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
1. 项目类型 — Fullstack / Backend / Generic（CLI / 库 / 移动 / ML / 嵌入式 等）—— 三种一等公民 overlay
2. 技术栈 — 自由文本（如 "Next.js + NestJS + Postgres"、"Rust CLI tool"、"PyTorch 训练流水线"）
3. 启用 `verify_all` Stop hook — Yes / No
4. Developer 分区 — Partitioned（默认）/ Single（Generic 跳过此问题，默认单 developer，项目长大后 AI 再建议分区）
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

### 工具无关真相源（v0.10 —— progressive disclosure）

```
.harness/rules/*.md     ← 你只编辑这里（单一真相源，模块化片段）
       ↑
       │  被引用
       │
AI-GUIDE.md             ← 工具无关入口（~50 行索引，每条带"什么时候读"）
       ↑
       │  被指向
       │
CLAUDE.md                            (~15 行 bootstrap stub；Claude Code 读)
.github/copilot-instructions.md      (~15 行 bootstrap stub；Copilot 读)
```

你编辑一个地方：`.harness/rules/`。stub 和 AI-GUIDE.md 都靠引用，**不再生成**。AI 工具跟着引用、**按需懒加载相关片段** —— 跟 Claude Code 自己的 skill 系统同模式。

**Context 预算**：常驻 system prompt 的规则集从 ~3500 token（v0.9.x 全量 CLAUDE.md）降到 ~250 token（v0.10 stub）。小问答里（~92% 节省）AI 甚至不读 AI-GUIDE.md。中等任务读 AI-GUIDE.md 一次 + 触发条件命中的 1-3 个片段，平均 ~50% 节省。

`harness-sync` 还在，但只复制 `.harness/agents/` 和 `.harness/skills/` 到 `.claude/`（Claude Code 强要求这些路径）。规则不 sync。git pre-commit hook（来自 `scripts/install-hooks`）兜底保证 Copilot / Cursor / 手编辑用户的 `.claude/` 也跟得上 `.harness/`，工具无关。

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

- `verify_all`（30 项检查）— 仓库本身健康度
- `test-init`（PowerShell 227 断言；不带 python3 的 Bash 191）— init 模板逻辑（空目录；3 种项目类型 × 75 PS / 63 Bash，外加 2 条不依赖 shell 的 BUG-2 placeholder 正则回归断言）
- `test-real-project`（82 断言）— 真实 fixture 上 overlay（todo-fullstack、todo-backend）

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
│   ├── harness-status/
│   └── harness-intervene/
│
├── .claude-plugin/               Claude Code plugin manifests
│   ├── plugin.json
│   └── marketplace.json
│
├── .harness/                     本仓库 SOT（dogfood）
│   ├── agents/                   与 templates/common/.harness/agents/ byte 一致
│   └── rules/                    本仓库特定规则
├── AI-GUIDE.md                   工具无关入口（索引 .harness/rules/）
├── .claude/                      Claude Code binding（harness-sync 重新生成）
├── CLAUDE.md                     ~15 行 stub，指向 AI-GUIDE.md（init 时一次性生成，不重新合成）
├── .github/copilot-instructions.md  ~15 行 stub，指向 AI-GUIDE.md
│
├── scripts/
│   ├── verify_all.{ps1,sh}       总验证
│   ├── harness-sync.{ps1,sh}     .harness/agents + .harness/skills → .claude/（v0.10 起 CLAUDE.md 已变 stub，不再合成）
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
| 0.9.x | 已交付 | 自动 sync via Stop hook + OS-aware `{{SYNC_COMMAND}}` + 工具无关 git pre-commit hook；"Other / Generic" 项目类型 |
| 0.10.0 | 已交付 | **Progressive-disclosure 布局**：`AI-GUIDE.md` 入口 + stub CLAUDE.md / copilot-instructions.md；规则不再组合（~50% context 预算降低）|
| 0.11.x | 已交付 | **三个执行模式** + **对抗性验证** + **跨任务 insight index**（来自 GenericAgent 借鉴）+ 对称 `/harness` skill + AI-GUIDE.md ↔ rules 漂移检查 |
| 0.12.0 | 已交付 | **Generic 项目类型升为一等公民 overlay**（跟 fullstack/backend 平级）—— 关闭 Other-Generic gap。新增 `templates/generic/`，包含 `50-generic.md` 规则 stub + 最小 `verify_all` 骨架。test-init 现在覆盖 3 个项目类型（+33 断言）。|
| 0.13.0 | 已交付 | **中途介入协议**（`/harness-kit:harness-intervene`）：单次 `.harness/intervention.md` 信号文件（STOP / REDIRECT / SKIP / NOTE），PM 在每个阶段切换时消费。v0.12 之后第一个面向用户的新能力。 |
| 0.14.0 | 已交付 | **文档大小策略**：8 类文档的数值上限（rules / agents / 每任务文档 / insight-index / tasks.md），加 `verify_all` 中的 WARN 级大小检查（仓库本身 I.1-I.5，用户项目模板 F.1-F.6）。"引用不要粘贴" + 强制 archive-task 纪律。 |
| 0.15.0 | 已交付 | **AI 安全护栏**：跨平台 `guard-rm.{ps1,sh}` PreToolUse hook 阻断目标路径在项目 root 之外的破坏性命令（`rm` / `Remove-Item` / `find -delete` / 嵌套 `pwsh -c`）；单次 override 走 `HARNESS_ALLOW_OUTSIDE_RM=1`。新增 `.harness/rules/75-safety-hook.md`。再加 D1+D2 文档：AI 工具流模式（Claude Code 自动派发 / Copilot 手动 / Copilot 可选"走全流程" Gate Review 后硬性 STOP）和 Claude Code 子 agent 派发的显式 callout。verify_all 26 → 27（新增 F.2）。 |
| 0.15.1 | 已交付 | **文档漂移清扫 + I.6 retired-claim 守护**：把 v0.10 合成模型退役遗留在 14 个文件里的过时表述（docs / 模板 / 本仓库规则 / 中文 overlay）清扫干净；并在 `verify_all` 里加一道字面子串黑名单（任何退役表述复现 → FAIL）。verify_all 27 → 28（新增 I.6）。 |
| 0.16.0 | 已交付 | **AI 原生 init / adopt**：`/harness-init` Q6 与 `/harness-adopt` Q6 可选打开 AI 草拟，让 AI 基于 Q2 stack 描述 + 顶层文件名 + 已读到的 manifest 内容起草定制的 `.harness/rules/50-<project-slug>.md`（以及可选的 `dev-*` 分区 agent）。四条不变量（必须含六个段落、无 `{{...}}`、≤200 行、不撞 7 个保留 agent 名）任一失败就回落到静态 stub。每段都带 `<!-- source: ... -->` 来源标注。测试与 dry-run 走 `HARNESS_AI_NATIVE_MOCK` mock fixture。verify_all 28 → 29（新增 D.3 段级 sanity 检查）。 |
| 0.17.0 | 已交付 | **Supervisor agent + `/harness-supervise` skill**：旁观者辅助 agent，读取进行中或归档的 7-stage 任务文件夹，检测 4 个 anti-pattern（AP-1 同阶段 rollback 比率、AP-1b 跨阶段 rollback 总数、AP-2 阶段文档过薄、AP-3 缺 intervention check、AP-4 缺 archive 调用），按固定阈值分级 INFO/WARN/ALERT，单次调用产出一份 `SUPERVISION_REPORT.md`，最后一行 `Verdict: HEALTHY | WATCH | INTERVENE`。仅手动调用（不进入 7-stage 路由）；`allowed-tools` 白名单物理排除 `Edit`/`Bash`/`PowerShell`/`Task`/`AskUserQuestion`。新增 `verify_all I.7` 被动守护：`INTERVENE` 报告 >48h 未处理且任务仍 active → WARN。verify_all 29 → 30。 |
| 0.18+ | 规划中 | PM 在用户配置的阶段边界自动派发 supervisor（v0.18+ 在 ≥10 个真实任务证明误报预算后启用） |

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
