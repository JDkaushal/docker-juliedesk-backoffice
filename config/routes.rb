Rails.application.routes.draw do
  root to: "messages_threads#index"



  resources :messages_threads, only: [:show, :index] do
    collection do
      get "index_with_import", action: :index_with_import, as: :index_with_import
    end
    member do
      post "archive", action: :archive, as: :archive
      post "split", action: :split, as: :split
      post "associate_to_account", action: :associate_to_account
      get "remove_event_link", action: :remove_event_link
      get "unlock", action: :unlock
      get "history", action: :history
    end
  end

  resources :julie_aliases, only: [:index, :create, :edit, :new, :show, :update]

  resources :messages, only: [:show] do
    member do
      get "classifying/:classification", action: :classifying, as: :classifying
      post "classifying/:classification", action: :classifying

      get "wait_for_preference_change", action: :wait_for_preference_change
      post "classify", action: :classify, as: :classify
      post "mark_as_read", action: :mark_as_read, as: :mark_as_read

      post "reply", action: :reply, as: :reply
      post "generate_threads", action: :generate_threads, as: :generate_threads

      get "attachments/:attachment_id", action: :get_attachment
    end
  end

  resources :julie_actions, only: [:show] do
    member do
      post "update", action: :update, as: :update
    end
  end

  namespace :review do
    resources :operators, only: [:show, :index] do
      collection do
        get "my_stats", action: :my_stats, as: :my_stats
      end
    end

    resources :messages_threads, only: [] do
      member do
        get "review", action: :review
        post "reviewed", action: :reviewed

        get "group_review", action: :group_review
        post "group_reviewed", action: :group_reviewed

        get "learn", action: :learn
        post "learnt", action: :learnt
      end

      collection do
        get "review_next", action: :review_next
        get "learn_next", action: :learn_next
        get "group_review_next", action: :group_review_next
      end
    end

    root to: "operators#index"
  end



  get "stats", controller: :stats, action: :index
  get "stats/volume", controller: :stats, action: :volume

  get "test/js" => "test#js"
  get "test/templates" => "test#templates"

  get "/auth/:provider/callback" => "application#omniauth_callback"

  post "pusher/auth/", to: "pusher#auth"
  post "pusher/webhooks/", to: "pusher#webhooks"

  post "webhooks/new_email", to: "webhooks#new_email"

  post "change_sound" => "application#change_sound"

  get "logout" => "application#logout", as: :logout
end
