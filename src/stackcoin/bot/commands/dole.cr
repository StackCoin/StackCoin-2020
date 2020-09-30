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

        potential_id = user_id_from_snowflake(cnn, author.id)

        if !potential_id
          create_result = Core::Bank.open(cnn, author.id, author.username, author.avatar_url)

          # TODO handle create result
        end

        result = Core::StackCoinReserveSystem.dole(cnn, potential_id)

        # TODO merge results into one message
      end

      result
    end
  end
end
