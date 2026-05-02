---
name: code-review
description: >
  Synergy code review checklist. Triggered when reviewing code, PRs,
  or when the user asks for a review of any file.
---

# Synergy Code Review Checklist

Review every change against these criteria. Flag any violation.

## 1. Correctness
- [ ] Logic matches the intended behavior
- [ ] Edge cases handled (nil, empty, concurrent access)
- [ ] Error paths return meaningful errors (not swallowed)
- [ ] Parameterized queries only — no string interpolation in SQL/GQL

## 2. Security
- [ ] No secrets, keys, tokens, or passwords in code
- [ ] Input validated and sanitized at the handler level
- [ ] Authorization check present for every data access
- [ ] No new dependencies without security review

## 3. Performance
- [ ] No N+1 query patterns (batch or join instead)
- [ ] Spanner reads use appropriate staleness (strong for mutations, bounded for reads)
- [ ] Response payloads are bounded (pagination, field selection)
- [ ] No blocking calls in hot paths

## 4. Accessibility (frontend)
- [ ] Every interactive element has an accessible name (aria-label or visible label)
- [ ] Keyboard navigation works for all new components
- [ ] Focus management is correct after state changes
- [ ] Color is not the sole indicator of state
- [ ] Contrast ratios meet WCAG 2.2 AA (4.5:1 body, 3:1 large text)

## 5. Observability
- [ ] OpenTelemetry span created for the operation
- [ ] Structured log at INFO for success, WARN for retries, ERROR for failures
- [ ] Metrics emitted for latency and error count

## 6. Testing
- [ ] New behavior has corresponding tests
- [ ] Tests are deterministic (no sleep, no external deps without mocks)
- [ ] Tests run in under 30 seconds

## 7. Style
- [ ] Follows Go/Python/TypeScript conventions in synergy-conventions skill
- [ ] Functions under 50 lines; files under 300 lines
- [ ] Comments explain WHY, not WHAT
