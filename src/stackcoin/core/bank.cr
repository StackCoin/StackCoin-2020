require "../result"

class StackCoin::Core::Bank
  class Result < StackCoin::Result
    class SuccessfulTransaction < Success
      getter transaction_id : Int32
      getter from_user_balance : Int32
      getter to_user_balance : Int32

      def initialize(message, @transaction_id, @from_user_balance, @to_user_balance)
        super(message)
      end
    end

    class Balance < Success
      getter balance : Int32

      def initialize(message, @balance)
        super(message)
      end
    end

    class NoSuchUserAccount < Failure
    end

    class TransferSelf < Failure
    end

    class InvalidAmount < Failure
    end

    class InsufficentFunds < Failure
    end

    class BannedUser < Failure
    end
  end

  MAX_TRANSFER_AMOUNT = 100000

  def self.transfer(tx : ::DB::Transaction, from_user_id : Int32?, to_user_id : Int32?, amount : Int32, label : String? = nil) : Result::Base
    unless from_user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("You don't have an user account yet")
    end

    unless to_user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("Recieving user doesn't have an user account")
    end

    if from_user_id == to_user_id
      return Result::TransferSelf.new("Can't transfer money to self")
    end

    unless amount > 0
      return Result::InvalidAmount.new("Amount must be greater than zero")
    end

    if amount > MAX_TRANSFER_AMOUNT
      return Result::InvalidAmount.new("Amount can't be greater than #{MAX_TRANSFER_AMOUNT}")
    end

    cnn = tx.connection

    from_balance, from_banned = cnn.query_one(<<-SQL, from_user_id, as: {Int32, Bool})
      SELECT balance, banned FROM "user" WHERE id = $1
      SQL

    to_balance, to_banned = cnn.query_one(<<-SQL, to_user_id, as: {Int32, Bool})
      SELECT balance, banned FROM "user" WHERE id = $1
      SQL

    if from_banned || to_banned
      return Result::BannedUser.new("Banned user mentioned in transfer")
    end

    if from_balance - amount < 0
      return Result::InsufficentFunds.new("Insufficient funds")
    end

    from_new_balance = from_balance - amount
    cnn.exec(<<-SQL, from_new_balance, from_user_id)
      UPDATE "user" SET balance = $1 WHERE id = $2
      SQL

    to_new_balance = to_balance + amount
    cnn.exec(<<-SQL, to_new_balance, to_user_id)
      UPDATE "user" SET balance = $1 WHERE id = $2
      SQL

    now = Time.utc

    transaction_id = cnn.query_one(<<-SQL, from_user_id, from_new_balance, to_user_id, to_new_balance, amount, now, as: Int32)
      INSERT INTO "transaction" (
        from_id,
        from_new_balance,
        to_id,
        to_new_balance,
        amount,
        time
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      ) RETURNING id
      SQL

    Result::SuccessfulTransaction.new(
      "Transfer sucessful",
      transaction_id: transaction_id,
      from_user_balance: from_new_balance,
      to_user_balance: to_new_balance,
    )
  end

  def self.balance(cnn : ::DB::Connection, user_id : Int32?) : Result::Base
    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("No user account to check the balance of")
    end

    balance = cnn.query_one(<<-SQL, user_id, as: Int32)
      SELECT balance FROM "user" WHERE id = $1
      SQL

    Result::Balance.new("Your balance is #{balance} STK", balance)
  end
end
