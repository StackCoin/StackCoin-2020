require "json"

abstract class StackCoin::Model
  include ::DB::Serializable
  include JSON::Serializable
end

require "./models/*"
