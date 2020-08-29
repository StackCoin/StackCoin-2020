CREATE TABLE user (
  id integer PRIMARY KEY,
  created_at timestamp without time zone not null default (now() at time zone 'utc'),
  username text not null,
  avatar_url text not null,
  balance integer not null,
  last_given_dole timestamp without time zone,
  banned boolean default false,
);

CREATE TABLE bot_user {
  id integer PRIMARY KEY,
  user_id text not null references user(id),
  token text not null 
};

CREATE TABLE discord_user {
  id integer PRIMARY KEY,
  user_id text not null references user(id),
  last_updated timestamp without time zone,
  snowflake text not null,
};

CREATE TABLE transaction {
  id integer PRIMARY KEY,
  from_id text not null references user(id),
  from_new_balance integer not null,
  to_id text not null references user(id),
  to_new_balance integer not null,
  time timestamp not null default (now() at time zone 'utc')
};

CREATE TABLE request {
  id integer PRIMARY KEY,
  requester_id text not null references user(id),
  responder_id text not null references user(id),
  status ENUM,
  amount integer not null,
  label text,
  requested_at timestamp not null default (now() at time zone 'utc'),
  resolved_at timestamp
};
