Rails.application.routes.draw do
  root to: "dashboard#dashboard"

  resources :events, only: [:show, :index] do
    member do
      post "classify", controller: :events, action: :classify, as: :classify
    end
  end

  resources :emails, only: [:show, :index] do
    member do
      post "classify", controller: :events, action: :classify, as: :classify
    end
  end

  namespace :api do
    get "classified_events", controller: :events, action: :classified_events
  end
end
