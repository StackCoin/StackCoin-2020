require "json"

abstract class StackCoin::Model
  include ::DB::Serializable
  include JSON::Serializable
end

class StackCoin::Models
  include JSON::Serializable

  getter users : Array(Models::User::Full)

  def initialize(@users)
  end

  def self.all
    all_models = nil
    DB.transaction do |tx|
      all_models = all(tx.connection)
    end
    all_models
  end

  def self.all(cnn : ::DB::Connection)
    new(
      users: Models::User::Full.all(cnn)
    )
  end
end

module StackCoin::Models::Converters
  module Database
    class Enum(T)
      def from_rs(rs)
        T.parse(String.new(rs.read(Bytes)))
      end
    end
  end
end

require "./models/*"
