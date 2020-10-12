require "http/server"

class StackCoin::Api::Internal
end

require "./internal/*"

class StackCoin::Api::Internal
  def self.not_found(r)
    r.status_code = 404
    r.content_type = "text/plain"
    r.print("Not found")
  end

  class SchemaExecuteInput
    include JSON::Serializable

    getter query : String
    getter variables : Hash(String, JSON::Any)?
    getter operation_name : String?
  end

  def self.run!
    schema = Gql.schema

    server = HTTP::Server.new do |context|
      resource = context.request.resource
      method = context.request.method

      r = context.response

      case resource
      when "/auth"
        unless method == "GET"
          next not_found(r)
        end

        if token = context.request.headers["Authorization"]?
          # TODO handle auth token
          # r.status_code = 401

          r.status_code = 200
          r.content_type = "application/json"
          r.print(<<-JSON)
            {
              "X-Hasura-Role": "user",
              "X-Hasura-User-ID": "1"
            }
            JSON
        else
          r.status_code = 200
          r.content_type = "application/json"
          r.print(<<-JSON)
            {
              "X-Hasura-Role": "anonymous"
            }
            JSON
        end
        next
      when "/graphql"
        unless method == "POST"
          next not_found(r)
        end

        headers = context.request.headers

        user_id = if header = headers["X-Hasura-User-ID"]?
                    header.to_i?
                  else
                    nil
                  end

        role = headers["X-Hasura-Role"]?

        c = Gql::Context.new(user_id, role)

        schema_execute_input = SchemaExecuteInput.from_json(context.request.body.not_nil!.gets_to_end)

        r.content_type = "application/json"

        r.print(schema.execute(
          schema_execute_input.query,
          schema_execute_input.variables,
          schema_execute_input.operation_name,
          c
        ))
        next
      else
      end

      not_found(r)
    end

    address = server.bind_tcp(4000)
    server.listen
  end
end
