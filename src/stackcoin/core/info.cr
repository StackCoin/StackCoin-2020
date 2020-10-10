require "../result"

class StackCoin::Core::Info
  class Result < StackCoin::Result
    class Circulation < Success
      getter amount : Int64

      def initialize(message, @amount)
        super(message)
      end
    end

    class Leaderboard < Success
      class Entry
        include ::DB::Serializable
        getter username : String
        getter balance : Int32
      end

      getter entries : Array(Entry)

      def initialize(message, @entries)
        super(message)
      end
    end

    class Profile < Success
      class Data
        include ::DB::Serializable
        getter id : Int32
        getter username : String
        getter balance : Int32
        getter created_at : Time
        getter last_given_dole : Time?
      end

      getter data : Data

      def initialize(message, @data)
        super(message)
      end
    end

    class NoSuchUserAccount < Failure
    end
  end

  def self.circulation(cnn : ::DB::Connection)
    amount = cnn.query_one(<<-SQL, as: Int64)
      SELECT SUM(balance) FROM "user"
      SQL

    Result::Circulation.new(
      "#{amount} STK currently in circulation",
      amount: amount,
    )
  end

  def self.leaderboard(cnn : ::DB::Connection, limit : Int32 = 5, offset : Int32 = 0)
    entries = Result::Leaderboard::Entry.from_rs(cnn.query(<<-SQL, limit, offset))
      SELECT username, balance FROM "user"
      ORDER BY balance DESC LIMIT $1 OFFSET $2
      SQL

    Result::Leaderboard.new("Rankings, limited by #{limit} and offsetted by #{offset}", entries: entries)
  end

  def self.profile(cnn : ::DB::Connection, user_id : Int32?)
    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("No user account to check profile of")
    end

    data = Result::Profile::Data.from_rs(cnn.query(<<-SQL, user_id))
      SELECT
        id, username, balance, created_at, last_given_dole
      FROM "user" WHERE id = $1
      SQL

    # TODO assert size of 1 or fail some otherway cause this sucks
    data = data[0]

    Result::Profile.new("Profile for #{data.username} (\##{data.id})", data: data)
  end
end
