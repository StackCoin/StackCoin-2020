class StackCoin::Bot::Commands
  class Login < Command
    getter trigger = "login"
    getter aliases = ["signin"]
    getter desc = "Be DM'd a one-time-use link to sign into the StackCoin with"

    def initialize
    end

    def invoke(message, parsed)
      unless parsed.arguments.size == 0
        raise Parser::Error.new("Expected zero arguments, got #{parsed.arguments.size}")
      end

      result = nil
      DB.transaction do |tx|
        cnn = tx.connection
        user_id = user_id_from_snowflake(cnn, message.author.id)
        result = Core::Accounts.one_time_link(tx, user_id)
      end
      result = result.as(Result::Base)

      if result.is_a?(Core::Accounts::Result::OneTimeLink)
        begin
          dms = client.create_dm(message.author.id)
          client.create_message(dms.id, <<-MESSAGE)
            Here's your one time login link:
            #{result.link}
            MESSAGE
          send_message(message, "One time login link sent to you, check your direct messages with this bot")
        rescue Discord::CodeException
          send_message(message, "Failed to send your a direct message, cannot send one time link via Discord")
        end
      else
        send_message(message, result.message)
      end

      result
    end
  end
end
