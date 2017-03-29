require 'resque/server'

Resque.redis = RESQUE_REDIS
begin
  Resque.logger = Logger.new(Rails.root.join('log', "resque.#{Rails.env}.log"))
rescue 
end


Resque::Server.use(Rack::Auth::Basic) do |user, password|
  operator = Operator.find_by(email: user, privilege: Operator::PRIVILEGE_ADMIN)
  operator && operator.password_correct?(password)
end

module Resque
  class Worker

    def work(interval = 5.0, &block)
      interval = Float(interval)
      $0 = "resque: Starting"
      startup

      loop do
        break if shutdown?

        begin
          if not paused? and job = reserve
            log_with_severity :info, "got: #{job.inspect}"
            job.worker = self

            working_on job

            procline "Processing #{job.queue} since #{Time.now.to_i} [#{job.payload_class_name}]"
            if @child = fork(job)
              srand # Reseeding
              procline "Forked #{@child} at #{Time.now.to_i}"
              begin
                Process.waitpid(@child)
              rescue SystemCallError
                nil
              end
              job.fail(DirtyExit.new("Child process received unhandled signal #{$?.stopsig}")) if $?.signaled?
            else
              unregister_signal_handlers if will_fork? && term_child
              begin

                reconnect if will_fork?
                perform(job, &block)

              rescue Exception => exception
                report_failed_job(job,exception)
              end

              if will_fork?
                run_at_exit_hooks ? exit : exit!
              end
            end

            done_working
            @child = nil
          else
            break if interval.zero?
            log_with_severity :debug, "Sleeping for #{interval} seconds"
            procline paused? ? "Paused" : "Waiting for #{queues.join(',')}"
            sleep interval
          end

        rescue Redis::CannotConnectError => e
          reconnect_extended if will_fork?
          if job.present?
            perform(job, &block)
          end
        end
      end

      unregister_worker
    rescue Exception => exception
      unless exception.class == SystemExit && !@child && run_at_exit_hooks
        log_with_severity :error, "Failed to start worker : #{exception.inspect}"

        unregister_worker(exception)
      end
    end

    # Attempt to reconnect to redis in case the server goes down, exponential retries on a 7 minutes period
    def reconnect_extended
      tries = 0

      begin
        log_with_severity :info, "Trying reconnecting to redis... attempt ##{tries + 1}"
        redis.client.reconnect
      rescue Redis::BaseConnectionError
        if (tries += 1) <= 30
          log_with_severity :error, "Error reconnecting to Redis; retrying"
          sleep(tries)
          retry
        else
          log_with_severity :error, "Error reconnecting to Redis; quitting"
          raise
        end
      end
    end
  end
end