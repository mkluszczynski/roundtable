BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "agent" DROP CONSTRAINT IF EXISTS "agent_fk_0";
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "agent"
    ADD CONSTRAINT "agent_fk_0"
    FOREIGN KEY("machineId")
    REFERENCES "machine"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20260923174159145-agent_machine_cascade_delete', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260923174159145-agent_machine_cascade_delete', "timestamp" = now();

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
