# Spring Boot CircleCI Demo

这是一个基于 `Spring Boot 2.7.18` 和 `JDK 1.8.0_462` 的最小示例项目，用来演示如何在 CircleCI 中完成 CI/CD 流程。

## 技术选型

- JDK: `1.8.0_462`
- Spring Boot: `2.7.18`
- 构建工具: `Maven 3.6+`
- CI/CD: `CircleCI 2.1`

## 项目结构

```text
.
├── .circleci/config.yml
├── pom.xml
├── scripts/deploy.sh
└── src
    ├── main
    │   ├── java/com/example/demo
    │   │   ├── DemoApplication.java
    │   │   ├── controller/HealthController.java
    │   │   └── service/GreetingService.java
    │   └── resources/application.yml
    └── test
        └── java/com/example/demo
            ├── controller/HealthControllerTest.java
            └── service/GreetingServiceTest.java
```

## 本地运行

```bash
mvn clean test
mvn spring-boot:run
```

启动后访问：

- `GET /api/health`
- `GET /api/greeting?name=CircleCI`

## CircleCI 流程说明

### 自动化验证如何落地

这个项目现在不是“每次都只跑一套固定脚本”，而是先做变更分析，再决定验证深度：

1. `scripts/verification-plan.sh` 读取本次提交与 `main` 的差异。
2. 根据变更位置做风险评分，例如：
   - `pom.xml`、`.circleci/`、`scripts/` 变更属于高风险。
   - `controller` 变更属于中高风险。
   - `service` 变更属于中风险。
   - 仅文档变更属于低风险。
3. 输出验证计划到 `target/verification/verification-plan.env`。
4. `scripts/run-automated-verification.sh` 根据风险决定执行：
   - `lightweight`：只做 `mvn validate`
   - `targeted`：执行测试验证并记录定向目标
   - `full`：执行完整 `mvn clean test`
5. 最终输出验证摘要和制品，作为 CircleCI artifact 保存。

### Chunk CLI 与 sidecar

除了推送后的 CI 流程，这个项目也适合接入 `Chunk CLI` 做提交前验证。

三者的职责可以这样理解：

- `.circleci/config.yml`：负责代码推送后的标准 CI/CD。
- `Chunk Tasks`：负责 CircleCI 平台侧的 AI 分析与自动修复，例如 flaky test 修复。
- `Chunk CLI / sidecar`：负责开发者在本地提交前先运行校验，或把这些校验迁移到 CircleCI 远端 sidecar 环境执行。

对于当前这个 Spring Boot Maven 项目，建议先把提交前验证保持为最小闭环：

```bash
chunk init
chunk validate
```

建议 `chunk validate` 执行的核心校验命令为：

```bash
mvn -B -ntp test
```

如果后续你增加了更严格的质量门禁，可以扩展为：

```bash
mvn -B -ntp test
mvn -B -ntp package -DskipTests
```

为了让 `my_project` 更适合提交前校验，仓库里已经预置了以下文件：

- `.claude/settings.json`
- `scripts/chunk-pre-commit-gate.sh`
- `scripts/chunk-validate-tests.sh`
- `scripts/chunk-validate-package.sh`
- `scripts/chunk-validate-circleci.sh`

这些文件的职责是：

- 在 AI 编码代理尝试执行 `git commit` 前自动触发校验
- 通过 `chunk validate ... --override-cmd` 运行项目级验证命令
- 验证 Maven 测试、可打包性，以及 CircleCI 配置文件合法性

推荐的本地启用步骤如下：

```bash
brew install CircleCI-Public/circleci/chunk
brew install circleci
chunk hook env update --profile tests-lint
chunk init
```

由于 `chunk init` 会生成自己的 `.chunk/config.json` 和 `.claude/settings.json`，执行后建议保留本仓库中的提交门禁逻辑，或将生成内容合并到当前的 `.claude/settings.json` 中。

手动执行时，推荐使用下面这组命令：

```bash
chunk validate tests --no-check --override-cmd "bash scripts/chunk-validate-tests.sh"
chunk validate package --no-check --override-cmd "bash scripts/chunk-validate-package.sh"
chunk validate circleci-config --no-check --override-cmd "bash scripts/chunk-validate-circleci.sh"
```

如果想在一次命令里跑完整提交流程，可以直接执行：

```bash
bash scripts/chunk-pre-commit-gate.sh
```

这样做的好处是：

- 在代码提交前尽早发现问题
- 尽量减少“本地能过、CI 失败”的情况
- 如果升级到支持 remote sidecar 的付费方案，可以把这些校验迁移到远端统一环境中执行

需要注意：

- 根据 CircleCI 官方 Chunk CLI 说明，Chunk CLI 目前支持 `macOS` 和 `Linux`，`Windows` 暂不支持。
- 这个仓库已经把校验逻辑写成 Bash 脚本，因此最适合在 macOS、Linux 或 WSL 环境中使用。

### 当前项目推荐的落地顺序

1. 保持现有 `.circleci/config.yml` 作为推送后验证主流程。
2. 在 CircleCI 控制台启用 `Chunk Tasks`，先从 `Fix flaky tests` 开始。
3. 在开发机安装 `Chunk CLI`，先使用 `chunk validate` 做本地提交前校验。
4. 团队需要更强一致性时，再将本地校验升级到 remote sidecar。

### CI 阶段

`automated_verification` 作业完成以下事情：

1. 拉取代码。
2. 安装 `git` 以便分析差异。
3. 执行变更分析和风险分级。
4. 恢复 Maven 缓存。
5. 按风险级别执行自动化验证。
6. 按需执行打包。
7. 保存 `~/.m2` 缓存。
8. 上传测试结果、验证报告和 Jar 制品。

### CD 阶段

`deploy_snapshot` 作业只在 `main` 分支触发，目前提供了一个可直接替换的部署脚本模板 `scripts/deploy.sh`。

你可以按实际环境改造成：

- 部署到测试服务器
- 推送到制品仓库
- 构建并推送 Docker 镜像
- 发布到 Kubernetes

## 在 CircleCI 中接入步骤

1. 将代码推送到 GitHub。
2. 在 CircleCI 中选择对应仓库并启用项目。
3. 确保默认分支为 `main`，这样会触发部署阶段。
4. 如果有真实部署动作，在 CircleCI Project Settings -> Environment Variables 中配置密钥，例如：
   - `DEPLOY_HOST`
   - `DEPLOY_USER`
   - `DEPLOY_TOKEN`
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_PASSWORD`

## 可扩展建议

- 增加 `Jacoco` 生成覆盖率报告
- 增加 `Checkstyle` / `SpotBugs` 做质量门禁
- 增加多环境部署工作流
- 如果生产要容器化，可补充 `Dockerfile` 和镜像发布任务
- 将 `verification-plan.sh` 的规则接入真实构建历史、失败率和 flaky test 数据
- 将高风险变更自动关联审批、回滚策略和发布窗口
