BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "code_review" (
    "id" bigserial PRIMARY KEY,
    "taskId" bigint NOT NULL,
    "reviewerAgentId" bigint,
    "status" text NOT NULL DEFAULT 'queued'::text,
    "summary" text,
    "failureReason" text,
    "githubReviewId" bigint,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "review_comment" (
    "id" bigserial PRIMARY KEY,
    "reviewId" bigint NOT NULL,
    "path" text NOT NULL,
    "line" bigint,
    "body" text NOT NULL,
    "severity" text NOT NULL DEFAULT 'issue'::text,
    "state" text NOT NULL DEFAULT 'open'::text,
    "githubCommentId" bigint,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "code_review"
    ADD CONSTRAINT "code_review_fk_0"
    FOREIGN KEY("taskId")
    REFERENCES "task"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "code_review"
    ADD CONSTRAINT "code_review_fk_1"
    FOREIGN KEY("reviewerAgentId")
    REFERENCES "agent"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "review_comment"
    ADD CONSTRAINT "review_comment_fk_0"
    FOREIGN KEY("reviewId")
    REFERENCES "code_review"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261002210947223', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261002210947223', "timestamp" = now();

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
