class StackCoin::Core::Group
  class Result < StackCoin::Result
    class NoDirectMessage < Failure
    end

    class NoDesignatedChannel < Failure
    end

    class InvalidGroupChannel < Failure
    end

    class ValidGroupChannel < Success
    end
  end

  class_getter discord_guild_to_channel_cache : Hash(Discord::Snowflake, Discord::Snowflake) = {} of Discord::Snowflake => Discord::Snowflake

  def self.query_valid_channel(guild_id : Discord::Snowflake) : Discord::Snowflake?
    if channel_as_string = DB.query_one?(<<-SQL, guild_id, as: String)
      SELECT designated_channel_snowflake FROM "discord_guild" WHERE snowflake = $1
      SQL
      Discord::Snowflake.new(channel_as_string)
    end
  end

  def self.validate_group_channel(guild_id : Discord::Snowflake?, channel_id : Discord::Snowflake) : Result::Base
    unless guild_id.is_a?(Discord::Snowflake)
      return Result::NoDirectMessage.new("Can't access via direct message")
    end

    designated_channel = if discord_guild_to_channel_cache.includes?(guild_id)
                           discord_guild_to_channel_cache[guild_id]
                         else
                           query_valid_channel(guild_id)
                         end

    unless designated_channel && designated_channel == channel_id
      return Result::NoDesignatedChannel.new("No designated channel set")
    end

    Result::ValidGroupChannel.new("Valid group channel")
  end
end
