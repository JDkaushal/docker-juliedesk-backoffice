Rails.application.routes.draw do
  root to: "dashboard#dashboard"

  get "events", controller: :events, action: :index, as: :events_url
  get "events/:event_id", controller: :events, action: :show
  post "events/:event_id/classify", controller: :events, action: :classify

  get "emails", controller: :emails, action: :index, as: :emails_url
  get "emails/:email_id", controller: :emails, action: :show
  post "emails/:email_id/classify", controller: :emails, action: :classify
end
