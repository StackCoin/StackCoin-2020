class StackCoin::Result
  class Base
    include JSON::Serializable

    getter message : String
    getter name : String
    getter success : Bool

    def initialize(@message, @success)
      @name = generate_name
    end

    def generate_name
      self.class.name.split("::").last(1)[0]
    end
  end

  class Success < Base
    def initialize(message)
      super(message, true)
    end
  end

  class Failure < Base
    def initialize(message)
      super(message, false)
    end
  end
end
