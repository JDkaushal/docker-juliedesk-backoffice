JULIE_ALIASES = ["julie@juliedesk.com", "julie.filhol@breega.com"]

JULIE_ALIASES_DATA = {
    "julie@juliedesk.com" => {
        id: "juliedesk",
        name: "Julie Desk",
        signature: "Cordialement, \n\nJulie\nIntelligence artificielle"
    },
    "julie.filhol@breega.com" => {
        id: "breega",
        name: "Julie FILHOL",
        signature: "Julie Filhol\nExecutive Assistant\n\n42 avenue Montaigne\n\n75008 Paris - France\n\nTel: +33 1 72 74 10 01\nFax: +33 1 72 74 10 02\n\nEmail: julie.filhol@breega.com\nWeb: www.breega.com"
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