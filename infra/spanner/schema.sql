-- =================================================================
-- Synergy Work Graph — Cloud Spanner DDL
-- =================================================================
-- This schema defines the unified Work Graph as a Spanner property
-- graph with relational tables, vector embeddings, full-text search
-- indexes, and change streams for ZeroETL to BigQuery.
-- =================================================================

-- ===================== NODE TABLES =====================

CREATE TABLE Workspaces (
  workspace_id   STRING(36) NOT NULL,
  name           STRING(256) NOT NULL,
  plan           STRING(36) DEFAULT ('free'),
  region         STRING(36) DEFAULT ('us-central1'),
  settings_json  JSON,
  created_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id);

CREATE TABLE Users (
  user_id    STRING(36) NOT NULL,
  email      STRING(512) NOT NULL,
  name       STRING(256) NOT NULL,
  avatar_url STRING(2048),
  locale     STRING(10) DEFAULT ('en'),
  timezone   STRING(64) DEFAULT ('UTC'),
  created_at TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (user_id);

CREATE UNIQUE INDEX idx_users_email ON Users(email);

CREATE TABLE Memberships (
  workspace_id STRING(36) NOT NULL,
  user_id      STRING(36) NOT NULL,
  role         STRING(36) NOT NULL DEFAULT ('member'),
  joined_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, user_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

CREATE TABLE Teams (
  workspace_id   STRING(36) NOT NULL,
  team_id        STRING(36) NOT NULL,
  name           STRING(256) NOT NULL,
  parent_team_id STRING(36),
  created_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, team_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

CREATE TABLE Projects (
  workspace_id STRING(36) NOT NULL,
  project_id   STRING(36) NOT NULL,
  name         STRING(256) NOT NULL,
  status       STRING(36) DEFAULT ('active'),
  owner_id     STRING(36),
  start_date   DATE,
  due_date     DATE,
  created_at   TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at   TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, project_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

CREATE TABLE Channels (
  workspace_id STRING(36) NOT NULL,
  channel_id   STRING(36) NOT NULL,
  project_id   STRING(36),
  name         STRING(256) NOT NULL,
  privacy      STRING(36) DEFAULT ('public'),
  topic        STRING(1024),
  created_at   TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, channel_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

CREATE TABLE Messages (
  workspace_id   STRING(36) NOT NULL,
  channel_id     STRING(36) NOT NULL,
  message_id     STRING(36) NOT NULL,
  author_id      STRING(36) NOT NULL,
  body           STRING(MAX) NOT NULL,
  thread_root_id STRING(36),
  embedding      ARRAY<FLOAT32>(vector_length=>768),
  created_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, channel_id, message_id),
  INTERLEAVE IN PARENT Channels ON DELETE CASCADE;

CREATE TABLE Tasks (
  workspace_id   STRING(36) NOT NULL,
  project_id     STRING(36) NOT NULL,
  task_id        STRING(36) NOT NULL,
  title          STRING(1024) NOT NULL,
  description    STRING(MAX),
  status         STRING(36) DEFAULT ('todo'),
  priority       STRING(36) DEFAULT ('medium'),
  owner_ids      ARRAY<STRING(36)>,
  due_at         TIMESTAMP,
  parent_task_id STRING(36),
  embedding      ARRAY<FLOAT32>(vector_length=>768),
  created_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at     TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, project_id, task_id),
  INTERLEAVE IN PARENT Projects ON DELETE CASCADE;

CREATE TABLE Documents (
  workspace_id       STRING(36) NOT NULL,
  doc_id             STRING(36) NOT NULL,
  title              STRING(1024) NOT NULL,
  content_json       JSON,
  current_version_id STRING(36),
  embedding          ARRAY<FLOAT32>(vector_length=>768),
  created_at         TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
  updated_at         TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, doc_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

CREATE TABLE Decisions (
  workspace_id STRING(36) NOT NULL,
  decision_id  STRING(36) NOT NULL,
  title        STRING(1024) NOT NULL,
  source_type  STRING(36),
  source_id    STRING(36),
  decided_by   ARRAY<STRING(36)>,
  decided_at   TIMESTAMP NOT NULL,
  rationale    STRING(MAX),
  merkle_hash  STRING(128),
  embedding    ARRAY<FLOAT32>(vector_length=>768),
  created_at   TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, decision_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

CREATE TABLE Files (
  workspace_id STRING(36) NOT NULL,
  file_id      STRING(36) NOT NULL,
  owner_id     STRING(36) NOT NULL,
  name         STRING(1024) NOT NULL,
  mime_type    STRING(256),
  size_bytes   INT64,
  storage_url  STRING(2048) NOT NULL,
  created_at   TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, file_id),
  INTERLEAVE IN PARENT Workspaces ON DELETE CASCADE;

-- ===================== EDGE TABLES =====================

CREATE TABLE AssignedTo (
  workspace_id STRING(36) NOT NULL,
  task_id      STRING(36) NOT NULL,
  user_id      STRING(36) NOT NULL,
  assigned_at  TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, task_id, user_id);

CREATE TABLE Blocks (
  workspace_id    STRING(36) NOT NULL,
  blocker_task_id STRING(36) NOT NULL,
  blocked_task_id STRING(36) NOT NULL,
  blocked_since   TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, blocker_task_id, blocked_task_id);

CREATE TABLE BelongsTo (
  workspace_id STRING(36) NOT NULL,
  entity_type  STRING(36) NOT NULL,
  entity_id    STRING(36) NOT NULL,
  project_id   STRING(36) NOT NULL,
) PRIMARY KEY (workspace_id, entity_type, entity_id);

CREATE TABLE PromotedFrom (
  workspace_id STRING(36) NOT NULL,
  target_type  STRING(36) NOT NULL,
  target_id    STRING(36) NOT NULL,
  message_id   STRING(36) NOT NULL,
  promoted_by  STRING(36) NOT NULL,
  promoted_at  TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, target_type, target_id);

CREATE TABLE Mentions (
  workspace_id STRING(36) NOT NULL,
  source_type  STRING(36) NOT NULL,
  source_id    STRING(36) NOT NULL,
  user_id      STRING(36) NOT NULL,
  mention_type STRING(36) DEFAULT ('direct'),
) PRIMARY KEY (workspace_id, source_type, source_id, user_id);

CREATE TABLE MemberOf (
  workspace_id STRING(36) NOT NULL,
  user_id      STRING(36) NOT NULL,
  group_type   STRING(36) NOT NULL,
  group_id     STRING(36) NOT NULL,
  role         STRING(36) DEFAULT ('member'),
  joined_at    TIMESTAMP NOT NULL OPTIONS (allow_commit_timestamp=true),
) PRIMARY KEY (workspace_id, user_id, group_type, group_id);

-- ===================== FULL-TEXT SEARCH INDEXES =====================

CREATE SEARCH INDEX idx_messages_ft
  ON Messages(body_tokens)
  STORING (author_id, created_at)
  OPTIONS (sort_order_sharding=true);

ALTER TABLE Messages ADD COLUMN body_tokens TOKENLIST
  AS (TOKENIZE_FULLTEXT(body, language_tag=>'en')) HIDDEN;

CREATE SEARCH INDEX idx_tasks_ft
  ON Tasks(title_tokens)
  OPTIONS (sort_order_sharding=true);

ALTER TABLE Tasks ADD COLUMN title_tokens TOKENLIST
  AS (TOKENIZE_FULLTEXT(title, language_tag=>'en')) HIDDEN;

CREATE SEARCH INDEX idx_decisions_ft
  ON Decisions(rationale_tokens)
  OPTIONS (sort_order_sharding=true);

ALTER TABLE Decisions ADD COLUMN rationale_tokens TOKENLIST
  AS (TOKENIZE_FULLTEXT(rationale, language_tag=>'en')) HIDDEN;

-- ===================== VECTOR INDEXES (ANN) =====================

CREATE VECTOR INDEX idx_messages_vec
  ON Messages(embedding)
  OPTIONS (distance_type='COSINE', tree_depth=3, num_leaves=1000);

CREATE VECTOR INDEX idx_tasks_vec
  ON Tasks(embedding)
  OPTIONS (distance_type='COSINE', tree_depth=3, num_leaves=1000);

CREATE VECTOR INDEX idx_decisions_vec
  ON Decisions(embedding)
  OPTIONS (distance_type='COSINE', tree_depth=3, num_leaves=1000);

-- ===================== PROPERTY GRAPH =====================

CREATE OR REPLACE PROPERTY GRAPH SynergyWorkGraph
  NODE TABLES (
    Workspaces  KEY (workspace_id),
    Users       KEY (user_id),
    Projects    KEY (workspace_id, project_id),
    Channels    KEY (workspace_id, channel_id),
    Messages    KEY (workspace_id, channel_id, message_id),
    Tasks       KEY (workspace_id, project_id, task_id),
    Documents   KEY (workspace_id, doc_id),
    Decisions   KEY (workspace_id, decision_id),
    Files       KEY (workspace_id, file_id)
  )
  EDGE TABLES (
    AssignedTo
      SOURCE KEY (workspace_id, task_id) REFERENCES Tasks
      DESTINATION KEY (user_id) REFERENCES Users,
    Blocks
      SOURCE KEY (workspace_id, blocker_task_id) REFERENCES Tasks
      DESTINATION KEY (workspace_id, blocked_task_id) REFERENCES Tasks,
    PromotedFrom
      SOURCE KEY (workspace_id, target_type, target_id) REFERENCES Decisions
      DESTINATION KEY (workspace_id, message_id) REFERENCES Messages,
    Mentions
      SOURCE KEY (workspace_id, source_type, source_id) REFERENCES Messages
      DESTINATION KEY (user_id) REFERENCES Users,
    MemberOf
      SOURCE KEY (workspace_id, user_id) REFERENCES Users
      DESTINATION KEY (workspace_id, group_type, group_id) REFERENCES Channels
  );

-- ===================== CHANGE STREAMS =====================

CREATE CHANGE STREAM WorkGraphChanges
  FOR Workspaces, Projects, Channels, Messages, Tasks, Documents, Decisions, Files,
      AssignedTo, Blocks, PromotedFrom, Mentions, MemberOf
  OPTIONS (
    retention_period = '7d',
    value_capture_type = 'NEW_AND_OLD_VALUES'
  );
