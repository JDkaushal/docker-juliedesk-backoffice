require 'rack-mini-profiler'

unless ENV['DISABLE_MINI_PROFILER']
  Rack::MiniProfiler.config.position = 'left'
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rails.application.middleware.delete(Rack::MiniProfiler)
  Rails.application.middleware.insert_after(Rack::Deflater, Rack::MiniProfiler)
end