Rails.application.routes.draw do
  root to: "messages_threads#index"

  resources :events, only: [:show, :index] do
    member do
      post "classify", controller: :events, action: :classify, as: :classify
    end
  end

  resources :messages_threads, only: [:show, :index] do
    collection do
      get "index_with_import", action: :index_with_import, as: :index_with_import
    end
    member do
      post "archive", action: :archive, as: :archive
      post "split", action: :split, as: :split
      post "associate_to_account", action: :associate_to_account
      get "remove_event_link", action: :remove_event_link
    end
  end

  resources :messages, only: [:show] do
    member do
      get "classifying/:classification", action: :classifying, as: :classifying
      post "classify", action: :classify, as: :classify
      post "mark_as_read", action: :mark_as_read, as: :mark_as_read

      post "reply", action: :reply, as: :reply
      post "generate_threads", action: :generate_threads, as: :generate_threads
    end
  end

  resources :julie_actions, only: [:show] do
    member do
      post "update", action: :update, as: :update
    end
  end

  namespace :api do
    get "classified_events", controller: :events, action: :classified_events
  end

  get "stats", controller: :stats, action: :index

  get "test/js" => "test#js"
  get "test/templates" => "test#templates"

  get "/auth/:provider/callback" => "application#omniauth_callback"

  post "pusher/auth/", to: "pusher#auth"

  post "webhooks/new_email", to: "webhooks#new_email"
end
