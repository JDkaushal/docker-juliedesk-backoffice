# REDIS is configured for HA using Sentinel
if ENV['REDIS_SENTINELS'].present? then

  # We transform 1-line env variable to a usable array for Redis connection
  # REDIS_SENTINELS env is as follow: server1:port1|server2:port2|...
  SENTINELS = []
  sentinels_split = ENV['REDIS_SENTINELS'].split("|");

  i = 0
  sentinels_split.each{|sentinel|
    s = sentinel.split(":");
    SENTINELS.insert(i,{ host: s[0], port: s[1].to_i });
    i = i + 1
  };

  REDIS_FOR_ACCOUNTS_CACHE = Redis.new(:url => ENV['REDIS_URL_FOR_ACCOUNTS_CACHE'], sentinels: SENTINELS, role: :master)
  DATA_CACHE_REDIS = Redis.new(:url => ENV['DATA_CACHE_REDIS_URL'], sentinels: SENTINELS, role: :master)
  RESQUE_REDIS = Redis.new(:url => ENV['RESQUE_REDIS_URL'], sentinels: SENTINELS, role: :master)

# Classic Standalone REDIS
else
  REDIS_FOR_ACCOUNTS_CACHE = Redis.new(:url => ENV['REDIS_URL_FOR_ACCOUNTS_CACHE'])
  DATA_CACHE_REDIS = Redis.new(:url => ENV['DATA_CACHE_REDIS_URL'])
  RESQUE_REDIS = Redis.new(:url => ENV['RESQUE_REDIS_URL'])
end