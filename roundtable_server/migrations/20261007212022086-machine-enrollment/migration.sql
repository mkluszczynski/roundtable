BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "machine_enrollment" (
    "id" bigserial PRIMARY KEY,
    "tokenHash" text NOT NULL,
    "name" text,
    "expiresAt" timestamp without time zone NOT NULL,
    "machineId" bigint
);

-- Indexes
CREATE UNIQUE INDEX "machine_enrollment_token_idx" ON "machine_enrollment" USING btree ("tokenHash");


--
-- MIGRATION VERSION FOR roundtable
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('roundtable', '20261007212022086-machine-enrollment', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261007212022086-machine-enrollment', "timestamp" = now();

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
