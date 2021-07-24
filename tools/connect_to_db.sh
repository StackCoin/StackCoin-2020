#!/usr/bin/env sh

. ./.env
pgcli "$STACKCOIN_DATABASE_CONNECTION_STRING_BASE/stackcoin"
