class StackCoin::Bot::Commands
  class Mark < Command
    getter trigger = "mark"
    getter aliases = [] of String
    getter desc = "Mark a channel as the designated channel for StackCoin"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected no arguments, got #{parsed.arguments.size}")
      end

      guild_id = message.guild_id

      unless guild_id.is_a?(Discord::Snowflake)
        raise Parser::Error.new("Cannot invoke command in DMs")
      end

      result = nil
      DB.transaction do |tx|
        cnn = tx.connection
        invokee_id = user_id_from_snowflake(cnn, message.author.id)
        result = Core::Group.set_group_channel(tx, invokee_id, guild_id, message.channel_id)
      end
      result = result.as(Result::Base)

      send_message(message, result.message)

      result
    end
  end
end
