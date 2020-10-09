class StackCoin::Bot::Commands
  class Circulation < Command
    getter trigger = "circulation"
    getter aliases = ["circ"]
    getter desc = "Check the amount of STK in circlation"

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
