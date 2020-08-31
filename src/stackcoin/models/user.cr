abstract class StackCoin::Models::User < StackCoin::Model
  TABLE = "\"user\""

  enum UserType
    Internal
    Bot
    Discord
  end

  abstract def insert(cnn : DB::Connection)
end

class StackCoin::Models::User::Full < StackCoin::Models::User
  property id : Int32?
  property created_at : Time
  @[::DB::Field(converter: StackCoin::Models::Converters::Database::Enum(StackCoin::Models::User::UserType).new)]
  property type : UserType
  property username : String
  property avatar_url : String
  property balance : Int32
  property last_given_dole : Time?
  property banned : Bool

  def initialize(@type, @username,
                 @avatar_url = "https://stackcoin.world/assets/default_avatar.png",
                 @balance = 0, @banned = false, @last_given_dole = nil,
                 @created_at = Time.utc, @id = nil)
  end

  def insert(cnn)
    query = <<-SQL
      INSERT INTO #{TABLE}
        (created_at, type, username, avatar_url, balance, last_given_dole, banned)
      VALUES
        ($1, $2, $3, $4, $5, $6, $7)
      RETURNING #{TABLE}.id
    SQL

    @id = cnn.query_one(
      query,
      args: [@created_at, @type, @username, @avatar_url, @balance, @last_given_dole, @banned],
      as: Int32
    )
  end

  def self.all(cnn)
    self.from_rs(cnn.query(<<-SQL))
      SELECT * FROM #{TABLE}
      SQL
  end
end
