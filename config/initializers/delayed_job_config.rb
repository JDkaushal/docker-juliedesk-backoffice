Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 1
Delayed::Worker.max_attempts = 0
Delayed::Worker.max_run_time = 5.minutes


module Delayed
  module Plugins
    class ErrorNotifier < Plugin

      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, *args, &block|
          begin
            # Forward the call to the next callback in the callback chain
            block.call(job, *args)
          rescue Exception => error
            p "WORKER FAILED", {
                :error_class => error.class.name,
                :error_message => "#{error.class.name}: #{error.message}",
                :backtrace => error.backtrace,
                :parameters => {
                    :failed_job => job.inspect
                }
            }
            # Make sure we propagate the failure!
            raise error
          end
        end
      end

    end
  end
end

Delayed::Worker.plugins << Delayed::Plugins::ErrorNotifier