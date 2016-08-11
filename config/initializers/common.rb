JULIE_ALIASES = ["julie@juliedesk.com", "julie.filhol@breega.com", "julie@hourlynerd.com"]

JULIE_ALIASES_DATA = {
    "julie@juliedesk.com" => {
        id: "juliedesk",
        name: "Julie Desk"
    },
    "julie.filhol@breega.com" => {
        id: "breega",
        name: "Julie FILHOL"
    },
    "julie@hourlynerd.com" => {
        id: "hourlynerd",
        name: "Julie Desk"
    }
}

if ENV['PUSHER_APP_ID']
    Pusher.app_id = ENV['PUSHER_APP_ID']
    Pusher.key = ENV['PUSHER_KEY']
    Pusher.secret = ENV['PUSHER_SECRET']
elsif ENV['RED_SOCK_URL']
    RedSock.url = ENV['RED_SOCK_URL']
end
