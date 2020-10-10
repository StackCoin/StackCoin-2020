class StackCoin::Bot::Commands
  class Ban < Command
    getter trigger = "ban"
    getter aliases = ["frigoff"]
    getter usage = "<@user>"
    getter desc = "Ban users"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 1
        raise Parser::Error.new("Expected one arguments, got #{parsed.arguments.size}")
      end

      user_mention = parsed.arguments[0].to_user_mention

      result = nil
      DB.transaction do |tx|
        cnn = tx.connection
        invokee_id = user_id_from_snowflake(cnn, message.author.id)
        user_id = user_id_from_snowflake(cnn, Discord::Snowflake.new(user_mention.id))
        result = Core::Banned.ban(tx, invokee_id, user_id)
      end
      result = result.as(Result::Base)

      send_message(message, result.message)

      result
    end
  end
end
