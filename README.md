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
