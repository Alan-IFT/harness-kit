# Harness Kit

[English](README.md) · **简体中文**

![version](https://img.shields.io/badge/version-0.30.1-blue) ![verify_all](https://img.shields.io/badge/verify__all-32%2F32-brightgreen) ![test-init](https://img.shields.io/badge/test--init-287%2F287-brightgreen) ![integration](https://img.shields.io/badge/integration-82%2F82-brightgreen) ![license](https://img.shields.io/badge/license-MIT-green)

> **Claude Code 的 Harness Engineering 工具包** — 一个 Claude Code Plugin（15 个 skills + 8 个框架 agent + 项目模板），把"有纪律的 AI 驱动开发"带到全栈和后端项目里。**Claude 原生**（框架 agent 以 plugin agent 形式分发，不再逐项目拷贝）。
>
> **目标**：人工只做"描述需求"和"AI 做不到时介入"；其他全部 — 7-Agent 流水线、验证闸门、结构化文档 — 自动运行。

## 包含什么

这是一个 Claude Code Plugin 包，给任何项目装上 15 个 AI skill：

**流水线类**（6 种任务形态，AI 根据你的自然语言自动挑对应那条）
- `/harness-kit:harness` — 完整 7-stage 流水线（RA → SA → GR → Dev → CR → QA → 交付）。用于真正的功能 / bug / 重构。
- `/harness-kit:harness-plan` — 只做设计：跑 RA + SA + GR，给出判决后停止，**不写代码**。用于"投入工程时间前先验证设计"。
- `/harness-kit:harness-explore` — 调研/可行性：轻量 RA + 一份带引用的 `findings.md`。**不做设计、不写代码**。用于"这事儿到底能不能做？"
- `/harness-kit:harness-goal` — 开放式 Dev + QA 循环，由可量化的成功标准 + 预算限定。用于"持续改进直到覆盖率 > 80%"这类任务。
- `/harness-kit:harness-batch` — 把 `T-01…T-NN`（`docs/batches/<batch-id>/BATCH_PLAN.md` 里的任务表）一条条顺序灌给 pm-orchestrator 跑，每条都派发到独立的 Task 子 agent，主上下文只累加每任务一行的摘要。仅在强信号上停止（`verify_all` FAIL、pm-orchestrator FAIL、intervention STOP、安全 hook 拦截）。适合 `/harness-plan` 拆出来的批、积压 bug 列表、checkup 后修复批、外部任务列表 —— 比手敲 N 次 `/harness` 省力。
- `/harness-kit:harness-stream` — 像 batch，但任务池是**活的**：每轮迭代都重读 `BATCH_PLAN.md`，所以你运行中追加的任务（聊天框里发、或直接往池里追加、或发 `ADD` 干预）会被自动规划执行，**无需重新调用**。**尽力完成**语义（某任务失败就标记+跳过，整条流不停）+ 与 batch 相同的硬安全急停。适合"想到啥需求就丢进去、只看结果"的常驻开发流。**环境模式（ambient）：** 直接不带 pool-id 调用即可——会自动创建默认池（`docs/batches/default/`），并由一个 `UserPromptSubmit` hook（受 `.harness/ambient.flag` 开关控制）把你每条聊天消息变成心跳：自动把需求折叠进池子并排干，无需 `/loop`、无需重新调用、无需口令。**会话级生效**：`SessionStart` hook 在每个新会话自动清除 flag，想继续就再调用一次 `/harness-stream`。

**安装类**
- `/harness-kit:harness-init` — 新项目从零生成 Harness 骨架（问 6 个问题，~30 秒生成 `.harness/` + `.claude/` + `AI-GUIDE.md` + stub CLAUDE.md / copilot-instructions.md）
- `/harness-kit:harness-adopt` — 给现有项目无侵入接入 Harness（侦察栈、提取约定、用户确认后再 apply）
- `/harness-kit:harness-upgrade` — 把已初始化但**过时**的项目升级到当前插件布局（把脚本迁到 `.harness/scripts/`、对深度敏感脚本做内容刷新以修正 repo-root 推导、重装 pre-commit hook、改写 settings、从类型模板重新生成 `verify_all` 同时保留你的 B.* 检查 —— 带 dry-run 预览、幂等、最后用一次绿色 `verify_all` 证明）
- `/harness-kit:harness-language` — 设置、切换（英文 ↔ 中文）或刷新项目的输出语言策略：只精准改写三处策略载体（`.harness/rules/00-core.md` 的策略章节 + `CLAUDE.md` 顶部那行 + `.github/copilot-instructions.md` 顶部那行），换成目标语言当前的标准策略文本（英文为单一英文策略；中文为按消费者分流的策略）。文本从插件模板自举（旧项目也能拉到刷新后的策略），非破坏、幂等、带 dry-run 预览、每个文件先写 `.bak`。

**运维类**
- `/harness-kit:harness-verify` — 跑总验证（编译 + 测试 + 规则扫描 + 基线对比）
- `/harness-kit:harness-status` — 健康度快照（哪些资产存在、基线、最近 verify 状态、活动任务）
- `/harness-kit:harness-intervene` — 给正在跑的流水线发"软 Ctrl-C"：写一个 `STOP` / `REDIRECT` / `SKIP` / `NOTE` 信号文件，PM 在下一次阶段切换时消费
- `/harness-kit:harness-supervise` — 旁观者辅助 skill（v0.17+）：读取进行中或归档的任务文件夹，产出 `SUPERVISION_REPORT.md`，标注 anti-pattern（rollback 比率、阶段文档过薄、缺 intervention check、缺 archive 调用），分 `INFO`/`WARN`/`ALERT`，最后一行给出 `HEALTHY`/`WATCH`/`INTERVENE` 判决
- `/harness-kit:harness-decision-mode` — 设置或切换项目的决策/升级**模式**：Mode 1（人工决策，默认）、Mode 2（AI 按预设 rubric 自己拿主意）、Mode 3（AI 按你自己的自定义 rubric 决策）。只外科式改写 `.harness/rules/25-decision-policy.md` 里的"Active mode"那一行；首次切到 Mode 3 时收集你的自定义决策提示。非破坏、幂等、要求干净 git 工作区

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

6 个问题（`AskUserQuestion` 弹窗）：
1. 项目类型 — Fullstack / Backend / Generic（CLI / 库 / 移动 / ML / 嵌入式 等）—— 三种一等公民 overlay
2. 技术栈 — 自由文本（如 "Next.js + NestJS + Postgres"、"Rust CLI tool"、"PyTorch 训练流水线"）
3. 启用 `verify_all` Stop hook — Yes / No
4. Developer 分区 — Partitioned（默认）/ Single（Generic 跳过此问题，默认单 developer，项目长大后 AI 再建议分区）
5. 项目输出语言 — English（默认）/ 中文
6. AI 定制 `50-<project>.md` 规则片段 — opt-in（默认 No，仅用静态模板）

~30 秒后你的项目里就有：
- 7 个框架 agent（+ supervisor）以 `harness-kit:<name>` 形式由 plugin 提供 —— **不再拷贝进项目**
- `.harness/`（项目真相源：rules、skills，以及任何分区 `dev-*` agent）
- `.claude/`（Claude Code binding：`agents/` 分区 `dev-*` + `skills/` 从 `.harness/` 同步，外加 `settings.json`）
- `.github/copilot-instructions.md`（Copilot bootstrap stub）
- `CLAUDE.md`（Claude Code 读的 bootstrap stub —— 指向 `AI-GUIDE.md`）
- `docs/`（workflow、dev-map、tasks、spec）
- `.harness/scripts/`（verify_all、harness-sync、baseline）
- `evals/`（金标准回归任务）

然后描述任务：

```
Take this task: 在订单页加 CSV 导出按钮。
```

PM Orchestrator 接手，跑完 7 个 stage，在 `docs/features/<slug>/` 下产出 6 份阶段文档，写代码、跑 verify_all，最后给你一个完成的 feature。

## 核心特性

### 规则真相源（v0.10 —— progressive disclosure）

```
.harness/rules/*.md     ← 你只编辑这里（单一真相源，模块化片段）
       ↑
       │  被引用
       │
AI-GUIDE.md             ← 默认 Claude 原生入口（~50 行索引，每条带"什么时候读"）
       ↑
       │  被指向
       │
CLAUDE.md                            (~15 行 bootstrap stub；Claude Code 读)
.github/copilot-instructions.md      (~15 行 bootstrap stub；Copilot 读)
```

你编辑一个地方：`.harness/rules/`。stub 和 AI-GUIDE.md 都靠引用，**不再生成**。AI 工具跟着引用、**按需懒加载相关片段** —— 跟 Claude Code 自己的 skill 系统同模式。

**Context 预算**：常驻 system prompt 的规则集从 ~3500 token（v0.9.x 全量 CLAUDE.md）降到 ~250 token（v0.10 stub）。小问答里（~92% 节省）AI 甚至不读 AI-GUIDE.md。中等任务读 AI-GUIDE.md 一次 + 触发条件命中的 1-3 个片段，平均 ~50% 节省。

v0.30 起框架 agent 由 plugin 提供（`harness-kit:<name>`），不再拷贝进你的项目。`harness-sync` 还在，只复制 `.harness/agents/`（仅分区 `dev-*`）和 `.harness/skills/` 到 `.claude/`（Claude Code 强要求这些路径）。规则不 sync。git pre-commit hook（来自 `.harness/scripts/install-hooks`）兜底保证 Copilot / Cursor / 手编辑用户的 `.claude/` 也跟得上 `.harness/`。

### 项目级语言策略

中文团队 init 时选 `中文` — 产出**按消费者分流**：面向人的产出（对话回复、状态报告、错误消息、交付总结、README 及人读文档）用**中文**；面向 agent/LLM 的产出（7-stage 阶段文档、PM_LOG、tasks.md / dev-map / insight-index 台账、agent / rule / AI-GUIDE / CLAUDE 编辑、代码注释、commit message）用**英文** —— LLM 读英文同样顺畅，也与英文框架内部保持一致。即使你用其他语言提问，对话回复仍用中文。分流定义在项目的 `.harness/rules/00-core.md` "输出语言" 章节。

英文项目只有一种语言 —— 全英文，不分流。

### Developer 分区

全栈：`dev-frontend` / `dev-backend` / `dev-db` agents，每个有 owned-paths glob。Solution Architect 产出 partition assignment 表；PM 按依赖顺序派发（默认 db → backend → frontend）。越界改动报 `BLOCKED ON PARTITION`，PM 重新路由。

后端：同样思路，三层 — `dev-api` / `dev-services` / `dev-db`。

小项目可选 single developer 模式。

### 跨工具切换（Claude Code ↔ Copilot）

Claude Code 5 小时额度用完？切到 VS Code + GitHub Copilot 继续，额度恢复后切回。任务状态全部持久化在文件里（`docs/tasks.md`、`docs/features/<task>/`、`PM_LOG.md`），不在会话记忆里 — resume 只需要读这些文件。两个工具的 binding 都包含 `.harness/rules/60-tool-handoff.md` 定义的切换协议。

### 三层回归测试

- `verify_all`（32 项检查）— 仓库本身健康度
- `test-init` — init 模板逻辑（空目录；覆盖 3 种项目类型，外加 migrate-layout 块、zh-overlay 消费者分流策略断言、v0.30 通用 agent 不落地断言、以及 BUG-2 placeholder 正则回归；计数随 v0.30 agent 切换而变动，实时计数见 `.harness/scripts/baseline.json`）
- `test-real-project`（82 断言）— 真实 fixture 上 overlay（todo-fullstack、todo-backend）

每个 commit 必须三套都过。`test-init` 和 `test-real-project` 端到端走通生成项目的结构，离线秒级跑。

### Dogfood

本仓库自己用 Harness Kit 开发。同样的 7-agent 流水线（以 `harness-kit:<name>` plugin agent 形式）既给用户也管理本仓库的工作，跑在同一份 rules / skills 真相源上 —— 就是 init 写进新项目的那份。如果我们自己用不下去，就不该 ship。

## 仓库布局

```
harness-kit/
├── skills/                       Claude Code Skills（产品）
│   ├── harness-init/             Bootstrap skill + 模板
│   │   └── templates/
│   │       ├── common/           共享资产（基础规则、docs、evals；框架 agent v0.30 起不在这里）
│   │       ├── fullstack/        全栈 overlay（分区 dev-* agents、overlay rules）
│   │       ├── backend/          后端 overlay
│   │       └── i18n/zh/          中文翻译 overlay
│   ├── harness-adopt/
│   ├── harness-verify/
│   ├── harness-status/
│   └── harness-intervene/
│
├── agents/                       Plugin 原生框架 agent（v0.30+）：7 个 canonical + supervisor
│                                 （自动发现，以 harness-kit:<name> 派发；唯一来源）
├── .claude-plugin/               Claude Code plugin manifests
│   ├── plugin.json
│   └── marketplace.json
│
├── .harness/                     本仓库项目 SOT（dogfood）
│   ├── agents/                   仅分区 dev-* agent（本仓库为空；框架 agent 已移到顶层 agents/）
│   ├── rules/                    本仓库特定规则
│   └── scripts/                  verify_all、harness-sync、sync-self、test-init… （v0.20 起迁来此处）
├── AI-GUIDE.md                   默认 Claude 原生入口（索引 .harness/rules/）
├── .claude/                      Claude Code binding（harness-sync 重新生成）
├── CLAUDE.md                     ~15 行 stub，指向 AI-GUIDE.md（init 时一次性生成）
├── .github/copilot-instructions.md  ~15 行 stub，指向 AI-GUIDE.md
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
| 0.17.1 | 已交付 | **补丁清扫**：BUG-2（I.7 active-row slug 匹配在两个 shell 上改为列锚定，消除 `foo` / `foo-extra` 子串误判）+ BUG-3（`supervisor.md` 边界表在 cross-task N=0 上的文档漂移，与 `harness-supervise` SKILL.md 对齐）。无功能变更；verify_all 仍 30 项检查。 |
| 0.17.2 | 已交付 | **`settings.json` schema 修复**：Claude Code settings schema 把 `hooks` 对象声明为 `additionalProperties: false`——只有真实的 hook 事件名才是合法键。harness-kit 把 `_doc_sync_hook` / `_guard_hook` 文档说明字符串放在了 `hooks` 对象*内部*，导致每个生成的 `.claude/settings.json` 都无法通过 schema 校验。两个键已移至根对象（`additionalProperties: true`，根层允许 `_*` 文档键）。无功能变更；verify_all 仍 30 项检查。 |
| 0.17.3 | 已交付 | **bootstrap 红线措辞修复**：`CLAUDE.md` / `copilot-instructions.md` 的红线把 `.claude/` 错标成"生成/静态文件"。`.claude/settings.json` 两者都不是——它是 agent 活的、手工维护的启动配置。该条拆成两条：一条讲 `.claude/`（活配置 + 同步生成的 `agents/`/`skills/`，附正确理由），一条讲真正的静态 stub。修了 4 个模板 + 2 个 dogfood 文件。无功能变更；verify_all 仍 30 项检查。 |
| 0.17.4 | 已交付 | **v0.10 文档漂移清扫**：把残留在 live 文档/注释里的 v0.10 之前措辞扫干净 —— 不再把 `harness-sync` 描述成会重新生成 `CLAUDE.md` / `copilot-instructions.md`，也不再把 `CLAUDE.md` 错标成"生成的"。改了 `00-core.md` 规则模板（中英）、`settings.json` 模板、`dev-frontend` 模板、README 布局框、getting-started、CONTRIBUTING、init/adopt 两个 skill，并把 `verify_all` I.6 豁免注释与代码对齐。无功能变更；verify_all 仍 30 项检查。 |
| 0.18.0 | 已交付 | **I.6 gap-tolerant retired-claim 守护**：`verify_all` I.6 短语守护从字面子串匹配升级为 gap-tolerant 有序锚点扫描 —— 每条黑名单条目是一组纯文本锚点，必须在一行内按顺序出现且间隔在限定范围内，并可带行级 `exclude` token，使准确的否定表述不再误 FAIL。I.6 豁免目录拓宽到整个 `docs/features/` 子树。新增 `.harness/scripts/test-verify-i6.{ps1,sh}` 回归脚本对。无新增检查；verify_all 仍 30 项。 |
| 0.18.1 | 已交付 | **`test-verify-i6` 加固**：结构化锁步升级到完整的 2×2（`test-verify-i6.{ps1,sh}` × `verify_all.{ps1,sh}`）逐条目 × 4 字段（anchors / reason / exclude / gap）逐字比较 —— 修复 v0.18.0 留下的 PS 侧只校 entry count + 第 #10 条 `.claude/` exclude 的缺口。新增与现有 dir-exempt 对称的 file-exempt 谓词，并对 I.6 exempt-file (`CHANGELOG.md`、`architecture.html`、…) 与 exempt-dir 列表做逐元素锁步。AC-8（`CHANGELOG.md` / `_archived/` 豁免）从 v0.18.0 的临时 inline-injection 探针升级为永久 corpus fixture。断言计数：35→56（PS）、34→56（bash）；verify_all 仍 30 项。 |
| 0.18.2 | 已交付 | **`settings.json` schema 校验守护（J.1）**：dogfood 与模板里的 `.claude/settings.json` `$schema` URL 漏写了 `.json` 后缀，导致 301 重定向目标返回 `application/octet-stream`，许多编辑器静默拒绝加载 schema —— 即使 JSON 能解析整个文件仍被标记非法。已恢复为规范 URL。新增 `verify_all` J.1 检查同时解析仓库文件与 `.tmpl`，强制 `$schema` 取规范值，并拒绝 `hooks` 下任何非上游事件枚举里的键 —— 在 gate 一次性拦截 v0.17.2（键位错放）和 v0.18.2（URL 形式错）两类错误。新规则片段 `.harness/rules/80-settings-schema.md` 沉淀"修改前先用 context7 查官方 schema"的工作流。verify_all 30 → 31 项。 |
| 0.19.0 | 已交付 | **批量模式**：新 skill `/harness-kit:harness-batch <batch-id>`，把 `docs/batches/<batch-id>/BATCH_PLAN.md` 里的 `T-01…T-NN` 顺序灌给 `pm-orchestrator` 执行，每个任务通过 `Task` 工具派发到独立子 agent 上下文，主上下文只累加每任务一行摘要。仅在强信号上停止（`verify_all` FAIL、pm-orchestrator FAIL、3 次同阶段 rollback、`intervention.md` STOP、安全 hook 拦截）。可重入：再次用同一 `<batch-id>` 调用会跳过已 `DELIVERED` 的任务。新增 `docs/batches/` 目录（lifecycle README + `_template/BATCH_PLAN.md`）。`verify_all` skill 数 10 → 11（C.1 / G.1 / G.2 两个 shell 都已对齐）。 |
| 0.20.0 | 已交付 | **脚本搬迁**：所有 harness 自带脚本从 `scripts/` 移到 `.harness/scripts/`，不再与用户项目自己的 `scripts/` 目录冲突。新增幂等的 `.harness/scripts/migrate-scripts-layout.{ps1,sh}` 助手，为既有项目迁移（带时间戳 `.bak`、`-DryRun`/`-Force`、外科式路径改写）。所有 live 路径引用、hook 接线（模板 + 仅提议的 dogfood settings）、`verify_all` 自检（两个 shell）、贡献者文档 + `MIGRATION.md` 同步更新。`verify_all` 仍 31 项检查。 |
| 0.22.0 | 已交付 | **流式 / 活池模式**：新 skill `/harness-kit:harness-stream <pool-id>`，把一个可持续追加的任务池（`docs/batches/<pool-id>/BATCH_PLAN.md`）一条条灌给 pm-orchestrator 执行，每轮迭代重读任务池，所以运行中追加的任务（聊天 / 池内追加 / `ADD` 干预）会被自动规划，无需重新调用。**尽力完成**（失败任务标记+跳过，整条流继续）对比 batch 的失败即停；硬安全急停一致（`verify_all` FAIL / `STOP` / 安全 hook）。新增 `ADD <slug> — <goal>` 干预关键字（池作用域）。`verify_all` skill 数 11 → 12。 |
| 0.23.0 | 已交付 | **升级旧项目**：新增安装类 skill `/harness-kit:harness-upgrade`，把已初始化但过时的项目升级到当前插件布局——把脚本迁到 `.harness/scripts/`，**内容刷新**深度敏感脚本（修正迁移后仍是一级向上的 repo-root 推导），重装 pre-commit hook，改写 `.claude/settings.json`（裸文本替换，绝不重新序列化），并从类型模板重新生成 `verify_all`，同时用 `HARNESS:B-CUSTOM` 分隔符保留用户的 B.* 检查（原样拼接，或停下来要确认）。一个确定性 helper `upgrade-project.{ps1,sh}`（dry-run、幂等、退出码契约）；6 个 `verify_all` 模板加入无副作用的 B.* 标记。`verify_all` skill 数 12 → 13（检查数仍为 32）。 |
| 0.30.0 | 已交付 | **Agent 切换（重设计 Leg 1 完成）**：7 个框架 agent（+ supervisor）改为 **plugin 原生**（顶层 `agents/`，以 `harness-kit:<name>` 派发）—— 项目不再拷贝它们，彻底消除 agent 的重复/漂移这一类问题。所有 skill 的流水线派发切到 `harness-kit:<name>`；分区 `dev-*` agent 仍保留在项目本地。`sync-self` 去掉 agent 镜像；`verify_all` D.1/E.3/E.4/I.3 重新指向 `agents/`。`verify_all` 仍 32 项检查，skill 仍 15 个。 |
| 0.20+ | 规划中 | PM 在用户配置的阶段边界自动派发 supervisor（在 ≥10 个真实任务证明误报预算后启用）。**流式并行派发——已暂缓**：经一轮对抗评审的设计（[docs/parallel-stream-design.html](docs/parallel-stream-design.html)）结论是，串行 stream + 现有的任务内 partition 并行已满足需求；**Model B**（同树 partition、无合并）作为按需路径，仅当攒到一批真正解耦、Amdahl 账算得过来的任务才做；**Model A**（worktree 真并行）搁置（风险 > 收益：env 供给、Windows junction、每任务分支提交、合并活锁需整套调度/协调层）。 |

## 设计原则

1. **不重造平台机制** — Sandbox、Hooks、Sub-agents、MCP、Memory 是 Claude Code 的事
2. **机制 vs 内容** — 平台给机制，本仓库给内容
3. **默认 Claude 原生** — 框架 agent 以 plugin agent（`harness-kit:<name>`）分发；`.harness/` 是项目的规则/skill/分区 agent 真相；`.claude/agents/`（分区 `dev-*`）+ `.claude/skills/` 是同步出来的 binding；`CLAUDE.md` + `.github/copilot-instructions.md` 是静态 bootstrap stub。
4. **演化式交付** — MVP → Hardening → Scale，不是大爆炸
5. **基线只升不降** — 测试数、规则覆盖永远不悄悄退步
6. **发现者不修** — Reviewer 不能改代码，Gate 不能改需求
7. **下游不能改上游** — 只能通过 PM 提阻塞回退
8. **PM 只路由** — 永不给专业判断

## 贡献

见 [CONTRIBUTING.md](CONTRIBUTING.md)。欢迎 PR 和 issue。

## License

[MIT](LICENSE)
