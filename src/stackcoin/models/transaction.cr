abstract class StackCoin::Models::Transaction < StackCoin::Model
  TABLE = "\"transaction\""

  abstract def insert(cnn : DB::Connection)
end

class StackCoin::Models::Transaction::Full < StackCoin::Models::Transaction
  property id : Int32?
  property from_id : Int32
  property from_new_balance : Int32
  property to_id : Int32
  property to_new_balance : Int32
  property time : Time
  property label : String?

  def initialize(@from_id, @from_new_balance, @to_id,
                 @to_new_balance, @id = nil, @time = Time.utc,
                 @label = nil)
  end

  def insert(cnn)
    query = <<-SQL
      INSERT INTO #{TABLE}
        (from_id, from_new_balance, to_id, to_new_balance, time, label)
      VALUES
        ($1, $2, $3, $4, $5, $6)
      RETURNING #{TABLE}.id
    SQL

    @id = cnn.query_one(
      query,
      args: [@from_id, @from_new_balance, @to_id, @to_new_balance, @time, @label],
      as: Int32
    )
  end

  def self.all(cnn)
    self.from_rs(cnn.query(<<-SQL))
      SELECT * FROM #{TABLE}
      SQL
  end
end

