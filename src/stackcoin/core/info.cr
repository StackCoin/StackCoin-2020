require "../result"

class StackCoin::Core::Info
  class Result < StackCoin::Result
    class Circulation < Success
      getter amount : Int64

      def initialize(tx, message, @amount)
        super(tx, message)
      end
    end

    class Leaderboard < Success
      class Entry
        include ::DB::Serializable
        getter username : String
        getter balance : Int32
      end

      getter entries : Array(Entry)

      def initialize(tx, message, @entries)
        super(tx, message)
      end
    end
  end

  def self.circulation(tx : ::DB::Transaction)
    amount = tx.connection.query_one(<<-SQL, as: Int64)
      SELECT SUM(balance) FROM "user"
      SQL

    Result::Circulation.new(
      tx,
      "#{amount} STK currently in circulation",
      amount: amount,
    )
  end

  def self.leaderboard(tx : ::DB::Transaction, limit : Int32 = 5, offset : Int32 = 0)
    entries = Result::Leaderboard::Entry.from_rs(tx.connection.query(<<-SQL, limit, offset))
      SELECT username, balance FROM "user"
      ORDER BY balance DESC LIMIT $1 OFFSET $2
      SQL

    Result::Leaderboard.new(
      tx,
      "Rankings, limited by #{limit} and offsetted by #{offset}",
      entries: entries,
    )
  end
end
