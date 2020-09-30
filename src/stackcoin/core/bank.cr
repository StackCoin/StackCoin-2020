require "humanize_time"
require "../result"

class StackCoin::Core::Bank
  class Result < StackCoin::Result
    class SuccessfulTransaction < Success
    end

    class NewUserAccount < Success
      getter new_user_id : Int32

      def initialize(message, @new_user_id)
        super(message)
      end
    end

    class NoSuchUserAccount < Failure
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

  def self.transfer(cnn : ::DB::Connection, from_user_id : Int32?, to_user_id : Int32?, amount : Int32, label : String? = nil)
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
      return Result::InsufficientFunds.new("Insufficient funds")
    end

    # TODO widthdraw / deposit
    # withdraw(from, amount)
    # deposit(to, amount)

    # TODO update database with new values

    # TODO create transaction
    # transaction = Models::Transaction::Full.new(
    #  from_id: from_id,
    #  from_new_balance: from.balance,
    #  to_id: to_id,
    #  to_new_balance: to.balance,
    #  label: label,
    # )
    # transaction.insert(cnn)

    Result::SuccessfulTransaction.new("Transfer sucessful")
  end

  def self.open(cnn : ::DB::Connection, discord_snowflake : Discord::Snowflake, username : String, avatar_url : String)
    now = Time.utc

    created_at = now
    balance = 0
    admin = false
    banned = false

    if discord_snowflake == Bot::OWNER_SNOWFLAKE
      admin = true
    end

    preexisting_id = cnn.query_one?(<<-SQL, snowflake.to_u64, as: Int32)
      SELECT id FROM discord_user WHERE snowflake = $1
      SQL

    if preexisting_id
      return Result::PreExistingUserAccount.new(tx, client, message, "You already have an user account associated with your Discord account")
    end

    # TODO ensure discord id isn't associated with an account

    user_id = cnn.query_one(<<-SQL, created_at, username, avatar_url, balance, admin, banned, as: Int32)
      INSERT INTO "user" (
        created_at,
        username,
        avatar_url,
        balance,
        admin,
        banned
      ) VALUES (
        $1, $2, $3, $4, $5, $6
      ) RETURNING id
      SQL

    cnn.exec(<<-SQL, user_id, now, discord_snowflake)
      INSERT INTO "discord_user" (
        id, last_updated, snowflake
      ) VALUES (
        $1, $2, $3
      )
      SQL

    return Result::NewUserAccount.new("User account created", user_id)
  end
end
