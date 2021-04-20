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

    class Transactions < Success
      class Entry
        include ::DB::Serializable
        getter id : Int32
        getter time : Time
        getter from_username : String
        getter from_new_balance : Int32
        getter to_username : String
        getter to_new_balance : Int32
        getter amount : Int32
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
        getter avatar_url : String
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

  def self.circulation(cnn : ::DB::Connection) : Result::Circulation
    amount = cnn.query_one(<<-SQL, as: Int64)
      SELECT SUM(balance) FROM "user"
      SQL

    Result::Circulation.new(
      "#{amount} STK currently in circulation",
      amount: amount,
    )
  end

  def self.leaderboard(cnn : ::DB::Connection, limit : Int32 = 5, offset : Int32 = 0) : Result::Leaderboard
    entries = Result::Leaderboard::Entry.from_rs(cnn.query(<<-SQL, limit, offset))
      SELECT username, balance FROM "user"
      ORDER BY balance DESC LIMIT $1 OFFSET $2
    SQL

    Result::Leaderboard.new("Rankings, limited by #{limit} and offsetted by #{offset}", entries: entries)
  end

  def self.transactions(cnn : ::DB::Connection, limit : Int32 = 5, offset : Int32 = 0) : Result::Transactions
    entries = Result::Transactions::Entry.from_rs(cnn.query(<<-SQL, limit, offset))
      SELECT
        "transaction".id, time, "from".username as "from_username", from_new_balance, "to".username as "to_username", to_new_balance, amount
      FROM "transaction"
        LEFT JOIN "user" AS "from" ON "transaction".from_id = "from".id
        LEFT JOIN "user" AS "to" ON "transaction".to_id = "to".id
      ORDER BY time DESC LIMIT $1 OFFSET $2;
      SQL

    Result::Transactions.new("Transactions, limited by #{limit} and offsetted by #{offset}", entries: entries)
  end

  def self.profile(cnn : ::DB::Connection, user_id : Int32?) : Result::Base
    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("No user account to check profile of")
    end

    data = Result::Profile::Data.from_rs(cnn.query(<<-SQL, user_id))
      SELECT
        id, avatar_url, username, balance, created_at, last_given_dole
      FROM "user" WHERE id = $1
      SQL

    # TODO assert size of 1 or fail some otherway cause this sucks
    data = data[0]

    Result::Profile.new("Profile for #{data.username} (\##{data.id})", data: data)
  end
end
