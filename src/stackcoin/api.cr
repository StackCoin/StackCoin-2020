require "http/server"

class StackCoin::Api
end

require "./api/*"

class StackCoin::Api
  def self.run
    spawn(External.run!)
    spawn(Internal.run!)
  end
end
