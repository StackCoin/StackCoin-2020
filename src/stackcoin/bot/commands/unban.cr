class StackCoin::Bot::Commands
  class Unban < Command
    getter trigger = "unban"
    getter aliases = ["pardon"]
    getter desc = "Unban a user"

    def initialize
    end

    def invoke(message, parsed)
      send_message(message, "TODO")
    end
  end
end

