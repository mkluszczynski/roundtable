BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "task" ADD COLUMN "prAdditions" bigint;
ALTER TABLE "task" ADD COLUMN "prDeletions" bigint;
ALTER TABLE "task" ADD COLUMN "openReviewComments" bigint NOT NULL DEFAULT 0;

-- Backfill (hand-added): count the unresolved comments of existing tasks.
UPDATE "task" SET "openReviewComments" = c."count"
    FROM (
        SELECT r."taskId", count(*) AS "count"
        FROM "review_comment" rc
        JOIN "code_review" r ON r."id" = rc."reviewId"
        WHERE rc."state" IN ('open', 'sentToFix')
        GROUP BY r."taskId"
    ) c
    WHERE "task"."id" = c."taskId";

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261007175141237-kanban-change-stats', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261007175141237-kanban-change-stats', "timestamp" = now();

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
