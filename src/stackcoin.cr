require "json_mapping" # TODO remove once deps no longer have usages of JSON.mapping

require "./stackcoin/exceptions"
require "./stackcoin/config"
require "./stackcoin/db.cr"
require "./stackcoin/models"
require "./stackcoin/fixtures"
require "./stackcoin/core"
require "./stackcoin/bot"

module StackCoin
  def self.run!
    run_migrations

    spawn(Bot.run!)

    loop do
      sleep 1.day
      # TODO something fun while sleeping
    end
  end
end
