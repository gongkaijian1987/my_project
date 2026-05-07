# `my_project` CircleCI 自动化验证实施方案

## 1. 目标

`my_project` 是一个基于 Spring Boot 和 Maven 的示例项目。本文档将参考 CircleCI 自动化验证理念，把“基础 CI”、“Chunk 平台能力”和“提交前校验”三层能力映射到当前仓库，形成一套可执行的实施方案。

本文档关注的不是抽象概念，而是如何在当前项目中落地以下能力：

- 保持基础构建、测试、打包流水线稳定运行
- 为 Chunk 提供可复现的运行环境
- 让 Chunk 基于测试历史和上下文处理问题
- 在代码提交前尽早运行本地校验，减少无效 CI 失败

## 2. 当前项目的对应关系

当前仓库已经具备以下基础：

- 基础 CI 配置：
  - `.circleci/config.yml`
- Chunk 环境准备：
  - `.circleci/cci-agent-setup.yml`
  - `.circleci/fix-flaky-test.md`
- 自动化验证脚本：
  - `scripts/verification-plan.sh`
  - `scripts/run-automated-verification.sh`
- 提交前校验脚本：
  - `.claude/settings.json`
  - `scripts/chunk-pre-commit-gate.sh`
  - `scripts/chunk-validate-tests.sh`
  - `scripts/chunk-validate-package.sh`
  - `scripts/chunk-validate-circleci.sh`

这几部分分别承担不同职责：

- `.circleci/config.yml`：负责推送后的标准 CI/CD
- `cci-agent-setup.yml`：负责告诉 Chunk 如何准备仓库环境
- `fix-flaky-test.md`：负责告诉 Chunk 团队规则和修复偏好
- `verification-plan.sh` / `run-automated-verification.sh`：负责仓库内的规则驱动验证
- `chunk-pre-commit-gate.sh`：负责提交前的本地门禁

## 3. 分层实施方案

### 3.1 第一层：基础 CI（Baseline）

基础 CI 的目标是确保每次 push 后，都有一个稳定、可重复的标准验证过程。

当前项目的基础流程已经在 `.circleci/config.yml` 中实现，核心包括：

- checkout 代码
- 恢复 Maven 缓存
- 分析变更范围
- 运行自动化验证
- 保存测试结果
- 保存构建产物

在这个层面，团队需要重点确保以下几点长期成立：

- `mvn test` 始终可运行
- `mvn package -DskipTests` 始终可运行
- `store_test_results` 始终保留
- 所有测试报告持续输出到 `target/surefire-reports`

原因很简单：Chunk 的 flaky test 识别和测试历史分析依赖 CircleCI 收集到的测试结果。

### 3.2 第二层：自动化验证（Automation Validation）

传统 CI 只是“执行脚本”，而自动化验证强调“基于上下文决定验证动作”。

当前项目已经用两类机制实现这个思路：

#### 机制 A：仓库内规则驱动验证

`scripts/verification-plan.sh` 会分析本次代码变更并输出：

- 变更文件列表
- 风险评分
- 验证模式
  - `lightweight`
  - `targeted`
  - `full`

然后 `scripts/run-automated-verification.sh` 根据风险级别决定：

- 只做 `mvn validate`
- 只跑命中的测试
- 或执行完整 `mvn clean test`

这层能力解决的问题是：

- 避免每次都无差别跑完整验证
- 在代码小改动时尽量缩短反馈时间
- 在高风险改动时保守执行完整验证

#### 机制 B：Chunk 平台侧自动化能力

启用 Chunk 后，CircleCI 会在平台侧进一步补足这些能力：

- 修复 flaky tests
- 分析失败构建
- 结合构建历史和环境上下文给出修复建议

对 `my_project` 的建议落地顺序是：

1. 先启用 Chunk
2. 先从 `Fix flaky tests` 任务开始
3. 保留当前仓库内验证脚本作为第一层过滤
4. 将 Chunk 作为“失败后的分析与修复增强层”

这样能避免一下子把所有责任都压到平台能力上，也更容易渐进式验证效果。

### 3.3 第三层：提交前校验（Inner Loop）

自动化验证真正要提速，不能只依赖 push 之后的 CI，还要让问题尽可能在提交前暴露。

当前仓库已经通过以下文件实现了这层能力：

- `.claude/settings.json`
- `scripts/chunk-pre-commit-gate.sh`

设计思路是：

- 当 AI 代理尝试执行 `git commit` 时
- 先触发提交前门禁
- 门禁脚本串行调用项目校验脚本
- 测试、打包、CircleCI 配置不通过时，阻止提交

当前项目的推荐提交前校验内容是：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

在支持 `Chunk CLI` 的环境中，可以进一步用 `chunk validate ... --override-cmd` 统一驱动这些脚本。

## 4. 推荐落地步骤

对于 `my_project`，建议按以下顺序推进：

### 第一步：保持基础流水线稳定

确保以下命令在开发机和 CircleCI 中都稳定通过：

```bash
mvn -B -ntp test
mvn -B -ntp package -DskipTests
```

### 第二步：启用 Chunk

在 CircleCI 组织中完成以下操作：

1. 启用 Chunk
2. 选择模型提供方
3. 配置 `circleci-agents` context
4. 验证 GitHub App 已安装

### 第三步：提供 Chunk 环境

将以下文件保留在仓库中：

- `.circleci/cci-agent-setup.yml`
- `.circleci/fix-flaky-test.md`

它们分别负责：

- 环境初始化
- 团队规范和修复边界

### 第四步：开启首个 Chunk 任务

建议第一个任务就用：

- `Fix flaky tests`

原因：

- 对现有流水线侵入最小
- 最容易从测试历史中看到效果
- 风险最低

### 第五步：启用提交前门禁

对本地开发环境，建议按环境区分：

- Windows：
  - 可直接运行仓库脚本完成本地校验
  - `Chunk CLI` 建议放到 WSL 或 Linux/macOS 环境中运行
- Linux/macOS：
  - 可直接使用 Bash 脚本
  - 可进一步接入 `chunk init` / `chunk validate`

## 5. Windows 与 Linux 使用差异

### Windows

当前仓库已经兼容在 Windows 中调用 Maven，但有两点要注意：

- `circleci CLI` 可以原生安装在 Windows
- `Chunk CLI` 不建议按原生 Windows 路线作为团队标准方案

推荐用法：

```powershell
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

### Linux / macOS / WSL

这些环境更适合完整使用 Chunk CLI 工作流。

推荐用法：

```bash
bash scripts/chunk-pre-commit-gate.sh
```

如果已经安装了 Chunk CLI，还可以继续执行：

```bash
chunk init
chunk validate
```

## 6. 最终效果

当这套方案完整落地后，`my_project` 的验证链路会变成：

1. 开发阶段：
   - 本地提交前先运行校验
2. push 阶段：
   - CircleCI 执行标准自动化验证
3. 失败处理阶段：
   - Chunk 基于历史和上下文分析失败原因
4. 持续优化阶段：
   - Chunk 识别 flaky tests 并持续修复

这意味着 CI 系统不再只是“被动执行脚本”，而是逐步演进成：

- 能理解上下文的验证层
- 能降低重复劳动的辅助层
- 能和开发内循环协同工作的质量守门层

## 7. 建议的下一步

对于当前项目，建议优先继续推进这三项：

1. 在 CircleCI 控制台完成 Chunk 启用和环境验证
2. 用 `circleci config validate` 校验 `.circleci/config.yml` 与 `cci-agent-setup.yml`
3. 在 Linux、macOS 或 WSL 环境补齐 `Chunk CLI`，完成 `chunk init` 和 `chunk validate` 接入
