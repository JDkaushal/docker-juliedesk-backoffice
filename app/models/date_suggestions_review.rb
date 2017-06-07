class DateSuggestionsReview< ActiveRecord::Base

  belongs_to :julie_action

  REVIEW_STATUS_UNREVIEWED = nil
  REVIEW_STATUS_REVIEWED = "reviewed"

  REVIEW_SET_STATUS_CORRECT = "correct"
  REVIEW_SET_STATUS_INCORRECT_SET = "incorrect_set"
  REVIEW_SET_STATUS_INCORRECT_SUGGESTIONS = "incorrect_suggestions"

  def self.generate_from_julie_action julie_action_id
    ja = JulieAction.find julie_action_id

    self.create({
        julie_action_id: julie_action_id,
        action_at: ja.created_at,
        generated_from_julie_action: true,
        date_suggestions: JSON.parse(ja.date_times || "[]"),
                })
  end

  def review params
    self.review_set_errors = params[:set_errors] || []
    self.review_items_errors = params[:items_errors] || {}

    self.review_full_auto_errors = params[:full_auto_errors] || []
    self.review_full_auto_custom_error = params[:full_auto_custom_error].present? ? params[:full_auto_custom_error] : nil
    self.comment = params[:comment].present? ? params[:comment] : nil

    self.review_items_incorrect_count = self.review_items_errors.keys.length
    self.reviewed_by_operator_id = params[:operator_id]
    self.review_status = REVIEW_STATUS_REVIEWED
    self.review_set_status = if self.review_items_errors.length > 0
                               REVIEW_SET_STATUS_INCORRECT_SUGGESTIONS
                             elsif self.review_set_errors.length > 0
                               REVIEW_SET_STATUS_INCORRECT_SET
                             else
                               REVIEW_SET_STATUS_CORRECT
                             end
    self.save
  end
end