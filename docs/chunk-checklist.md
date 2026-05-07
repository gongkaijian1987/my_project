# Chunk 配置检查清单

本文档用于在 CircleCI 控制台中逐项确认 `my_project` 是否已经具备稳定运行 Chunk 的条件。

## 1. 组织级检查

- 已在 CircleCI 组织中启用 Chunk
- 已完成模型提供方配置
- 如果使用自带密钥模式，确认 `circleci-agents` context 已存在
- 如果仓库需要私有资源访问，确认相关 `context` 已准备完毕

## 2. 仓库级检查

- 默认分支为 `main`
- `.circleci/config.yml` 已合并到默认分支
- `.circleci/cci-agent-setup.yml` 已合并到默认分支
- 仓库根目录存在 `agents.md` 或 `claude.md`
- 如果要修 flaky tests，确认 `.circleci/fix-flaky-test.md` 已提交

## 3. CI 配置检查

- 主流程能稳定执行 Maven 构建和测试
- `store_test_results` 已配置
- 测试结果路径为 `target/surefire-reports`
- 测试失败时 job 会真实失败，而不是被吞掉
- 默认分支不会因为“空 diff”跳过测试

## 4. Chunk 环境检查

- `cci-agent-setup.yml` 中存在一个名为 `cci-agent-setup` 的 job
- 该 job 只负责环境准备，不直接运行测试
- 该 job 能成功执行 `checkout`
- 该 job 能安装或准备项目依赖
- 如果项目依赖数据库、缓存或第三方服务，这些服务也已在该文件中准备
- 如果需要 `context`，确认已经显式绑定到 `cci-agent-setup` job

## 5. Fix flaky tests 检查

- 项目中已有可重复收集的测试历史
- 测试报告会持续上传到 CircleCI
- `.circleci/fix-flaky-test.md` 明确了修复边界
- 团队接受 Chunk 自动创建 PR 修复测试问题

## 6. Fix job failure 检查

- 失败 job 的日志在 CircleCI 页面中可见
- 失败 job 不是被取消状态
- 失败原因可以稳定复现
- 失败不是纯权限、配额、网络中断类问题
- 如果是代码逻辑问题，仓库中的规则文件已经明确修复偏好

## 7. 控制台验证动作

建议按以下顺序验证：

1. 在 CircleCI 中打开 Chunk
2. 使用 `Chunk Environment` 测试 `.circleci/cci-agent-setup.yml`
3. 手动触发一次主流水线
4. 确认测试结果被正确采集
5. 对一个真实失败 job 运行 `Fix job failure`
6. 对项目启用 `Fix flaky tests`
