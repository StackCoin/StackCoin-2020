require "humanize_time"
require "../result"

class StackCoin::Core::StackCoinReserveSystem
  class Result < StackCoin::Result
    class PrematureDole < Failure
    end

    class NoSuchUserAccount < Failure
    end

    class EmptyReserves < Success
    end

    class GivenDole < Success
    end
  end

  DOLE_AMOUNT                              = 10
  STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER = "StackCoin Reserve System"

  @@stackcoin_reserve_system_user_id : Int32? = nil

  def self.stackcoin_reserve_system_user(tx : ::DB::Transaction)
    if stackcoin_reserve_system_user_id = @@stackcoin_reserve_system_user_id
      return stackcoin_reserve_system_user_id
    else
      cnn = tx.connection
      stackcoin_reserve_system_user_id = cnn.query_one(<<-SQL, STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER, as: Int32)
        SELECT id FROM "internal_user" WHERE identifier = $1
        SQL
      return stackcoin_reserve_system_user_id
    end
  end

  def self.pump(tx : ::DB::Transaction, amount : Int32)
    # TODO log pump

    user_id = stackcoin_reserve_system_user(tx)
    cnn.exec(<<-SQL, amount, user_id)
      UPDATE "user" SET balance = balanace + $1 WHERE id = $2
      SQL
  end

  def self.dole(tx : ::DB::Transaction, to_user_id : Int32?)
    unless to_user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new(tx, "You don't have an user account to deposit dole to yet")
    end

    now = Time.utc
    cnn = tx.connection

    to_user_last_given_dole = cnn.query_one(<<-SQL, to_user_id, as: Time?)
      SELECT last_given_dole FROM "user" WHERE id = $1
      SQL

    if last_given_dole = to_user_last_given_dole
      if last_given_dole.day == now.day
        time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
        return Result::PrematureDole.new(tx, "Dole already received today, rollover in #{time_till_rollver}")
      end
    end

    from_user_id = stackcoin_reserve_system_user(tx)
    result = Bank.transfer(tx, from_user_id, to_user_id, amount: DOLE_AMOUNT)

    if result.is_a?(Core::Bank::Result::SuccessfulTransaction)
      cnn.exec(<<-SQL, now, to_user_id)
        UPDATE "user" SET last_given_dole = $1 WHERE id = $1
        SQL

      return Result::GivenDole.new(tx, "Dole given, your new balance is #{result.to_user_balance}")
    end

    Result::EmptyReserves.new(tx, "The StackCoin Reserve System is empty, dole cannot be given")
  end
end
