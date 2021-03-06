# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.

Rails.application.config.assets.precompile += [
    "stats.css",
    "operators/sources.css",
    "planning.css",
    "bootstrap_v4_only"
]
Rails.application.config.assets.precompile += [
    "stats.js",
    "test.js",
    "angular_attendees_app.js",
    "angular_dependencies.js",
    "angular_virtual_meetings_helper_app.js",
    "thread_messages/actions.js",
    "operators/sources.js",
    "angular_reply_box_app.js",
    "angular_AI_manager_app.js",
    "angular_dates_manager_appp.js",
    "angular_event_creator_app.js",
    "angular_travel_time_manager_app.js",
    "automatic_templates_manager.js",
    "classif_form_tracking.js",
    "angular_meeting_rooms_manager_app.js",
    "angular_restaurant_booking_manager_app.js",
    "angular_utilities.js",
    "angular_client_account_tile_app.js",
    "threads_tags_management/manager.js",
    "angular_no_account_tile_app.js",
    "angular_date_suggestions_review_manager_app.js",
    "client_agreement_management/manager.js",
    "angular_date_suggestions_comparison_manager_app.js",
    "angular_calendar_viewer.js",
    "julie_actions/julie_action_show.js",
    "angular_date_suggestions_full_auto_review_manager_app.js",
    "angular_info_panel_app.js",
    "angular_meeting_rooms_availaibilities_panel_app.js",
    "online_meeting/main.js"
]

