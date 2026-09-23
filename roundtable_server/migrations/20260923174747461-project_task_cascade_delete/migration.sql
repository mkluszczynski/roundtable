BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "machine_metric" DROP CONSTRAINT IF EXISTS "machine_metric_fk_0";
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task" DROP CONSTRAINT IF EXISTS "task_fk_0";
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task_feedback" DROP CONSTRAINT IF EXISTS "task_feedback_fk_0";
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task_log_entry" DROP CONSTRAINT IF EXISTS "task_log_entry_fk_0";
--
-- ACTION ALTER TABLE
--
ALTER TABLE "task_question" DROP CONSTRAINT IF EXISTS "task_question_fk_0";
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "machine_metric"
    ADD CONSTRAINT "machine_metric_fk_0"
    FOREIGN KEY("machineId")
    REFERENCES "machine"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task"
    ADD CONSTRAINT "task_fk_0"
    FOREIGN KEY("projectId")
    REFERENCES "project"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task_feedback"
    ADD CONSTRAINT "task_feedback_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task_log_entry"
    ADD CONSTRAINT "task_log_entry_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "task_question"
    ADD CONSTRAINT "task_question_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20260923174747461-project_task_cascade_delete', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260923174747461-project_task_cascade_delete', "timestamp" = now();

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
