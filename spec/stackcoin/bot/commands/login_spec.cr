require "../../../spec_helper"
require "../../../../src/stackcoin/core/session_store"
require "../../../../src/stackcoin/core/accounts"

require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/bot/commands/open"
require "../../../../src/stackcoin/bot/commands/login"

describe "StackCoin::Bot::Commands::Login" do
  it "is able to generate a one-time-link that contains the session id at the end of said link" do
    open = StackCoin::Bot::Commands::Open.new
    login = StackCoin::Bot::Commands::Login.new
    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      result = Actor::JACK.say("s!login", login)

      user_id = Actor::JACK.id(tx)

      result.should be_a(StackCoin::Core::Accounts::Result::OneTimeLink)
      result = result.as(StackCoin::Core::Accounts::Result::OneTimeLink)

      result.link.should end_with result.session_id
      result.session.one_time_use.should be_true
    end
  end

  it "cant generate a one-time-link if the user doesn't have an account" do
    login = StackCoin::Bot::Commands::Login.new
    rollback_once_finished do |tx|
      result = Actor::JACK.say("s!login", login)
      result.should be_a(StackCoin::Core::Accounts::Result::NoSuchUserAccount)
    end
  end
end
