require "../result"

class StackCoin::Core::Accounts
  class SessionStore
    class Session
      property user_id : Int32
      property expires_at : Time

      def initialize(@user_id, @expires_at)
      end
    end

    # TODO back by database instead of in memory eventually
    class_property in_memory_session_store : Hash(String, Session?) = {} of String => Session?

    def self.create(user_id : Int32, valid_for : Time::Span = 2.days)
      now = Time.utc
      expires_at = now + valid_for

      id = Random::Secure.hex

      session = Session.new(user_id, expires_at)

      in_memory_session_store[id] = session

      {id, session}
    end
  end

  class Result < StackCoin::Result
    class NewUserAccount < Success
      getter new_user_id : Int32

      def initialize(message, @new_user_id)
        super(message)
      end
    end

    class OneTimeLink < Success
      getter link : String

      def initialize(message, @link)
        super(message)
      end
    end

    class NoSuchUserAccount < Failure
    end

    class PreExistingUserAccount < Failure
    end

    class BannedUser < Failure
    end
  end

  def self.one_time_link(tx : ::DB::Transaction, user_id : Int32?)
    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("No user account to login to")
    end

    SessionStore.create(user_id)

    link = "http://foo"

    Result::OneTimeLink.new("One time link generated", link)
  end

  def self.open(tx : ::DB::Transaction, username : String, avatar_url : String, admin : Bool)
    cnn = tx.connection

    now = Time.utc
    created_at = now
    balance = 0
    banned = false

    user_id = cnn.query_one(<<-SQL, created_at, username, avatar_url, balance, admin, banned, as: Int32)
      INSERT INTO "user" (
        created_at,
        username,
        avatar_url,
        balance,
        admin,
        banned
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      ) RETURNING id
      SQL

    Result::NewUserAccount.new("User account created", user_id)
  end

  def self.open(tx : ::DB::Transaction, discord_snowflake : Discord::Snowflake, username : String, avatar_url : String)
    now = Time.utc
    admin = false

    if discord_snowflake == Bot::OWNER_SNOWFLAKE
      admin = true
    end

    cnn = tx.connection

    preexisting_id = cnn.query_one?(<<-SQL, discord_snowflake.to_u64, as: Int32)
      SELECT id FROM discord_user WHERE snowflake = $1
      SQL

    if preexisting_id
      return Result::PreExistingUserAccount.new("You already have an user account associated with your Discord account")
    end

    result = open(tx, username, avatar_url, admin)

    cnn.exec(<<-SQL, result.new_user_id, now, discord_snowflake)
      INSERT INTO "discord_user" (
        id, last_updated, snowflake
      ) VALUES (
        $1, $2, $3
      )
      SQL

    Result::NewUserAccount.new("User account associated with Discord created", result.new_user_id)
  end
end
