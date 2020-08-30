class StackCoin::Fixtures
  def self.populate(rollback = false)
    DB.transaction do |tx|
      populate(tx.connection)

      tx.rollback if rollback
    end
  end

  def self.populate(cnn : ::DB::Connection)
    users = [] of Models::User

    now = Time.utc

    users << Models::User::Full.new(
      type: Models::User::UserType::Internal,
      username: "John Doe",
    )

    users.each do |user|
      user.insert(cnn)
    end

    pp users
  end
end
