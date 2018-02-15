JdAuth.configure do |configuration|
  configuration.redis_url = ENV['JD_AUTH_REDIS']
  configuration.application_resource_id = ENV['JD_AUTH_APPLICATION_RESOURCE_ID']
  configuration.application_resource_encryption_key = ENV['JD_AUTH_APPLICATION_RESOURCE_ENCRYPTION_KEY']
  configuration.host = ENV['JD_AUTH_HOST']
  configuration.login_path = "/login"
end