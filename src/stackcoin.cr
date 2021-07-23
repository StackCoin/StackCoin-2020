require "./stackcoin/config"
require "./stackcoin/db"
require "./stackcoin/core"
require "./stackcoin/bot"

# require "./stackcoin/api"

module StackCoin
  def self.run!
    Dir.mkdir_p("/tmp/stackcoin/")

    run_migrations

    # spawn(Api::External.run!)
    # spawn(Api::Internal.run!)

    spawn(Bot.run!)

    loop do
      sleep 1.day
      # TODO something fun while sleeping
    end
  end
end
