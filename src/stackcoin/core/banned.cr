class StackCoin::Core::Banned
  class Result < StackCoin::Result
    class AlreadyBanned < Failure
    end

    class AlreadyUnbanned < Failure
    end

    class UserBanned < Success
    end

    class UserUnbanned < Success
    end
  end

  def self.ban(tx : ::DB::Transaction, user_id : Int32?)
    cnn = tx.connection

    already_banned = cnn.query_one(<<-SQL, user_id, as: Bool)
      SELECT banned FROM "user" WHERE id = $1
      SQL

    if already_banned
      Result::AlreadyBanned.new("User was already banned")
    end

    cnn.exec(<<-SQL, user_id)
      UPDATE "user" SET banned = TRUE WHERE id = $1
      SQL

    Result::UserBanned.new("User is now banned")
  end

  def self.unban(tx : ::DB::Transaction, user_id : Int32?)
    cnn = tx.connection

    already_banned = cnn.query_one(<<-SQL, user_id, as: Bool)
      SELECT banned FROM "user" WHERE id = $1
      SQL

    unless already_banned
      Result::AlreadyUnbanned.new("User was already unbanned")
    end

    cnn.exec(<<-SQL, user_id)
      UPDATE "user" SET banned = FALSE WHERE id = $1
      SQL

    Result::UserUnbanned.new("User is now unbanned")
  end

  def self.is_banned(user_id : Int32?)
  end
end
