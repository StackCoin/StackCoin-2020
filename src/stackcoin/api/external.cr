require "runcobo"

class StackCoin::Api::External
  def self.run!
    Runcobo.start
  end
end

class StackCoin::Api::External::Auth < BaseAction
  get "/auth"
  query NamedTuple(one_time_key: String?)

  call do |context|
    expires = Time.utc + 2.days

    if one_time_key = params[:one_time_key]
      result = Core::SessionStore.upgrade_one_time_to_real_session(one_time_key)

      if result.is_a?(Core::SessionStore::Result::NewSession)
        cookie = Core::SessionStore::Session.to_cookie(result.new_session_id)
        context.response.cookies << cookie

        render_plain("TODO redirect") # TODO redirect
      else
        render_plain(result.message)
      end
    else
      render_plain("~") # TODO maybe redirect to login?
    end
  end
end
