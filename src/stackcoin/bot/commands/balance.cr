class StackCoin::Bot::Commands
  class Balance < Command
    getter trigger = "balance"
    getter aliases = ["bal"]
    getter usage = "<?@other_user>"
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

      result = DB.using_connection do |cnn|
        potential_id = user_id_from_snowflake(cnn, snowflake)
        Core::Bank.balance(cnn, potential_id)
      end

      user = cache.resolve_user(snowflake)
      if result.is_a?(Core::Bank::Result::Balance)
        send_embed(message, Discord::Embed.new(
          title: "_Balance:_",
          fields: [Discord::EmbedField.new(
            name: "#{user.username}",
            value: "#{result.balance} STK",
          )]
        ))
      else
        send_message(message, result.message)
      end

      result
    end
  end
end
