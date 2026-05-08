# Spring Boot CircleCI Demo

这是一个基于 `Spring Boot 2.7.18`、`Maven` 和 `JDK 1.8.0_462` 的示例项目，用来演示：

- Spring Boot Web 接口与测试
- CircleCI 并行测试与测试分片
- Maven 依赖缓存策略
- Chunk 环境准备与修复规则接入
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
├── pom.xml
└── README.md
```

## 业务接口

启动应用后可访问：

- `GET /api/health`
- `GET /api/greeting?name=CircleCI`
- `GET /api/test?name=CircleCI`

其中 `/api/greeting` 和 `/api/test` 都会返回包含 `message` 字段的 JSON。

## 本地运行

### 运行测试

```bash
mvn -B -ntp test
```

### 打包

```bash
mvn -B -ntp package -DskipTests
```

### 启动应用

```bash
mvn spring-boot:run
```

## CircleCI 设计

### 1. 并行测试与分片

当前 `.circleci/config.yml` 中的主测试 job 为 `parallel_test_verification`：

- 使用 `parallelism: 4`
- 通过 `scripts/run-circleci-parallel-tests.sh` 调用 `circleci tests run`
- 将测试类按历史耗时拆分到 4 个并行执行器

项目中额外加入了 4 组慢测试：

- `ParallelDemoAlphaTest`
- `ParallelDemoBetaTest`
- `ParallelDemoGammaTest`
- `ParallelDemoDeltaTest`

每组测试都带有固定延迟，方便在 CircleCI 页面中直观看到：

- 串行执行较慢
- 分片并行后整体 wall time 明显下降

### 2. Maven 缓存策略

当前缓存策略采用：

```yaml
maven-jdk8-v1-{{ checksum "pom.xml" }}
```

设计原则如下：

- 使用 `pom.xml` 的 checksum 保证缓存精确失效
- 使用 `jdk8` 前缀标记当前运行时语义
- 并行测试 job 只恢复缓存，不重复上传缓存
- 单实例 `package_application` job 统一写回 `~/.m2`

对应文件：

- `.circleci/config.yml`
- `.circleci/cci-agent-setup.yml`

### 3. 打包与部署

CircleCI workflow 目前包含 3 个阶段：

1. `parallel_test_verification`
2. `package_application`
3. `deploy_snapshot`

其中：

- 测试通过后才会打包
- `deploy_snapshot` 只在 `main` 分支触发
- 当前部署脚本是占位实现，位于 `scripts/deploy.sh`

## Chunk 相关配置

### 1. 环境准备

`.circleci/cci-agent-setup.yml` 用于给 Chunk 提供项目执行环境，主要负责：

- checkout
- 恢复 Maven 缓存
- 校验 Java / Maven 版本
- 执行 `mvn dependency:go-offline`
- 保存 Maven 缓存

### 2. 修复规则

项目当前有两类规则文件：

- 仓库通用规则：`agents.md`
- flaky test 专项规则：`.circleci/fix-flaky-test.md`

它们用于告诉 Chunk：

- 优先修应用代码，而不是简单弱化测试
- 不要删除断言来让流水线变绿
- 保持 JDK 8 兼容
- 保持现有 JSON 字段和接口语义稳定

### 3. Chunk 文档

更完整的说明见：

- [docs/chunk-checklist.md](./docs/chunk-checklist.md)
- [docs/chunk-implementation-guide.md](./docs/chunk-implementation-guide.md)

## 提交前校验

仓库中已经准备了一组提交前校验脚本：

- `scripts/chunk-validate-tests.sh`
- `scripts/chunk-validate-package.sh`
- `scripts/chunk-validate-circleci.sh`
- `scripts/chunk-pre-commit-gate.sh`

适合的使用方式：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

如果后续在 Linux、macOS 或 WSL 中安装了 `Chunk CLI`，也可以继续接 `chunk validate`。

## 当前仓库的重点演示能力

这个项目当前最适合拿来演示 4 件事：

1. Spring Boot + JUnit 5 + MockMvc 的基础测试结构
2. CircleCI `parallelism + circleci tests run` 的测试分片
3. Maven 依赖缓存的优化方式
4. Chunk 的环境接入和修复规则设计

## 后续可扩展方向

- 增加 `Jacoco` 覆盖率报告
- 增加 `Checkstyle` / `SpotBugs`
- 增加 nightly 全量测试任务
- 增加 Docker 镜像构建与发布
- 增加多环境部署工作流
