BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "pr_check_run" (
    "id" bigserial PRIMARY KEY,
    "taskId" bigint NOT NULL,
    "headSha" text NOT NULL,
    "workflowRunId" bigint NOT NULL,
    "runAttempt" bigint NOT NULL,
    "workflowName" text NOT NULL,
    "jobId" bigint NOT NULL,
    "jobName" text NOT NULL,
    "status" text NOT NULL,
    "conclusion" text,
    "failedStep" text,
    "htmlUrl" text,
    "startedAt" timestamp without time zone,
    "completedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "pr_check_run_task_idx" ON "pr_check_run" USING btree ("taskId", "jobId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ADD COLUMN "autoFixFailingChecks" boolean NOT NULL DEFAULT false;
ALTER TABLE "project" ADD COLUMN "maxCheckFixAttempts" bigint NOT NULL DEFAULT 2;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task" ADD COLUMN "prHeadSha" text;
ALTER TABLE "task" ADD COLUMN "prHeadSeenAt" timestamp without time zone;
ALTER TABLE "task" ADD COLUMN "checkState" text NOT NULL DEFAULT 'none'::text;
ALTER TABLE "task" ADD COLUMN "checkError" text;
ALTER TABLE "task" ADD COLUMN "checkFixAttempts" bigint NOT NULL DEFAULT 0;
ALTER TABLE "task" ADD COLUMN "checkFixSentForSha" text;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "pr_check_run"
    ADD CONSTRAINT "pr_check_run_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261004232103110-pr-checks', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004232103110-pr-checks', "timestamp" = now();

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
    VALUES ('serverpod_auth_idp', '20260924105404509', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105404509', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260924105232991', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260924105232991', "timestamp" = now();


COMMIT;
