class Review::MessagesThreadsController < ReviewController

  skip_before_filter :only_admin, only: [:learn, :learnt, :learn_next]
  before_filter :only_mine, only: [:learn, :learnt, :learn_next]

  def review
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_review_count = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_REVIEW).map(&:messages_thread_id).uniq.length
  end

  def learn
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_learn_count = OperatorActionsGroup.where(review_status: OperatorActionsGroup::REVIEW_STATUS_TO_LEARN, operator_id: params[:operator_id]).map(&:messages_thread_id).uniq.length
  end

  def group_review
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}, operator_actions_groups: {operator: {}, target: {}}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_group_review_count = OperatorActionsGroup.where(group_review_status: OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN).map(&:messages_thread_id).uniq.length
  end

  def learnt
    messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])
    messages_thread.operator_actions_groups.select{|oag| oag.review_status == OperatorActionsGroup::REVIEW_STATUS_TO_LEARN && oag.operator_id == params[:operator_id].to_i}.each do |oag|
      oag.update_attribute :review_status, OperatorActionsGroup::REVIEW_STATUS_LEARNT
    end

    learn_next_messages_thread
  end

  def reviewed
    messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])

    data = JSON.parse(params[:data]).map(&:with_indifferent_access)

    messages_thread.operator_actions_groups.each do |operator_actions_group|
      data_entry = data.select{|d| d[:operator_actions_group_id] == operator_actions_group.id}.first
      if data_entry
        operator_actions_group.update_attributes({
            review_status: (data_entry[:notation] == 5)?(OperatorActionsGroup::REVIEW_STATUS_REVIEWED):(OperatorActionsGroup::REVIEW_STATUS_TO_LEARN),
            review_notation: data_entry[:notation],
            group_review_status: (data_entry[:should_review_in_group])?(OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN):(OperatorActionsGroup::GROUP_REVIEW_STATUS_UNSET),
            review_comment: data_entry[:comment]
                                                 })
      end
    end

    review_next_messages_thread
  end

  def group_reviewed
    messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])
    messages_thread.operator_actions_groups.select{|oag| oag.review_status == OperatorActionsGroup::GROUP_REVIEW_STATUS_TO_LEARN}.each do |oag|
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

  private

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
    session[:privilege] == "admin" || params[:operator_id] == session[:operator_id]
  end



end
