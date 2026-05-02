# Synergy Project Context

## What is Synergy
Synergy is a unified team collaboration platform that replaces Slack + Asana + Notion
with one connected system. Chat, tasks, docs, and decisions live in a single Work Graph.

## Architecture Overview
- **Monorepo**: Services in `/services/`, frontend in `/web/`, infra in `/infra/`
- **Database**: Cloud Spanner Graph as the canonical Work Graph (GQL + SQL + Vector + Full-text)
- **Compute**: GKE Autopilot for long-running services, Cloud Run for event handlers
- **AI**: Vertex AI + Gemini for search, summarization, Q&A, status rollups
- **Sync**: Firestore for client-side offline replicas with real-time listeners
- **Events**: Cloud Pub/Sub for all cross-service communication
- **Analytics**: BigQuery via ZeroETL from Spanner change streams

## GCP Configuration
- **Project ID**: synergy-platform-prod
- **Region**: us-central1
- **Spanner Instance**: synergy-instance
- **Spanner Database**: synergy-work-graph
- **GKE Cluster**: synergy-cluster
- **Artifact Registry**: synergy-images
- **Namespace**: synergy

## Technology Stack
| Component | Technology |
|-----------|-----------|
| Backend services | Go 1.22 |
| AI Gateway | Python 3.12 / FastAPI |
| Web client | TypeScript / React / Vite |
| API | GraphQL (gqlgen) + REST |
| Auth | Firebase Auth (OIDC/SAML) |
| IaC | Terraform |
| CI/CD | Cloud Build + GitHub Actions |
| Containers | Docker → Artifact Registry → GKE Autopilot |

## Key Conventions
- Service names: kebab-case (e.g., `work-graph-service`)
- Database tables: PascalCase (e.g., `Messages`, `Tasks`)
- All services must have: `Dockerfile`, `README.md`, tests, OpenTelemetry instrumentation
- All GCP resources defined in Terraform under `/infra/terraform/`
- Every mutation publishes an event to Pub/Sub
- Every API endpoint has OTEL tracing
- Accessibility: WCAG 2.2 AA baseline on all frontend components

## Data Model (Work Graph)
The Work Graph is a Spanner property graph with these node types:
Workspaces, Users, Projects, Channels, Messages, Tasks, Documents, Decisions, Files

And these edge types:
AssignedTo, Blocks, DependsOn, BelongsTo, PromotedFrom, References, DecidedIn, Mentions, MemberOf
