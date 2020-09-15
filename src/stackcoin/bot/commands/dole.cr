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
        cnn = tx.connection
        author = message.author

        potential_id = user_id_from_snowflake(cnn, author.id)

        unless potential_id
          create_result = Core::Bank.open(cnn, author.id, author.username, author.avatar_url)

          p create_result
        end

        dole_result = Core::StackCoinReserveSystem.dole(cnn, potential_id)

        p dole_result
      end
    end
  end
end
