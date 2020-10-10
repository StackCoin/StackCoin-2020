class StackCoin::Bot::Commands
  class Transactions < Command
    LIMIT = 5

    getter trigger = "transactions"
    getter aliases = ["t", "ledger", "l"]
    getter usage = "<?#page=1> TODO"
    getter desc = "List of users, ranked by balance"

    def initialize
    end

    def invoke(message, parsed)
      page = 0 #O TODO

      offset = (page - 1) * LIMIT

      result = nil
      DB.transaction do |tx|
        # result = Core::Info.leaderboard(tx, limit: LIMIT, offset: offset)
      end
      # result = result.as(Core::Info::Result::Leaderboard)

      fields = [] of Discord::EmbedField

      #result.entries.each_with_index do |entry, index|
      #  fields << Discord::EmbedField.new(
      #    name: "\##{offset + index + 1}: #{entry.username}",
      #    value: "Balance: #{entry.balance} STK",
      #  )
      #end

      #fields << Discord::EmbedField.new(
      # name: "*crickets*",
      #  value: "No users found on page #{page}, maybe try a smaller number?"
      #) if fields.size == 0

      #send_embed(message, Discord::Embed.new(
      #  title: "_Leaderboard:_",
      #  fields: fields
      #))

      send_message(message, "TODO")
    end
  end
end
