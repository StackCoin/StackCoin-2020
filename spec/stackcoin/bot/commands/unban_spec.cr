require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/banned"

require "../../../../src/stackcoin/bot/commands/unban"
require "../../../../src/stackcoin/bot/commands/ban"
require "../../../../src/stackcoin/bot/commands/open"

describe "StackCoin::Bot::Commands::Unban" do
  it "user is unbanned" do
    unban = StackCoin::Bot::Commands::Unban.new
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::NINT.say("s!open", open)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)

      result = Actor::JACK.say("s!unban #{Actor::NINT.mention}", unban)
      result.should be_a(StackCoin::Core::Banned::Result::UserUnbanned)

      is_banned = StackCoin::Core::Banned.is_banned(tx, Actor::NINT.id(tx))
      is_banned.should be_false
    end
  end

  it "user cannot be unbanned twice, but should remain unbanned" do
    unban = StackCoin::Bot::Commands::Unban.new
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::NINT.say("s!open", open)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      Actor::JACK.say("s!unban #{Actor::NINT.mention}", unban)

      result = Actor::JACK.say("s!unban #{Actor::NINT.mention}", unban)
      result.should be_a(StackCoin::Core::Banned::Result::AlreadyUnbanned)

      is_banned = StackCoin::Core::Banned.is_banned(tx, Actor::NINT.id(tx))
      is_banned.should be_false
    end
  end

  it "user without account cannot be unbanned" do
    unban = StackCoin::Bot::Commands::Unban.new
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      result = Actor::JACK.say("s!unban #{Actor::NINT.mention}", unban)
      result.should be_a(StackCoin::Core::Banned::Result::NoSuchUserAccount)
    end
  end

  it "user without account cannot unban" do
    unban = StackCoin::Bot::Commands::Unban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::NINT.say("s!open", open)
      result = Actor::JACK.say("s!unban #{Actor::NINT.mention}", unban)
      result.should be_a(StackCoin::Core::Banned::Result::NoSuchUserAccount)
    end
  end

  it "user who isn't admin can't unban others" do
    unban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::NINT.say("s!open", open)
      result = Actor::NINT.say("s!unban #{Actor::JACK.mention}", unban)
      result.should be_a(StackCoin::Core::Banned::Result::NotAuthorized)
    end
  end
end
