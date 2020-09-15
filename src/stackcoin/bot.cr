require "levenshtein"

require "discordcr"

class StackCoin::Bot
end

require "./bot/parser.cr"

class StackCoin::Bot
  abstract class Command
    getter trigger : String
    getter aliases : Array(String)
    getter usage : String?
    getter desc : String

    class Result < StackCoin::Result
      class FailureWithMessage < Failure
        def initialize(tx, client, payload, message)
          client.create_message(payload.channel_id, message)
          super(tx, message)
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
      INSTANCE.client
    end

    def send_message(message, content)
      client.create_message(message.channel_id, content)
    end

    def cache
      INSTANCE.cache
    end
  end
end

require "./bot/commands/*"

class StackCoin::Bot
  TOKEN     = "Bot #{ENV["STACKCOIN_DISCORD_TOKEN"]}"
  CLIENT_ID = ENV["STACKCOIN_DISCORD_CLIENT_ID"].to_u64
  OWNER_SNOWFLAKE = Discord::Snowflake.new(ENV["STACKCOIN_DISCORD_OWNER_ID"].to_u64)

  PREFIX    = ENV["STACKCOIN_DISCORD_PREFIX"]

  INSTANCE = new

  getter client : Discord::Client
  getter cache : Discord::Cache

  class_getter lookup : Hash(String, Command) = {} of String => Command
  class_getter commands : Hash(String, Command) = {} of String => Command

  def initialize
    @client = Discord::Client.new(token: TOKEN, client_id: CLIENT_ID)
    @cache = Discord::Cache.new(@client)
    @client.cache = @cache

    load_commands

    @client.on_message_create do |message|
      begin
        next if message.guild_id.is_a?(Nil) || message.author.bot
        handle_message(message)
      rescue ex : Parser::Error
        send_message(message, "_Invalid argument(s)_: #{ex.message}")
      rescue ex
        # TODO error logging
        # Log.error { "Exception while invoking discord command: #{ex.inspect_with_backtrace}" }
        send_message(message, <<-MESSAGE)
          `Error: #{ex.message}`
          ```
          #{ex.inspect_with_backtrace}
          ```
          MESSAGE
      end
    end
  end

  def send_message(message, content)
    @client.create_message(message.channel_id, content)
  end

  def load_commands
    all_commands = [
      Commands::Dole.new,
      Commands::Leaderboard.new,
      Commands::Send.new,
      Commands::Pump.new,
      Commands::Open.new,
    ]

    all_commands.each do |command|
      @@commands[command.trigger] = command
      @@lookup[command.trigger] = command
      command.aliases.each do |command_alias|
        @@lookup[command_alias] = command
      end
    end
  end

  def handle_message(message)
    parsed = Parser.parse(message.content)

    return if parsed.nil?

    if parsed.command == ""
      # TODO show help
      return
    end

    if @@lookup.has_key?(parsed.command)
      command = @@lookup[parsed.command]
      begin
        command.invoke(message, parsed)
      rescue ex : Parser::Error
        send_message(message, <<-MESSAGE)
          _Invalid argument(s)_: #{ex.message}
          _Usage_: `#{PREFIX}#{command.trigger} #{command.usage}`
          MESSAGE
      end
    else
      potential = Levenshtein.find(parsed.command, @@lookup.keys)
      if potential
        postfix = ", did you mean `#{potential}`?"
      end

      send_message(message, "_Unknown command_: `#{parsed.command}`#{postfix}")
    end
  end

  def self.run!
    INSTANCE.client.run
  end
end
