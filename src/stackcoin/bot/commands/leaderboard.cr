class StackCoin::Bot::Commands
  class Leaderboard < Command
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
      send_message(message, "TODO")
    end
  end
end
