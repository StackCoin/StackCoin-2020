class StackCoin::Bot::Commands
  class Graph < Command
    getter trigger = "graph"
    getter aliases = ["g", "chart"]
    getter usage = "<?@graph>"
    getter desc = "Graph balance over time"

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
        Core::Graph.balance_over_time(cnn, potential_id)
      end

      if result.is_a? Core::Graph::Result::File
        user = cache.resolve_user(snowflake)
        client.upload_file(
          channel_id: message.channel_id,
          content: "#{user.username}'s STK balance over time",
          file: result.file
        )
        result.file.delete
      else
        send_message(message, result.message)
      end

      result
    end
  end
end
