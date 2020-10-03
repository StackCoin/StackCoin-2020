require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"

require "../../../../src/stackcoin/bot/commands/open"

describe "StackCoin::Bot::Commands::Open" do
  it "creates new account that isn't an admin" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do |tx|
      result = Actor::NINT.say("s!open", open)
      result.should be_a(StackCoin::Core::Bank::Result::NewUserAccount)
      result = result.as(StackCoin::Core::Bank::Result::NewUserAccount)

      id = Actor::NINT.id(tx)
      admin = Actor::NINT.admin(tx)

      id.should eq result.new_user_id
      admin.should be_false
    end
  end

  it "fails to create new account if account already exists" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do |tx|
      initial_result = Actor::NINT.say("s!open", open)
      initial_result = initial_result.as(StackCoin::Core::Bank::Result::NewUserAccount)

      result = Actor::NINT.say("s!open", open)
      result.should be_a(StackCoin::Core::Bank::Result::PreExistingUserAccount)
    end
  end

  it "creates bot owners account as admin on initial creation" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do |tx|
      result = Actor::JACK.say("s!open", open)

      result.should be_a(StackCoin::Core::Bank::Result::NewUserAccount)
      result = result.as(StackCoin::Core::Bank::Result::NewUserAccount)

      id = Actor::JACK.id(tx)
      admin = Actor::JACK.admin(tx)

      id.should eq result.new_user_id
      admin.should be_true
    end
  end
end
