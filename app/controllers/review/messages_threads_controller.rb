class Review::MessagesThreadsController < ReviewController

  skip_before_filter :only_super_operator_level_2_or_admin, only: [:learn, :learnt, :learn_next]
  before_filter :only_mine, only: [:learn, :learnt, :learn_next]
  before_filter :only_admin, only: [:admin_review_turing_index]

  def review
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account
    operator_ids = Operator.where("email <> 'guillaume@juliedesk.com'").map(&:id)
    @to_review_count = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW, operator_id: operator_ids).map(&:messages_thread_id).uniq.length

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten

  end

  def from_server_thread_id
    messages_thread = MessagesThread.find_by server_thread_id: params[:server_thread_id]
    raise "No thread with that id" unless messages_thread

    redirect_to action: :review, id: messages_thread.id
  end

  def learn
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_learn_count = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, operator_id: params[:operator_id]).map(&:messages_thread_id).uniq.length

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten
  end

  def group_review
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_group_review_count = OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN).map(&:messages_thread_id).uniq.length

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten
  end

  def learnt
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])

    @messages_thread.operator_actions_groups.select{|oag| oag.review_status == OperatorActionsGroup::REVIEW_STATUS_TO_LEARN && oag.operator_id == params[:operator_id].to_i}.each do |oag|
      oag.update_attribute :review_status, OperatorActionsGroup::REVIEW_STATUS_LEARNT
    end

    learn_next_messages_thread
  end

  def reviewed
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])

    data = JSON.parse(params[:data]).map(&:with_indifferent_access)

    @messages_thread.operator_actions_groups.each do |operator_actions_group|
      data_entry = data.select{|d| d[:operator_actions_group_id] == operator_actions_group.id}.first
      if data_entry
        operator_actions_group.update_attributes({
          review_status: (data_entry[:notation] == 5)?(OperatorActionsGroup::REVIEW_STATUS_REVIEWED):(OperatorActionsGroup::REVIEW_STATUS_TO_LEARN),
          review_notation: data_entry[:notation],
          group_review_status: (data_entry[:should_review_in_group])?(OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN):(OperatorActionsGroup::GROUP_REVIEW_STATUS_UNSET),
          review_comment: (data_entry[:comment].blank?)?nil:("#{data_entry[:comment]}\n\n#{session[:user_name]}"),
          reviewed_by_operator_id: session[:operator_id]
         })
      else
        operator_actions_group.update_attributes({
            review_status: OperatorActionsGroup::REVIEW_STATUS_REVIEWED,
            reviewed_by_operator_id: session[:operator_id]
        })
      end
    end

    close_tab
  end

  def group_reviewed
    @messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])
    @messages_thread.operator_actions_groups.select{|oag| oag.group_review_status == OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN}.each do |oag|
      oag.update_attribute :group_review_status, OperatorActionsGroup::GROUP_REVIEW_STATUS_LEARNT
    end

    group_review_next_messages_thread
  end


  def review_next
    review_next_messages_thread
  end

  def group_review_next
    group_review_next_messages_thread
  end

  def learn_next
    learn_next_messages_thread
  end

  def change_messages_thread_status
    messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])

    last_message = messages_thread.messages.sort_by(&:updated_at).last
    message_classification = last_message.message_classifications.create_from_params classification: MessageClassification::NOTHING_TO_DO, operator: session[:user_username], thread_status: params[:thread_status]
    message_classification.julie_action.update_attribute :done, true

    redirect_to action: :review
  end

  def review_turing_index
    @reviewed_by_me_count = AutoMessageClassificationReview.where(operator_id: session[:operator_id]).count
    @count_to_review = AutoMessageClassification.where.not(message_id: nil).count - @reviewed_by_me_count
  end

  def admin_review_turing_index
    @auto_message_classification_reviews = AutoMessageClassificationReview.joins(:auto_message_classification).where.not(auto_message_classifications: {message_id: nil})
    if params[:operator_id]
      @auto_message_classification_reviews = @auto_message_classification_reviews.where(operator_id: params[:operator_id])
    end
    @amc_count = AutoMessageClassification.where.not(message_id: nil).count
    @auto_message_classification_reviews = @auto_message_classification_reviews.includes(auto_message_classification: {message: :messages_thread, julie_action: []}, operator: {}).sort_by(&:notation).reverse
    @operators = @auto_message_classification_reviews.map(&:operator).flatten.uniq
  end

  def review_turing_next
    redirect_to action: :review_turing, id: find_next_messages_thread_id_to_turing_review
  end

  def review_turing
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import
    @messages_thread.mock_conscience_first_message


    @messages_thread.account

    @turing_mode = "machine"

    @accounts_cache_light = Account.accounts_cache(mode: "light")
    @julie_emails = JulieAlias.all.map(&:email).map(&:downcase)
    @client_emails = @accounts_cache_light.map{|k, account| [account['email']] + account['email_aliases']}.flatten

  end

  def submit_turing_notation
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    amc = @messages_thread.messages.sort_by(&:received_at).first.auto_message_classification
    data = JSON.parse(params[:data]).with_indifferent_access
    amc.auto_message_classification_reviews.where(operator_id: session[:operator_id]).destroy_all
    amc.auto_message_classification_reviews << AutoMessageClassificationReview.new({
                                                                                       notation: data[:notation],
                                                                                       comments: data[:comments],
                                                                                       operator_id: session[:operator_id]
                                                                                   })
    next_id = find_next_messages_thread_id_to_turing_review
    if next_id
      redirect_to action: :review_turing, id: next_id
    else
      redirect_to action: :review_turing_index
    end
  end

  private

  def find_next_messages_thread_id_to_turing_review
    reviewed_by_me_amc_ids = AutoMessageClassificationReview.where(operator_id: session[:operator_id]).map(&:auto_message_classification_id)
    AutoMessageClassification.where.not(message_id: nil).where.not(id: reviewed_by_me_amc_ids).first.try(:message).try(:messages_thread_id)
  end

  def group_review_next_messages_thread
    oag = OperatorActionsGroup.order("initiated_at ASC").find_by_group_review_status(OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN)
    if oag
      redirect_to action: :group_review, id: oag.messages_thread_id
    else
      redirect_to review_operators_path
    end
  end

  def review_next_messages_thread
    oag = OperatorActionsGroup.order("initiated_at ASC").find_by_review_status(OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW)
    if oag
      redirect_to action: :review, id: oag.messages_thread_id
    else
      redirect_to review_operators_path
    end
  end

  def learn_next_messages_thread
    oag = OperatorActionsGroup.order("initiated_at ASC").find_by_review_status_and_operator_id(OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, params[:operator_id])
    if oag
      redirect_to action: :learn, id: oag.messages_thread_id, operator_id: params[:operator_id]
    else
      redirect_to my_stats_review_operators_path
    end
  end

  def only_mine
    if params[:operator_id].nil?
      params[:operator_id] = session[:operator_id]
    end

    unless session[:privilege] == Operator::PRIVILEGE_ADMIN ||
        session[:privilege] == Operator::PRIVILEGE_SUPER_OPERATOR_LEVEL_2 ||
        "#{params[:operator_id]}" == "#{session[:operator_id]}"
      redirect_to "/"
    end
  end

  def close_tab
    render html: "<script>window.close();</script>".html_safe
  end
end
