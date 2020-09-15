class StackCoin::Bot::Commands
  class Send < Command
    getter trigger = "pump"
    getter usage = "<#amount> <''>"
    getter desc = "Send your STK to others"

    def initialize
    end

    def invoke(message, parsed)
      # TODO
    end
  end
end
