require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/banned"

require "../../../../src/stackcoin/bot/commands/ban"
require "../../../../src/stackcoin/bot/commands/open"

describe "StackCoin::Bot::Commands::Ban" do
  it "user is banned" do
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::NINT.say("s!open", open)

      result = Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      result.should be_a(StackCoin::Core::Banned::Result::UserBanned)

      is_banned = StackCoin::Core::Banned.is_banned(tx, Actor::NINT.id(tx))
      is_banned.should be_true
    end
  end

  it "user cannot be banned twice, but should remain banned" do
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::NINT.say("s!open", open)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)

      result = Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      result.should be_a(StackCoin::Core::Banned::Result::AlreadyBanned)

      is_banned = StackCoin::Core::Banned.is_banned(tx, Actor::NINT.id(tx))
      is_banned.should be_true
    end
  end

  it "user without account cannot be banned" do
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      result = Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      result.should be_a(StackCoin::Core::Banned::Result::NoSuchUserAccount)
    end
  end

  it "user without account cannot ban" do
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::NINT.say("s!open", open)
      Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      result = Actor::JACK.say("s!ban #{Actor::NINT.mention}", ban)
      result.should be_a(StackCoin::Core::Banned::Result::NoSuchUserAccount)
    end
  end

  it "user who isn't admin can't ban others" do
    ban = StackCoin::Bot::Commands::Ban.new
    open = StackCoin::Bot::Commands::Open.new

    rollback_once_finished do |tx|
      Actor::JACK.say("s!open", open)
      Actor::NINT.say("s!open", open)
      result = Actor::NINT.say("s!ban #{Actor::JACK.mention}", ban)
      result.should be_a(StackCoin::Core::Banned::Result::NotAuthorized)
    end
  end
end
