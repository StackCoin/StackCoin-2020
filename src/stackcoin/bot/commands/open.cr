class StackCoin::Bot::Commands
  class Open < Command
    getter trigger = "open"
    getter aliases = ["create"]
    getter desc = "Create an user account"

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
        if potential_id
          return Result::PreExistingUserAccount.new(tx, client, message, "You already have an user account associated with your Discord account")
        end

        result = Core::Bank.open(cnn, author.id, author.username, author.avatar_url)
      end

      if result.is_a?(Result::Base)
        send_message(message, result.message)
      else
        raise Exceptions::UnexpectedState.new("Result was an unexpected value: #{result}")
      end

      result
    end
  end
end
