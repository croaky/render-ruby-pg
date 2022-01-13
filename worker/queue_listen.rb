require_relative "../lib/x"

class QueueOne
  def listen
    db = X::Database.new
    puts sql = "LISTEN queue_one_inserted"
    db.exec(sql)

    loop do
      conn.wait_for_notify do |_, _, job_id|
        job = conn.exec(<<~SQL, [job_id]).first
          SELECT
            job_name
          FROM
            queue_one
          WHERE
            id = $1
        SQL
        if job.nil?
          next
        end

        t = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        begin
          status =
            case job["job_name"]
            when "PrintJobID"
              puts job["id"]
            else
              "invalid job name"
            end
        rescue => _err
          # event = Sentry.capture_exception(err)
          # status = "error: Sentry event ID #{event.event_id}"
          status = "error"
        end

        db.exec(<<~SQL, [status, job["id"]])
          UPDATE
            queue_one
          SET
            status = $1,
            worked_at = now()
          WHERE
            id = $2
        SQL

        elapsed = "%.3f" % (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t)
        puts "#{elapsed}s queue_one id=#{job["id"]} job_name=#{job["job_name"]} status=#{status}"
      rescue => _err
        # Sentry.capture_exception(err)
      end
    end
  ensure
    puts sql = "UNLISTEN queue_one_inserted"
    db&.exec(sql)
    db&.close
  end
end

queues = [
  QueueOne.new
  # Queue::Two.new
].freeze

children = queues.map { |queue|
  fork {
    begin
      $stdout.sync = true
      queue.listen
    rescue SignalException
    end
  }
}

begin
  children.each { |pid| Process.wait(pid) }
rescue SignalException => sig
  if Signal.list.values_at("HUP", "INT", "KILL", "QUIT", "TERM").include?(sig.signo)
    children.each { |pid| Process.kill("KILL", pid) }
  end
end
