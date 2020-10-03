require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

require "../../../../src/stackcoin/bot/commands/open"
require "../../../../src/stackcoin/bot/commands/pump"
require "../../../../src/stackcoin/bot/commands/dole"
require "../../../../src/stackcoin/bot/commands/send"

describe "StackCoin::Bot::Commands::Pump" do
  it "send money from one user to another" do
    send = StackCoin::Bot::Commands::Send.new
    dole = StackCoin::Bot::Commands::Dole.new
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::JACK.say("s!pump 100 money", pump)
      Actor::STEVE.say("s!dole", dole)

      amount = 5
      result = Actor::STEVE.say("s!send #{Actor::JACK.mention} #{amount}", send)
      result.should be_a(StackCoin::Core::Bank::Result::SuccessfulTransaction)
      result = result.as(StackCoin::Core::Bank::Result::SuccessfulTransaction)

      cnn = tx.connection
      from_id, from_new_balance, to_id, to_new_balance = cnn.query_one(<<-SQL, result.transaction_id, as: {Int32, Int32, Int32, Int32})
        SELECT from_id, from_new_balance, to_id, to_new_balance FROM "transaction" WHERE id = $1
        SQL

      from_id.should eq Actor::STEVE.id(tx)
      from_new_balance.should eq StackCoin::Core::StackCoinReserveSystem::DOLE_AMOUNT - amount

      to_id.should eq Actor::JACK.id(tx)
      to_new_balance.should eq amount
    end
  end

  it "can't send money from one user to another if from user does not have an account" do
  end

  it "can't send money from one user to another if to user does not have an account" do
  end

  it "can't send money from self to self" do
  end

  it "can't send less than zero" do
  end

  it "can't send more than the upwards limit" do
  end

  it "can't send to a banned user" do
  end

  it "can't send from a banned user" do
  end

  it "can't send if no funds available" do
  end
end
