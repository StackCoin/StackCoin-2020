require "json_mapping" # TODO remove once deps no longer have usages of JSON.mapping

require "pg"
require "micrate"

module StackCoin
  EPOCH                      = Time.unix(1574467200)
  POSTGRES_DB                = ENV["POSTGRES_DB"]
  DATABASE_CONNECTION_STRING_BASE = ENV["STACKCOIN_DATABASE_CONNECTION_STRING_BASE"]
  DATABASE_CONNECTION_STRING = "#{DATABASE_CONNECTION_STRING_BASE}/#{POSTGRES_DB}"
  DB                         = PG.connect(DATABASE_CONNECTION_STRING)
end

# require "./stackcoin/core"
require "./stackcoin/models"
require "./stackcoin/fixtures"
require "./stackcoin/bot"

module StackCoin
  def self.run_migrations
    Micrate::DB.connection_url = DATABASE_CONNECTION_STRING
    Micrate.up(DB)
  end

  def self.run!
    run_migrations

    spawn(Bot.run!)

    loop do
      sleep 1.day
      # TODO something fun while sleeping
    end
  end
end
