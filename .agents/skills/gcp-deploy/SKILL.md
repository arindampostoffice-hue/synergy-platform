---
name: gcp-deploy
description: >
  How to deploy Synergy services to Google Cloud. Triggered when the user
  asks to deploy, provision, create infrastructure, or push to GKE/Cloud Run.
---

# GCP Deployment Procedures

## Infrastructure (Terraform)
All GCP resources are defined in `/infra/terraform/`. Never create resources manually.

```bash
cd infra/terraform
terraform init
terraform plan -out=plan.out   # ALWAYS review before applying
terraform apply plan.out
```

## Container Images
```bash
# Authenticate Docker with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# Build and push (replace SERVICE_NAME)
export REGISTRY=us-central1-docker.pkg.dev/synergy-platform-prod/synergy-images
docker build -t $REGISTRY/SERVICE_NAME:latest services/SERVICE_NAME/
docker push $REGISTRY/SERVICE_NAME:latest
```

## Deploy to GKE Autopilot
```bash
# Get cluster credentials
gcloud container clusters get-credentials synergy-cluster --region=us-central1

# Apply manifests
kubectl apply -f infra/k8s/namespace.yaml
kubectl apply -f infra/k8s/SERVICE_NAME.yaml

# Verify
kubectl get pods -n synergy
kubectl logs -n synergy deployment/SERVICE_NAME
```

## Deploy to Cloud Run (event handlers)
```bash
gcloud run deploy SERVICE_NAME \
  --image=$REGISTRY/SERVICE_NAME:latest \
  --region=us-central1 \
  --service-account=SERVICE_NAME-sa@synergy-platform-prod.iam.gserviceaccount.com \
  --set-env-vars="PROJECT_ID=synergy-platform-prod,REGION=us-central1"
```

## Spanner Schema Updates
```bash
gcloud spanner databases ddl update synergy-work-graph \
  --instance=synergy-instance \
  --ddl-file=infra/spanner/schema.sql
```

## Verification Checklist
After every deployment:
1. `kubectl get pods -n synergy` — all pods Running
2. `kubectl get ingress -n synergy` — external IP assigned
3. Hit the health endpoint: `curl https://EXTERNAL_IP/healthz`
4. Check Cloud Monitoring for error rate spikes
5. Check Cloud Logging for startup errors

## Rollback
```bash
# GKE: rollback to previous revision
kubectl rollout undo deployment/SERVICE_NAME -n synergy

# Cloud Run: rollback to previous revision
gcloud run services update-traffic SERVICE_NAME --to-revisions=PREVIOUS_REVISION=100
```
