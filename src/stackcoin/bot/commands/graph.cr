class StackCoin::Bot::Commands
  class Graph < Command
    getter trigger = "graph"
    getter aliases = ["g", "chart"]
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

      result = nil
      DB.transaction do |tx|
        potential_id = user_id_from_snowflake(tx, snowflake)
        result = Core::Graph.balance_over_time(tx, potential_id)
        p result
      end
      result = result.as(Result::Base)

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
