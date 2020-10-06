class StackCoin::Bot::Commands
  class Graph < Command
    getter trigger = "graph"
    getter aliases = ["chart"]
    getter desc = "Graph balance over time"

    def initialize
    end

    def invoke(message, parsed)
      send_message(message, "TODO")
    end
  end
end
