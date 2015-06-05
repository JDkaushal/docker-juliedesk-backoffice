class Review::MessagesThreadsController < ApplicationController


  def review
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_review_count = MessageClassification.where(review_status: MessageClassification::REVIEW_STATUS_TO_REVIEW).includes(message: :messages_thread).map{|mc| mc.message.messages_thread_id}.uniq.length
  end

  def learn
    @messages_thread = MessagesThread.includes(messages: {message_classifications: :julie_action}).find(params[:id])
    @messages_thread.re_import

    @messages_thread.account

    @to_learn_count = MessageClassification.where(review_status: MessageClassification::REVIEW_STATUS_TO_LEARN, operator: params[:operator]).includes(message: :messages_thread).map{|mc| mc.message.messages_thread_id}.uniq.length
  end

  def learnt
    messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])
    messages_thread.messages.map(&:message_classifications).flatten.select{|mc| mc.review_status == MessageClassification::REVIEW_STATUS_TO_LEARN && mc.operator == params[:operator]}.each do |mc|
      mc.update_attribute :review_status, MessageClassification::REVIEW_STATUS_LEARNT
    end

    learn_next_messages_thread
  end

  def reviewed
    messages_thread = MessagesThread.includes(messages: :message_classifications).find(params[:id])

    message_classification_ids_to_learn = params[:message_classification_ids_to_learn]
    if message_classification_ids_to_learn.is_a? Array

    elsif message_classification_ids_to_learn.is_a?(String) && message_classification_ids_to_learn.present?
      message_classification_ids_to_learn = JSON.parse(message_classification_ids_to_learn)
    else
      message_classification_ids_to_learn = []
    end
    message_classification_ids_to_learn.map!(&:to_i)

    messages_thread.messages.map(&:message_classifications).flatten.select{|mc| mc.review_status == MessageClassification::REVIEW_STATUS_TO_REVIEW}.each do |mc|
      if message_classification_ids_to_learn.include? mc.id
        mc.update_attribute :review_status, MessageClassification::REVIEW_STATUS_TO_LEARN
      else
        mc.update_attribute :review_status, MessageClassification::REVIEW_STATUS_REVIEWED
      end
    end

    review_next_messages_thread
  end

  def review_next
    review_next_messages_thread
  end

  def learn_next
    learn_next_messages_thread
  end

  private

  def review_next_messages_thread
    mc = MessageClassification.find_by_review_status(MessageClassification::REVIEW_STATUS_TO_REVIEW)
    if mc
      redirect_to action: :review, id: mc.message.messages_thread_id
    else
      redirect_to review_operators_path
    end
  end

  def learn_next_messages_thread
    mc = MessageClassification.find_by_review_status_and_operator(MessageClassification::REVIEW_STATUS_TO_LEARN, params[:operator])
    if mc
      redirect_to action: :learn, id: mc.message.messages_thread_id, operator: params[:operator]
    else
      redirect_to review_operators_path
    end
  end



end
