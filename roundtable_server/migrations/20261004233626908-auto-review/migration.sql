BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "project" ADD COLUMN "autoReview" boolean;
ALTER TABLE "project" ADD COLUMN "reviewerAgentId" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task" ADD COLUMN "autoReview" boolean NOT NULL DEFAULT false;
ALTER TABLE "task" ADD COLUMN "reviewerAgentId" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "workspace_settings" ADD COLUMN "autoReview" boolean NOT NULL DEFAULT false;
ALTER TABLE "workspace_settings" ADD COLUMN "reviewerAgentId" bigint;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "project"
    ADD CONSTRAINT "project_fk_0"
    FOREIGN KEY("reviewerAgentId")
    REFERENCES "agent"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task"
    ADD CONSTRAINT "task_fk_2"
    FOREIGN KEY("reviewerAgentId")
    REFERENCES "agent"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "workspace_settings"
    ADD CONSTRAINT "workspace_settings_fk_0"
    FOREIGN KEY("reviewerAgentId")
    REFERENCES "agent"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261004233626908-auto-review', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004233626908-auto-review', "timestamp" = now();

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
