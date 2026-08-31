\set token random(1,2147483647)
BEGIN;
SET LOCAL ROLE titan_load_tester;
INSERT INTO titan_ops.operational_load_probe(worker_token,payload_hash)
VALUES (:token,md5(:token::text || clock_timestamp()::text || random()::text));
COMMIT;
