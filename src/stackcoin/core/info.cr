require "../result"

class StackCoin::Core::Info
  class Result < StackCoin::Result
    class Circulation < Success
      getter amount : Int64

      def initialize(tx, message, @amount)
        super(tx, message)
      end
    end
  end

  MAX_TRANSFER_AMOUNT = 100000

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
end
