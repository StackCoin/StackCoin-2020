require "../../../spec_helper"
require "../../../../src/stackcoin/bot/command"
require "../../../../src/stackcoin/core/bank"

require "../../../../src/stackcoin/bot/commands/open"

def id_and_admin_from_discord_snowflake(tx, snowflake)
  id, admin = tx.connection.query_one(<<-SQL, Actor::JACK.user_snowflake.to_s, as: {Int32, Bool})
    SELECT "user".id, "user".admin
      FROM "user"
      JOIN "discord_user" ON "user".id = "discord_user".id
      WHERE "discord_user".snowflake = $1
    SQL
end

describe "StackCoin::Bot::Commands::Open" do
  it "creates new account that isn't an admin" do
    open = StackCoin::Bot::Commands::Open.new
    rollback_once_finished do |tx|
      result = Actor::NINT.say("s!open", open)
      result.should be_a(StackCoin::Core::Bank::Result::NewUserAccount)
      result = result.as(StackCoin::Core::Bank::Result::NewUserAccount)

      id, admin = id_and_admin_from_discord_snowflake(tx, Actor::JACK.user_snowflake)
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

      id, admin = id_and_admin_from_discord_snowflake(tx, Actor::JACK.user_snowflake)
      id.should eq result.new_user_id
      admin.should be_true
    end
  end
end
