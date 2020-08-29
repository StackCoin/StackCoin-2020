require "json_mapping" # TODO remove once deps no longer have usages of JSON.mapping

require "./stackcoin/bot"

module StackCoin
  EPOCH = Time.unix(1574467200)

  def self.run!
    spawn(Bot.run!)

    loop do
      sleep 1.day
      # TODO something fun while sleeping
    end
  end
end
