require "../result"

class StackCoin::Core::SessionStore
  class Result < StackCoin::Result
  end

  # TODO back by database instead of in memory eventually
  class_property in_memory_session_store : Hash(String, Session?) = {} of String => Session?

  class Session
    property user_id : Int32
    property expires_at : Time
    property one_time_use : Bool

    def initialize(@user_id : Int32, @expires_at : Time, @one_time_use : Bool = false)
    end
  end

  def self.create(user_id : Int32, valid_for : Time::Span = 2.days, one_time_use : Bool = false)
    now = Time.utc
    expires_at = now + valid_for

    id = Random::Secure.hex

    session = Session.new(user_id, expires_at, one_time_use)

    in_memory_session_store[id] = session

    id
  end

  def self.create_new_from_existing(existing_session : Session, valid_for : Time::Span = 2.days)
    # create new

    # invalidate existing
  end

  def self.upgrade_one_time_to_real_session(one_time_key : String)
    if session = in_memory_session_store[one_time_key]?
      in_memory_session_store.delete(one_time_key)
      return "you're in"
    else
      return "nah"
    end
  end
end
