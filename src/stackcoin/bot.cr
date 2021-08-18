require "levenshtein"

require "discordcr"

class StackCoin::Bot
end

require "./bot/parser"
require "./bot/command"
require "./bot/commands/*"

class StackCoin::Bot
  TOKEN           = "Bot #{ENV["STACKCOIN_DISCORD_TOKEN"]}"
  CLIENT_ID       = ENV["STACKCOIN_DISCORD_CLIENT_ID"].to_u64
  OWNER_SNOWFLAKE = Discord::Snowflake.new(ENV["STACKCOIN_DISCORD_OWNER_ID"].to_u64)

  PREFIX = ENV["STACKCOIN_DISCORD_PREFIX"]

  INSTANCE = new

  getter client : Discord::Client
  getter cache : Discord::Cache

  class_getter lookup : Hash(String, Command) = {} of String => Command
  class_getter commands : Hash(String, Command) = {} of String => Command
  getter help_command : Command

  def initialize
    @client = Discord::Client.new(token: TOKEN, client_id: CLIENT_ID)
    @cache = Discord::Cache.new(@client)
    @client.cache = @cache

    all_commands = [
      Commands::Balance.new,
      Commands::Ban.new,
      Commands::Circulation.new,
      Commands::Dole.new,
      Commands::Graph.new,
      Commands::Leaderboard.new,
      # TODO bring back when api is ready
      # Commands::Login.new,
      Commands::Mark.new,
      Commands::Open.new,
      Commands::Profile.new,
      Commands::Pump.new,
      Commands::Reserves.new,
      Commands::Send.new,
      Commands::Transactions.new,
      Commands::Unban.new,
    ]

    @help_command = Commands::Help.new(all_commands)

    all_commands << @help_command

    all_commands.each do |command|
      @@commands[command.trigger] = command
      @@lookup[command.trigger] = command
      command.aliases.each do |command_alias|
        @@lookup[command_alias] = command
      end
    end

    setup_handle_message
  end

  def setup_handle_message
    @client.on_message_create do |message|
      begin
        next if message.author.bot
        handle_message(message)
      rescue ex : Parser::Error
        send_message(message, "Invalid argument(s): #{ex.message}")
      rescue ex
        # TODO error logging
        # Log.error { "Exception while invoking discord command: #{ex.inspect_with_backtrace}" }
        send_message(message, <<-MESSAGE)
          Error: `#{ex.message}`, ping <@#{OWNER_SNOWFLAKE}>
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

  def handle_message(message)
    parsed = Parser.parse(message.content)

    return if parsed.nil?

    valid_check = Core::Group.validate_group_channel(message.guild_id, message.channel_id)
    unless valid_check.is_a?(Core::Group::Result::ValidGroupChannel)
      send_message(message, valid_check.message)
      return
    end

    if parsed.command == ""
      @help_command.invoke(message, parsed)
      return
    end

    if @@lookup.has_key?(parsed.command)
      command = @@lookup[parsed.command]
      begin
        command.invoke(message, parsed)
      rescue ex : Parser::Error
        send_message(message, <<-MESSAGE)
          Invalid argument(s): #{ex.message}
          Usage: `#{PREFIX}#{command.trigger} #{command.usage}`
          MESSAGE
      end
    else
      potential = Levenshtein.find(parsed.command, @@lookup.keys)
      if potential
        postfix = ", did you mean `#{potential}`?"
      end

      send_message(message, "Unknown command: `#{parsed.command}`#{postfix}")
    end
  end

  def self.run!
    INSTANCE.client.run
  end
end
