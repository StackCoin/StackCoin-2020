require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/banned"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

require "../../../../src/stackcoin/bot/commands/send"
require "../../../../src/stackcoin/bot/commands/open"
require "../../../../src/stackcoin/bot/commands/dole"
require "../../../../src/stackcoin/bot/commands/pump"
require "../../../../src/stackcoin/bot/commands/ban"

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
    send = StackCoin::Bot::Commands::Send.new

    rollback_once_finished do |tx|
      result = Actor::YICK.say("s!send #{Actor::JACK.mention} 10", send)
      result.should be_a(StackCoin::Core::Bank::Result::NoSuchUserAccount)
    end
  end

  it "can't send money from one user to another if to user does not have an account" do
    send = StackCoin::Bot::Commands::Send.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::YICK.say("s!open", open)
      result = Actor::YICK.say("s!send #{Actor::JACK.mention} 10", send)
      result.should be_a(StackCoin::Core::Bank::Result::NoSuchUserAccount)
    end
  end

  it "can't send money from self to self" do
    send = StackCoin::Bot::Commands::Send.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::MITCH.say("s!open", open)
      result = Actor::MITCH.say("s!send #{Actor::MITCH.mention} 10", send)
      result.should be_a(StackCoin::Core::Bank::Result::TransferSelf)
    end
  end

  it "can't send less than zero" do
    send = StackCoin::Bot::Commands::Send.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::BIGMAN.say("s!open", open)
      Actor::YICK.say("s!open", open)
      result = Actor::BIGMAN.say("s!send #{Actor::YICK.mention} -420", send)
      result.should be_a(StackCoin::Core::Bank::Result::InvalidAmount)
    end
  end

  it "can't send more than the upwards limit" do
    send = StackCoin::Bot::Commands::Send.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::BIGMAN.say("s!open", open)
      Actor::YICK.say("s!open", open)
      result = Actor::BIGMAN.say("s!send #{Actor::YICK.mention} #{StackCoin::Core::Bank::MAX_TRANSFER_AMOUNT + 1}", send)
      result.should be_a(StackCoin::Core::Bank::Result::InvalidAmount)
    end
  end

  it "can't send to a banned user" do
    send = StackCoin::Bot::Commands::Send.new
    dole = StackCoin::Bot::Commands::Dole.new
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new
    ban = StackCoin::Bot::Commands::Ban.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::JACK.say("s!pump 100 money", pump)
      Actor::NINT.say("s!dole", dole)
      Actor::JACK.say("s!dole", dole)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)

      result = Actor::JACK.say("s!send #{Actor::NINT.mention} 10", send)
      result.should be_a(StackCoin::Core::Bank::Result::BannedUser)
    end
  end

  it "can't send from a banned user" do
    send = StackCoin::Bot::Commands::Send.new
    dole = StackCoin::Bot::Commands::Dole.new
    open = StackCoin::Bot::Commands::Open.new
    pump = StackCoin::Bot::Commands::Pump.new
    ban = StackCoin::Bot::Commands::Ban.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::JACK.say("s!pump 100 money", pump)
      Actor::NINT.say("s!dole", dole)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)

      result = Actor::NINT.say("s!send #{Actor::JACK.mention} 10", send)
      result.should be_a(StackCoin::Core::Bank::Result::BannedUser)
    end
  end

  it "can't send if no funds available" do
    send = StackCoin::Bot::Commands::Send.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::BIGMAN.say("s!open", open)
      Actor::YICK.say("s!open", open)
      result = Actor::BIGMAN.say("s!send #{Actor::YICK.mention} #{StackCoin::Core::Bank::MAX_TRANSFER_AMOUNT}", send)
      result.should be_a(StackCoin::Core::Bank::Result::InsufficentFunds)
    end
  end
end
