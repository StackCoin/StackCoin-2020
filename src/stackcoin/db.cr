module StackCoin
  DB = PG.connect(DATABASE_CONNECTION_STRING)

  def self.run_migrations
    Micrate::DB.connection_url = DATABASE_CONNECTION_STRING
    Micrate.up(DB)
  end
end
