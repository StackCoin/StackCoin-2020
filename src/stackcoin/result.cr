class StackCoin::Result
  class Base
    include JSON::Serializable

    getter message : String

    def initialize(@message)
    end

    def name
      self.class.name.split("::").last(1)[0]
    end
  end

  class Success < Base
    getter success : String

    def initialize(@message)
      @success = name
    end

    def initialize(tx, @message)
      @success = name
    end
  end

  class Failure < Base
    getter failure : String

    def initialize(@message)
      @failure = name
    end

    def initialize(tx, @message)
      @failure = name
      tx.rollback
    end
  end
end
