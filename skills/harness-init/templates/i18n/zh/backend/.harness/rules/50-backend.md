---

## 后端项目专属规则

### 分区 Developer（v0.5+）

partitioned 模式下，这个项目用**分区 Developer agents**：

- `dev-api` 负责路由 handler / controllers / 请求-响应 schema / 中间件
- `dev-services` 负责业务逻辑 / 领域模型 / 编排 / 队列
- `dev-db` 负责 schema / migrations / ORM 模型 / repositories / seed 脚本

Solution Architect 必须在每份 `02_SOLUTION_DESIGN.md` 里写 `## Partition assignment`（分区分配）章节。PM Orchestrator 按依赖顺序派分区（通常 dev-db → dev-services → dev-api）。Generic `developer` 作为模糊任务的 fallback 保留。每个分区的 owned paths 和契约见 `.harness/agents/dev-*.md`。

如果用 single Developer 模式初始化，本章节仅供参考，所有代码改动由 generic `developer` agent 处理。

### API
- 每个 endpoint 必须有 typed schema（OpenAPI / Pydantic / Zod / Go struct tags）。
- 响应 envelope 在所有 endpoint 间保持一致（用统一的 error 格式）。
- 幂等操作要明确标注（PUT / DELETE / 带 idempotency key 的特定 POST）。

### 数据库
- 所有 schema 改动通过 migration。**绝不**在普通代码路径里"顺手改一下 schema"。
- Migration 必须可回滚；不可回滚的需要用户确认。
- **N+1 查询**：任何循环里查 DB → 批量或 JOIN，**无例外**。

### 错误 / 日志
- 跨模块抛出的错误必须 typed（自定义 error class）。
- 日志要结构化（生产环境 JSON），带 request ID 上下文。
- 代码里**不能有 `print` / `console.log`**；用 logger。

### 安全
- 每个 API 入口必须输入验证。用 schema，**不要信任 client**。
- Secret 通过 env，**绝不**写代码或配置文件里。
- 鉴权在**路由层 + service 层双重检查**（纵深防御）。

### 性能
- 长时操作放队列，**不阻塞 HTTP**。
- WHERE / JOIN 用到的每列都要有 DB 索引。
- 每个外部调用要设合理默认超时。
