class StackCoin::Bot::Commands
  class Pump < Command
    getter trigger = "pump"
    getter aliases = [] of String
    getter usage = "<#amount> <\"label\">"
    getter desc = "Pump the Stackcoin Reserve System"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 2
        raise Parser::Error.new("Expected two arguments, got #{parsed.arguments.size}")
      end

      amount = parsed.arguments[0].to_i
      label = parsed.arguments[1].to_s

      author = message.author
      result = nil
      DB.transaction do |tx|
        cnn = tx.connection
        potential_id = user_id_from_snowflake(cnn, author.id)
        result = Core::StackCoinReserveSystem.pump(tx, potential_id, amount, label)
      end
      result = result.as(Result::Base)

      send_message(message, result.message)
      result
    end
  end
end
