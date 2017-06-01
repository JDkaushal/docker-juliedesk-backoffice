if ENV['PUSHER_APP_ID']
    Pusher.app_id = ENV['PUSHER_APP_ID']
    Pusher.key = ENV['PUSHER_KEY']
    Pusher.secret = ENV['PUSHER_SECRET']
elsif ENV['RED_SOCK_URL']
    RedSock.url = ENV['RED_SOCK_URL']
end
