require 'rack-mini-profiler'

unless ENV['DISABLE_MINI_PROFILER']
  Rack::MiniProfiler.config.position = 'left'
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rails.application.middleware.swap(Rack::Deflater, Rack::MiniProfiler)
  Rails.application.middleware.swap(Rack::MiniProfiler, Rack::Deflater)
  
end