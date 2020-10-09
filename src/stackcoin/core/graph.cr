require "uuid"

require "../result"

class StackCoin::Core::Graph
  class Result < StackCoin::Result
    class File < Success
      getter file : ::File

      def initialize(tx, message, @file)
        super(tx, message)
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
    getter to_new_balance : Int32
    getter amount : Int32
  end

  def self.balance_over_time(tx : ::DB::Transaction, user_id : Int32?)
    unless user_id.is_a?(Int32)
      return Result::NoSuchUserAccount.new(tx, "No user account to graph")
    end

    balance_over_time = BalanceAtTime.from_rs(tx.connection.query(<<-SQL, user_id))
      SELECT time, to_new_balance, amount FROM "transaction"
      WHERE to_id = $1 ORDER BY time
      SQL

    p balance_over_time

    datapoints = 0
    reader, writer = IO.pipe

    balance_over_time.each do |b|
      datapoints += 1
      writer.puts("#{b.time},#{b.to_new_balance},#{b.amount}")
    end

    if datapoints <= 1
      return Result::NotEnoughDatapoints.new("Not enough datapoints!")
    end

    random = UUID.random
    image_filename = "/tmp/stackcoin/graph_#{user_id}_#{random}.png"
    title = "#{user_id} - #{Time.utc}"

    process = Process.new(
      "gnuplot",
      ["-e", "imagefilename='#{image_filename}';customtitle='#{title}'", "./src/stackcoin/gnuplot/balance_over_time.plt"],
      input: reader,
      output: Process::Redirect::Pipe,
      error: Process::Redirect::Pipe
    )

    stdout = process.output.gets_to_end
    stderr = process.error.gets_to_end

    puts stdout
    puts stderr

    raise stderr if stderr != ""

    Result::File.new(tx, "Balance over time graph", File.open(image_filename))
  end
end
