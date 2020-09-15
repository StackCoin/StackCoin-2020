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
    if stackcoin_reserve_system_user = @@stackcoin_reserve_system_user
      return stackcoin_reserve_system_user
    else
      raise "todo select da user"
      return stackcoin_reserve_system_user
    end
  end

  def self.pump(cnn : ::DB::Connection, amount : Int32)
    # TODO log pump

    #user = stackcoin_reserve_system_user(cnn)
    #Bank.deposit(user, amount)

    # TODO update values
  end

  def self.dole(cnn : ::DB::Connection, to_user_id : Int32)
    now = Time.utc

    to_user_last_given_dole = cnn.query_one(<<-SQL, from_user_id, as: Time)
      SELECT last_given_dole FROM user WHERE id = $1
      SQL

    if last_given_dole = to_user_last_given_dole
      if last_given_dole.day == now.day
        time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
        return Result::PrematureDole.new("Dole already received today, rollover in #{time_till_rollver}")
      end
    end

    # TODO
    #from = stackcoin_reserve_system_user(cnn)
    #result = Bank.transfer(cnn, from: from, to: user, amount: DOLE_AMOUNT)

    # if result is success

    if true
      # TODO user.last_given_dole = now
    else
      # TODO no dole??? unheard of
    end

    # TODO update values
    #from.update("balance")
    #user.update("last_given_dole", "balance")

    result
  end
end
