class StackCoin::Bot::Commands
  class Reserves < Command
    getter trigger = "reserves"
    getter aliases = ["r", "reserve"]
    getter desc = "Check the amount of STK in StackCoin"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected no arguments, got #{parsed.arguments.size}")
      end

      result = nil
      DB.transaction do |tx|
        stackcoin_reserve_system_user_id = StackCoin::Core::StackCoinReserveSystem.stackcoin_reserve_system_user(tx)
        result = Core::Bank.balance(tx, stackcoin_reserve_system_user_id)
      end
      result = result.as(Core::Bank::Result::Balance)

      send_embed(message, Discord::Embed.new(
        title: "_Reserves:_",
        fields: [Discord::EmbedField.new(
          name: StackCoin::Core::StackCoinReserveSystem::STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER,
          value: "#{result.balance} STK",
        )]
      ))
    end
  end
end
