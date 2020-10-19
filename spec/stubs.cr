record MessageAuthor, id : Discord::Snowflake, username : String, avatar_url : String do
  def self.new(id, username, avatar_url)
    id = Discord::Snowflake.new(id.to_u64)
    new(id, username, avatar_url)
  end
end

record MessageStub, channel_id : Discord::Snowflake, guild_id : Discord::Snowflake, content : String, author : MessageAuthor do
  def self.new(channel_id, guild_id, content, author)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    new(channel_id, guild_id, content, author)
  end
end

record MessageWithEmbedStub, channel_id : Discord::Snowflake, guild_id : Discord::Snowflake, content : String, author : MessageAuthor, embed : Discord::Embed do
  def self.new(channel_id, guild_id, content, author, embed)
    channel_id = Discord::Snowflake.new(channel_id.to_u64)
    guild_id = Discord::Snowflake.new(guild_id.to_u64)
    new(channel_id, guild_id, content, author, embed)
  end
end

record DMStub, id : Discord::Snowflake do
  def self.new(id)
    id = Discord::Snowflake.new(id.to_u64)
    new(id)
  end
end

class MockClient
  INSTANCE = new

  # TODO class_property current_guild = CSBOIS_GUILD_SNOWFLAKE

  def create_message(channel_id : Discord::Snowflake, content : String)
    # TODO MessageStub.new(channel_id, @@current_guild, content)
  end

  def create_message(channel_id : Discord::Snowflake, content : String, embed : Discord::Embed)
    # TODO MessageWithEmbedStub.new(channel_id, @@current_guild, content, embed)
  end

  def create_dm(user_id : Discord::Snowflake)
    DMStub.new(0_u64)
  end
end

class MockCache
  INSTANCE = new

  def resolve_user(user_id : UInt64)
    MessageAuthor.new(user_id, "stub", "stub")
  end
end
