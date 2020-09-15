require "humanize_time"
require "../result"

class StackCoin::Core::StackCoinReserveSystem
  class Result < StackCoin::Result
    class PrematureDole < Failure
    end
  end

  DOLE_AMOUNT                              = 10
  STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER = "StackCoin Reserve System"

  @@stackcoin_reserve_system_user_id : Int32? = nil

  def self.stackcoin_reserve_system_user(cnn)
    if stackcoin_reserve_system_user_id = @@stackcoin_reserve_system_user_id
      return stackcoin_reserve_system_user_id
    else
      stackcoin_reserve_system_user_id = cnn.query_one(<<-SQL, STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER, as: Int32)
        SELECT id FROM "internal_user" WHERE identifier = $1
        SQL
      return stackcoin_reserve_system_user_id
    end
  end

  def self.pump(cnn : ::DB::Connection, amount : Int32)
    # TODO log pump

    user = stackcoin_reserve_system_user(cnn)
    Bank.deposit(user, amount)
  end

  def self.dole(cnn : ::DB::Connection, to_user_id : Int32?)
    unless to_user_id.is_a?(Int32)
      return Core::Bank::Result::NoSuchUserAccount.new("You don't have an user account yet")
    end

    now = Time.utc

    to_user_last_given_dole = cnn.query_one(<<-SQL, to_user_id, as: Time?)
      SELECT last_given_dole FROM "user" WHERE id = $1
      SQL

    if last_given_dole = to_user_last_given_dole
      if last_given_dole.day == now.day
        time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
        return Result::PrematureDole.new("Dole already received today, rollover in #{time_till_rollver}")
      end
    end

    from_user_id = stackcoin_reserve_system_user(cnn)
    result = Bank.transfer(cnn, from_user_id, to_user_id, amount: DOLE_AMOUNT)

    # if result is success

    if true
      # TODO user.last_given_dole = now
    else
      # TODO no dole??? unheard of
    end

    # TODO update values
    # from.update("balance")
    # user.update("last_given_dole", "balance")

    result
  end
end
