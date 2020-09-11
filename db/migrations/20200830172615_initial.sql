-- +micrate Up
BEGIN;

CREATE TYPE user_type AS ENUM ('Internal', 'Bot', 'Discord');

CREATE TABLE "user" (
  "id" serial PRIMARY KEY,
  "created_at" timestamp without time zone not null,
  "type" user_type not null,
  "username" text not null,
  "avatar_url" text not null,
  "balance" integer not null CHECK ("balance" >= 0),
  "last_given_dole" timestamp without time zone,
  "admin" boolean not null,
  "banned" boolean not null
);

CREATE TABLE "internal_user" (
  "id" integer PRIMARY KEY references "user"(id),
  "identifier" text not null UNIQUE
);

CREATE TABLE "bot_user" (
  "id" integer PRIMARY KEY references "user"(id),
  "token" text not null UNIQUE
);

CREATE TABLE "discord_user" (
  "id" integer PRIMARY KEY references "user"(id),
  "last_updated" timestamp without time zone not null,
  "snowflake" text not null UNIQUE
);

CREATE TABLE "transaction" (
  "id" serial PRIMARY KEY,
  "from_id" integer not null references "user"(id),
  "from_new_balance" integer not null CHECK ("from_new_balance" >= 0),
  "to_id" integer not null references "user"(id),
  "to_new_balance" integer not null CHECK ("to_new_balance" >= 0),
  time timestamp not null,
  "label" text,
  CHECK ("from_id" <> "to_id")
);

CREATE TABLE "pump" (
  "id" serial PRIMARY KEY,
  "signee_id" integer not null references "user"(id),
  "to_id" integer not null references "internal_user"(id),
  "to_new_balance" integer not null CHECK ("to_new_balance" >= 0),
  time timestamp not null,
  "label" text not null,
  CHECK ("signee_id" <> "to_id")
);

CREATE TYPE request_status AS ENUM ('Pending', 'Accepted', 'Denied');

CREATE TABLE "request" (
  "id" serial PRIMARY KEY,
  "requester_id" integer not null references "user"(id),
  "responder_id" integer not null references "user"(id),
  "status" request_status not null,
  "amount" integer not null CHECK ("amount" > 0),
  "requested_at" timestamp not null,
  "transaction" integer references "transaction"(id),
  "resolved_at" timestamp,
  "label" text
);

WITH stackcoin_reserve_system_user AS (
  INSERT INTO "user"
    (
      created_at,
      type,
      username,
      avatar_url,
      balance,
      last_given_dole,
      admin,
      banned
    )
  VALUES
    (
      now() at time zone 'utc',
      'Internal',
      'StackCoin Reserve System',
      'https://stackcoin.world/assets/default_avatar.png',
      0,
      null,
      false,
      false
    )
  RETURNING id, username
)
INSERT INTO "internal_user" SELECT id, username AS identifier FROM stackcoin_reserve_system_user;

COMMIT;

-- +micrate Down

BEGIN;

DROP TABLE "request";

DROP TABLE "transaction";

DROP TABLE "pump";

DROP TYPE request_status;

DROP TABLE "bot_user";

DROP TABLE "discord_user";

DROP TABLE "internal_user";

DROP TABLE "user";

DROP TYPE user_type;

COMMIT;
