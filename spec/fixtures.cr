class Actor
  getter user_snowflake : Discord::Snowflake
  getter guild_snowflake : Discord::Snowflake
  getter username : String
  getter avatar_url : String
  getter author : MessageAuthor

  def initialize(@user_snowflake, @guild_snowflake, @username, @avatar_url)
    @author = MessageAuthor.new(@user_snowflake, @username, @avatar_url)
  end

  def say(message_content, command)
    parsed = StackCoin::Bot::Parser.parse(message_content).not_nil!
    message = MessageStub.new(@user_snowflake, @guild_snowflake, message_content, author)
    command.invoke(message, parsed)
  end

  JACK = new(
    user_snowflake: Discord::Snowflake.new(178958252820791296),
    guild_snowflake: CSBOIS_GUILD_SNOWFLAKE,
    username: "<i>jack arthur null</i>#7539",
    avatar_url: "https://cdn.discordapp.com/avatars/178958252820791296/30bfbbc587afd1e0eeaf85811df2e743.png?size=256"
  )

  STEVE = new(
    user_snowflake: Discord::Snowflake.new(534038548295450637),
    guild_snowflake: CSBOIS_GUILD_SNOWFLAKE,
    username: "Steve Oh?",
    avatar_url: "https://cdn.discordapp.com/avatars/534038548295450637/b397385735a75b456d6d2e2240c1c4e9.png?size=256"
  )

  STACK = new(
    user_snowflake: Discord::Snowflake.new(153935534207533056),
    guild_snowflake: CSBOIS_GUILD_SNOWFLAKE,
    username: "Koalas",
    avatar_url: "https://cdn.discordapp.com/avatars/153935534207533056/2806f65e5d073b75cb472e75dccdaaa9.png?size=256"
  )

  BOB = new(
    user_snowflake: Discord::Snowflake.new(231748115856752651),
    guild_snowflake: CSBOIS_GUILD_SNOWFLAKE,
    username: "dolekemp96",
    avatar_url: "https://cdn.discordapp.com/embed/avatars/3.png"
  )

  MITCH = new(
    user_snowflake: Discord::Snowflake.new(562052013878280233),
    guild_snowflake: CSBOIS_GUILD_SNOWFLAKE,
    username: "30 cent",
    avatar_url: "https://cdn.discordapp.com/avatars/562052013878280233/812c0be217e52f56e5308837988c6fe6.png?size=256"
  )

  NINT = new(
    user_snowflake: Discord::Snowflake.new(106162668032802816),
    guild_snowflake: CSBOIS_GUILD_SNOWFLAKE,
    username: "nint8835",
    avatar_url: "https://cdn.discordapp.com/avatars/106162668032802816/aa0651a5ceaefa7a9e30adbcbcd8449a.png?size=256"
  )

  YICK = new(
    user_snowflake: Discord::Snowflake.new(72069821960822784),
    guild_snowflake: JKE_GUILD_SNOWFLAKE,
    username: "Ninja Ricecakes",
    avatar_url: "https://cdn.discordapp.com/avatars/72069821960822784/04373d8d01b433e4565550ee2c6e576b.png?size=256"
  )

  BIGMAN = new(
    user_snowflake: Discord::Snowflake.new(163415804761735170),
    guild_snowflake: JKE_GUILD_SNOWFLAKE,
    username: "bigman69",
    avatar_url: "https://cdn.discordapp.com/avatars/163415804761735170/c637fda62ed2dfe05d2d13a73b2c2176.png?size=1024"
  )
end
