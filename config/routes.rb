Rails.application.routes.draw do
  root to: "messages_threads#index"

  resources :client_contacts, param: :client_email, only: [] do
    collection do
      post :synchronize
      get :fetch
      get :emails_suggestions
      get :fetch_one
    end
  end

  resources :messages_threads, only: [:show, :index] do
    collection do
      get "index_with_import", action: :index_with_import, as: :index_with_import
      get "search"
    end

    member do
      post "archive", action: :archive, as: :archive
      post "split", action: :split, as: :split
      post "associate_to_account", action: :associate_to_account
      post "remove_data", action: :remove_data
      get "remove_event_link", action: :remove_event_link
      get "unlock", action: :unlock
      get "history", action: :history
      get "preview", action: :preview
    end
  end

  resources :julie_aliases, only: [:index, :create, :edit, :new, :show, :update]

  resources :messages, only: [:show] do
    member do
      get "classifying/:classification", action: :classifying, as: :classifying
      post "classifying/:classification", action: :classifying

      post "classify", action: :classify, as: :classify

      post "reply", action: :reply, as: :reply
      post "generate_threads", action: :generate_threads, as: :generate_threads
      post "generate_threads_for_follow_up", action: :generate_threads_for_follow_up, as: :generate_threads_for_follow_up
    end
  end

  resources :julie_actions, only: [:show] do
    member do
      post "update", action: :update, as: :update
    end
  end

  namespace :admin do
    resources :operators, only: [:show, :index, :new, :create, :update, :edit] do
      member do
        post :disable, action: :disable, as: :disable
      end
    end


    get "parallel_run", controller: :parallel_run, action: :recap
    get "parallel_run/stats", controller: :parallel_run, action: :stats

    get "stats", controller: :stats, action: :main


    root to: "operators#index"
  end


  namespace :review do
    resources :operators, only: [:show, :index] do
      collection do
        get "my_stats", action: :my_stats, as: :my_stats
        get "messages_thread_ids_to_review", action: :messages_thread_ids_to_review
      end
    end

    resources :operators_presence, only: [:index] do
      collection do
        post "/add", action: :add
        post "/remove", action: :remove
        post "/reset_day", action: :reset_day
        post "/copy_day", action: :copy_day
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

        post "change_messages_thread_status", action: :change_messages_thread_status
      end

      collection do
        get "review_next", action: :review_next
        get "learn_next", action: :learn_next
        get "group_review_next", action: :group_review_next
      end
    end

    root to: "operators#index"
  end

  namespace :api do
    namespace :v1 do
      get "operators_count_at_time", controller: :operators_presences, action: :operators_count_at_time
      get "inbox_count", controller: :messages_threads, action: :inbox_count
      get "weekly_recap_data", controller: :messages_threads, action: :weekly_recap_data
      get "messages_thread_context", controller: :messages_threads, action: :messages_thread_context

      post "julie_aliases/synchronize", controller: :julie_aliases, action: :synchronize
    end
  end



  get "stats", controller: :stats, action: :index
  get "stats/volume", controller: :stats, action: :volume

  get "test/js" => "test#js"
  get "test/templates" => "test#templates"

  post "pusher/auth/", to: "pusher#auth"
  post "pusher/webhooks/", to: "pusher#webhooks"

  post "webhooks/new_email", to: "webhooks#new_email"

  post "change_sound" => "application#change_sound"

  get "logout" => "application#logout", as: :logout

  if ENV['STAGING_APP']
    namespace :staging do
      get "import_context_from_production", to: "messages_threads#import_context_from_production"

      get "get_attendees", to: "events#get_attendees"

      post "save_attendees", to: "events#save_attendees"
    end
  end

end
