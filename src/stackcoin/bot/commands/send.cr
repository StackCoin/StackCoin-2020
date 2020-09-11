class StackCoin::Bot::Commands
  class Send < Command
    getter trigger = "send"
    getter aliases = ["transfer"]
    getter usage = "<@user> <#amount>"
    getter desc = "Send your STK to others"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 2
        raise Parser::Error.new("Expected two arguments, got #{parsed.arguments.size}")
      end

      user = parsed.arguments[0].to_user
      amount = parsed.arguments[1].to_i

      # TODO
    end
  end
end
