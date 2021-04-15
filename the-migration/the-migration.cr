require "dotenv"
require "discordcr"
require "pg"
require "sqlite3"

begin
  Dotenv.load
end

alias DiscordUser = NamedTuple(username: String, avatar_url: String)

class Cache
  property discord_users : Hash(String, DiscordUser)
  include JSON::Serializable

  def initialize(@discord_users)
  end

  def self.clean
    new(Hash(String, DiscordUser).new)
  end
end

CACHE_NAME  = "./the-migration/cache.json"
CLEAN_CACHE = false

if CLEAN_CACHE
  File.write(CACHE_NAME, Cache.clean.to_pretty_json)
end

cache_file = File.read(CACHE_NAME)
cache = Cache.from_json(cache_file)

JACKS_SNOWFLAKE = 178958252820791296
EPOCH           = Time.unix(1574467200)

new_db = PG.connect("postgresql://postgres:password@localhost/stackcoin")
old_db = DB.open("sqlite3://./the-migration/old.db")

TOKEN     = "Bot #{ENV["STACKCOIN_DISCORD_TOKEN"]}"
CLIENT_ID = ENV["STACKCOIN_DISCORD_CLIENT_ID"].to_u64

discord_client = Discord::Client.new(token: TOKEN, client_id: CLIENT_ID)
discord_cache = Discord::Cache.new(discord_client)

class OldBalance
  include ::DB::Serializable
  property user_id : String
  property bal : Int32
end

class OldDesignatedChannel
  include ::DB::Serializable
  property guild_id : String
  property channel_id : String
end

class OldToken
  include ::DB::Serializable
  property user_id : String
  property token : String
end

class OldLedger
  include ::DB::Serializable
  property id : Int32
  property from_id : String
  property from_bal : Int32
  property to_id : String
  property to_bal : Int32
  property amount : Int32
  property time : Time
end

class OldBenefit
  include ::DB::Serializable
  property id : Int32
  property user_id : String
  property user_bal : Int32
  property amount : Int32
  property time : Time
end

class OldLastGivenDole
  include ::DB::Serializable
  property user_id : String
  property time : Time
end

class NewUser
  include ::DB::Serializable

  def initialize(@id, @created_at, @username, @avatar_url, @balance, @last_given_dole, @admin, @banned)
  end

  property id : Int32
  property created_at : Time
  property username : String
  property avatar_url : String
  property balance : Int32
  property last_given_dole : Time
  property admin : Bool
  property banned : Bool
end

class NewDiscordUser
  include ::DB::Serializable

  def initialize(@id, @last_updated, @snowflake)
  end

  property id : Int32
  property last_updated : Time
  property snowflake : String
end

amount_in_circulation = old_db.query_one(<<-SQL, as: Int64)
  SELECT SUM(bal) FROM balance
  SQL

old_banned = old_db.query_all("select user_id from banned", as: String)
old_balance = old_db.query_all("select * from balance", as: OldBalance)
old_designated_channel = old_db.query_all("select * from designated_channel", as: OldDesignatedChannel)
old_token = old_db.query_all("select * from token", as: OldToken)
old_ledger = old_db.query_all("select * from ledger", as: OldLedger)
old_benefit = old_db.query_all("select * from benefit", as: OldBenefit)
old_last_given_dole = old_db.query_all("select * from last_given_dole", as: OldLastGivenDole)

old_balance.each_with_index do |old_balance, index|
  id = index # TODO set id based on created_at

  # all of these are TODO
  # TODO infer from earliest transaction, EPOCH if special user that had bal before dole was created
  created_at = EPOCH
  # TODO verify if the balance before and after is the same
  balance = 0 # old_balance.bal

  cached = cache.discord_users[old_balance.user_id]?

  if cached.nil?
    discord_user = discord_cache.resolve_user(old_balance.user_id.to_u64)
    cached = DiscordUser.new(username: discord_user.username, avatar_url: discord_user.avatar_url)
    cache.discord_users[old_balance.user_id] = cached
  end

  username = cached[:username]
  avatar_url = cached[:avatar_url]

  last_given_dole = old_last_given_dole.find { |u| u.user_id == old_balance.user_id }.not_nil!.time
  admin = old_balance.user_id == JACKS_SNOWFLAKE.to_s
  banned = old_banned.includes?(old_balance.user_id)

  new_user = NewUser.new(
    id, created_at, username, avatar_url, balance, last_given_dole, admin, banned
  )

  last_updated = EPOCH # TODO
  snowflake = old_balance.user_id

  new_discord_user = NewDiscordUser.new(
    id, last_updated, snowflake
  )

  pp new_user, new_discord_user
end

File.write(CACHE_NAME, cache.to_pretty_json)
