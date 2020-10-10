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

      result = DB.using_connection do |cnn|
        stackcoin_reserve_system_user_id = StackCoin::Core::StackCoinReserveSystem.stackcoin_reserve_system_user(cnn)
        Core::Bank.balance(cnn, stackcoin_reserve_system_user_id)
      end

      if result.is_a?(Core::Bank::Result::Balance)
        send_embed(message, Discord::Embed.new(
          title: "_Reserves:_",
          fields: [Discord::EmbedField.new(
            name: StackCoin::Core::StackCoinReserveSystem::STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER,
            value: "#{result.balance} STK",
          )]
        ))
      else
        send_message(message, result.message)
      end
    end
  end
end
