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

### CI 阶段

`build_and_test` 作业完成以下事情：

1. 拉取代码。
2. 恢复 Maven 缓存。
3. 执行 `mvn clean test`。
4. 执行 `mvn package -DskipTests` 打包。
5. 保存 `~/.m2` 缓存。
6. 上传测试报告和 Jar 制品。

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
