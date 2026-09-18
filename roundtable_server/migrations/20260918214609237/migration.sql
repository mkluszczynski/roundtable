BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "agent" (
    "id" bigserial PRIMARY KEY,
    "machineId" bigint NOT NULL,
    "name" text NOT NULL,
    "role" text NOT NULL DEFAULT 'generalist'::text,
    "defaultModel" text,
    "defaultEffort" text,
    "executionMode" text NOT NULL DEFAULT 'native'::text,
    "status" text NOT NULL DEFAULT 'idle'::text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "machine" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "tokenHash" text,
    "status" text NOT NULL DEFAULT 'offline'::text,
    "lastSeenAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "machine_token_hash_idx" ON "machine" USING btree ("tokenHash");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "machine_metric" (
    "id" bigserial PRIMARY KEY,
    "machineId" bigint NOT NULL,
    "cpuPercent" double precision NOT NULL,
    "memoryUsedMb" bigint NOT NULL,
    "memoryTotalMb" bigint NOT NULL,
    "recordedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "machine_metric_recorded_idx" ON "machine_metric" USING btree ("machineId", "recordedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "project" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "repoUrl" text NOT NULL,
    "repoAccessToken" text,
    "dockerImage" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "task" (
    "id" bigserial PRIMARY KEY,
    "projectId" bigint NOT NULL,
    "agentId" bigint,
    "prompt" text NOT NULL,
    "skipPlanning" boolean NOT NULL DEFAULT false,
    "status" text NOT NULL DEFAULT 'queued'::text,
    "currentPlan" text,
    "failureReason" text,
    "claudeSessionId" text,
    "branchName" text,
    "prUrl" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" timestamp without time zone,
    "finishedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "task_feedback" (
    "id" bigserial PRIMARY KEY,
    "taskId" bigint NOT NULL,
    "message" text NOT NULL,
    "phase" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "task_log_entry" (
    "id" bigserial PRIMARY KEY,
    "taskId" bigint NOT NULL,
    "content" text NOT NULL,
    "source" text NOT NULL DEFAULT 'agent'::text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "task_question" (
    "id" bigserial PRIMARY KEY,
    "taskId" bigint NOT NULL,
    "question" text NOT NULL,
    "options" json NOT NULL,
    "answer" text,
    "answeredAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "agent"
    ADD CONSTRAINT "agent_fk_0"
    FOREIGN KEY("machineId")
    REFERENCES "machine"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "machine_metric"
    ADD CONSTRAINT "machine_metric_fk_0"
    FOREIGN KEY("machineId")
    REFERENCES "machine"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task"
    ADD CONSTRAINT "task_fk_0"
    FOREIGN KEY("projectId")
    REFERENCES "project"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "task"
    ADD CONSTRAINT "task_fk_1"
    FOREIGN KEY("agentId")
    REFERENCES "agent"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task_feedback"
    ADD CONSTRAINT "task_feedback_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task_log_entry"
    ADD CONSTRAINT "task_log_entry_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task_question"
    ADD CONSTRAINT "task_question_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20260918214609237', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260918214609237', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260824182259319', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182259319', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260910193913364-string-rate-limit-keys', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260910193913364-string-rate-limit-keys', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260824182354731', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260824182354731', "timestamp" = now();


COMMIT;
