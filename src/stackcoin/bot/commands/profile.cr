class StackCoin::Bot::Commands
  class Profile < Command
    LIMIT = 5

    getter trigger = "transactions"
    getter aliases = ["t", "ledger", "l"]
    getter usage = "<?#page=1> TODO"
    getter desc = "List of users, ranked by balance"

    def initialize
    end

    def invoke(message, parsed)
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
        Core::Info.profile(cnn, potential_id)
      end

      if result.is_a?(Core::Info::Result::Profile)
        profile = result.data

        fields = [] of Discord::EmbedField

        fields << Discord::EmbedField.new(
          name: "#{profile.username} (#{profile.id})",
          value: <<-TEXT
            Balance: #{profile.balance} STK
            Created at : #{profile.created_at}
            Last given dole: #{profile.last_given_dole}
            TEXT
        )

        send_embed(message, Discord::Embed.new(
          title: "_Profile:_",
          fields: fields
        ))
      else
        send_message(message, result.message)
      end

      result
    end
  end
end

