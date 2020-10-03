require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

require "../../../../src/stackcoin/bot/commands/open"
require "../../../../src/stackcoin/bot/commands/pump"

describe "StackCoin::Bot::Commands::Pump" do
  it "market is pumped" do
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)

      amount = 100
      label = "money in the market fo today"

      result = Actor::JACK.say("s!pump #{amount} \"#{label}\"", pump)

      result.should be_a(StackCoin::Core::StackCoinReserveSystem::Result::Pump)
      result = result.as(StackCoin::Core::StackCoinReserveSystem::Result::Pump)

      result.stackcoin_reserve_system_user_balance.should eq amount

      cnn = tx.connection
      signee_id, to_id, to_new_balance, to_new_balance_label = cnn.query_one(<<-SQL, result.pump_id, as: {Int32, Int32, Int32, String})
        SELECT signee_id, to_id, to_new_balance, label FROM "pump" WHERE id = $1
        SQL

      to_new_balance_label.should eq label
      to_new_balance.should eq amount
    end
  end

  it "market isn't pumped if user account doesn't exist" do
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new

    rollback_once_finished do |tx|
      result = Actor::JACK.say("s!pump 100 money", pump)
      result.should be_a(StackCoin::Core::StackCoinReserveSystem::Result::NoSuchUserAccount)
    end
  end

  it "market isn't pumped if user isn't an admin" do
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new

    rollback_once_finished do |tx|
      Actor::YICK.say("s!open", open)
      result = Actor::YICK.say("s!pump 100 money", pump)
      result.should be_a(StackCoin::Core::StackCoinReserveSystem::Result::NotAuthorized)
    end
  end
end
