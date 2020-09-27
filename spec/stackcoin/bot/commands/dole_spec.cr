require "spec"

require "dotenv"

begin
  Dotenv.load
end

require "pg"
require "micrate"

require "json_mapping" # TODO remove once deps no longer have usages of JSON.mapping
require "discordcr"

class StackCoin::Bot
  OWNER_SNOWFLAKE = Discord::Snowflake.new(0)
end

require "../../../../src/stackcoin/bot/parser"

PREFIX = "s!"

record MessageAuthor, id : Discord::Snowflake, username : String, avatar_url : String do
  def self.new(id, username, avatar_url = "http://nop")
    id = Discord::Snowflake.new(id.to_u64)
    new(id, username)
  end
end

record MessageStub, channel_id : Discord::Snowflake, guild_id : Discord::Snowflake, content : String, author : MessageAuthor do
  def self.new(channel_id, guild_id, content)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    author = MessageAuthor.new(1, "johndoe")
    new(channel_id, guild_id, content, author)
  end

  def self.new(channel_id, guild_id, content, author)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    new(channel_id, guild_id, content, author)
  end
end

record MessageWithEmbedStub, channel_id : Discord::Snowflake, guild_id : Discord::Snowflake, content : String, author : MessageAuthor, embed : Discord::Embed do
  def self.new(channel_id, guild_id, content, embed)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    author = MessageAuthor.new(1, "johndoe")
    new(channel_id, guild_id, content, author, embed)
  end

  def self.new(channel_id, guild_id, content, author, embed)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    new(channel_id, guild_id, content, author, embed)
  end
end

class MockClient
  def create_message(channel_id : Discord::Snowflake, content : String)
    MessageStub.new(channel_id, 1, content)
  end

  def create_message(channel_id : Discord::Snowflake, content : String, embed : Discord::Embed)
    MessageWithEmbedStub.new(channel_id, 1, content, embed)
  end
end

POSTGRES_DB                     = "#{ENV["POSTGRES_DB"]}_test"
DATABASE_CONNECTION_STRING_BASE = ENV["STACKCOIN_DATABASE_CONNECTION_STRING_BASE"]
DATABASE_CONNECTION_STRING      = "#{DATABASE_CONNECTION_STRING_BASE}/#{POSTGRES_DB}"

StackCoin::DB = PG.connect(DATABASE_CONNECTION_STRING)

StackCoin::DB.exec("DROP DATABASE #{POSTGRES_DB}")
StackCoin::DB.exec("CREATE DATABASE #{POSTGRES_DB}")

Micrate::DB.connection_url = DATABASE_CONNECTION_STRING
Micrate.up(StackCoin::DB)

abstract class Command
  getter trigger : String
  getter aliases : Array(String)
  getter usage : String?
  getter desc : String

  class Result
    class FailureWithMessage
      def initialize(tx, client, payload, message)
      end
    end

    class PreExistingUserAccount < FailureWithMessage
    end
  end

  def initialize(@trigger, @aliases, @usage, @desc)
  end

  abstract def invoke(message : Discord::Message, parsed : ParsedCommand)

  def user_id_from_snowflake(cnn : ::DB::Connection, snowflake : Discord::Snowflake)
    cnn.query_one?(<<-SQL, snowflake.to_u64, as: Int32)
      SELECT id FROM discord_user WHERE snowflake = $1
      SQL
  end

  def client
    nil
  end

  def send_message(message, content)
    client.create_message(message.channel_id, content)
  end

  def cache
    nil
  end
end

require "../../../../src/stackcoin/bot/commands/dole"
require "../../../../src/stackcoin/core/bank"
require "../../../../src/stackcoin/core/stackcoin_reserve_system"

describe "StackCoin::Bot::Commands::Dole" do
  it "fails on non-existant user" do
    dole = StackCoin::Bot::Commands::Dole.new
    parsed = StackCoin::Bot::Parser.parse("s!dole").not_nil!
    message = MessageStub.new(1, 1, "s!dole")
    dole.invoke(message, parsed)
  end
end
