class StackCoin::Bot::Commands
  class Send < Command
    getter trigger = "send"
    getter aliases = ["transfer"]
    getter usage = "<@user> <#amount>"
    getter desc = "Send your STK to others"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 2
        raise Parser::Error.new("Expected two arguments, got #{parsed.arguments.size}")
      end

      user_mention = parsed.arguments[0].to_user_mention
      amount = parsed.arguments[1].to_i

      result = nil
      DB.transaction do |tx|
        from_id = user_id_from_snowflake(tx, message.author.id)
        to_id = user_id_from_snowflake(tx, Discord::Snowflake.new(user_mention.id))
        result = Core::Bank.transfer(tx, from_id, to_id, amount)
      end
      result = result.as(Result::Base)

      if result.is_a?(Core::Bank::Result::SuccessfulTransaction)
        send_message(message, result.message)
      else
        send_message(message, result.message)
      end

      result
    end
  end
end
