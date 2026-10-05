BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ALTER COLUMN "autoFixFailingChecks" DROP NOT NULL;
ALTER TABLE "project" ALTER COLUMN "autoFixFailingChecks" DROP DEFAULT;
ALTER TABLE "project" ALTER COLUMN "maxCheckFixAttempts" DROP NOT NULL;
ALTER TABLE "project" ALTER COLUMN "maxCheckFixAttempts" DROP DEFAULT;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task" ADD COLUMN "autoFixFailingChecks" boolean NOT NULL DEFAULT false;
ALTER TABLE "task" ADD COLUMN "maxCheckFixAttempts" bigint NOT NULL DEFAULT 2;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_settings" ADD COLUMN "autoFixFailingChecks" boolean NOT NULL DEFAULT false;
ALTER TABLE "workspace_settings" ADD COLUMN "maxCheckFixAttempts" bigint NOT NULL DEFAULT 2;

--
-- Data: CI auto-fix moves from the project to the task (with project and
-- workspace defaults). Tasks still in flight keep their project's setting;
-- projects left at the old defaults inherit the workspace instead of
-- overriding it.
--
UPDATE "task" SET
    "autoFixFailingChecks" = p."autoFixFailingChecks",
    "maxCheckFixAttempts" = p."maxCheckFixAttempts"
FROM "project" p
WHERE "task"."projectId" = p."id"
    AND "task"."status" NOT IN ('done', 'failed', 'cancelled');
UPDATE "project" SET "autoFixFailingChecks" = NULL
    WHERE "autoFixFailingChecks" = false;
UPDATE "project" SET "maxCheckFixAttempts" = NULL
    WHERE "maxCheckFixAttempts" = 2;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261005162835759-ci-autofix-cascade', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261005162835759-ci-autofix-cascade', "timestamp" = now();

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
