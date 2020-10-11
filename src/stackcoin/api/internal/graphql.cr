require "graphql"

class StackCoin::Api::Internal::Gql
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
    def echo(str : String) : String
      str
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
