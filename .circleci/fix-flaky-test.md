# Chunk Guidance For `my_project`

## Project context

- This project is a Spring Boot demo application built with Maven.
- The runtime baseline is JDK 8, and compatibility with `1.8.0_462` must be preserved.
- The main package is `com.example.demo`.
- The current API surface includes `/api/health` and `/api/greeting`.

## Testing preferences

- Prefer JUnit 5 for unit and integration tests.
- Prefer `MockMvc` for controller-level HTTP tests.
- Keep tests deterministic and isolated.
- Do not rely on test execution order.
- Avoid time-sensitive assertions unless they are tolerant to small timing differences.

## Fix strategy preferences

- When fixing flaky tests, prefer the smallest safe change.
- Prefer fixing shared mutable state, timing assumptions, and implicit environment dependencies before increasing retries or timeouts.
- Do not remove assertions just to make a test pass.
- Do not skip or disable tests unless there is a clearly documented reason.

## Code safety rules

- Do not change the public JSON field names returned by existing endpoints unless the change is explicitly required.
- Do not introduce dependencies that require Java versions above 8.
- Do not hardcode secrets, credentials, or tokens.
- Keep Spring Boot and Maven changes minimal and compatible with the current project structure.

## Verification expectations

- Ensure all modified tests pass in CircleCI.
- If application code changes, verify both unit tests and controller tests when relevant.
- Preserve `store_test_results` compatibility so CircleCI can continue collecting test history.
