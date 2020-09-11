require "humanize_time"
require "../result"

class StackCoin::Core::Bank
  class Result < StackCoin::Result
    class SuccessfulTransaction < Success
    end

    class TransferSelf < Failure
    end

    class InvalidAmount < Failure
    end

    class InsufficientFunds < Failure
    end

    class BannedUser < Failure
    end
  end

  MAX_TRANSFER_AMOUNT = 100000

  def self.transfer(cnn : ::DB::Connection, from_user_id : Int64, to_user_id : Int64, amount : Int32, label : String? = nil)
    if from_user_id == to_user_id
      return Result::TransferSelf.new("Can't transfer money to self")
    end

    unless amount > 0
      return Result::InvalidAmount.new("Amount must be greater than zero")
    end

    if amount > MAX_TRANSFER_AMOUNT
      return Result::InvalidAmount.new("Amount can't be greater than #{MAX_TRANSFER_AMOUNT}")
    end

    from_balance, from_banned = cnn.query_one(<<-SQL, from_user_id, as: {Int32, Bool})
      SELECT balance, banned FROM user WHERE id = $1
      SQL

    if from_banned || to_banned
      return Result::BannedUser.new("Banned user mentioned in transfer")
    end

    if from_balance - amount < 0
      return Result::InsufficientFunds.new("Insufficient funds")
    end

    # TODO widthdraw / deposit
    #withdraw(from, amount)
    #deposit(to, amount)

    # TODO update database with new values

    # TODO create transaction
    #transaction = Models::Transaction::Full.new(
    #  from_id: from_id,
    #  from_new_balance: from.balance,
    #  to_id: to_id,
    #  to_new_balance: to.balance,
    #  label: label,
    #)
    #transaction.insert(cnn)

    Result::SuccessfulTransaction.new("Transfer sucessful")
  end
end
