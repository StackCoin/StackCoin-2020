class StackCoin::Bot::Commands
  class Dole < Command
    getter trigger = "dole"
    getter aliases = ["d"]
    getter desc = "Collect some funds from the StackCoin Reserve System"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected zero arguments, got #{parsed.arguments.size}")
      end

      results = [] of Result::Base

      DB.transaction do |tx|
        author = message.author

        potential_id = user_id_from_snowflake(tx, author.id)

        if !potential_id
          result = Core::Bank.open(tx, author.id, author.username, author.avatar_url)
          results << result

          if result.is_a?(Core::Bank::Result::NewUserAccount)
            potential_id = result.new_user_id
          else
            next
          end
        end

        results << Core::StackCoinReserveSystem.dole(tx, potential_id)
      end

      send_message(message, results.join("\n") { |result| result.message })

      results
    end
  end
end
