
class StackCoin::Bot::Commands
  class Leaderboard < Command
    getter trigger = "leaderboard"
    getter aliases = ["scoreboard"]
    getter usage = "<?#page=1>"
    getter desc = "List of accounts, ranked by balance"

    def initialize
    end

    def invoke(message, parsed)
      page = 1

      if parsed.arguments.size >= 1
        page = parsed.arguments[0].to_i
      end

      # TODO
    end
  end
end
