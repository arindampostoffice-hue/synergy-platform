# Synergy Platform

> A unified team collaboration platform — chat, tasks, docs, decisions — built on Google Cloud with Spanner Graph at its core.

## Architecture

| Layer | Technology |
|-------|-----------|
| **Work Graph** | Cloud Spanner (Graph + Vector + Full-text + ML.PREDICT) |
| **Compute** | GKE Autopilot + Cloud Run |
| **AI** | Vertex AI + Gemini (Flash / Pro) |
| **Real-time** | Firestore + Pub/Sub + Eventarc |
| **Search** | Vertex AI Search + Spanner ANN |
| **Edge** | Cloud CDN + Media CDN + Cloud Armor |
| **Analytics** | BigQuery + Looker |
| **Security** | Confidential GKE + BeyondCorp + Cloud KMS/HSM |

## Repository Structure

```
synergy-platform/
├── services/
│   ├── work-graph-service/   # Go — Core Work Graph CRUD + GraphQL
│   ├── channel-service/      # Go — Real-time messaging + WebSocket
│   ├── task-service/         # Go — Task management + boards
│   ├── doc-service/          # Go — Document collaboration + CRDT
│   ├── ai-gateway/           # Python — Vertex AI routing + RAG
│   ├── sync-service/         # Go — Spanner ↔ Firestore sync
│   └── notification-service/ # Go — Notifications + digests
├── web/                      # TypeScript/React — Web client
├── infra/
│   ├── terraform/            # All GCP infrastructure as code
│   ├── spanner/              # Spanner DDL (Graph schema)
│   └── k8s/                  # Kubernetes manifests
├── proto/                    # Protobuf definitions
├── scripts/                  # Utility scripts
├── .agents/                  # Antigravity Skills & Rules
├── .github/workflows/        # GitHub Actions CI
└── cloudbuild.yaml           # Cloud Build CD
```

## Prerequisites

- Google Cloud CLI (`gcloud`) authenticated
- Terraform 1.8+
- Go 1.22+
- Node.js 20+ LTS
- Python 3.11+
- Docker 24+
- Google Antigravity IDE (antigravity.google/download)

## Quick Start

```bash
# 1. Clone
git clone https://github.com/YOUR_ORG/synergy-platform.git
cd synergy-platform

# 2. Set your GCP project
export PROJECT_ID="synergy-platform-prod"
gcloud config set project $PROJECT_ID

# 3. Provision infrastructure
cd infra/terraform
terraform init && terraform apply
cd ../..

# 4. Apply Spanner schema
gcloud spanner databases ddl update synergy-work-graph \
  --instance=synergy-instance \
  --ddl-file=infra/spanner/schema.sql

# 5. Build & deploy
gcloud builds submit --config=cloudbuild.yaml

# 6. Open in Antigravity for agent-driven development
# File > Open Folder > synergy-platform/
```

## Development with Antigravity

This project includes Antigravity Skills in `.agents/` that teach the AI agent:
- **synergy-conventions**: Coding standards, naming, architecture rules
- **gcp-deploy**: How to deploy services to GKE and Cloud Run
- **code-review**: Review checklist including accessibility and security

See the [Antigravity Development Guide](docs/antigravity-guide.md) for detailed workflows.

## License

Proprietary — All rights reserved.
