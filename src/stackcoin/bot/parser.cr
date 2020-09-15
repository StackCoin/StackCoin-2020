class StackCoin::Bot::Parser
  class Error < Exception
    def initialize(@reason : String)
      super
    end

    def message
      @reason
    end
  end

  struct Argument
    def initialize(@raw : String)
    end

    def to_s
      @raw
    end

    def to_i
      to_i? || raise Error.new(%(`#{@raw}` is not a valid integer))
    end

    def to_i?
      @raw.to_i?
    end

    def to_f
      to_f? || raise Error.new(%(`#{@raw}` is not a valid float))
    end

    def to_f?
      @raw.to_f?
    end

    def to_bool
      value = to_bool?
      raise Error.new(%(`#{@raw}` is not a valid bool (true/false, yes/no))) if value.nil?
      value
    end

    def to_bool?
      case @raw
      when "true", "yes", "yep", "yeet", "y"
        true
      when "false", "no", "nope", "nah", "n"
        false
      else
        nil
      end
    end

    def to_mention?
      mentions = Discord::Mention.parse(@raw)
      if mentions.size == 1
        return mentions.first
      else
        nil
      end
    end

    def to_mention
      to_mention? || raise Error.new(%(`#{@raw}` is not a valid mention))
    end

    def to_mention?
      Discord::Mention.parse(@raw).first?
    end

    def to_user_mention
      to_user_mention? || raise Error.new(%(`#{@raw}` is not a valid user mention))
    end

    def to_user_mention?
      to_mention?.as?(Discord::Mention::User)
    end

    def to_snowflake
      to_snowflake? || raise Error.new(%(`#{@raw}` is not a valid snowflake))
    end

    def to_snowflake?
      if value = @raw.to_u64?
        Discord::Snowflake.new(value)
      else
        nil
      end
    end
  end

  class ParsedCommand
    getter command : String
    getter arguments : Array(Argument)

    def initialize(@command : String, @arguments : Array(Argument))
    end

    def [](index : Int32)
      @arguments[index]? || raise Error.new("not enough arguments")
    end
  end

  def self.parse(string : String)
    parser = new(string)

    return if !parser.saw_prefix

    command = parser.read_argument.to_s

    arguments = Array(Argument).new

    parser.parse do |parsed|
      case parsed
      when Argument
        arguments << parsed
      end
    end

    ParsedCommand.new(command, arguments)
  end

  def initialize(string : String)
    @reader = Char::Reader.new(string)
  end

  def saw_prefix
    index = 0

    while @reader.has_next?
      case @reader.current_char
      when ' '
        @reader.next_char
      else
        char = @reader.current_char.downcase

        unless char == PREFIX[index]
          return false
        end

        index += 1
        @reader.next_char

        return true if index == PREFIX.size
      end
    end

    false
  end

  def parse
    while @reader.has_next?
      case @reader.current_char
      when ' '
        @reader.next_char
      else
        value = read_argument
        yield Argument.new(value)
      end
    end
  end

  def read_argument
    quoted = false
    String.build do |string|
      while true
        case @reader.current_char
        when ' '
          if quoted
            string << ' '
            @reader.next_char
          else
            break
          end
        when '"'
          @reader.next_char
          if quoted
            break
          else
            quoted = true
          end
        else
          break unless @reader.has_next?
          string << @reader.current_char
          @reader.next_char
        end
      end
    end
  end
end
