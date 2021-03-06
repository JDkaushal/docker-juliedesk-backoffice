class HealthcheckController < ApiController
  skip_before_action :authenticate

  def check

    # If no signalisation file is present, answer with a HTTP 200
    #
    # Server will be temporarly deactivated from loadbalancers if :
    # - a signalisation file is present (server is in deployment mode). This check will answer a 503
    # - the application is down (connection error, ...), ruby will return the app statuscode
    # - timeout has been reached (app is slow because it is starting/server is busy, app has crashed...)

    status_code = :ok
    if File.exist?('tmp/pids/deploy_in_progress') then
      status_code = :service_unavailable
    end

    head status_code
  end


  def raise
    Kernel.raise 'Error raised intentionnaly'
  end
end