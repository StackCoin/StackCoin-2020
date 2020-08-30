require "humanize_time"
require "../result"

class StackCoin::Bank
  class Result < StackCoin::Result
    class TransferSuccess < Success
      property from_balance : Int32
      property to_balance : Int32

      def initialize(@message, @from_balance, @to_balance)
      end
    end

    class PrematureDole < Error
    end

    class TransferSelf < Error
    end

    class InvalidAmount < Error
    end

    class InsufficientFunds < Error
    end

    class BannedUser < Error
    end
  end

  @@dole_amount : Int32 = 10
  @@max_transfer_amount : Int32 = 100000

  private def deposit(cnn : DB::Connection, user : User, amount : Int32)
  end

  private def withdraw(cnn : DB::Connection, user : User, amount : Int32)
  end

  def dole(cnn : DB::Connection, user : User)
    now = Time.utc

    if user.last_given_dole.day == now.day
      time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
      return Result::PrematureDole.new(tx, "Dole already received today, rollover in #{time_till_rollver}")
    end

    # deposit(cnn, user, @@dole_amount)

    # update last given dole

    bal = 0 # TODO

    # log transaction

    Result::Success.new("#{@@dole_amount} STK given, your balance is now #{bal} STK")
  end

  def transfer(cnn : DB::Connection, from : User, to : User, amount : Int32)
    if from_id == to_id
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

    # return Result::InsufficientFunds.new(tx, "Insufficient funds")

    # withdraw(cnn, from_id, amount)

    # deposit(cnn, to_id, amount)

    # TODO log transfer

    Result::TransferSuccess.new("Transfer sucessful")
  end
end
