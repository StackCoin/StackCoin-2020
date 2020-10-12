require "http/server"

abstract class StackCoin::Api
  def self.not_found(r)
    r.status_code = 404
    r.content_type = "text/plain"
    r.print("Not found")
  end
end

require "./api/*"
