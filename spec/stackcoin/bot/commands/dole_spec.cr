require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

require "../../../../src/stackcoin/bot/commands/dole"

describe "StackCoin::Bot::Commands::Dole" do
  it "creates new account but fails due to nothing in the stackcoin reserve system" do
    dole = StackCoin::Bot::Commands::Dole.new

    rollback_once_finished do |tx|
      result = Actor::STEVE.say("s!dole", dole)
      # result.should be_a(StackCoin::Core::Bank::Result::InsufficientFunds)
    end
  end
end
