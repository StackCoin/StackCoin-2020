require "humanize_time"
require "../result"

class StackCoin::Core::Bank
  class Result < StackCoin::Result
    class SuccessfulTransaction < Success
      property transaction : Models::Transaction

      def initialize(message, @transaction)
        super(message)
      end
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

  def self.deposit(user : Models::User, amount : Int32)
    user.balance += amount
  end

  def self.withdraw(user : Models::User, amount : Int32)
    user.balance -= amount
  end

  def self.transfer(cnn : ::DB::Connection, from : Models::User, to : Models::User, amount : Int32, label : String? = nil)
    from_id = from.id
    raise "bank given from user without id" if from_id.nil?

    to_id = to.id
    raise "bank given from to without id" if to_id.nil?

    if from.id == to.id
      return Result::TransferSelf.new("Can't transfer money to self")
    end

    unless amount > 0
      return Result::InvalidAmount.new("Amount must be greater than zero")
    end

    if amount > MAX_TRANSFER_AMOUNT
      return Result::InvalidAmount.new("Amount can't be greater than #{MAX_TRANSFER_AMOUNT}")
    end

    if from.banned || to.banned
      return Result::BannedUser.new("Banned user mentioned in transfer")
    end

    if from.balance - amount < 0
      return Result::InsufficientFunds.new("Insufficient funds")
    end

    withdraw(from, amount)
    deposit(to, amount)

    from.update_balance
    to.update_balance

    # TODO update database with new values

    transaction = Models::Transaction::Full.new(
      from_id: from_id,
      from_new_balance: from.balance,
      to_id: to_id,
      to_new_balance: to.balance,
      label: label,
    )
    transaction.insert(cnn)

    Result::SuccessfulTransaction.new("Transfer sucessful", transaction)
  end
end
