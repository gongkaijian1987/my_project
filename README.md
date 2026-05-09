# Spring Boot CircleCI Demo

这是一个基于 `Spring Boot 2.7.18`、`Maven` 和 `JDK 1.8.0_462` 的示例项目，用来演示：

- Spring Boot Web 接口与测试
- CircleCI 并行测试与测试分片
- Maven 依赖缓存
- CircleCI `resource_class` 资源分级
- Chunk 环境准备、修复规则与 Web Chat 体验
- 提交前校验脚本设计

## 技术栈

- JDK: `1.8.0_462`
- Spring Boot: `2.7.18`
- Maven: `3.6+`
- Test: `JUnit 5`、`MockMvc`
- CI/CD: `CircleCI 2.1`

## 当前目录结构

```text
.
├── .circleci
│   ├── cci-agent-setup.yml
│   ├── config.yml
│   └── fix-flaky-test.md
├── .claude
│   └── settings.json
├── docs
│   ├── chunk-checklist.md
│   ├── chunk-implementation-guide.md
│   ├── chunk-web-prompts.md
│   └── README.md
├── scripts
│   ├── chunk-pre-commit-gate.sh
│   ├── chunk-run-maven.sh
│   ├── chunk-validate-circleci.sh
│   ├── chunk-validate-package.sh
│   ├── chunk-validate-tests.sh
│   ├── deploy.sh
│   ├── run-automated-verification.sh
│   ├── run-circleci-parallel-tests.sh
│   └── verification-plan.sh
├── src
│   ├── main
│   │   ├── java/com/example/demo
│   │   │   ├── DemoApplication.java
│   │   │   ├── controller/HealthController.java
│   │   │   └── service/GreetingService.java
│   │   └── resources/application.yml
│   └── test
│       └── java/com/example/demo
│           ├── controller/HealthControllerTest.java
│           ├── performance
│           │   ├── ParallelDemoAlphaTest.java
│           │   ├── ParallelDemoBetaTest.java
│           │   ├── ParallelDemoDeltaTest.java
│           │   └── ParallelDemoGammaTest.java
│           ├── service/GreetingServiceTest.java
│           └── support/SlowTestSupport.java
├── agents.md
├── claude.md
├── pom.xml
└── README.md
```

## 业务接口

启动应用后可访问：

- `GET /api/health`
- `GET /api/greeting?name=CircleCI`
- `GET /api/test?name=CircleCI`

其中 `/api/greeting` 和 `/api/test` 都会返回带有 `message` 字段的 JSON。

## 本地开发

运行测试：

```bash
mvn -B -ntp test
```

打包应用：

```bash
mvn -B -ntp package -DskipTests
```

启动应用：

```bash
mvn spring-boot:run
```

## CircleCI 流水线说明

主流程定义在 `.circleci/config.yml` 中，目前包含 3 个 job：

1. `parallel_test_verification`
2. `package_application`
3. `deploy_snapshot`

### 1. 并行测试与分片

`parallel_test_verification` 主要演示：

- `parallelism: 4`
- 使用 `circleci tests run` 做测试分片
- 通过 `scripts/run-circleci-parallel-tests.sh` 在每个节点执行分配到的测试类

项目中额外加入了 4 组带固定延迟的慢测试：

- `ParallelDemoAlphaTest`
- `ParallelDemoBetaTest`
- `ParallelDemoGammaTest`
- `ParallelDemoDeltaTest`

这样可以在 CircleCI 页面中比较直观地看到：

- 串行执行较慢
- 测试分片后整体 wall time 明显下降

#### 演示目的

这个项目专门通过“固定延迟测试 + CircleCI 并行分片”来演示：

- 为什么测试数量一多后，串行执行会明显拖慢反馈速度
- 为什么 `parallelism` 可以通过横向扩执行器数量来缩短总耗时
- 为什么 `circleci tests run` 比简单按文件平均拆分更适合真实项目

在本项目中，4 组慢测试每组都有固定等待时间，因此：

- 本地串行执行时，总耗时会明显累加
- CircleCI 中使用 4 个并行执行器后，多个慢测试类会被拆散到不同节点
- 最终 wall time 会明显低于串行测试

#### 演示步骤

如果你要在 CircleCI 页面里向别人演示这项能力，建议按下面顺序操作：

1. 推送一次代码，触发 `ci_cd` workflow
2. 打开 `parallel_test_verification` job
3. 观察该 job 使用了 `parallelism: 4`
4. 查看每个并行节点分配到的测试类
5. 观察慢测试被分散到多个节点，而不是全部堆在同一个节点
6. 对比总耗时与本地串行测试时间

#### 观察点

演示时建议重点说明这几个点：

- `parallelism` 是“横向扩节点”，不是单机提速
- `circleci tests run --split-by=timings` 会尽量按照历史耗时做均衡拆分
- 慢测试越多、总测试时间越长，并行分片带来的收益越明显
- 如果测试本身很少，或者每个测试都很快，并行收益就不会特别明显

### 2. Maven 缓存策略

当前使用的缓存键模式为：

```yaml
maven-jdk8-v1-{{ checksum "pom.xml" }}
```

当前缓存设计如下：

- `parallel_test_verification` 只恢复缓存
- `package_application` 恢复缓存并统一写回 `~/.m2`
- `.circleci/cci-agent-setup.yml` 也会恢复并保存同一套 Maven 缓存

这样做的目的是：

- 使用 `pom.xml` 的 checksum 保证缓存精确失效
- 使用 `jdk8` 前缀标识当前运行时语义
- 避免并行测试节点重复上传同一个 Maven 缓存

### 3. resource_class 资源分级

当前资源规格配置如下：

- `parallel_test_verification`: `medium`
- `package_application`: `medium`
- `deploy_snapshot`: `small`
- `cci-agent-setup`: `medium`

设计思路是：

- 测试 job 需要加载 Spring Boot 测试上下文并执行分片，使用 `medium`
- 打包 job 需要编译和重打包，使用 `medium`
- 部署 job 当前只是执行示例脚本，使用 `small`
- Chunk 环境准备需要下载依赖和准备运行环境，使用 `medium`

#### 为什么要分级配置

`resource_class` 用来控制单个 job 的计算资源大小。它解决的问题不是“能不能跑”，而是：

- 资源是否够用
- 是否存在明显浪费
- 执行时间和 CircleCI 额度之间是否平衡

如果所有 job 都统一使用同一种规格，通常会出现两类问题：

- 测试或编译任务资源不足，导致变慢甚至不稳定
- 简单脚本任务资源过剩，造成额度浪费

因此，本项目特意做了分级配置，方便演示“按 job 类型分配资源”的思路。

#### 这项能力怎么演示

在当前项目里，可以这样解释 `resource_class`：

- `parallel_test_verification` 需要执行 Spring Boot 测试和测试分片，所以使用 `medium`
- `package_application` 需要进行 Maven 编译和 Spring Boot 打包，也使用 `medium`
- `deploy_snapshot` 当前只执行示例脚本，因此 `small` 足够
- `cci-agent-setup` 需要为 Chunk 准备依赖环境，因此使用 `medium`

这可以帮助理解：

- `parallelism` 是横向扩容
- `resource_class` 是纵向调整单节点资源
- 两者结合后，才是更完整的 CircleCI 性能优化思路

#### 实践建议

对于真实项目，通常建议：

- 从 `medium` 起步，而不是一上来就全用大规格
- 对测试、构建、部署类 job 分别设置不同资源等级
- 当测试时间已经通过分片明显下降后，再评估是否还需要继续加大 `resource_class`
- 不要把所有性能问题都归因于机器规格，测试设计、依赖缓存和分片策略同样重要

### 4. 打包与部署

当前工作流顺序如下：

1. 先执行 `parallel_test_verification`
2. 测试通过后执行 `package_application`
3. 最后在 `main` 分支执行 `deploy_snapshot`

其中：

- 打包 job 会上传 Jar 制品
- 部署 job 当前只是示例脚本，位于 `scripts/deploy.sh`

## Chunk 相关配置

### 1. 环境准备

`.circleci/cci-agent-setup.yml` 用于给 Chunk 提供项目运行环境，主要负责：

- checkout 代码
- 恢复 Maven 缓存
- 校验 Java / Maven 版本
- 执行 `mvn -B -ntp dependency:go-offline`
- 保存 Maven 缓存

### 2. 修复规则

当前仓库包含三层规则文件：

- `agents.md`：仓库通用修复规则
- `claude.md`：更适合 Chunk Web Chat 读取的项目背景和优化偏好
- `.circleci/fix-flaky-test.md`：flaky test 专项规则

这些文件用于告诉 Chunk：

- 优先修应用代码，而不是简单弱化测试
- 不要通过删除断言让流水线变绿
- 保持 JDK 8 兼容
- 保持现有接口语义和 JSON 字段稳定
- 当用户希望体验 AI 辅助时，优先分析缓存、并行、资源等级和反馈速度优化

### 3. 更适合体验 Chunk 的 Web 用法

当前项目更容易在 CircleCI Web 界面中体验到 Chunk 的场景是：

- 流水线配置优化
- 测试反馈速度分析
- flaky test 准备度检查
- 缓存、并行和资源等级建议

如果目标是体验 Chunk 的价值，建议优先让它做：

- `Optimize build configs`
- `Review pipeline design`
- `Assess flaky test readiness`

推荐提示词见：

- [docs/chunk-web-prompts.md](./docs/chunk-web-prompts.md)

### 4. 补充文档

更多说明见：

- [docs/chunk-checklist.md](./docs/chunk-checklist.md)
- [docs/chunk-implementation-guide.md](./docs/chunk-implementation-guide.md)

## 提交前校验

仓库已经准备了一组本地校验脚本：

- `scripts/chunk-validate-tests.sh`
- `scripts/chunk-validate-package.sh`
- `scripts/chunk-validate-circleci.sh`
- `scripts/chunk-pre-commit-gate.sh`

常见用法：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

如果后续在 Linux、macOS 或 WSL 中安装了 `Chunk CLI`，这些脚本也可以接到 `chunk validate` 后面使用。

## Chunk Sidecars

`Chunk sidecars` 可以理解为一种“提交前、接近 CI 环境的快速验证层”。

它的目标不是替代主流水线，而是把本来就不该进入外层 CI 的基础问题，尽量在更早阶段拦下来，例如：

- 编译失败
- 单元测试失败
- 配置文件错误
- 本地环境与 CI 环境不一致导致的问题

对于 `my_project` 这样的 Spring Boot Maven 项目，可以把它理解成：

- 在代码 push 之前
- 让 agent 或开发者先在一个更接近 CircleCI 的 sidecar 环境里运行小范围验证
- 如果失败，就先在内循环修掉，而不是把问题直接推到外层 CI

### 这项能力解决什么问题

它主要解决的是：

- “本地看起来没问题，但 CI 挂了”
- “低级错误推上去才发现”
- “AI 生成代码很快，但每次都要等主流水线兜底”

因此，这项能力更像是：

- 对外层 CI 的前置过滤
- 对 AI 编码内循环的加速器
- 对环境一致性的增强

### 结合当前项目怎么理解

这个项目当前已经具备比较适合接 sidecar 的基础条件：

- 有稳定的 Maven 测试入口
- 有打包入口
- 有 CircleCI 配置校验脚本
- 有 Chunk 环境文件
- 有测试结果与缓存策略

如果未来接入 `Chunk sidecars`，当前项目最适合放进 sidecar / microbuild 的验证动作是：

1. `bash scripts/chunk-validate-tests.sh`
2. `bash scripts/chunk-validate-package.sh`
3. `bash scripts/chunk-validate-circleci.sh`

也就是说，sidecar 最适合承接当前这些“轻量但关键”的提交前校验，而不是直接替代完整发布流程。

### 本地使用方式

如果后续要在本地体验 `Chunk sidecars`，更适合的环境是：

- Linux
- macOS
- WSL

当前推荐的本地接入思路是：

1. 安装 `Chunk CLI`
2. 完成 `chunk init`
3. 将当前仓库的轻量校验动作接入 sidecar 或 microbuild
4. 在代码提交前先运行 sidecar 验证，再决定是否 push

对当前项目来说，最适合接入 sidecar 的本地验证内容是：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

你可以把它理解成这样：

- 本地先准备改动
- 由 sidecar 在更接近 CI 的环境中执行这几组验证
- 如果 sidecar 失败，就先在本地继续修复
- 通过后再进入正式的 CircleCI 外层流水线

### 推荐的本地体验顺序

如果是第一次在这个项目里体验 sidecar，建议顺序如下：

1. 先在本地直接运行：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

2. 确认这些脚本本地可用后，再把它们映射到 `Chunk sidecars` 的 microbuild 验证步骤
3. 优先把 sidecar 用在测试、打包和 CircleCI 配置校验上
4. 不要一开始就让 sidecar 承担完整部署或复杂集成测试

这样做的好处是：

- 更容易验证 sidecar 是否真正带来了环境一致性收益
- 更容易把“本地校验”升级成“接近 CI 的本地前置验证”
- 更适合当前这个以演示并行测试、缓存和 Chunk 接入为主的示例项目

### 适合演示时怎么说

如果你要向团队解释这项能力，可以用下面这句话：

`Chunk sidecars` 通过一个尽量接近 CI 环境的轻量远程验证层，在代码提交前先执行 microbuild，提前拦截基础错误，从而减少无效 CI 构建和反馈往返。

## 当前项目最适合演示的能力

这个项目当前最适合演示：

1. Spring Boot + JUnit 5 + MockMvc 的测试结构
2. CircleCI `parallelism + circleci tests run`
3. Maven 依赖缓存优化
4. `resource_class` 按 job 分级配置
5. Chunk 的环境准备、修复规则和 Web Chat 分析能力

## 后续可扩展方向

- 增加 `Jacoco` 覆盖率报告
- 增加 `Checkstyle` 或 `SpotBugs`
- 增加 nightly 全量测试 workflow
- 增加 Docker 镜像构建与发布
- 增加多环境部署流程
