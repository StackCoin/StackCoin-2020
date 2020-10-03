require "humanize_time"
require "../result"

class StackCoin::Core::Bank
  class Result < StackCoin::Result
    class SuccessfulTransaction < Success
      getter transaction_id : Int32
      getter from_user_balance : Int32
      getter to_user_balance : Int32

      def initialize(tx, message, @transaction_id, @from_user_balance, @to_user_balance)
        super(tx, message)
      end
    end

    class NewUserAccount < Success
      getter new_user_id : Int32

      def initialize(tx, message, @new_user_id)
        super(tx, message)
      end
    end

    class NoSuchUserAccount < Failure
    end

    class PreExistingUserAccount < Failure
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

  def self.transfer(tx : ::DB::Transaction, from_user_id : Int32?, to_user_id : Int32?, amount : Int32, label : String? = nil)
    unless from_user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new(tx, "You don't have an user account yet")
    end

    unless to_user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new(tx, "Recieving user doesn't have an user account")
    end

    if from_user_id == to_user_id
      return Result::TransferSelf.new(tx, "Can't transfer money to self")
    end

    unless amount > 0
      return Result::InvalidAmount.new(tx, "Amount must be greater than zero")
    end

    if amount > MAX_TRANSFER_AMOUNT
      return Result::InvalidAmount.new(tx, "Amount can't be greater than #{MAX_TRANSFER_AMOUNT}")
    end

    cnn = tx.connection

    from_balance, from_banned = cnn.query_one(<<-SQL, from_user_id, as: {Int32, Bool})
      SELECT balance, banned FROM "user" WHERE id = $1
      SQL

    to_balance, to_banned = cnn.query_one(<<-SQL, to_user_id, as: {Int32, Bool})
      SELECT balance, banned FROM "user" WHERE id = $1
      SQL

    if from_banned || to_banned
      return Result::BannedUser.new(tx, "Banned user mentioned in transfer")
    end

    if from_balance - amount < 0
      return Result::InsufficientFunds.new(tx, "Insufficient funds")
    end

    from_new_balance = from_balance - amount
    cnn.exec(<<-SQL, from_new_balance, from_user_id)
      UPDATE "user" SET balance = $1 WHERE id = $2
      SQL

    to_new_balance = to_balance + amount
    cnn.exec(<<-SQL, to_new_balance, to_user_id)
      UPDATE "user" SET balance = $1 WHERE id = $2
      SQL

    now = Time.utc

    transaction_id = cnn.query_one(<<-SQL, from_user_id, from_new_balance, to_user_id, to_new_balance, now, as: Int32)
      INSERT INTO "transaction" (
        from_id,
        from_new_balance,
        to_id,
        to_new_balance,
        time
      ) VALUES (
        $1, $2, $3, $4, $5
      ) RETURNING id
      SQL

    Result::SuccessfulTransaction.new(
      tx,
      "Transfer sucessful",
      transaction_id: transaction_id,
      from_user_balance: from_new_balance,
      to_user_balance: to_new_balance,
    )
  end

  def self.open(tx : ::DB::Transaction, discord_snowflake : Discord::Snowflake, username : String, avatar_url : String)
    now = Time.utc

    created_at = now
    balance = 0
    admin = false
    banned = false

    if discord_snowflake == Bot::OWNER_SNOWFLAKE
      admin = true
    end

    cnn = tx.connection

    preexisting_id = cnn.query_one?(<<-SQL, discord_snowflake.to_u64, as: Int32)
      SELECT id FROM discord_user WHERE snowflake = $1
      SQL

    if preexisting_id
      return Result::PreExistingUserAccount.new(tx, "You already have an user account associated with your Discord account")
    end

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

    return Result::NewUserAccount.new(tx, "User account created", user_id)
  end
end
