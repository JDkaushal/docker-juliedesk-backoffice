class Review::JulieActionsController < ReviewController

  def compare_date_suggestions
    respond_to do |format|
      format.html do

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
                review_comment: ja.date_suggestions_comparison_review.try(:comment)
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