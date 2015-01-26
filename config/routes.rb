Rails.application.routes.draw do
  root to: "messages_threads#index"

  resources :events, only: [:show, :index] do
    member do
      post "classify", controller: :events, action: :classify, as: :classify
    end
  end

  resources :messages_threads, only: [:show, :index] do
    member do
      post "archive", action: :archive, as: :archive
    end
  end

  resources :messages, only: [:show] do
    collection do
      get "next_to_classify", action: :next_to_classify, as: :next_to_classify
    end
    member do
      get "classifying/:classification", action: :classifying, as: :classifying
      get "process_actions", action: :process_actions, as: :process_actions
      post "classify", action: :classify, as: :classify
      post "reply", action: :reply, as: :reply
    end
  end

  resources :julie_actions, only: [] do
    member do
      post "update", action: :update, as: :update
    end
  end

  namespace :api do
    get "classified_events", controller: :events, action: :classified_events
  end
end
