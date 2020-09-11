require "humanize_time"
require "../result"

class StackCoin::Core::StackCoinReserveSystem
  class Result < StackCoin::Result
    class PrematureDole < Failure
    end
  end

  DOLE_AMOUNT                              = 10
  STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER = "StackCoin Reserve System"

  @@stackcoin_reserve_system_user : Models::InternalUser? = nil

  def self.stackcoin_reserve_system_user(cnn)
    if stackcoin_reserve_system_user = @@stackcoin_reserve_system_user
      return stackcoin_reserve_system_user
    else
      stackcoin_reserve_system_user = Models::InternalUser.from_identifier(cnn, STACKCOIN_RESERVE_SYSTEM_USER_IDENTIFIER)
      @@stackcoin_reserve_system_user = stackcoin_reserve_system_user
      return stackcoin_reserve_system_user
    end
  end

  def self.pump(cnn : ::DB::Connection, amount : Int32)
    # TODO log pump

    user = stackcoin_reserve_system_user(cnn)
    Bank.deposit(user, amount)

    # TODO update values
  end

  def self.dole(cnn : ::DB::Connection, user : Models::User)
    now = Time.utc

    if last_given_dole = user.last_given_dole
      if last_given_dole.day == now.day
        time_till_rollver = HumanizeTime.distance_of_time_in_words(now.at_end_of_day - now, now)
        return Result::PrematureDole.new("Dole already received today, rollover in #{time_till_rollver}")
      end
    end

    from = stackcoin_reserve_system_user(cnn)
    result = Bank.transfer(cnn, from: from, to: user, amount: DOLE_AMOUNT)

    # if result is success

    if true
      user.last_given_dole = now
    else
      # no dole??? unheard of
    end

    # TODO update values
    #from.update("balance")
    #user.update("last_given_dole", "balance")

    result
  end
end
