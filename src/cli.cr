require "dotenv"
require "option_parser"

begin
  Dotenv.load
end

require "./stackcoin"

{Signal::INT, Signal::TERM}.each &.trap do
  puts("bye!")
  exit
end

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: stackcoin [arguments]"

  parser.on("-r", "--run", "Run StackCoin") do
    StackCoin.run!
    exit
  end

  parser.on("-f", "--fixtures", "Populate fixture data") do
    StackCoin.run_migrations
    StackCoin::Fixtures.populate
    exit
  end

  parser.on("-t", "--test-fixtures", "Populate fixture data, then rollback") do
    StackCoin.run_migrations
    StackCoin::Fixtures.populate(rollback: true)
    exit
  end

  parser.on("-n", "--nuke-database", "Nuke the database, and then run migrations") do
    StackCoin::DB.close
    db = PG.connect(StackCoin::DATABASE_CONNECTION_STRING_BASE)
    db.exec("DROP DATABASE #{StackCoin::POSTGRES_DB}")
    db.exec("CREATE DATABASE #{StackCoin::POSTGRES_DB}")
    StackCoin.run_migrations
    exit
  end

  parser.on("-m", "--dump-models", "Dump all models to json") do
    all_models = StackCoin::Models.all
    puts all_models.to_json
    exit
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

puts parser
