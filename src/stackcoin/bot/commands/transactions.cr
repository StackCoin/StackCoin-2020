class StackCoin::Bot::Commands
  class Transactions < Command
    LIMIT = 5

    getter trigger = "transactions"
    getter aliases = ["t", "ledger", "l"]
    getter usage = "<?#page=1>"
    getter desc = "List of transactions"

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
        Core::Info.transactions(cnn, limit: LIMIT, offset: offset)
      end

      fields = [] of Discord::EmbedField

      result.entries.each_with_index do |entry, index|
        fields << Discord::EmbedField.new(
          name: "\##{entry.id}: #{entry.time}",
          value: "#{entry.from_username} (#{entry.from_new_balance}) ⟶ #{entry.to_username} (#{entry.to_new_balance}) - #{entry.amount} STK"
        )
      end

      fields << Discord::EmbedField.new(
        name: "*crickets*",
        value: "No transactions found on page #{page}, maybe try a smaller number?"
      ) if fields.size == 0

      send_embed(message, Discord::Embed.new(
        title: "_Transactions:_",
        fields: fields
      ))
    end
  end
end
