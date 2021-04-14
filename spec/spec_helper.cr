require "spec"

require "pg"
require "micrate"
require "dotenv"
require "discordcr"

begin
  Dotenv.load
end

class MockBot
  def client
    MockClient::INSTANCE
  end

  def cache
    MockCache::INSTANCE
  end
end

class StackCoin::Bot
  OWNER_SNOWFLAKE = Discord::Snowflake.new(178958252820791296)
  INSTANCE        = MockBot.new
end

CSBOIS_GUILD_SNOWFLAKE = Discord::Snowflake.new(497544520695808000)
JKE_GUILD_SNOWFLAKE    = Discord::Snowflake.new(72070136256794624)

require "./stubs"
require "./fixtures"
require "../src/stackcoin/config"
require "../src/stackcoin/result"
require "../src/stackcoin/bot/parser"

PREFIX = "s!"

POSTGRES_DB                     = "#{ENV["POSTGRES_DB"]}_test"
DATABASE_CONNECTION_STRING_BASE = ENV["STACKCOIN_DATABASE_CONNECTION_STRING_BASE"]
DATABASE_CONNECTION_STRING      = "#{DATABASE_CONNECTION_STRING_BASE}/#{POSTGRES_DB}"

db = PG.connect(DATABASE_CONNECTION_STRING_BASE)

db.exec(<<-SQL)
  SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE datname = '#{POSTGRES_DB}'
    AND pid <> pg_backend_pid();
SQL

db.exec("DROP DATABASE IF EXISTS #{POSTGRES_DB}")
db.exec("CREATE DATABASE #{POSTGRES_DB}")

db.close

class WrappedDB
  INNER = PG.connect(DATABASE_CONNECTION_STRING)
  delegate exec, to: INNER
  delegate query_all, to: INNER
  delegate query_one, to: INNER
  delegate scalar, to: INNER

  property existing_tx : DB::Transaction?

  def transaction
    if previous_tx = existing_tx
      begin
        previous_tx.transaction do |tx|
          @existing_tx = tx
          yield tx
        end
      ensure
        @existing_tx = previous_tx
      end
    else
      begin
        INNER.transaction do |tx|
          @existing_tx = tx
          yield tx
        end
      ensure
        @existing_tx = nil
      end
    end
  end
end

StackCoin::DB = WrappedDB.new

def rollback_once_finished
  StackCoin::DB.transaction do |tx|
    yield tx
    tx.rollback
  end
end

Micrate::DB.connection_url = DATABASE_CONNECTION_STRING
Micrate.up(StackCoin::DB)
