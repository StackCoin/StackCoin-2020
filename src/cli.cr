require "dotenv"

begin
  Dotenv.load
end

require "./stackcoin"

{Signal::INT, Signal::TERM}.each &.trap do
  puts("bye!")
  exit
end

StackCoin.run!
