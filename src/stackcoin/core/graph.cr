require "uuid"

require "../result"

class StackCoin::Core::Graph
  class Result < StackCoin::Result
    class File < Success
      getter file : ::File

      def initialize(message, @file)
        super(message)
      end
    end

    class NoSuchUserAccount < Failure
    end

    class NotEnoughDatapoints < Failure
    end
  end

  private class BalanceAtTime
    include ::DB::Serializable
    getter time : Time
    getter balance : Int32
    getter amount : Int32
  end

  def self.balance_over_time(cnn : ::DB::Connection, user_id : Int32?) : Result::Base
    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new("No user account to graph")
    end

    balance_over_time = BalanceAtTime.from_rs(cnn.query(<<-SQL, user_id))
      (
        SELECT time, to_new_balance as balance, amount FROM "transaction" WHERE to_id = $1
        UNION
        SELECT time, from_new_balance as balance, amount FROM "transaction" WHERE from_id = $1
      ) ORDER BY time
      SQL

    datapoints = 0
    reader, writer = IO.pipe

    balance_over_time.each do |b|
      datapoints += 1
      writer.puts("#{b.time},#{b.balance},#{b.amount}")
    end
    writer.close

    if datapoints <= 1
      return Result::NotEnoughDatapoints.new("Not enough datapoints!")
    end

    random = UUID.random
    image_filename = "/tmp/stackcoin/graph_#{user_id}_#{random}.png"
    title = "User ##{user_id} - #{Time.utc}"

    process = Process.new(
      "gnuplot",
      ["-e", "imagefilename='#{image_filename}';customtitle='#{title}'", "./src/stackcoin/gnuplot/balance_over_time.plt"],
      input: reader,
      output: Process::Redirect::Pipe,
      error: Process::Redirect::Pipe
    )

    stdout = process.output.gets_to_end
    stderr = process.error.gets_to_end

    raise stderr if stderr != ""

    Result::File.new("Balance over time graph", File.open(image_filename))
  end
end
