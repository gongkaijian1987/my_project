# Chunk Repair Guidance For `my_project`

## Purpose

This repository uses Chunk to help fix job failures and flaky tests.
When a failing job is caused by application behavior not matching an existing test expectation, prefer fixing the application code to satisfy the intended behavior.

## Repair priorities

- Prefer fixing controller, service, or configuration code before weakening tests.
- Do not remove assertions just to make the pipeline pass.
- Do not change a test expectation unless the test is clearly incorrect and the existing application behavior is the intended behavior.
- If an endpoint test expects a JSON field such as `message`, prefer updating the endpoint implementation to return that field when it matches the feature intent.

## API behavior rules

- Preserve existing JSON response field names unless a change is explicitly required.
- Keep endpoint behavior consistent with the semantics implied by the test name.
- For controller endpoint failures, prefer reusing existing service logic rather than duplicating behavior.

## Safety rules

- Keep changes minimal and focused on the failing job.
- Preserve JDK 8 compatibility.
- Do not introduce new dependencies unless necessary.
- Do not hardcode secrets or environment-specific values.

## Testing expectations

- After a fix, run the related Spring Boot controller tests and any directly related unit tests.
- Prefer deterministic fixes over retries, sleeps, or timing-based workarounds.
