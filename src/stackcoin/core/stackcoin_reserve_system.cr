require "humanize_time"
require "../result"

class StackCoin::Core::StackCoinReserveSystem
  class Result < StackCoin::Result
    class PrematureDole < Failure
    end

    class NoSuchUserAccount < Failure
    end

    class NotAuthorized < Failure
    end

    class InvalidAmount < Failure
    end

    class EmptyReserves < Failure
    end

    class GivenDole < Success
      getter transaction_id : Int32
      getter stackcoin_reserve_system_user_balance : Int32
      getter to_user_balance : Int32

      def initialize(message, @transaction_id, @stackcoin_reserve_system_user_balance, @to_user_balance)
        super(message)
      end
    end

    class Pump < Success
      getter pump_id : Int32
      getter stackcoin_reserve_system_user_balance : Int32

      def initialize(message, @pump_id, @stackcoin_reserve_system_user_balance)
        super(message)
      end
    end
  end

  DOLE_AMOUNT                              = 10
  STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER = "StackCoin Reserve System"

  class_getter stackcoin_reserve_system_user_id : Int32? = nil

  def self.stackcoin_reserve_system_user(cnn : ::DB::Connection)
    if stackcoin_reserve_system_user_id = @@stackcoin_reserve_system_user_id
      return stackcoin_reserve_system_user_id
    else
      stackcoin_reserve_system_user_id = cnn.query_one(<<-SQL, STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER, as: Int32)
        SELECT id FROM "internal_user" WHERE identifier = $1
        SQL
      @@stackcoin_reserve_system_user_id = stackcoin_reserve_system_user_id
      return stackcoin_reserve_system_user_id
    end
  end

  def self.pump(tx : ::DB::Transaction, signee_id : Int32?, amount : Int32, label : String)
    unless signee_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("You don't have an user account to pump the StackCoin Reserve System with yet")
    end

    unless amount > 0
      return Result::InvalidAmount.new("Pump amount must be greater than 0")
    end

    now = Time.utc
    cnn = tx.connection

    signee_is_admin = cnn.query_one(<<-SQL, signee_id, as: Bool)
      SELECT admin FROM "user" WHERE id = $1
      SQL

    unless signee_is_admin
      return Result::NotAuthorized.new("Not authorized to pump the StackCoin Reserve System")
    end

    user_id = stackcoin_reserve_system_user(cnn)

    current_balance = cnn.query_one(<<-SQL, user_id, as: Int32)
      SELECT balance FROM "user" WHERE id = $1
      SQL

    new_balance = current_balance + amount

    cnn.exec(<<-SQL, new_balance, user_id)
      UPDATE "user" SET balance = $1 WHERE id = $2
      SQL

    pump_id = cnn.query_one(<<-SQL, signee_id, user_id, new_balance, now, label, as: Int32)
      INSERT INTO "pump" (
        signee_id,
        to_id,
        to_new_balance,
        time,
        label
      ) VALUES (
        $1, $2, $3, $4, $5
      ) RETURNING id
      SQL

    return Result::Pump.new(
      "Successfully pumped the StackCoin Reserve System with #{amount} STK, with label: \"#{label}\"",
      pump_id: pump_id,
      stackcoin_reserve_system_user_balance: new_balance,
    )
  end

  def self.dole(tx : ::DB::Transaction, to_user_id : Int32?)
    unless to_user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("You don't have an user account to deposit dole to yet")
    end

    now = Time.utc
    cnn = tx.connection

    to_user_last_given_dole = cnn.query_one(<<-SQL, to_user_id, as: Time?)
      SELECT last_given_dole FROM "user" WHERE id = $1
      SQL

    if last_given_dole = to_user_last_given_dole
      if last_given_dole.day == now.day
        time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
        time_since_dole = HumanizeTime.distance_of_time_in_words(now - last_given_dole)
        return Result::PrematureDole.new("Dole already received #{time_since_dole} ago, rollover in #{time_till_rollver}")
      end
    end

    from_user_id = stackcoin_reserve_system_user(cnn)
    result = Bank.transfer(tx, from_user_id, to_user_id, amount: DOLE_AMOUNT)

    # TODO handle every type of result the bank can throw back

    if result.is_a?(Core::Bank::Result::SuccessfulTransaction)
      cnn.exec(<<-SQL, now, to_user_id)
        UPDATE "user" SET last_given_dole = $1 WHERE id = $2
        SQL

      return Result::GivenDole.new(
        "Dole given, your new balance is #{result.to_user_balance}",
        transaction_id: result.transaction_id,
        stackcoin_reserve_system_user_balance: result.from_user_balance,
        to_user_balance: result.to_user_balance,
      )
    end

    Result::EmptyReserves.new("The StackCoin Reserve System is empty, dole cannot be given")
  end
end
