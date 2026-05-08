# Chunk Web prompts

These prompts are designed for the CircleCI Chunk Web UI for `my_project`.

## 1. Optimize build configuration

```text
Analyze this project's CircleCI pipeline and suggest build configuration optimizations.
Focus on caching, parallelism, resource_class sizing, and ways to improve test feedback speed.
Prefer practical changes that fit a Spring Boot Maven project on JDK 8.
```

## 2. Review pipeline design

```text
Review the current CircleCI workflow for this repository.
Explain whether the current split between parallel_test_verification, package_application, and deploy_snapshot is appropriate.
Suggest any changes that would make the workflow easier to understand or faster to run.
```

## 3. Investigate flaky test readiness

```text
Assess whether this repository is well prepared for Chunk flaky test analysis.
Check test result collection, environment setup, repair guidance, and any gaps that would reduce Chunk effectiveness.
```

## 4. Fix failed job with explicit intent

```text
Fix the failing job by changing application code or build configuration rather than weakening tests.
Keep JDK 8 compatibility, preserve endpoint semantics, and prefer minimal changes.
```
