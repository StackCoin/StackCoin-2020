class StackCoin::Core::Banned
  class Result < StackCoin::Result
    class NoSuchUserAccount < Failure
    end

    class NotAuthorized < Failure
    end

    class AlreadyBanned < Failure
    end

    class AlreadyUnbanned < Failure
    end

    class UserBanned < Success
    end

    class UserUnbanned < Success
    end
  end

  def self.ban(tx : ::DB::Transaction, invokee_id : Int32?, user_id : Int32?) : Result::Base
    unless invokee_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("You doesn't have a user account")
    end

    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("User doesn't have a user account")
    end

    cnn = tx.connection

    invokee_is_admin = cnn.query_one(<<-SQL, invokee_id, as: Bool)
      SELECT admin FROM "user" WHERE id = $1
      SQL

    unless invokee_is_admin
      return Result::NotAuthorized.new("Not authorized to ban users")
    end

    already_banned = cnn.query_one(<<-SQL, user_id, as: Bool)
      SELECT banned FROM "user" WHERE id = $1
      SQL

    if already_banned
      return Result::AlreadyBanned.new("User was already banned")
    end

    cnn.exec(<<-SQL, user_id)
      UPDATE "user" SET banned = TRUE WHERE id = $1
      SQL

    Result::UserBanned.new("User is now banned")
  end

  def self.unban(tx : ::DB::Transaction, invokee_id : Int32?, user_id : Int32?) : Result::Base
    unless invokee_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("You doesn't have a user account")
    end

    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("User doesn't have a user account")
    end

    cnn = tx.connection

    invokee_is_admin = cnn.query_one(<<-SQL, invokee_id, as: Bool)
      SELECT admin FROM "user" WHERE id = $1
      SQL

    unless invokee_is_admin
      return Result::NotAuthorized.new("Not authorized to unban users")
    end

    already_banned = cnn.query_one(<<-SQL, user_id, as: Bool)
      SELECT banned FROM "user" WHERE id = $1
      SQL

    unless already_banned
      return Result::AlreadyUnbanned.new("User was already unbanned")
    end

    cnn.exec(<<-SQL, user_id)
      UPDATE "user" SET banned = FALSE WHERE id = $1
      SQL

    Result::UserUnbanned.new("User is now unbanned")
  end

  def self.is_banned(cnn : ::DB::Connection, user_id : Int32?) : Bool?
    cnn.query_one?(<<-SQL, user_id, as: Bool)
      SELECT banned FROM "user" WHERE id = $1
      SQL
  end
end
