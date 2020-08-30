require "micrate"
require "pg"
require "dotenv"

begin
  Dotenv.load
end

Micrate::DB.connection_url = "#{ENV["STACKCOIN_DATABASE_CONNECTION_STRING_BASE"]}/#{ENV["POSTGRES_DB"]}"
Micrate::Cli.run
