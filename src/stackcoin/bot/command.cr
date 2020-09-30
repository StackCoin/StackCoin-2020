class StackCoin::Bot
  abstract class Command
    getter trigger : String
    getter aliases : Array(String)
    getter usage : String?
    getter desc : String

    class Result < StackCoin::Result
      class FailureWithMessage < Failure
        def initialize(tx, client, payload, message)
          client.create_message(payload.channel_id, message)
          super(tx, message)
        end
      end

      class PreExistingUserAccount < FailureWithMessage
      end
    end

    def initialize(@trigger, @aliases, @usage, @desc)
    end

    abstract def invoke(message : Discord::Message, parsed : ParsedCommand)

    def user_id_from_snowflake(cnn : ::DB::Connection, snowflake : Discord::Snowflake)
      cnn.query_one?(<<-SQL, snowflake.to_u64, as: Int32)
        SELECT id FROM discord_user WHERE snowflake = $1
        SQL
    end

    def client
      INSTANCE.client
    end

    def send_message(message, content)
      client.create_message(message.channel_id, content)
    end

    def cache
      INSTANCE.cache
    end
  end
end
