class Review::DateSuggestionsReviewsController < ReviewController


  def full_auto_index
    respond_to do |format|
      format.html do

      end

      format.json do
        date_suggestions_reviews = DateSuggestionsReview.joins(:julie_action).where(julie_actions: {
            date_suggestions_full_ai: true
        }).where("action_at >= ? AND action_at < ?", DateTime.parse(params[:start]), DateTime.parse(params[:end]))

        render json: {
            status: 'success',
            data: {
                julie_actions: date_suggestions_reviews.map{|dsr|
                  {
                      id: dsr.id,
                      julie_action_id: dsr.julie_action.id,
                      operator: dsr.julie_action.message_classification.operator,
                      client_email: dsr.julie_action.message_classification.message.messages_thread.account_email,
                      date: dsr.action_at,
                      review_status: dsr.review_status,
                      review_full_auto_errors: dsr.review_full_auto_errors
                  }
                },
                total_count: date_suggestions_reviews.count
            }
        }
      end
    end
  end

  def full_auto_show
    dsr = DateSuggestionsReview.find(params[:id])
    raise "Invalid DateSuggestionsReview" unless dsr.generated_from_julie_action
    ja = dsr.julie_action
    @window_thread_account = {
        email: ja.message_classification.message.messages_thread.account_email,
        travel_time_transport_mode: ja.message_classification.message.messages_thread.account.try(:travel_time_transport_mode) || "max"
    }
    @window_thread_computed_data = {
        location: ja.message_classification.location,
        appointment_nature: ja.message_classification.appointment_nature,
        is_virtual_appointment: MessagesThread.virtual_appointment_natures.include?(ja.message_classification.appointment_nature)
    }
  end

  def show
    respond_to do |format|
      format.html do

      end

      format.json do
        dsr = DateSuggestionsReview.find(params[:id])
        raise "Invalid DateSuggestionsReview" unless dsr.generated_from_julie_action
          ja = dsr.julie_action
          mc = ja.message_classification
          mt = mc.message.messages_thread
          account = mt.account

          render json: {
              status: "success",
              data: {
                  julie_action_id: ja.id,
                  event_type: mc.appointment_nature,
                  duration: mc.duration,
                  location: mc.location,
                  other_notes: mc.other_notes,
                  constraints_data: JSON.parse(mc.constraints_data || "[]"),
                  date_suggestions: JSON.parse(ja.date_times || "[]"),
                  account_email: mt.account_email,
                  other_account_emails: mc.other_account_emails,
                  date: ja.created_at,
                  used_timezones: mc.used_timezones,
                  main_address: account.try(:main_address).try(:[], 'address'),

                  set_errors: dsr.review_set_errors || [],
                  items_errors: dsr.review_items_errors || [],
                  comment: dsr.comment,
                  full_auto_errors: dsr.review_full_auto_errors || [],
                  full_auto_custom_error: dsr.review_full_auto_custom_error,
                  review_thread_link: "/review/messages_threads/#{mt.id}/review"
              }
          }
      end
    end
  end

  def update
    items_errors = {}
    params[:items_errors].each do |item_error|
      if item_error['errors'].present?
        items_errors[item_error['date']] = {
            errors: item_error['errors'],
            custom_error: item_error['customError']
        }
      end
    end

    dsr = DateSuggestionsReview.find(params[:id])
    dsr.review({
                   set_errors: params[:set_errors],
                   items_errors: items_errors,
                   operator_id: session[:operator_id],
                   full_auto_errors: params[:full_auto_errors],
                   full_auto_custom_error: params[:full_auto_custom_error],
                   comment: params[:comment]
               })
    next_id = next_date_suggestion_review_id

    render json: {
        status: "success",
        data: {
            next_id: next_id
        }
    }
  end

  private

  def next_date_suggestion_review_id
    DateSuggestionsReview.where(review_status: DateSuggestionsReview::REVIEW_STATUS_UNREVIEWED).order(:id).limit(1).first.try(:id)
  end
end