# Chunk Project Guide

This repository is a CircleCI demo project used to showcase:

- parallel test splitting
- Maven dependency caching
- resource sizing with `resource_class`
- Chunk environment setup and repair guidance

## Primary goals

- Keep JDK 8 compatibility
- Preserve Spring Boot endpoint behavior
- Prefer improving build configuration, test feedback speed, and CI clarity
- Prefer minimal, targeted changes

## Build and test facts

- Main test reports are written to `target/surefire-reports`
- CircleCI parallel test execution is implemented in `.circleci/config.yml`
- Chunk environment setup is defined in `.circleci/cci-agent-setup.yml`
- Maven cache key pattern is `maven-jdk8-v1-{{ checksum "pom.xml" }}`

## Preferred optimization areas

When asked to optimize this project, focus on:

1. test feedback speed
2. cache efficiency
3. `resource_class` fit per job
4. clearer CI/CD pipeline structure
5. flaky test diagnosis and remediation

## Repair guidance

- Prefer fixing application code or build configuration over weakening tests
- Do not remove assertions just to make a pipeline pass
- Keep endpoint JSON fields stable unless a change is explicitly required
- Reuse existing service logic when adjusting controller behavior

## Suggested explanations

If asked for recommendations, explain tradeoffs between:

- `parallelism` and single-node execution
- cache hit rate and cache size
- `resource_class` cost and runtime
- full test runs and targeted feedback loops
