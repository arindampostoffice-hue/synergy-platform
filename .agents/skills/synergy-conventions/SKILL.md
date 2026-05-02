---
name: synergy-conventions
description: >
  Synergy platform coding conventions, naming patterns, architecture rules,
  and quality gates. Triggered when creating or modifying any service code,
  API definition, test, or infrastructure file.
---

# Synergy Coding Conventions

## Go Services
- Use standard Go project layout: `/handlers`, `/internal`, `/cmd`
- HTTP framework: `net/http` with `chi` router (no gin/echo)
- GraphQL: `gqlgen` with schema-first approach
- Spanner client: `cloud.google.com/go/spanner`
- Error handling: wrap errors with `fmt.Errorf("context: %w", err)`
- Logging: `slog` (structured, JSON in prod)
- Config: environment variables, never hardcoded values
- Tests: table-driven tests; `go test -race ./...`

## Python Services (AI Gateway)
- Framework: FastAPI with Pydantic v2 models
- Async: use `async def` for all endpoint handlers
- AI SDK: `google-cloud-aiplatform` for Vertex AI
- Type hints: mandatory on all functions
- Tests: pytest with httpx.AsyncClient for API tests

## Web Client (React)
- TypeScript strict mode (`"strict": true` in tsconfig)
- State: React Query (TanStack Query) for server state, Zustand for client state
- Styling: Tailwind CSS with design tokens in `tailwind.config.ts`
- GraphQL: urql client
- Accessibility: every interactive component must have ARIA labels, keyboard support
- Testing: Vitest + Testing Library; axe-core in dev mode

## API Design
- GraphQL for client-facing queries/mutations (single gateway)
- REST for third-party integrations and webhooks
- gRPC for internal service-to-service calls
- All mutations are idempotent with client-supplied request IDs
- All responses include trace IDs for debugging

## Events
- Every state-changing operation publishes to Pub/Sub
- Topic naming: `{entity}-events` (e.g., `work-graph-events`)
- Event schema: `{ event_type, workspace_id, entity_id, actor_id, timestamp, payload }`
- Subscribers must be idempotent (deduplication by event_id)

## Security
- No secrets in code or environment files; use Secret Manager
- All service accounts follow least-privilege
- Input validation on every handler; never trust client data
- SQL/GQL injection prevention: always use parameterized queries

## Quality Gates (CI must pass all)
1. Unit tests pass with race detector
2. Lint clean (golangci-lint / eslint / ruff)
3. No critical/serious axe-core violations
4. No new high/critical CVEs in dependencies
5. Docker image builds successfully
6. OpenTelemetry spans present on all handlers
