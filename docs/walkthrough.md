# Walkthrough: How to Actually Use This

从 "我刚听说 Harness Engineering" 到 "我用它在 todo-list 项目交付了第一个 feature" 的完整流程。

> 角色：你是项目的 owner / lead engineer。AI 做执行，你做提需求 + 关键节点确认。

## 总览（一张图）

```
┌─────────────────────────────────────────────────────────────────────┐
│  一次性 (10 分钟)                                                    │
│  ① 装 Skills → ~/.claude/skills/                                    │
│  ② 在项目目录跑 /harness-init (新项目) 或 /harness-adopt (现有)     │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  日常 (每个 feature / bug)                                          │
│  ③ 在 Claude Code 里说 "Take this task: ..."                        │
│  ④ PM 把任务派给 7 个 Agent 走流水线                                │
│  ⑤ 你只在 2-3 个关键节点确认（歧义答复、闸门 review、最终）         │
│  ⑥ 任务完成 → 代码已写 + 测试已加 + 文档归档                        │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  系统进化 (AI 反复犯错时)                                            │
│  ⑦ 编辑 .harness/rules/ 或 .harness/skills/ → 跑 harness-sync       │
│  ⑧ 下次任务 AI 自动遵守新规矩                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Step 1 (一次性): 装 Skills

```powershell
# Windows
git clone <repo-url> ~/harness-engineering
& ~/harness-engineering/install.ps1
```

```bash
# macOS / Linux
git clone <repo-url> ~/harness-engineering
~/harness-engineering/install.sh
```

装完后 `~/.claude/skills/` 里有 4 个 skill 目录：

```
~/.claude/skills/
├── harness-init/
├── harness-adopt/
├── harness-verify/
└── harness-status/
```

Claude Code 任何会话都能看到 `/harness-init` 等命令。

---

## Step 2 (每个新项目): Bootstrap

### 场景 A：新项目

```bash
mkdir my-todo-app && cd my-todo-app
claude     # 启动 Claude Code
```

在 Claude Code 会话里：

```
> /harness-init
```

**会发生什么**：

Skill 弹出 4 个问题（一次性问完）：

| 问题 | 选项 | 我们选 |
|---|---|---|
| Project type? | Fullstack / Backend | **Fullstack** |
| Stack? | 自由输入 | **Next.js 14 + NestJS + Prisma + Postgres** |
| Enable verify_all hook on Stop? | Yes / No | **Yes** |
| Developer partitioning? | Partitioned (default) / Single | **Partitioned** |

Skill 自动做：

1. 复制模板（`templates/common/` + `templates/fullstack/`）到当前目录
2. 占位符替换（PROJECT_NAME=my-todo-app, STACK=...）
3. 跑 `scripts/harness-sync.ps1` 生成 `.claude/agents/`、`.claude/skills/`、`CLAUDE.md`
4. 写 `scripts/baseline.json` 初始基线（测试数=0）
5. `git init -b main`（如果还不是 git repo）
6. 输出汇总

完成后你的项目结构：

```
my-todo-app/
├── .harness/                      ← 你编辑这里
│   ├── agents/
│   │   ├── pm-orchestrator.md
│   │   ├── requirement-analyst.md
│   │   ├── solution-architect.md
│   │   ├── gate-reviewer.md
│   │   ├── developer.md          ← generic fallback
│   │   ├── dev-frontend.md       ← 分区
│   │   ├── dev-backend.md        ← 分区
│   │   ├── dev-db.md             ← 分区
│   │   ├── code-reviewer.md
│   │   └── qa-tester.md
│   ├── rules/
│   │   ├── 00-core.md           ← 项目规则（带 PROJECT_NAME）
│   │   └── 50-fullstack.md      ← fullstack 专属规则
│   └── skills/
│       ├── build/SKILL.md
│       ├── test/SKILL.md
│       └── verify/SKILL.md
│
├── .claude/                       ← 生成（不编辑）
│   ├── agents/      ← 与 .harness/agents/ 内容一致
│   ├── skills/
│   └── settings.json
├── CLAUDE.md                      ← 从 .harness/rules/ 合成
│
├── docs/
│   ├── workflow.md
│   ├── spec/README.md
│   ├── dev-map.md                 ← 空模板，AI 在工作中填充
│   ├── tasks.md                   ← 空看板
│   └── features/                  ← 每个任务一个子目录
│
├── scripts/
│   ├── verify_all.{ps1,sh}
│   ├── harness-sync.{ps1,sh}
│   └── baseline.json              ← test_count: 0
│
└── evals/golden-tasks.md
```

**这就是骨架。还没有业务代码——只有 Harness 资产。**

### 场景 B：现有项目

如果 `my-todo-app` 里已经有代码：

```
> /harness-adopt
```

Skill 会：
1. **侦察** — 扫包文件、测试配置、CI、README/CONTRIBUTING 找规范候选
2. **询问** — 同 init 的 4 个问题，但 pre-fill 检测到的值
3. **写方案** — `.harness-adopt/PLAN.md`，列要加什么、冲突在哪
4. **等你确认** — "Apply this plan? [yes / no / show plan]"
5. **应用** — 不修改任何现有文件，只新增
6. **跑 verify_all 捕获 baseline** — 当前测试数作为基线（而不是从 0 开始）

---

## Step 3 (日常): 派发任务

现在做一个具体功能：**"导出所有 todos 为 CSV 文件"**。

在 Claude Code 会话里：

```
> Take this task: Add a CSV export button to the todo list page that downloads all todos.
```

PM Orchestrator 接到任务。**接下来的事都是 AI 做的，你只在卡点确认**。

### Stage 1: requirement-analyst（需求分析，~2-3 min）

PM 调起 Requirement Analyst。Analyst 做：

1. 创建 `docs/features/csv-export-todos/INPUT.md`（保留你的原话）
2. 读 `docs/tasks.md`（任务看板）——空的，无历史任务
3. 读 `docs/spec/`（无具体 spec）
4. 写 `01_REQUIREMENT_ANALYSIS.md`，识别出歧义

**你被询问**（AskUserQuestion UI 弹出）：

```
1. CSV 应该包含哪些字段？
   [A] id, text, done
   [B] id, text, done, created_at
   [C] 其他

2. 是否包含已完成的 todos？
   [A] 全部
   [B] 仅未完成
   [C] 让用户选

3. 文件名格式？
   [A] todos-2026-05-15.csv
   [B] todos.csv
   [C] todos-{user-input}.csv
```

你选了 **B, A, A**。

Analyst 完成需求文档：

```markdown
# Requirement Analysis: CSV Export Todos

## Goal
Allow users to download all their todos as a CSV file with one click.

## In-scope behaviors
1. A "Export CSV" button appears on the todos page.
2. Clicking triggers download of `todos-YYYY-MM-DD.csv`.
3. CSV contains: id (UUID), text (string), done (boolean), created_at (ISO 8601).
4. All todos are exported (no filter; client orders by created_at desc).

## Out-of-scope
- Filtering / search before export.
- Server-side scheduled exports.
- Other formats (xlsx, json).

## Acceptance criteria
- AC-1: button renders on /todos page, accessible (aria-label).
- AC-2: click results in a Content-Disposition: attachment response.
- AC-3: file mime type is text/csv.
- AC-4: filename matches todos-YYYY-MM-DD.csv pattern.
- AC-5: row order matches client-side created_at desc.

## Verdict: READY
```

### Stage 2: solution-architect（方案设计，~3-5 min）

PM 调起 Architect。Architect 做：

1. 读需求文档
2. **读代码** — grep `todos` 找现有 todo 实现
3. 读 `docs/dev-map.md`（空，但能从目录推断）
4. 写 `02_SOLUTION_DESIGN.md`

关键章节（v0.4+ partition assignment 必需）：

```markdown
## Affected modules

- `apps/api/src/todos/todos.controller.ts` — edit (add export endpoint)
- `apps/api/src/todos/todos.service.ts` — edit (add listForExport method)
- `apps/web/src/components/ExportButton.tsx` — new
- `apps/web/src/app/todos/page.tsx` — edit (mount button)
- `apps/web/src/lib/csv.ts` — new (CSV serialization helper)

## Reuse audit
| Need | Existing | File | Decision |
|---|---|---|---|
| Todo data fetch | `todosService.list()` | `apps/api/src/todos/todos.service.ts` | Extend with listForExport() |
| CSV libraries | (none) | — | New helper (3 lines, no dep) |
| Download trigger | (none) | — | Standard Blob + a-tag pattern |

## Partition assignment
| File | Partition | Action | Dependency |
|---|---|---|---|
| apps/api/src/todos/todos.service.ts | dev-backend | edit | — |
| apps/api/src/todos/todos.controller.ts | dev-backend | edit | depends on service |
| apps/web/src/lib/csv.ts | dev-frontend | new | — |
| apps/web/src/components/ExportButton.tsx | dev-frontend | new | depends on csv.ts |
| apps/web/src/app/todos/page.tsx | dev-frontend | edit | depends on ExportButton |

## Dispatch order
1. dev-backend (service + controller)
2. dev-frontend (csv.ts → ExportButton → page edit)

## Parallelism
None — frontend consumes backend's new endpoint.

## Verdict: READY
```

### Stage 3: gate-reviewer（闸门审查，~2 min）

Gate Reviewer 做 **8 维度审计**：

| 维度 | 结论 |
|---|---|
| 需求完整性 | PASS — 所有 AC 可测 |
| 设计完整性 | PASS — 每个 AC 都有对应实现 |
| 复用正确性 | PASS — `todosService.list()` 确实存在 (gate 实际打开文件验证) |
| 风险覆盖 | WARN — 大 todo list 内存压力未提；建议加 limit 默认 10000 |
| 迁移安全 | PASS — 无 schema 变更 |
| 边界处理 | PASS — empty list 行为已定义 |
| 测试可行性 | PASS |
| 分区清晰 | PASS — 边界明确 |

**Verdict: APPROVED WITH CONDITION**: 加默认 limit=10000，超出则警告（不强制 fail）。

PM 决策：把这个 condition 写进 design 备注，advance to dev。

### Stage 4: 派分区开发

PM 看 Architect 的 partition assignment。两个分区按顺序派。

#### 4a. dev-backend 接手（~5-10 min）

dev-backend agent：
1. 读 01-03 文档 + CLAUDE.md
2. 读 `apps/api/src/todos/todos.service.ts`（既有代码）
3. 跑 verify_all 捕获 baseline
4. 实现：
   ```typescript
   // apps/api/src/todos/todos.service.ts
   async listForExport(limit: number = 10000): Promise<Todo[]> {
     return this.prisma.todo.findMany({
       take: limit,
       orderBy: { createdAt: 'desc' },
     });
   }
   ```
   ```typescript
   // apps/api/src/todos/todos.controller.ts
   @Get('export.csv')
   async exportCsv(@Res() res: Response) {
     const todos = await this.todosService.listForExport();
     const filename = `todos-${new Date().toISOString().slice(0, 10)}.csv`;
     res.setHeader('Content-Type', 'text/csv');
     res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
     res.send(this.toCsv(todos));
   }
   ```
5. 加单测覆盖 `listForExport`
6. 跑 verify_all → PASS
7. 写 `04a_DEVELOPMENT_backend.md`
8. Verdict: READY FOR REVIEW (backend partition complete)

#### 4b. dev-frontend 接手（~5-10 min）

dev-frontend agent：
1. 读 docs（含 backend partition 完成报告）
2. 实现：
   ```typescript
   // apps/web/src/lib/csv.ts (no deps)
   export function downloadCsv(filename: string, csv: string) {
     const blob = new Blob([csv], { type: 'text/csv' });
     const url = URL.createObjectURL(blob);
     const a = document.createElement('a');
     a.href = url; a.download = filename; a.click();
     URL.revokeObjectURL(url);
   }
   ```
   ```tsx
   // apps/web/src/components/ExportButton.tsx
   export function ExportButton() {
     const handleClick = async () => {
       const res = await fetch('/api/todos/export.csv');
       const csv = await res.text();
       const filename = `todos-${new Date().toISOString().slice(0, 10)}.csv`;
       downloadCsv(filename, csv);
     };
     return <button onClick={handleClick} aria-label="Export todos">Export CSV</button>;
   }
   ```
   ```tsx
   // apps/web/src/app/todos/page.tsx (edit)
   import { ExportButton } from '@/components/ExportButton';
   // ... 在 page header 加 <ExportButton />
   ```
3. 加 frontend 测试
4. 跑 verify_all → PASS
5. 写 `04b_DEVELOPMENT_frontend.md`
6. Verdict: READY FOR REVIEW (frontend partition complete)

PM 标记两个 partition 都 complete → advance to stage 5。

### Stage 5: code-reviewer（代码审查，~3-5 min）

Code Reviewer 做 **6 维度审查**，关键是**对照需求每条 AC**：

```markdown
## Requirement coverage check

| Criterion | Implementation | Status |
|---|---|---|
| AC-1 button renders on /todos page, accessible | `apps/web/.../page.tsx:14`, `ExportButton:6 aria-label` | ✅ |
| AC-2 Content-Disposition: attachment | `controller:32` | ✅ |
| AC-3 text/csv mime | `controller:31` | ✅ |
| AC-4 filename pattern | `controller:34`, `ExportButton:11` | ✅ |
| AC-5 row order created_at desc | `service:42 orderBy: { createdAt: 'desc' }` | ✅ |

## Findings
- MINOR [PERF]: `listForExport` returns all rows in memory. Fine at current
  scale but flag for v0.6 if users have >10k todos.
- NIT [STYLE]: csv.ts could use a named export instead of default.

## Verdict: APPROVED (0 CRITICAL / 0 MAJOR / 1 MINOR / 1 NIT)
```

### Stage 6: qa-tester（测试验证，~3-5 min）

QA Tester：
1. 读 04+05 文档
2. 加测试覆盖每条 AC：
   ```typescript
   // tests/csv-export.test.ts
   test('GET /api/todos/export.csv returns text/csv', ...);
   test('CSV contains expected columns', ...);
   test('filename matches date pattern', ...);
   test('empty list returns header-only CSV', ...);  // boundary
   test('large list (10000 todos) succeeds', ...);   // perf check
   ```
3. 跑 verify_all → PASS
4. 更新 `scripts/baseline.json`：test_count 从 X 升到 X+5
5. 写 `06_TEST_REPORT.md`
6. Verdict: APPROVED FOR DELIVERY

### Stage 7: PM 收尾（~1 min）

PM 写 `07_DELIVERY.md`：

```markdown
# Delivery Summary

- Task: csv-export-todos
- Stages: 7 (no rollbacks)
- Final verify_all: PASS
- Baseline: test_count 38 → 43 (+5)
- Files changed: 6 (5 new, 1 edit) — see git diff
- Outstanding risks: large-list perf (MINOR, flagged for v0.6)
- Next steps: none
```

PM 更新 `docs/tasks.md`：

```markdown
## Completed tasks
| T-001 | csv-export-todos | Delivered | 2026-05-15 | docs/features/csv-export-todos/ |
```

如果有新模块，PM 还会更新 `docs/dev-map.md`。

**任务完成。你只回答了 3 个问题（需求阶段的 AskUserQuestion）。**

---

## Step 4 (日常其他命令)

### `/harness-verify` — 验仓库健康
```
> /harness-verify
verify_all: PASS
  19 checks: 19 PASS, 0 WARN, 0 FAIL
  Baseline: test_count 43
  Last run: just now
```

### `/harness-status` — 健康度快照
```
> /harness-status

Health: 11/11
Assets:
  ✓ CLAUDE.md present
  ✓ docs/workflow.md present
  ...
Baseline:
  test_count: 43 (was 38)
  warnings_baseline: 0
  last_updated: 2026-05-15
Active tasks: (none)
Recent (last 5):
  T-001 csv-export-todos  Delivered  2026-05-15
```

---

## Step 5 (AI 反复犯错时): 改 Harness

假设第 3 个任务 AI 又一次直接 import PrismaClient 而不是用 PrismaService。

**做法**（不要重新跑任务，要改护栏）：

1. 编辑 `.harness/rules/80-internal.md`（新文件，80- 表示项目特定，在 50- 之后合成）:
   ```markdown
   ## Internal API conventions
   
   - Never `import { PrismaClient }` directly. Use `PrismaService` from
     `@/services/prisma`. PrismaService manages connection pooling and
     ensures clean shutdown.
   ```

2. 同步 binding：
   ```powershell
   pwsh scripts/harness-sync.ps1
   ```
   现在 `CLAUDE.md` 自动包含了这条规则。

3. （可选，更稳）加机器检查到 `scripts/verify_all.ps1`：
   ```powershell
   Step "X.1" "No direct PrismaClient import" {
       $hits = git grep -E "from '@prisma/client'" -- 'src/**/*.ts' ':!src/services/prisma.ts'
       if ($hits) { throw "Direct PrismaClient import in:`n$hits" }
   }
   ```

4. 跑 verify_all 确认新检查通过。

**下次 AI 写代码**：
- Stage 4 之前会读 CLAUDE.md（含新规则）
- 即使 AI 忘了规则，verify_all 也会拦截
- 不会再犯同一个错

---

## 几条关键纪律

| 纪律 | 谁强制 |
|---|---|
| 编辑 `.harness/`，不编辑 `.claude/` 或 `CLAUDE.md` | verify_all step E.2 |
| 测试数只能升不能降 | scripts/baseline.json 比较 |
| 发现问题的人不能修问题（Reviewer 不改代码，Gate 不改需求）| PM 的回退路由规则 |
| 下游不能改上游文档 | 通过 PM 提阻塞回退 |
| 同阶段回退 ≥3 次 → 停下来问人 | PM 自动停 |
| PM 只做路由，不做专业判断 | PM 提示词 |

---

## 一个完整任务大概多久？

| 任务规模 | 你回答问题次数 | AI 总耗时 |
|---|---|---|
| 单文件 typo 修复 | 0 | <5 min |
| 单模块小功能（如 CSV export） | 2-3 | 20-40 min |
| 跨分区中型功能（如新 entity + API + UI） | 3-5 | 1-2 hours |
| 跨服务大改 | 5-10 | 半天 |

时间主要花在：
- AI 读上下文 + 写文档（每 stage 1-3 min）
- AI 写代码 + 调试（dev stage 5-15 min）
- 跑 verify_all（每次 30s - 5 min，取决于测试规模）
- 你回答 AskUserQuestion（你的时间）

---

## 不会发生什么

- **不会**自动 push 到 git remote — 这是你的决定
- **不会**自动跑 `npm install` 或装新依赖 — adopt 流程明确避免
- **不会**碰生产数据库 — dev-db 硬规则
- **不会**修改 `.github/workflows/` — adopt 流程明确避免
- **不会**绕过 verify_all — 没办法绕，是 hard gate
- **不会**编辑你的 README 或 CONTRIBUTING — adopt 只读这些
- **不会**修改 `.harness-adopt/PLAN.md` 之外的任何东西在 user 同意前

---

## 如果出问题

| 问题 | 怎么办 |
|---|---|
| AI 回滚 ≥3 次到同一 stage | PM 自动停，问你；说明需求或设计有内在矛盾 |
| verify_all 失败你看不懂 | 看 `scripts/verification_history.log`；E.* 步骤说明 |
| `.harness/` 和 `.claude/` 不一致 | `pwsh scripts/harness-sync.ps1` |
| 改完 Harness 不知道是否破坏什么 | 跑 `scripts/test-init.ps1` + `scripts/test-real-project.ps1` |
| Skills 在 Claude Code 里找不到 | `~/.claude/skills/harness-init/SKILL.md` 是否存在；重启 Claude Code |

---

## 下一步阅读

- [getting-started.md](getting-started.md) — 更紧凑的上手版
- [workflow.md](workflow.md) — 7-Agent 流水线的完整规则
- [concepts.md](concepts.md) — 为什么这样设计
- [../architecture.html](../architecture.html) — 可视化架构
- [../MIGRATION.md](../MIGRATION.md) — v0.1.x 老项目升级到 v0.5
