require "pg"
require "sqlite3"

new_db = PG.connect("postgresql://postgres:password@localhost/stackcoin")
old_db = DB.open("sqlite3://./the-migration/old.db")

EPOCH = Time.unix(1574467200)

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

JACKS_SNOWFLAKE = 178958252820791296

old_banned = old_db.query_all("select user_id from banned", as: String)
old_balance = old_db.query_all("select * from balance", as: OldBalance)
old_designated_channel = old_db.query_all("select * from designated_channel", as: OldDesignatedChannel)
old_token = old_db.query_all("select * from token", as: OldToken)
old_ledger = old_db.query_all("select * from ledger", as: OldLedger)
old_benefit = old_db.query_all("select * from benefit", as: OldBenefit)
old_last_given_dole = old_db.query_all("select * from last_given_dole", as: OldLastGivenDole)

old_balance.each_with_index do |old_balance, index|
  id = index

  # all of these are TODO
  created_at = EPOCH
  username = "TODO"
  avatar_url = "TODO"

  balance = old_balance.bal
  last_given_dole = old_last_given_dole.find { |u| u.user_id == old_balance.user_id }.not_nil!.time
  admin = old_balance.user_id == JACKS_SNOWFLAKE.to_s
  banned = old_banned.includes?(old_balance.user_id)

  new_user = NewUser.new(
    id, created_at, username, avatar_url, balance, last_given_dole, admin, banned
  )

  pp new_user
end
