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

    john = Models::User::Full.new(
      type: Models::User::UserType::Internal,
      username: "John Doe",
    )
    users << john

    dole_result = Core::StackCoinReserveSystem.dole(cnn, john)

    p dole_result

    jane = Models::User::Full.new(
      type: Models::User::UserType::Internal,
      username: "Jane Bar",
    )
    users << jane

    users.each do |user|
      user.insert(cnn)
    end

    transfer_result = Core::Bank.transfer(cnn, from: john, to: jane, amount: 10)

    p transfer_result

    pp users
  end
end
