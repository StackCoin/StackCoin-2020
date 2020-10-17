require "../../spec_helper"
require "../../../src/stackcoin/core/session_store"
require "../../../src/stackcoin/core/accounts"

require "../../../src/stackcoin/bot/command"
require "../../../src/stackcoin/bot/commands/open"

describe "StackCoin::Core::SessionStore" do
  it "is able to generate a one-time-link" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)

      user_id = Actor::JACK.id(tx)
      valid_for = StackCoin::Core::SessionStore::TINY_SESSION_LENGTH
      id, session = StackCoin::Core::SessionStore.create(user_id, valid_for, one_time_use: true)
      link = StackCoin::Core::SessionStore::Session.one_time_link(id)

      link.should end_with id
    end
  end
end
