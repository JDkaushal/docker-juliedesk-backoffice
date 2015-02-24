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


Gmail.client_id = ENV['GOOGLE_CLIENT_ID']
Gmail.client_secret = ENV['GOOGLE_CLIENT_SECRET']
Gmail.refresh_token = ENV['GOOGLE_REFRESH_TOKEN']

Pusher.app_id = ENV['PUSHER_APP_ID']
Pusher.key = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']

DetectLanguage.configure do |config|
  config.api_key = ENV['DETECT_LANGUAGE_KEY']
end