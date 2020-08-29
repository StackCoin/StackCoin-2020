require "levenshtein"

require "discordcr"

class StackCoin::Bot
end

require "./bot/parser.cr"

class StackCoin::Bot
  abstract class Command
    getter trigger : String
    getter usage : String
    getter desc : String

    def initialize(@trigger, @usage, @desc)
    end

    abstract def invoke(message : Discord::Message, parsed : ParsedCommand)
  end
end

require "./bot/commands/*"

class StackCoin::Bot
  TOKEN     = "Bot #{ENV["STACKCOIN_DISCORD_TOKEN"]}"
  CLIENT_ID = ENV["STACKCOIN_DISCORD_CLIENT_ID"].to_u64
  PREFIX = ENV["STACKCOIN_DISCORD_PREFIX"]

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
        msg(message, "Invalid argument: #{ex.message}")
      rescue ex
        # TODO error logging
        # Log.error { "Exception while invoking discord command: #{ex.inspect_with_backtrace}" }
        msg(message, "```#{ex.inspect_with_backtrace}```")
      end
    end
  end

  def msg(message, content)
    @client.create_message(message.channel_id, content)
  end

  def load_commands
    all_commands = [
      Commands::Leaderboard.new,
      Commands::Send.new,
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
      command.invoke(message, parsed)
    else
      potential = Levenshtein.find(parsed.command, @@lookup.keys)
      if potential
        postfix = ", did you mean `#{potential}`?"
      end

      msg(message, "Unknown command: `#{parsed.command}`#{postfix}")
    end
  end

  def self.run!
    new.client.run
  end
end
