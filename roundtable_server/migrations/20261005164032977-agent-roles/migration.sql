BEGIN;

--
-- ACTION ALTER TABLE
--
--
-- ACTION CREATE TABLE
--
CREATE TABLE "agent_role" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "prompt" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX "agent_role_name_idx" ON "agent_role" USING btree ("name");

--
-- Data: the fixed AgentRole enum becomes editable roles. Seed them with the
-- prompts the runner had hard-coded and point each agent at its old role
-- before the enum column goes.
--
INSERT INTO "agent_role" ("name", "description", "prompt") VALUES
    ('frontend', 'UI, components, styling and client-side logic',
     'You are {name}, the frontend specialist on this team. Focus on UI, components, styling and client-side logic.'),
    ('backend', 'API design, data models and server-side logic',
     'You are {name}, the backend specialist. Focus on API design, data models and server-side logic.'),
    ('devops', 'Deployment, CI/CD and infrastructure',
     'You are {name}, the DevOps specialist. Focus on deployment, CI/CD and infrastructure configuration.'),
    ('fullstack', 'Works across the whole stack',
     'You are {name}, a fullstack generalist on this team.'),
    ('generalist', 'Any kind of task',
     'You are {name}, a generalist engineer on this team.');
ALTER TABLE "agent" ADD COLUMN "roleId" bigint;
UPDATE "agent" SET "roleId" = r."id"
    FROM "agent_role" r
    WHERE r."name" = "agent"."role";
ALTER TABLE "agent" DROP COLUMN "role";

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "agent"
    ADD CONSTRAINT "agent_fk_1"
    FOREIGN KEY("roleId")
    REFERENCES "agent_role"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261005164032977-agent-roles', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261005164032977-agent-roles', "timestamp" = now();

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
