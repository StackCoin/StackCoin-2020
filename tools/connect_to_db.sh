#!/usr/bin/env sh
. ./.env
psql "$STACKCOIN_DATABASE_CONNECTION_STRING_BASE"
