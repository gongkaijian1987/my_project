# Spring Boot CircleCI 演示项目

这是一个基于 `Spring Boot 2.7.18`、`Maven` 和 `JDK 1.8.0_462` 的示例项目，用来演示以下能力：

- Spring Boot Web 接口与测试
- CircleCI 并行测试分片
- Maven 依赖缓存
- `resource_class` 资源分级
- Chunk 环境接入与修复规则
- Chunk Sidecars 本地前置验证思路

## 技术栈

- JDK: `1.8.0_462`
- Spring Boot: `2.7.18`
- Maven: `3.8.x`
- Test: `JUnit 5`、`MockMvc`
- CI/CD: `CircleCI 2.1`

## 目录结构

```text
.
├── .circleci
│   ├── cci-agent-setup.yml
│   ├── config.yml
│   └── fix-flaky-test.md
├── .claude
│   └── settings.json
├── docs
├── scripts
├── src
├── agents.md
├── claude.md
├── pom.xml
└── README.md
```

## 接口说明

启动应用后可访问：

- `GET /api/health`
- `GET /api/greeting?name=CircleCI`
- `GET /api/test?name=CircleCI`

其中 `/api/greeting` 和 `/api/test` 都会返回包含 `message` 字段的 JSON。

## 本地使用

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

## CircleCI 流水线

当前主流程定义在 [.circleci/config.yml](/D:/code/circleci_test/my_project/.circleci/config.yml:1)，包含 3 个 job：

1. `parallel_test_verification`
2. `package_application`
3. `deploy_snapshot`

执行顺序如下：

1. 先执行并行测试
2. 测试通过后执行打包
3. 仅 `main` 分支执行示例部署

### 并行测试与分片

`parallel_test_verification` 用于演示：

- `parallelism: 4`
- `circleci tests run`
- `scripts/run-circleci-parallel-tests.sh`

仓库中包含 4 组带固定延迟的测试：

- `ParallelDemoAlphaTest`
- `ParallelDemoBetaTest`
- `ParallelDemoGammaTest`
- `ParallelDemoDeltaTest`

这些测试的目的是让 CircleCI 页面上能更直观看到：

- 串行执行时总时长明显累加
- 使用 4 路并行后，慢测试会被拆分到不同执行节点
- 整体 `wall time` 会明显下降

演示时建议重点观察：

- `parallelism` 负责横向扩容执行节点
- `circleci tests run --split-by=timings` 会按历史耗时尽量均衡分配测试
- 测试数量越多、单测越慢，并行分片收益越明显

## Maven 缓存策略

当前使用的缓存 key 为：

```yaml
maven-jdk8-v1-{{ checksum "pom.xml" }}
```

缓存设计如下：

- `parallel_test_verification` 只恢复缓存
- `package_application` 恢复并统一写回 `~/.m2`
- `.circleci/cci-agent-setup.yml` 也使用同一套 Maven 缓存策略

这样做的目的：

- 利用 `pom.xml` 的 `checksum` 精确控制缓存失效
- 用 `jdk8` 前缀标识当前运行时语义
- 避免并行测试节点重复上传同一份 Maven 缓存

## resource_class 资源分级

当前配置如下：

- `parallel_test_verification`: `medium`
- `package_application`: `medium`
- `deploy_snapshot`: `small`
- `cci-agent-setup`: `medium`

设计思路如下：

- 测试 job 需要运行 Spring Boot 测试上下文和测试分片，使用 `medium`
- 打包 job 需要编译和 Spring Boot 重打包，使用 `medium`
- 部署 job 当前只是示例脚本，使用 `small`
- Chunk 环境准备需要拉取依赖和准备环境，使用 `medium`

可以把这项能力理解成：

- `parallelism` 是横向增加节点
- `resource_class` 是纵向调整单节点资源

两者结合后，才是更完整的 CircleCI 性能优化方案。

## Docker Layer Caching

当前仓库还没有引入 `Dockerfile` 和镜像构建 job，因此 **Docker Layer Caching (DLC) 还未启用**。不过它是这个项目非常自然的下一步增强方向。

DLC 的作用是：

- 在 `docker build` 时缓存未变化的镜像层
- 只重建真正发生变更的层
- 减少依赖安装、系统包下载、源码复制后的重复构建成本

如果后续把本项目扩展成 “Spring Boot + Docker + CircleCI” 演示仓库，推荐做法是：

1. 新增 `Dockerfile`
2. 在 `.circleci/config.yml` 中增加镜像构建 job
3. 在 `setup_remote_docker` 中启用：

```yaml
- setup_remote_docker:
    docker_layer_caching: true
```

适合引入 DLC 的场景：

- 每次提交都要构建 Docker 镜像
- Dockerfile 前半部分比较稳定
- 依赖安装层较重

不适合盲目开启的原因：

- DLC 会增加 CircleCI credits 成本
- 如果项目本身不构建 Docker 镜像，这项能力没有收益

因此，对当前项目来说，DLC 更适合作为“下一阶段 Docker 优化能力”来演示，而不是当前默认开启项。

## Chunk 接入

### 环境准备

[.circleci/cci-agent-setup.yml](/D:/code/circleci_test/my_project/.circleci/cci-agent-setup.yml:1) 用于给 Chunk 提供专用执行环境，当前负责：

- `checkout`
- 恢复 Maven 缓存
- 校验 Java / Maven 版本
- 执行 `mvn -B -ntp dependency:go-offline`
- 保存 Maven 缓存

### 修复规则

当前仓库包含 3 层规则文件：

- [agents.md](/D:/code/circleci_test/my_project/agents.md:1)
- [claude.md](/D:/code/circleci_test/my_project/claude.md:1)
- [.circleci/fix-flaky-test.md](/D:/code/circleci_test/my_project/.circleci/fix-flaky-test.md:1)

这些文件用于告诉 Chunk：

- 优先修应用代码，不要简单弱化测试
- 保持 JDK 8 兼容
- 保持现有接口语义和 JSON 字段稳定
- 优先分析缓存、并行、资源分级和反馈速度优化

### Web 体验建议

当前项目更适合在 CircleCI Web 中体验的 Chunk 场景：

- `Optimize build configs`
- `Review pipeline design`
- `Assess flaky test readiness`

更详细的 Web prompt 示例见：

- [docs/chunk-web-prompts.md](/D:/code/circleci_test/my_project/docs/chunk-web-prompts.md:1)

## Chunk Sidecars

`Chunk Sidecars` 可以理解成一层“提交前、尽量接近 CI 环境的快速验证层”。

它的目标不是替代主流水线，而是提前拦截这些本不该进入外层 CI 的问题：

- 编译失败
- 单元测试失败
- CircleCI 配置错误
- 本地环境和 CI 环境不一致导致的问题

### 结合当前项目的使用方式

对 `my_project` 来说，最适合放进 sidecar 或 microbuild 的动作是：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

分别对应：

- 测试是否通过
- 应用是否还能正常打包
- CircleCI 配置是否合法

### 本地体验顺序

更适合体验 `Chunk Sidecars` 的环境：

- Linux
- macOS
- WSL

推荐顺序：

1. 安装 `Chunk CLI`
2. 执行 `chunk init`
3. 先手工验证仓库脚本
4. 再把这些脚本映射到 `chunk validate` 或 sidecar 流程

推荐先手工运行：

```bash
bash scripts/chunk-validate-tests.sh
bash scripts/chunk-validate-package.sh
bash scripts/chunk-validate-circleci.sh
```

### 推荐的 `.chunk/config.json` 最小思路

如果后续执行 `chunk init`，推荐先保持最小验证闭环：

```json
{
  "version": 1,
  "validations": [
    {
      "name": "tests",
      "description": "Run Spring Boot tests",
      "command": "bash scripts/chunk-validate-tests.sh"
    }
  ],
  "default_validations": [
    "tests"
  ]
}
```

这样做的好处：

- 默认只跑最核心的测试
- 更适合提交前和 sidecar 的快速反馈
- 后续可以再逐步加入 `package` 和 `circleci-config`

## 提交前校验脚本

仓库已经准备好以下脚本：

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

## 参考文档

- [docs/chunk-checklist.md](/D:/code/circleci_test/my_project/docs/chunk-checklist.md:1)
- [docs/chunk-implementation-guide.md](/D:/code/circleci_test/my_project/docs/chunk-implementation-guide.md:1)
- [docs/chunk-web-prompts.md](/D:/code/circleci_test/my_project/docs/chunk-web-prompts.md:1)

## 后续可扩展方向

- 增加 `Jacoco` 覆盖率报告
- 增加 `Checkstyle` 或 `SpotBugs`
- 增加 nightly 全量测试 workflow
- 增加 Docker 镜像构建与发布
- 在引入 Docker 构建后启用 `Docker Layer Caching`
