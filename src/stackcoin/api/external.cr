require "runcobo"

class StackCoin::Api::External
end

class StackCoin::Api::External::Auth < BaseAction
  get "/auth"
  query NamedTuple(one_time_key: String?)

  call do
    expires = Time.utc + 2.days

    cookie = HTTP::Cookie.new(
      name: "_stackcoin_",
      value: "TODO",
      expires: expires,
      http_only: true,
      secure: false, # TODO true if prod
      # path: Session.config.path, # TODO configure
      # domain: Session.config.domain, # TODO configure
    )

    # p cookie

    # context.response.cookies << cookie

    if one_time_key = params[:one_time_key]
      result = Core::SessionStore.upgrade_one_time_to_real_session(one_time_key)
      render_plain(result)
    else
      render_plain("~")
    end
  end
end

class StackCoin::Api::External
  def self.run!
    Runcobo.start
  end
end
