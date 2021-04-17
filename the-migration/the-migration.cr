puts "starting up."

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

RESERVE_USER_ID =                  1
DOLE            =                 10
JACKS_SNOWFLAKE = 178958252820791296
EPOCH           = Time.unix(1574467200)

puts "starting up.."

new_db = PG.connect("postgresql://postgres:password@localhost/stackcoin")
old_db = DB.open("sqlite3://./the-migration/old.db")

TOKEN     = "Bot #{ENV["STACKCOIN_DISCORD_TOKEN"]}"
CLIENT_ID = ENV["STACKCOIN_DISCORD_CLIENT_ID"].to_u64

discord_client = Discord::Client.new(token: TOKEN, client_id: CLIENT_ID)
discord_cache = Discord::Cache.new(discord_client)

puts "starting up..."

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

class NewDiscordUser
  include ::DB::Serializable

  def initialize(@id, @last_updated, @snowflake)
  end

  property id : Int32?
  property last_updated : Time
  property snowflake : String
end

class NewUser
  include ::DB::Serializable

  def initialize(@id, @created_at, @username, @avatar_url, @balance, @last_given_dole, @admin, @banned, @discord_user, @fixed_value)
  end

  property id : Int32?
  property created_at : Time
  property username : String
  property avatar_url : String
  property balance : Int32
  property last_given_dole : Time
  property admin : Bool
  property banned : Bool

  @[DB::Field(ignore: true)]
  property discord_user : NewDiscordUser

  @[DB::Field(ignore: true)]
  property to_transactions : Array(NewTransaction) = [] of NewTransaction
  property from_transactions : Array(NewTransaction) = [] of NewTransaction
  property doled_transactions : Array(NewTransaction) = [] of NewTransaction

  @[DB::Field(ignore: true)]
  property fixed_value : Int32?
end

class NewTransaction
  include ::DB::Serializable

  def initialize(@id, @from_id, @from_new_balance, @to_id, @to_new_balance, @amount, @time, @label)
  end

  property id : Int32?
  property from_id : Int32
  property from_new_balance : Int32
  property to_id : Int32
  property to_new_balance : Int32
  property amount : Int32
  property time : Time
  property label : String?
end

puts "quering old_db..."

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

puts "query'd old_db"

new_users = [] of NewUser
new_discord_users = [] of NewDiscordUser
special_case_epoch_users = [] of NewUser

snowflake_to_new_user = {} of String => NewUser

puts "parsing old_balance..."
old_balance.each_with_index do |old_balance, index|
  snowflake = old_balance.user_id
  balance = old_balance.bal

  old_ledger_from = old_ledger.select { |l| l.from_id == snowflake }.sort { |a, b| a.time <=> b.time }
  old_ledger_to = old_ledger.select { |l| l.to_id == snowflake }.sort { |a, b| a.time <=> b.time }
  old_benefit_for_user = old_benefit.select { |b| b.user_id == snowflake }.sort { |a, b| a.time <=> b.time }

  first_actions = [] of OldLedger | OldBenefit

  if first_old_ledger_from = old_ledger_from.first?
    first_actions << first_old_ledger_from
  end

  if first_old_ledger_to = old_ledger_to.first?
    first_actions << first_old_ledger_to
  end

  if first_old_benefit_for_user = old_benefit_for_user.first?
    first_actions << first_old_benefit_for_user
  end

  first_action = first_actions.sort { |a, b| a.time <=> b.time }.first?

  first_known_value = nil
  created_at = nil

  if first_action.is_a?(OldLedger)
    if first_action.from_id == snowflake
      first_known_value = first_action.from_bal + first_action.amount
    else
      first_known_value = first_action.to_bal - first_action.amount
    end
    created_at = first_action.time
  elsif first_action.is_a?(OldBenefit)
    first_known_value = first_action.user_bal - first_action.amount
    created_at = first_action.time
  else
    first_known_value = balance
    created_at = EPOCH # TODO don't be dis
  end

  sent = old_ledger_from.sum { |l| l.amount }
  received = old_ledger_to.sum { |l| l.amount }
  doled = old_benefit_for_user.sum { |b| b.amount }

  total = doled + received - sent

  cached = cache.discord_users[snowflake]?

  if cached.nil?
    discord_user = discord_cache.resolve_user(snowflake.to_u64)
    cached = DiscordUser.new(username: discord_user.username, avatar_url: discord_user.avatar_url)
    cache.discord_users[snowflake] = cached
  end

  username = cached[:username]
  avatar_url = cached[:avatar_url]

  last_given_dole = old_last_given_dole.find { |u| u.user_id == snowflake }.not_nil!.time
  admin = snowflake == JACKS_SNOWFLAKE.to_s
  banned = old_banned.includes?(snowflake)

  fixed_value = nil

  if total != balance
    fixed_value = first_known_value
    created_at = EPOCH
  end

  last_updated = Time.utc

  new_discord_user = NewDiscordUser.new(
    nil, last_updated, snowflake
  )
  new_discord_users << new_discord_user

  new_user = NewUser.new(
    nil, created_at, username, avatar_url, balance, last_given_dole, admin, banned, new_discord_user, fixed_value
  )
  new_users << new_user

  unless fixed_value.nil?
    special_case_epoch_users << new_user
  end

  snowflake_to_new_user[snowflake] = new_user
end
puts "parsed old_balance"

new_users.sort { |a, b| a.created_at <=> b.created_at }

# TODO for special EPOCH users, fix either here or later
new_users.each_with_index do |new_user, index|
  id = index + 2
  new_user.id = id
  new_user.discord_user.id = id
end

old_ledger.sort { |a, b| a.time <=> b.time }

new_transactions = [] of NewTransaction

puts "parsing transactions..."

special_case_epoch_users.each do |special_user|
  new_transaction = NewTransaction.new(
    nil,
    RESERVE_USER_ID,
    -1,
    special_user.id.not_nil!,
    special_user.fixed_value.not_nil!,
    special_user.fixed_value.not_nil!,
    EPOCH, # TODO be date of first ever action
    "Legacy accounts iniital value as transaction"
  )
  special_user.to_transactions << new_transaction
  new_transactions << new_transaction
end

old_benefit.each do |benefit|
  raise "NON-DOLE DOLE" if benefit.amount != DOLE

  new_user = snowflake_to_new_user[benefit.user_id]

  new_transaction = NewTransaction.new(
    nil,
    RESERVE_USER_ID,
    -1,
    new_user.id.not_nil!,
    benefit.user_bal,
    benefit.amount,
    benefit.time,
    "Legacy dole as transaction"
  )

  new_user.doled_transactions << new_transaction
  new_transactions << new_transaction
end

old_ledger.each_with_index do |old_transaction, index|
  from_user = snowflake_to_new_user[old_transaction.from_id]
  from_new_balance = old_transaction.from_bal

  to_user = snowflake_to_new_user[old_transaction.to_id]
  to_user_new_balance = old_transaction.to_bal

  amount = old_transaction.amount
  time = old_transaction.time

  new_transaction = NewTransaction.new(
    nil,
    from_user.id.not_nil!,
    from_new_balance,
    to_user.id.not_nil!,
    to_user_new_balance,
    amount,
    time,
    "Legacy transaction"
  )

  from_user.from_transactions << new_transaction
  to_user.to_transactions << new_transaction
  new_transactions << new_transaction
end

new_transactions.sort { |a, b| a.time <=> b.time }

puts "parsed transactions"

puts "validating transactions..."

new_users.each do |new_user|
  sent = new_user.from_transactions.sum { |l| l.amount }
  received = new_user.to_transactions.sum { |l| l.amount }
  doled = new_user.doled_transactions.sum { |d| d.amount }

  total = doled + received - sent

  if total != new_user.balance
    raise "#{new_user.username} calculated total: #{total}, real #{new_user.balance}"
  end
end

puts "transactions validated!"

puts "validating reserve user..."

reserve_user_transations = new_transactions.select { |t| t.from_id == RESERVE_USER_ID }

raise "assertion failed" unless special_case_epoch_users.size + old_benefit.size == reserve_user_transations.size

raise "assertion failed" unless reserve_user_transations.sum { |t| t.amount } == amount_in_circulation

reserve_user_transations.each do |transaction|
end

puts "validated reserve user"

File.write(CACHE_NAME, cache.to_pretty_json)
