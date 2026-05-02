terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.30"
    }
  }
  backend "gcs" {
    bucket = "synergy-terraform-state"
    prefix = "prod"
  }
}

variable "project_id" {
  default = "synergy-platform-prod"
}
variable "region" {
  default = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ============================================================
# NETWORKING
# ============================================================
resource "google_compute_network" "main" {
  name                    = "synergy-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke" {
  name          = "synergy-gke-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.main.id
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"
  }
  private_ip_google_access = true
}

# ============================================================
# SPANNER (THE WORK GRAPH)
# ============================================================
resource "google_spanner_instance" "main" {
  name             = "synergy-instance"
  display_name     = "Synergy Work Graph"
  config           = "regional-${var.region}"
  processing_units = 1000 # 1 node equivalent; scales up
  edition          = "ENTERPRISE_PLUS"
}

resource "google_spanner_database" "workgraph" {
  instance = google_spanner_instance.main.name
  name     = "synergy-work-graph"
  # DDL is applied separately via gcloud (see infra/spanner/schema.sql)
  deletion_protection = true
}

# ============================================================
# GKE AUTOPILOT
# ============================================================
resource "google_container_cluster" "main" {
  provider = google-beta
  name     = "synergy-cluster"
  location = var.region

  enable_autopilot = true
  network          = google_compute_network.main.name
  subnetwork       = google_compute_subnetwork.gke.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  confidential_nodes {
    enabled = true
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
}

# ============================================================
# ARTIFACT REGISTRY
# ============================================================
resource "google_artifact_registry_repository" "images" {
  repository_id = "synergy-images"
  location      = var.region
  format        = "DOCKER"
  description   = "Synergy container images"
}

# ============================================================
# PUB/SUB
# ============================================================
resource "google_pubsub_topic" "work_graph_events" {
  name = "work-graph-events"
}
resource "google_pubsub_topic" "notification_events" {
  name = "notification-events"
}
resource "google_pubsub_topic" "sync_events" {
  name = "sync-events"
}

# ============================================================
# FIRESTORE
# ============================================================
resource "google_firestore_database" "main" {
  name        = "synergy-sync"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

# ============================================================
# MEMORYSTORE (REDIS)
# ============================================================
resource "google_redis_instance" "cache" {
  name           = "synergy-cache"
  memory_size_gb = 6
  region         = var.region
  tier           = "STANDARD_HA"
  redis_version  = "REDIS_7_2"
  authorized_network = google_compute_network.main.id
}

# ============================================================
# CLOUD STORAGE
# ============================================================
resource "google_storage_bucket" "files" {
  name                        = "synergy-files-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true
  versioning { enabled = true }
  lifecycle_rule {
    action { type = "SetStorageClass" storage_class = "NEARLINE" }
    condition { age = 90 }
  }
  lifecycle_rule {
    action { type = "SetStorageClass" storage_class = "COLDLINE" }
    condition { age = 365 }
  }
}

# ============================================================
# BIGQUERY
# ============================================================
resource "google_bigquery_dataset" "analytics" {
  dataset_id = "synergy_analytics"
  location   = var.region
}

# ============================================================
# CLOUD KMS
# ============================================================
resource "google_kms_key_ring" "main" {
  name     = "synergy-keyring"
  location = var.region
}
resource "google_kms_crypto_key" "workspace_key" {
  name     = "workspace-encryption-key"
  key_ring = google_kms_key_ring.main.id
  purpose  = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days
}

# ============================================================
# OUTPUTS
# ============================================================
output "gke_cluster_name" { value = google_container_cluster.main.name }
output "spanner_instance" { value = google_spanner_instance.main.name }
output "redis_host"       { value = google_redis_instance.cache.host }
output "files_bucket"     { value = google_storage_bucket.files.name }
output "registry_url"     { value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.images.repository_id}" }
