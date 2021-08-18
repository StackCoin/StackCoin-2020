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

      balance, graph = DB.using_connection do |cnn|
        stackcoin_reserve_system_user_id = StackCoin::Core::StackCoinReserveSystem.stackcoin_reserve_system_user(cnn)

        balance_result = Core::Bank.balance(cnn, stackcoin_reserve_system_user_id)
        graph_result = Core::Graph.balance_over_time(cnn, stackcoin_reserve_system_user_id)

        {balance_result, graph_result}
      end

      if balance.is_a?(Core::Bank::Result::Balance) && graph.is_a?(Core::Graph::Result::File)
        # TODO make a graph api that returns images instead of this, such that they can be
        # put within an embed
        client.upload_file(
          channel_id: message.channel_id,
          content: "",
          file: graph.file
        )
        send_embed(message, Discord::Embed.new(
          title: "_Reserves:_",
          fields: [Discord::EmbedField.new(
            name: StackCoin::Core::StackCoinReserveSystem::STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER,
            value: "#{balance.balance} STK",
          )]
        ))
        graph.file.delete
      else
        unless balance.is_a?(Core::Bank::Result::Balance)
          send_message(message, balance.message)
        end

        unless graph.is_a?(Core::Graph::Result::File)
          send_message(message, graph.message)
        end
      end
    end
  end
end
