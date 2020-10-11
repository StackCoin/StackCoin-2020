require "graphql"

require "../../result"

class StackCoin::Api::Internal::Gql
  @[GraphQL::Object]
  class SuccessfulTransaction < Core::Bank::Result::SuccessfulTransaction
    include GraphQL::ObjectType

    def initialize(result)
    end

    @[GraphQL::Field]
    def message : String
      @message
    end

    @[GraphQL::Field]
    def name : String
      @name
    end

    @[GraphQL::Field]
    def success : Bool
      @success
    end

    @[GraphQL::Field]
    def transaction_id : Int32
      @transaction_id
    end

    @[GraphQL::Field]
    def from_user_balance : Int32
      @from_user_balance
    end

    @[GraphQL::Field]
    def to_user_balance : Int32
      @to_user_balance
    end
  end

  @[GraphQL::Object]
  class Query
    include GraphQL::ObjectType
    include GraphQL::QueryType

    @[GraphQL::Field]
    def pid : Int64
      Process.pid
    end
  end

  @[GraphQL::Object]
  class Mutation
    include GraphQL::ObjectType
    include GraphQL::MutationType

    @[GraphQL::Field]
    def send(id : Int32, amount : Int32) : SuccessfulTransaction
      # TODO auth, set this value based on the input header
      from_id = 1

      result = nil
      DB.transaction do |tx|
        result = Core::Bank.transfer(tx, from_id, id, amount)
      end
      result = result.as(StackCoin::Result::Base)

      if !result.is_a?(Core::Bank::Result::SuccessfulTransaction)
        raise result.message
      end

      return SuccessfulTransaction.new(result)
    end
  end

  def self.schema
    GraphQL::Schema.new(Query.new, Mutation.new)
  end

  class SchemaExecuteInput
    include JSON::Serializable

    getter query : String
    getter variables : Hash(String, JSON::Any)?
    getter operation_name : String?
  end
end
