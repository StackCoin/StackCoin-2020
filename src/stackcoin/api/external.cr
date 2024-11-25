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
    if one_time_key = params[:one_time_key]
      result = Core::SessionStore.upgrade_one_time_to_real_session(one_time_key)

      if result.is_a?(Core::SessionStore::Result::NewSession)
        cookie = Core::SessionStore::Session.to_cookie(result.new_session_id)
        context.response.cookies << cookie

        context = render_plain("redirecting")

        context.response.status_code = 303
        context.response.headers["Location"] = "/"
        context
      else
        render_plain(result.message)
      end
    else
      render_plain("~") # TODO maybe redirect to login?
    end
  end
end

class StackCoin::Api::External::Default < BaseAction
  get "/"
  get "/*"

  call do |context|
    context = render_plain(<<-HTML
      <html>
        <head>
          <link rel="preconnect" href="https://rsms.me/">
          <link rel="stylesheet" href="https://rsms.me/inter/inter.css">
          <style>
            :root {
              font-family: Inter, sans-serif;
              font-feature-settings: 'liga' 1, 'calt' 1;
            }
            @supports (font-variation-settings: normal) {
              :root { font-family: InterVariable, sans-serif; }
            }
            body {
              margin: 2rem;
              font-size: 1.4rem;
            }
            .no-func {
              color: gray;
              font-style: italic;
            }

            img {
              width: 30rem;
              max-width: 100%;
            }

            main {
              max-width: 40rem;
              margin: 0 auto;
            }
          </style>
        </head>
        <body>
          <a href="/">
            <p align="center">
              <img src="https://i.imgur.com/ou12BG6.png">
            </p>
          </a>
          <main>
            <p>stackcoin</p>
            <p class="no-func">this website has no functionality, at the moment</p>
          </main>
        </body>
      </html>
    HTML
    )

    context.response.content_type = "text/html"
    context
  end
end
