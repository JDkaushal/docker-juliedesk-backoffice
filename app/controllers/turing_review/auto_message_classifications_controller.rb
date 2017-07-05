class TuringReview::AutoMessageClassificationsController < TuringReviewController

  before_filter :only_admin, only: [:admin_review_turing_index]

  def main
    @data = Hash[AutoMessageClassification.get_all_batch_identifiers.map do |batch_identifier|
      reviewed_by_me_auto_message_classification_ids = AutoMessageClassificationReview.joins(:auto_message_classification).where(auto_message_classifications: {batch_identifier: batch_identifier}, auto_message_classification_reviews: {operator_id: session[:operator_id]}).select(:auto_message_classification_id).map(&:auto_message_classification_id).uniq
      all_reviews_count = AutoMessageClassificationReview.joins(:auto_message_classification).where(auto_message_classifications: {batch_identifier: batch_identifier}).select(:auto_message_classification_id).distinct.count
      [batch_identifier, {
          auto_message_classifications_count: AutoMessageClassification.where(batch_identifier: batch_identifier).count,
          all_reviews_count: all_reviews_count,
          my_reviews_count: reviewed_by_me_auto_message_classification_ids.length,
          next_auto_message_classification_id: AutoMessageClassification.where(batch_identifier: batch_identifier).where.not(id: reviewed_by_me_auto_message_classification_ids).select(:id).map(&:id).sample
      }]
    end]

  end

  def review
    @amc = AutoMessageClassification.find(params[:id])
    messages_thread_id = @amc.message.messages_thread_id
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(messages_thread_id)
    @messages_thread.re_import
    @messages_thread.mock_conscience_first_message


    @messages_thread.account

    @turing_mode = "machine"

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.select { |_, account| account['subscribed'] }.map{|k, account| [account['email']] + account['email_aliases']}.flatten
  end

  def reviewed
    amc = AutoMessageClassification.find(params[:id])
    data = JSON.parse(params[:data]).with_indifferent_access
    amc.auto_message_classification_reviews.where(operator_id: session[:operator_id]).destroy_all
    amc.auto_message_classification_reviews << AutoMessageClassificationReview.new({
                                                                                       notation: data[:notation],
                                                                                       comments: data[:comments],
                                                                                       operator_id: session[:operator_id]
                                                                                   })
    next_id = find_next_auto_message_classification_id_to_review params[:batch_identifier]
    if next_id
      redirect_to action: :review, id: next_id
    else
      redirect_to action: :main
    end
  end

  def mark_as_resolved
    amcr = AutoMessageClassificationReview.find_by_id(params[:auto_message_classification_review_id])
    if amcr
      amcr.update(resolved: true)
    end
    redirect_to action: :supervise, batch_identifier: amcr.auto_message_classification.batch_identifier
  end

  def supervise
    @batch_identifier = params[:batch_identifier]
    @auto_message_classification_reviews = AutoMessageClassificationReview.joins(:auto_message_classification).where.not(auto_message_classifications: {message_id: nil}).where(auto_message_classifications: {batch_identifier: @batch_identifier})
    if params[:operator_id]
      @auto_message_classification_reviews = @auto_message_classification_reviews.where(operator_id: params[:operator_id])
    end
    @amc_count = AutoMessageClassification.where.not(message_id: nil).where(batch_identifier: @batch_identifier).count
    @auto_message_classification_reviews = @auto_message_classification_reviews.includes(auto_message_classification: {message: :messages_thread, julie_action: []}, operator: {}).sort_by(&:notation).reverse
    @operators = @auto_message_classification_reviews.map(&:operator).flatten.uniq

    @unreviewed_message_classifications = AutoMessageClassification.where.not(message_id: nil).where(batch_identifier: @batch_identifier).where.not(id: @auto_message_classification_reviews.map(&:auto_message_classification_id))
  end

  private
  def find_next_auto_message_classification_id_to_review batch_identifier
    reviewed_by_me_auto_message_classification_ids = AutoMessageClassificationReview.joins(:auto_message_classification).where(auto_message_classifications: {batch_identifier: batch_identifier}, auto_message_classification_reviews: {operator_id: session[:operator_id]}).select(:auto_message_classification_id).map(&:auto_message_classification_id).uniq
    AutoMessageClassification.where(batch_identifier: batch_identifier).where.not(id: reviewed_by_me_auto_message_classification_ids).select(:id).map(&:id).sample
  end
end