BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "agent_machine_idx" ON "agent" USING btree ("machineId");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "code_review_task_created_idx" ON "code_review" USING btree ("taskId", "createdAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "review_comment_review_idx" ON "review_comment" USING btree ("reviewId");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "task_project_idx" ON "task" USING btree ("projectId");
CREATE INDEX "task_agent_idx" ON "task" USING btree ("agentId");
CREATE INDEX "task_status_progress_idx" ON "task" USING btree ("status", "lastProgressAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "task_feedback_task_created_idx" ON "task_feedback" USING btree ("taskId", "createdAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "task_log_entry_task_created_idx" ON "task_log_entry" USING btree ("taskId", "createdAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "task_question_task_created_idx" ON "task_question" USING btree ("taskId", "createdAt");

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261003224602697-hot-path-indexes', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261003224602697-hot-path-indexes', "timestamp" = now();

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
