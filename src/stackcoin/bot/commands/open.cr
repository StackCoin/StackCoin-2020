class StackCoin::Bot::Commands
  class Open < Command
    getter trigger = "open"
    getter aliases = ["create"]
    getter desc = "Create an user account"

    def initialize
    end

    def invoke(message, parsed, tx = nil)
      author = message.author
      result = nil
      DB.transaction do |tx|
        potential_id = user_id_from_snowflake(tx, author.id)
        result = Core::Bank.open(tx, author.id, author.username, author.avatar_url)
      end
      result = result.as(Result::Base)

      send_message(message, result.message)

      result
    end
  end
end
