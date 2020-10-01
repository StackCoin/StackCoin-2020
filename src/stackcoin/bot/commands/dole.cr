class StackCoin::Bot::Commands
  class Dole < Command
    getter trigger = "dole"
    getter aliases = [] of String
    getter desc = "Collect some funds from the StackCoin Reserve System"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected zero arguments, got #{parsed.arguments.size}")
      end

      result = nil
      DB.transaction do |tx|
        author = message.author

        potential_id = user_id_from_snowflake(tx, author.id)

        if !potential_id
          create_result = Core::Bank.open(tx, author.id, author.username, author.avatar_url)
          send_message(message, create_result.message)
        end

        result = Core::StackCoinReserveSystem.dole(tx, potential_id)
        send_message(message, result.message)
      end

      result
    end
  end
end
