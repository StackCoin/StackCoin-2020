class StackCoin::Bot::Commands
  class Unban < Command
    getter trigger = "unban"
    getter aliases = ["pardon"]
    getter desc = "Unban a user"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 1
        raise Parser::Error.new("Expected one arguments, got #{parsed.arguments.size}")
      end

      user_mention = parsed.arguments[0].to_user_mention

      result = nil
      DB.transaction do |tx|
        invokee_id = user_id_from_snowflake(tx, message.author.id)
        user_id = user_id_from_snowflake(tx, Discord::Snowflake.new(user_mention.id))
        result = Core::Banned.unban(tx, invokee_id, user_id)
      end
      result = result.as(Result::Base)

      send_message(message, result.message)

      result
    end
  end
end

