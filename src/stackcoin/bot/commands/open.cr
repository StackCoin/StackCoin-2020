class StackCoin::Bot::Commands
  class Open < Command
    getter trigger = "open"
    getter aliases = ["create"]
    getter desc = "Create an user account"

    def initialize
    end

    def invoke(message, parsed, tx = nil)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected no arguments, got #{parsed.arguments.size}")
      end

      author = message.author
      result = nil
      DB.transaction do |tx|
        result = Core::Accounts.open(tx, author.id, author.username, author.avatar_url)
      end
      result = result.as(Result::Base)

      send_message(message, result.message)
      result
    end
  end
end
