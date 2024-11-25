class StackCoin::Core::Group
  class Result < StackCoin::Result
    class NoDirectMessage < Failure
    end

    class NoDesignatedChannel < Failure
    end

    class InvalidGroupChannel < Failure
    end

    class NoSuchUserAccount < Failure
    end

    class NotAuthorized < Failure
    end

    class ValidChannel < Success
    end

    class ValidGroupChannel < ValidChannel
    end

    class ValidDirectMessage < ValidChannel
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
      return Result::ValidDirectMessage.new("Valid direct message")
    end

    designated_channel = if discord_guild_to_channel_cache.includes?(guild_id)
                           discord_guild_to_channel_cache[guild_id]
                         else
                           query_valid_channel(guild_id)
                         end

    unless designated_channel
      return Result::NoDesignatedChannel.new("No designated channel set")
    end

    unless designated_channel == channel_id
      return Result::NotAuthorized.new("Incorrect channel for messages, please use #{channel_id}")
    end

    Result::ValidGroupChannel.new("Valid group channel")
  end

  def self.set_group_channel(
    tx : ::DB::Transaction,
    invokee_id : Int32?,
    guild_id : Discord::Snowflake,
    channel_id : Discord::Snowflake
  )
    unless invokee_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("You don't have a user account")
    end

    cnn = tx.connection

    invokee_is_admin = cnn.query_one(<<-SQL, invokee_id, as: Bool)
      SELECT admin FROM "user" WHERE id = $1
      SQL

    unless invokee_is_admin
      return Result::NotAuthorized.new("Not authorized to set the group channel")
    end

    discord_guild_exists = cnn.query_one(<<-SQL, guild_id, as: Bool)
      SELECT EXISTS(SELECT 1 FROM "discord_guild" WHERE snowflake = $1)
      SQL

    unless discord_guild_exists
      guild = Bot::INSTANCE.cache.resolve_guild(guild_id)
      cnn.exec(<<-SQL, guild_id, guild.name, guild.icon_url, channel_id, Time.utc)
        INSERT INTO "discord_guild" (
          snowflake, name, icon_url, designated_channel_snowflake, last_updated
        ) VALUES (
          $1, $2, $3, $4, $5
        )
        SQL
    end

    cnn.exec(<<-SQL, channel_id, guild_id)
      UPDATE "discord_guild" SET designated_channel_snowflake = $1 WHERE snowflake = $2
      SQL

    Result::Success.new("Channel set to <##{channel_id}>")
  end
end
