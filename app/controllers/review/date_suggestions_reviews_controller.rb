class Review::DateSuggestionsReviewsController < ReviewController


  def show
    respond_to do |format|
      format.html do

      end

      format.json do
        dsr = DateSuggestionsReview.find(params[:id])
        if dsr.generated_from_julie_action
          ja = dsr.julie_action

          render json: {
              status: "success",
              data: {
                  set_errors: dsr.review_set_errors || [],
                  items_errors: dsr.review_items_errors || [],
                  event_type: ja.message_classification.appointment_nature,
                  duration: ja.message_classification.duration,
                  location: ja.message_classification.location,
                  other_notes: ja.message_classification.other_notes,
                  constraints_data: JSON.parse(ja.message_classification.constraints_data || "[]"),
                  date_suggestions: JSON.parse(ja.date_times || "[]"),
                  account_email: ja.message_classification.message.messages_thread.account_email,
                  other_account_emails: ja.message_classification.other_account_emails,
                  date: ja.created_at
              }
          }
        end

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
                   operator_id: session[:operator_id]
               })
    next_id = next_date_suggestion_review_id

    raise
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