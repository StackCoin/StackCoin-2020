class StackCoin::Bot::Commands
  class Mark < Command
    getter trigger = "mark"
    getter aliases = [] of String
    getter desc = "Mark a channel as the designated channel for StackCoin"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected no arguments, got #{parsed.arguments.size}")
      end

      send_message(message, "TODO")
    end
  end
end
