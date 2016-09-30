class GenerateFollowUpWorker

  @queue = :follow_up
  def self.enqueue(messages_thread_id, instruction, operator_id)
    Resque.enqueue(self, messages_thread_id, instruction, operator_id)
  end

  def self.perform (messages_thread_id, instruction, operator_id)
    messages_thread = MessagesThread.find messages_thread_id
    messages_thread.update_attributes(should_follow_up: true, follow_up_instruction: instruction)

    OperatorAction.create({
                              initiated_at: DateTime.now,
                              target: messages_thread,
                              nature: OperatorAction::NATURE_OPEN,
                              operator_id: session[:operator_id],
                              messages_thread_id: messages_thread.id
                          })
    OperatorAction.create_and_verify({
                                         initiated_at: DateTime.now,
                                         target: messages_thread,
                                         nature: OperatorAction::NATURE_SEND_TO_SUPPORT,
                                         operator_id: operator_id,
                                         messages_thread_id: messages_thread.id,
                                         message: "#FollowUp #{instruction}"
                                     })
  end
end