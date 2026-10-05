BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ADD COLUMN "autoFixReview" boolean;
ALTER TABLE "project" ADD COLUMN "maxReviewFixRounds" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task" ADD COLUMN "autoFixReview" boolean NOT NULL DEFAULT false;
ALTER TABLE "task" ADD COLUMN "maxReviewFixRounds" bigint NOT NULL DEFAULT 2;
ALTER TABLE "task" ADD COLUMN "reviewFixRounds" bigint NOT NULL DEFAULT 0;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_settings" ADD COLUMN "autoFixReview" boolean NOT NULL DEFAULT false;
ALTER TABLE "workspace_settings" ADD COLUMN "maxReviewFixRounds" bigint NOT NULL DEFAULT 2;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261005161317699-auto-fix-review', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261005161317699-auto-fix-review', "timestamp" = now();

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
