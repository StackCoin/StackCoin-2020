class StackCoin::Bot::Commands
  class Balance < Command
    getter trigger = "balance"
    getter aliases = ["bal"]
    getter desc = "Check yours or another users balance"

    def initialize
    end

    def invoke(message, parsed, tx = nil)
      unless parsed.arguments.size <= 1
        raise Parser::Error.new("Expected either no arguments or one, got #{parsed.arguments.size}")
      end

      snowflake = if first_argument = parsed.arguments[0]?
                    Discord::Snowflake.new(first_argument.to_user_mention.id)
                  else
                    message.author.id
                  end

      result = nil
      DB.transaction do |tx|
        potential_id = user_id_from_snowflake(tx, snowflake)
        result = Core::Bank.balance(tx, potential_id)
      end
      result = result.as(Result::Base)

      user = cache.resolve_user(snowflake)
      if result.is_a?(Core::Bank::Result::Balance)
        send_embed(message, Discord::Embed.new(
          title: "_Balance:_",
          fields: [Discord::EmbedField.new(
            name: "#{user.username}",
            value: "#{result.message}",
          )]
        ))
      else
        send_message(message, result.message)
      end

      result
    end
  end
end
