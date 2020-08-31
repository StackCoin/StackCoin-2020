require "humanize_time"
require "../result"

class StackCoin::Bank
  class Result < StackCoin::Result
    class SuccessfulTransaction < Success
      property transaction : Models::Transaction

      def initialize(message, @transaction)
        super(message)
      end
    end

    class PrematureDole < Failure
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

  @@dole_amount : Int32 = 10
  @@max_transfer_amount : Int32 = 100000

  private def self.deposit(user : Models::User, amount : Int32)
    user.balance += amount
  end

  private def self.withdraw(user : Models::User, amount : Int32)
    user.balance -= amount
  end

  def self.dole(cnn : ::DB::Connection, user : Models::User)
    now = Time.utc

    if last_given_dole = user.last_given_dole
      if last_given_dole.day == now.day
        time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
        return Result::PrematureDole.new("Dole already received today, rollover in #{time_till_rollver}")
      end
    end

    deposit(user, @@dole_amount)

    user.last_given_dole = now

    # TODO update database with new values

    # TODO log transaction
    # transaction = ...

    # Result::SuccessfulTransaction.new("#{@@dole_amount} STK given, your balance is now #{user.balance} STK", transaction)
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

    if amount > @@max_transfer_amount
      return Result::InvalidAmount.new("Amount can't be greater than #{@@max_transfer_amount}")
    end

    if from.banned || to.banned
      return Result::BannedUser.new("Banned user mentioned in transfer")
    end

    if from.balance - amount < 0
      return Result::InsufficientFunds.new("Insufficient funds")
    end

    withdraw(from, amount)
    deposit(to, amount)

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
