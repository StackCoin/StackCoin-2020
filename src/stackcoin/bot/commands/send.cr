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
        cnn = tx.connection
        from_id = user_id_from_snowflake(cnn, message.author.id)
        to_id = user_id_from_snowflake(cnn, Discord::Snowflake.new(user_mention.id))
        result = Core::Bank.transfer(cnn, from_id, to_id, amount)
      end

      if result.is_a?(Core::Bank::Result::SuccessfulTransaction)
        # TODO embed and such
        send_message(message, result.message)
      elsif result.is_a?(Result::Base)
        send_message(message, result.message)
      else
        p result
        raise Exceptions::UnexpectedState.new("Result was an unexpected value: #{result}")
      end
    end
  end
end
