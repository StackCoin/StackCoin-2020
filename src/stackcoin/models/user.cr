class StackCoin::Models::User < StackCoin::Model
  enum UserType
    Internal
    Bot
    Discord
  end

  class_getter table : String = "\"user\""
  mixin

  property id : Int32?
  property created_at : Time
  @[::DB::Field(converter: StackCoin::Models::Converters::Database::Enum(StackCoin::Models::User::UserType).new)]
  property type : UserType
  property username : String
  property avatar_url : String
  property balance : Int32
  property last_given_dole : Time?
  property admin : Bool
  property banned : Bool

  update_values(balance)

  def initialize(@type, @username,
                 @avatar_url = "https://stackcoin.world/assets/default_avatar.png",
                 @balance = 0, @admin = false, @banned = false,
                 @last_given_dole = nil, @created_at = Time.utc,
                 @id = nil)
  end

  def insert(cnn)
    query = <<-SQL
      INSERT INTO "user"
        (created_at, type, username, avatar_url, balance, last_given_dole, admin, banned)
      VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING "user".id
    SQL

    @id = cnn.query_one(
      query,
      args: [@created_at, @type, @username, @avatar_url, @balance, @last_given_dole, @admin, @banned],
      as: Int32
    )
  end
end

class StackCoin::Models::InternalUser < StackCoin::Models::User
  class_getter table : String = "\"internal_user\""
  polymorphic_mixin

  property identifier : String
  polymorphic_one_from_value identifier, String

  def insert(cnn)
    raise Exceptions::NotImplemented.new
  end

  def initialize(@identifier, @username, @type = UserType::Internal,
                 @avatar_url = "https://stackcoin.world/assets/default_avatar.png",
                 @balance = 0, @admin = false, @banned = false,
                 @last_given_dole = nil, @created_at = Time.utc,
                 @id = nil)
  end
end
