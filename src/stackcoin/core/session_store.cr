require "../result"
require "uri"

class StackCoin::Core::SessionStore
  class Result < StackCoin::Result
    class NewSession < Success
      getter new_session_id : Int32

      def initialize(message, @new_session_id)
        super(message)
      end
    end

    class InvalidOneTimeUpgrade < Failure
    end

    class InvalidSession < Failure
    end
  end

  TINY_SESSION_LENGTH    = 5.minutes
  REGULAR_SESSION_LENGTH = 2.days

  # TODO back by database instead of in memory eventually
  class_property in_memory_session_store : Hash(String, Session?) = {} of String => Session?

  class Session
    property user_id : Int32
    property expires_at : Time
    property one_time_use : Bool

    def initialize(@user_id : Int32, @expires_at : Time, @one_time_use : Bool = false)
    end

    def self.one_time_link(id : String)
      URI.encode("#{STACKCOIN_SITE_BASE}/auth?one_time_key=#{id}")
    end

    def self.to_cookie(id : String)
      session = in_memory_session_store[id]

      HTTP::Cookie.new(
        name: STACKCOIN_SITE_COOKIE,
        value: id,
        expires: session.expires,
        http_only: true,
        secure: !DEV_MODE,
        path: "/",
        domain: STACKCOIN_SITE_DOMAIN,
      )
    end
  end

  def self.create(user_id : Int32, valid_for : Time::Span, one_time_use : Bool = false) : Tuple(String, Session)
    now = Time.utc
    expires_at = now + valid_for

    id = Random::Secure.hex

    session = Session.new(user_id, expires_at, one_time_use)

    in_memory_session_store[id] = session

    {id, session}
  end

  def self.create_new_from_existing(existing_session : Session, valid_for : Time::Span) : Result::Base
    is_old_session_valid = self.is_session_still_valid(existing_session_key)

    unless is_old_session_valid
      return Result::InvalidSession.new("Invalid session, cannot upgrade")
    end

    new_sesion_tuple = SessionStore.create(user_id, valid_for, one_time_use: true)

    in_memory_session_store.delete(one_time_key)

    return Result::NewSession.new("New session generated", new_session_id: id)
  end

  private def self.is_session_still_valid(session : Session) : Bool
    session.expires_at < Time.utc
  end

  private def self.is_session_still_valid(session_key : String) : Bool
    if session = in_memory_session_store[one_time_key]?
      is_session_still_valid(session)
    else
      false
    end
  end

  def self.upgrade_one_time_to_real_session(one_time_key : String) : Result::Base
    if session = in_memory_session_store[one_time_key]?
      unless session.one_time_use
        Result::InvalidOneTimeUpgrade.new("Can't upgrade a session that's already a non-one-time-use session to a new session")
      end

      return self.create_new_from_existing(session, valid_for: REGULAR_SESSION_LENGTH)
    else
      return Result::InvalidSession.new("Invalid session, cannot upgrade")
    end
  end
end
