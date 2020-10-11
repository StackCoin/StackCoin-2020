require "http/server"

class StackCoin::Api::External
  def self.run!
    server = HTTP::Server.new do |context|
      resource = context.request.resource

      puts resource

      r = context.response
      case resource
      when "/discord-oauth"
        p "handle discord oauth"
      else
        r.status_code = 404
        r.content_type = "text/plain"
        r.print("Not found")
      end
    end

    address = server.bind_tcp(3000)
    server.listen
  end
end
