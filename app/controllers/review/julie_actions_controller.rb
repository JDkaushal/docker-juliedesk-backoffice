class Review::JulieActionsController < ReviewController

  def list_comments

    ids = params[:ids] || []
    data = Hash[ids.map {|id| [id, nil]}].merge(Hash[JulieAction.where(id: ids).joins(:date_suggestions_comparison_review).select(:id, date_suggestions_comparison_review: :comment).map do |ja|
      [ja.id, ja.date_suggestions_comparison_review.comment]
    end])

    render json: {
        status: "success",
        data: {
            julie_actions: data
        }
    }
  end

  def compare_date_suggestions
    respond_to do |format|
      format.html do

        # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        #   To remove when travel times are computed in backend
        ja = JulieAction.find(params[:id])
        @window_thread_account = {
            email: ja.message_classification.message.messages_thread.account_email,
            travel_time_transport_mode: ja.message_classification.message.messages_thread.account.try(:travel_time_transport_mode) || "max"
        }
        @window_thread_computed_data = {
            location: ja.message_classification.location,
            appointment_nature: ja.message_classification.appointment_nature,
            is_virtual_appointment: MessagesThread.virtual_appointment_natures.include?(ja.message_classification.appointment_nature)
        }
        # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      end

      format.json do
        ja = JulieAction.find(params[:id])
        render json: {
            status: "success",
            data: {
                event_type: ja.message_classification.appointment_nature,
                duration: ja.message_classification.duration,
                location: ja.message_classification.location,
                other_notes: ja.message_classification.other_notes,
                constraints_data: JSON.parse(ja.message_classification.constraints_data || "[]"),
                date_suggestions: JSON.parse(ja.date_times || "[]"),
                account_email: ja.message_classification.message.messages_thread.account_email,
                other_account_emails: ja.message_classification.other_account_emails,
                date: ja.created_at,
                review_comment: ja.date_suggestions_comparison_review.try(:comment),
                review_thread_link: url_for(controller: :messages_threads, action: :review, id: ja.message_classification.message.messages_thread_id)
            }
        }
      end
    end
  end

  def update_review_comment
    ja = JulieAction.find(params[:id])
    ja.date_suggestions_comparison_review ||= ja.build_date_suggestions_comparison_review
    ja.date_suggestions_comparison_review.update_attributes(comment: params[:review_comment])
    render json: {
        status: "success",
        data: {}
    }
  end
end