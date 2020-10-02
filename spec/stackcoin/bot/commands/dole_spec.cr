require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

require "../../../../src/stackcoin/bot/commands/dole"

describe "StackCoin::Bot::Commands::Dole" do
  it "creates new account on first dole but fails due the stackcoin reserve system being empty" do
    dole = StackCoin::Bot::Commands::Dole.new

    rollback_once_finished do |tx|
      results = Actor::STEVE.say("s!dole", dole)

      results.size.should eq 2

      results[0].should be_a(StackCoin::Core::Bank::Result::NewUserAccount)
      results[1].should be_a(StackCoin::Core::StackCoinReserveSystem::Result::EmptyReserves)
    end
  end
end
