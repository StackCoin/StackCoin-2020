require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"

require "../../../../src/stackcoin/bot/commands/open"

describe "StackCoin::Bot::Commands::Open" do
  it "creates new account" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do
      result = Actor::NINT.say("s!open", open)
      result.should be_a(StackCoin::Core::Bank::Result::NewUserAccount)
    end
  end

  it "fails to create new account if account already exists" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do
      Actor::NINT.say("s!open", open)
      result = Actor::NINT.say("s!open", open)
      result.should be_a(StackCoin::Core::Bank::Result::NewUserAccount)
    end
  end
end
