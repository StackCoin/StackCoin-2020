class StackCoin::Bot::Commands
  class Leaderboard < Command
    LIMIT = 5

    getter trigger = "leaderboard"
    getter aliases = ["l", "scoreboard"]
    getter usage = "<?#page=1>"
    getter desc = "List of users, ranked by balance"

    def initialize
    end

    def invoke(message, parsed)
      page = if parsed.arguments.size == 0
               1
             else
               parsed.arguments[0].to_i
             end

      unless page >= 1
        raise Parser::Error.new("Expected page to be greater than zero, was #{page}")
      end

      offset = (page - 1) * LIMIT

      result = DB.using_connection do |cnn|
        Core::Info.leaderboard(cnn, limit: LIMIT, offset: offset)
      end

      fields = [] of Discord::EmbedField

      result.entries.each_with_index do |entry, index|
        fields << Discord::EmbedField.new(
          name: "\##{offset + index + 1}: #{entry.username}",
          value: "Balance: #{entry.balance} STK",
        )
      end

      fields << Discord::EmbedField.new(
        name: "*crickets*",
        value: "No users found on page #{page}, maybe try a smaller number?"
      ) if fields.size == 0

      send_embed(message, Discord::Embed.new(
        title: "_Leaderboard:_",
        fields: fields
      ))
    end
  end
end
