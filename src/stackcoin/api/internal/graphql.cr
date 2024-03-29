require "graphql"

require "../../result"

class StackCoin::Api::Internal::Gql
  @[GraphQL::Object]
  class SuccessfulTransaction < Core::Bank::Result::SuccessfulTransaction
    include GraphQL::ObjectType

    def initialize(result)
      @message = result.message
      @name = result.name
      @success = result.success
      @transaction_id = result.transaction_id
      @from_user_balance = result.from_user_balance
      @to_user_balance = result.to_user_balance
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

  class Context < GraphQL::Context
    getter user_id : Int32?
    getter role : String?

    def initialize(@user_id, @role)
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
    def send(context : Context, id : Int32, amount : Int32) : SuccessfulTransaction
      unless context.user_id.is_a?(Int32)
        raise "Not authorized"
      end

      from_id = context.user_id

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
end
