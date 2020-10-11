require "http/server"

class StackCoin::Api::Internal
  def self.run!
    server = HTTP::Server.new do |context|
      resource = context.request.resource

      puts resource

      r = context.response
      case resource
      when "/auth"
        puts "auth"
        p context
        # handle auth
        # var token = request.get('Authorization');

        if token = context.request.headers["Authorization"]?
          r.status_code = 401
        else
          r.status_code = 200
          r.content_type = "application/json"
          r.print(<<-JSON)
            {
              "X-Hasura-Role": "anonymous"
            }
            JSON
        end
      when "/graphql"
        puts "graphql"
        # handle gql
      else
        r.status_code = 404
        r.content_type = "text/plain"
        r.print("Not found")
      end
    end

    address = server.bind_tcp(4000)
    server.listen
  end
end
