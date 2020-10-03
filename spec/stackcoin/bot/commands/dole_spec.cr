require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

require "../../../../src/stackcoin/bot/commands/dole"
require "../../../../src/stackcoin/bot/commands/open"
require "../../../../src/stackcoin/bot/commands/pump"

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

  it "gives out dole when dole is available" do
    dole = StackCoin::Bot::Commands::Dole.new
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::JACK.say("s!pump 100 money", pump)

      results = Actor::STEVE.say("s!dole", dole)
    end
  end
end
