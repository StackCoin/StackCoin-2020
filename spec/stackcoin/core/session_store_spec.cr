require "../../spec_helper"
require "../../../src/stackcoin/core/session_store"
require "../../../src/stackcoin/core/accounts"

require "../../../src/stackcoin/bot/command"
require "../../../src/stackcoin/bot/commands/open"

describe "StackCoin::Core::SessionStore" do
  it "is able to generate a one-time-link that contains the session id at the end of said link" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)

      user_id = Actor::JACK.id(tx)

      result = StackCoin::Core::Accounts.one_time_link(tx, user_id)

      result.should be_a(StackCoin::Core::Accounts::Result::OneTimeLink)
      result = result.as(StackCoin::Core::Accounts::Result::OneTimeLink)

      result.link.should end_with result.session_id
      result.session.one_time_use.should be_true
    end
  end
end
