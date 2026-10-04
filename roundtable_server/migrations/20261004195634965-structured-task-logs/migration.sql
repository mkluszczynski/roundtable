BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "task_log_entry" ADD COLUMN "kind" text;
ALTER TABLE "task_log_entry" ADD COLUMN "runId" text;
ALTER TABLE "task_log_entry" ADD COLUMN "phase" text;
ALTER TABLE "task_log_entry" ADD COLUMN "toolName" text;
ALTER TABLE "task_log_entry" ADD COLUMN "toolUseId" text;
ALTER TABLE "task_log_entry" ADD COLUMN "detail" text;
ALTER TABLE "task_log_entry" ADD COLUMN "isError" boolean;
ALTER TABLE "task_log_entry" ADD COLUMN "reviewId" bigint;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261004195634965-structured-task-logs', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004195634965-structured-task-logs', "timestamp" = now();

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
