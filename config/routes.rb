require 'resque/server'

Rails.application.routes.draw do
  mount Resque::Server, :at => "/resque"
  
  root to: "messages_threads#index"

  resources :client_contacts, param: :client_email, only: [] do
    collection do
      post :synchronize
      post :ai_get_company_name

      get :ai_parse_contact_civilities
      get :fetch
      get :emails_suggestions
      get :fetch_one
    end
  end


  get 'performance', controller: :performance, action: :show
  get 'performance/download_1mo', controller: :performance, action: :download_1mo
  post 'performance/upload', controller: :performance, action: :upload
  get 'performance/blank', controller: :performance, action: :blank


  resources :event_operator_interactions, only: [:create]

  resources :geo_zones, only: [:index] do
    collection do
      get :autocomplete
    end
  end


  resources :messages_threads, only: [:show, :index] do
    collection do
      get "index_with_import", action: :index_with_import, as: :index_with_import
      get "index_with_import_ai", action: :index_with_import_ai, as: :index_with_import_ai
      get "search"

      # Route used to test memory consumption (is also the root of the app)
      get 'index'
    end

    member do
      post "archive", action: :archive, as: :archive
      post "split", action: :split, as: :split
      post "associate_to_account", action: :associate_to_account
      post "remove_data", action: :remove_data
      post :set_to_be_merged
      get "remove_event_link", action: :remove_event_link
      get "unlock", action: :unlock
      get "history", action: :history
      get "preview", action: :preview

    end
  end

  get "accounts", controller: :accounts, action: :show

  get "accounts/autocomplete", controller: :accounts, action: :autocomplete

  resources :julie_aliases, only: [:index, :create, :edit, :new, :show, :update]

  resources :messages, only: [:show] do
    member do
      get "classifying/:classification", action: :classifying, as: :classifying
      get :main_interpretation
      post "classifying/:classification", action: :classifying

      post "classify", action: :classify, as: :classify

      post "let_ai_process", action: :let_ai_process

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

    get :production, controller: :stats, action: :production

    resources :features, only: [:new, :create, :edit, :update, :index, :destroy]

    get "parallel_run", controller: :parallel_run, action: :recap
    get "parallel_run/stats", controller: :parallel_run, action: :stats

    get "stats", controller: :stats, action: :main

    put "settings", controller: :my_settings, action: :update

    get "calendar_viewer", controller: :calendar, action: :viewer
    get "event_histories_viewer", controller: :calendar, action: :event_histories_viewer

    get "urls", controller: :main, action: :available_routes

    root to: "operators#index"
  end

  namespace :turing_review do
    get "", controller: :auto_message_classifications, action: :main
    get ":batch_identifier/supervise", controller: :auto_message_classifications, action: :supervise
    post ":batch_identifier/:auto_message_classification_review_id/mark_as_resolved", controller: :auto_message_classifications, action: :mark_as_resolved
    get ":batch_identifier/:id", controller: :auto_message_classifications, action: :review
    post ":batch_identifier/:id", controller: :auto_message_classifications, action: :reviewed
  end


  namespace :review do
    resources :operators, only: [:show, :index] do
      collection do
        get "my_stats", action: :my_stats, as: :my_stats
        get :my_errors
        get "messages_thread_ids_to_review", action: :messages_thread_ids_to_review
        get :download_report
      end

      member do
        get :errors
      end
    end

    resources :anonymised_messages_threads, only: [:index, :show]

    resources :julie_actions, only: [] do
      collection do
        get "list_errors", action: :list_errors
        post "list_comments", actions: :list_comments
        get "from_server_message_id/:server_message_id", action: :from_server_message_id
      end

      member do
        get "compare_date_suggestions", action: :compare_date_suggestions
        post "update_review_comment", action: :update_review_comment
      end
    end

    resources :operators_presence, only: [:index] do
      collection do
        post "/add", action: :add
        post "/remove", action: :remove
        post "/reset_day", action: :reset_day
        post "/copy_day", action: :copy_day
        post :upload_planning_constraints
        post :get_planning_from_ai
        get "/forecast", action: :forecast
      end
    end

    resources :locations, only: [] do
      collection do
        get "", action: :main
        get "review", action: :review
      end
    end

    resources :all_days, only: [] do
      collection do
        get "", action: :main
        get "review", action: :review
      end
    end

    resources :entities, only: [] do
      collection do
        get "", action: :main
        get "review", action: :review
      end
    end

    resources :classifications, only: [] do
      collection do
        get "", action: :main
        get "review", action: :review
      end
    end

    resources :constraints, only: [] do
      collection do
        get "", action: :main
        get "review", action: :review
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
        get "from_server_thread_id", action: :from_server_thread_id
        get "review_next", action: :review_next
        get "learn_next", action: :learn_next
        get "group_review_next", action: :group_review_next
      end
    end

    resources :date_suggestions_reviews, only: [:show] do

      collection do
        get "full_auto", action: :full_auto_index
      end
      member do
        get "full_auto", action: :full_auto_show
        post "", action: :update
      end
    end

    root to: "operators#index"
  end

  namespace :api do
    namespace :v1 do
      get "sent_messages_stats", controller: :messages_threads, action: :sent_messages_stats
      get "weekly_recap_data", controller: :messages_threads, action: :weekly_recap_data
      get "messages_thread_context", controller: :messages_threads, action: :messages_thread_context
      get "emails_forecast", controller: :ai_forecast, action: :emails

      post "generate_dates_suggestion_template_with_links", controller: :messages_threads, action: :generate_dates_suggestion_template_with_links
      post "julie_aliases/synchronize", controller: :julie_aliases, action: :synchronize
      post "/accounts/change_account_main_email", controller: :accounts, action: :change_account_main_email
      post "/client_requests/compute_count", controller: :client_requests, action: :compute_count
      post "/accounts/account_gone_unsubscribed", controller: :accounts, action: :account_gone_unsubscribed
      post "/messages_threads/parse_ticket", controller: :messages_threads, action: :parse_ticket
      post "/messages_threads/check_missing_messages", controller: :messages_threads, action: :check_missing_messages
      post "/client_contacts/ai_get_company_name", controller: :client_contacts, action: :ai_get_company_name
      get "/messages_threads/inbox_client_emails", controller: :messages_threads, action: :inbox_client_emails
      get "/messages_threads/only_inbox_messages_server_ids", controller: :messages_threads, action: :only_inbox_messages_server_ids
      get "/messages_threads/fetch_messages_threads", controller: :messages_threads, action: :fetch_messages_threads

      post "/client_requests/client_graph_data", controller: :client_requests, action: :client_graph_data

      post "/client_requests/client_request_data", controller: :client_requests, action: :client_request_data

      resources :messages_threads do
        post  :remove_syncing_tag,    on: :collection
        post  :add_syncing_tag,       on: :collection

        # Slash
        get   :get_details,               on: :member
        get   :get_user_details,          on: :member
        put   :compute_date_suggestions,  on: :member
        put   :validate_date_suggestion,  on: :member
        put   :update_missing_info,       on: :member
      end

      resources :messages do
        get :simulate_classify, on: :member
      end
    end
  end

  namespace :ai do
    namespace :dates_suggestions do
      post :fetch
      post :send_learning_data
      post :puts_calendar_in_conscience_cache
      post :dates_suggestions_auto_process_update
    end

    namespace :dates_verification do
      post :verify_dates_v8
      post :verify_dates_v9
      post :verify_dates_v10
      post :verify_dates_v11
      post :verify_dates_with_version
    end

    namespace :events_metadata do
      post :fetch
    end
  end

  get "stats", controller: :stats, action: :index
  get "stats/volume", controller: :stats, action: :volume

  get "test/js" => "test#js"
  get "test/templates" => "test#templates"
  get "test/template_generation" => "test#template_generation"

  post "pusher/auth/", to: "pusher#auth"
  post "pusher/webhooks/", to: "pusher#webhooks"

  post "webhooks/new_email", to: "webhooks#new_email"

  post "change_sound" => "application#change_sound"

  get "login" => "application#login", as: :login
  get "process_login" => "application#process_login", as: :process_login
  get "logout" => "application#logout", as: :logout

  if ENV['STAGING_APP']
    namespace :staging do
      get "import_context_from_production", to: "messages_threads#import_context_from_production"

      get "get_attendees", to: "events#get_attendees"

      post "save_attendees", to: "events#save_attendees"
    end
  end
  
    # Load balancers healthcheck
  get "/healthcheck/check", controller: :healthcheck, action: :check
  get "/healthcheck/raise", controller: :healthcheck, action: :raise

end
