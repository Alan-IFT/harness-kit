# Harness Engineering for Claude Code

> 一套把 AI 自动开发架构落到 Claude Code 的 Skills 包。
>
> 目标：**人工只做"提需求"和"AI 做不到时介入"**，其他由 7-Agent 流水线 + 验证闭环自动完成。

## 这是什么

把 Harness Engineering（Rule / Skill / Script / Multi-Agent / 验证闭环 / 知识库 / 演化）方法论
封装成 Claude Code 可直接调用的 Skills，让你能在任何全栈或后端项目里：

- `/harness-init` — 给新项目从零生成 Harness 骨架
- `/harness-adopt` — 给现有项目无侵入接入 Harness
- `/harness-verify` — 跑总验证脚本（编译 + 测试 + 规则扫描 + 基线对比）
- `/harness-status` — 查看项目当前 Harness 健康度

骨架包含：

- **7 个 Sub-Agent**（PM / 需求分析 / 方案设计 / 闸门 / 开发 / 评审 / 测试）+ 角色契约
- **Rule / Skill / Script 三层**（CLAUDE.md + `.claude/skills/` + `scripts/`）
- **verify_all 总验证脚本**（PowerShell + Bash 双版本）
- **workflow.md 流程定义** + dev-map + 任务看板
- **evals 轻量回归集**

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

然后自动生成 `.claude/` + `CLAUDE.md` + `docs/` + `scripts/verify_all.*` + `evals/`。

下一步直接和 Requirement Analyst 磨第一份 SPEC，PM Orchestrator 会接管 7-Agent 流水线。

详细使用见 [docs/getting-started.md](docs/getting-started.md)。

## 架构

完整架构设计：[architecture.html](architecture.html)（浏览器打开查看可视化）

核心思路：

```
人 → 提需求
    ↓
Layer 1（项目应用资产，本仓库提供模板）
  · SPEC 文档 · 7 Agent · Rule · Skill · Script · workflow · verify_all · dev-map · 任务看板
    ↓ 调用
Layer 0（Claude Code 平台机制，已就绪）
  · Permission · Sub-agents · Hooks · MCP · Memory · Skills · Auto-compaction · /cost
```

详见 [docs/concepts.md](docs/concepts.md)。

## 仓库结构

```
harness-engineering/
├── skills/                     # Claude Code Skills（核心产物）
│   ├── harness-init/           # 初始化新项目骨架
│   ├── harness-adopt/          # 接入现有项目
│   ├── harness-verify/         # 跑总验证
│   └── harness-status/         # 查看 Harness 状态
├── docs/                       # 文档
│   ├── getting-started.md      # 上手指南
│   ├── workflow.md             # 7-Agent 工作流详解
│   └── concepts.md             # 核心概念
├── architecture.html           # 完整架构设计（HTML 可视化）
├── install.ps1                 # Windows 安装脚本
├── install.sh                  # Unix 安装脚本
├── CHANGELOG.md
└── LICENSE
```

## 设计原则

1. **不重造 Claude Code 已有的能力**（Sandbox / Hooks / Sub-agents / MCP / Memory）
2. **机制层 vs 内容层分离**：平台给机制，本仓库给内容
3. **演化式落地**：MVP → Hardening → Scale，不一次到位
4. **基线只升不降**：测试数量、规则覆盖率永远不准退步
5. **发现问题的人不能修问题**：Reviewer 不改代码，Gate 不改需求
6. **下游不能改上游文档**：只能提阻塞回退给 PM
7. **PM 只做路由，不做专业判断**

## 贡献 & 反馈

issues / PRs 欢迎。详见 [CHANGELOG.md](CHANGELOG.md)。

## License

MIT
