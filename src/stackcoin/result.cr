class StackCoin::Result
  class Base
    include JSON::Serializable

    property message : String

    def initialize(@message)
    end

    def name
      self.class.name.split("::").last(1)[0]
    end
  end

  class Success < Base
    property success : String

    def initialize(@message)
      @success = name
    end
  end

  class Failure < Base
    property failure : String

    def initialize(@message)
      @failure = name
    end
  end
end
