require "json"

abstract class StackCoin::Model
  include ::DB::Serializable
  include JSON::Serializable

  class_getter table : String = ""

  macro polymorphic_one_from_value(value, type)
    SUPERCLASS_TABLE = {{ @type.superclass }}.table

    @@one_from_{{ type }}_query = <<-SQL
      SELECT * FROM #{@@table}
        INNER JOIN #{SUPERCLASS_TABLE} ON #{@@table}.id = #{SUPERCLASS_TABLE}.id
        WHERE #{@@table}.identifier = $1
      SQL

    def self.from_{{ value }}(cnn, value : {{ type }})
      cnn.query_one(@@one_from_{{ type }}_query, value, as: self)
    end
  end

  macro update_values(*args)
    {%
      function_name = args.reduce { |acc, str| acc + "_" + str}
      p function_name
    %}

    @@{{function_name}}_sql = <<-SQL
      UPDATE #{@@table} SET
      WHERE id = $
      SQL

    def update_{{function_name}}
      p @@{{function_name}}_sql
    end
    {{debug()}}
  end

  macro mixin
    @@all_query = <<-SQL
      SELECT * FROM #{@@table}
      SQL

    def self.all(cnn)
      self.from_rs(cnn.query(@@all_query))
    end
  end

  macro polymorphic_mixin
    @@superclass_table = {{ @type.superclass }}.table

    @@all_query = <<-SQL
      SELECT * FROM #{@@table}
        INNER JOIN #{@@superclass_table}
        ON #{@@table}.id = #{@@superclass_table}.id
      SQL

    def self.all(cnn)
      self.from_rs(cnn.query(@@all_query))
    end
  end
end

class StackCoin::Models
  include JSON::Serializable

  getter users : Array(Models::User)
  getter internal_users : Array(Models::InternalUser)

  def initialize(@users, @internal_users)
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
      users: Models::User.all(cnn),
      internal_users: Models::InternalUser.all(cnn)
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
