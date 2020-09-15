class StackCoin::Bot::Commands
  class Pump < Command
    getter trigger = "pump"
    getter aliases = [] of String
    getter usage = "<#amount> <\"label\">"
    getter desc = "Pump the Stackcoin Reserve System"

    def initialize
    end

    def invoke(message, parsed)
      # TODO
    end
  end
end
