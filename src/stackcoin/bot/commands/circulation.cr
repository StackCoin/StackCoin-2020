class StackCoin::Bot::Commands
  class Circulation < Command
    getter trigger = "circulation"
    getter aliases = ["c", "circ"]
    getter desc = "Check the amount of STK in circlation"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected no arguments, got #{parsed.arguments.size}")
      end

      result = nil
      DB.transaction do |tx|
        result = Core::Info.circulation(tx)
      end
      result = result.as(Core::Info::Result::Circulation)

      send_embed(message, Discord::Embed.new(
        title: "_Total StackCoin in Circulation:_",
        fields: [Discord::EmbedField.new(
          name: "#{result.amount} STK",
          value: "Since #{EPOCH}",
        )]
      ))
    end
  end
end
