module FlowConditionsHelper

  def handle_flow_conditions(input_objects, flow_conditions)
    Rails.logger.debug('- ' * 50)
    # Reinitialize the JSON because if we use the saved JSON and change it, il results in the record not being properly updated
    filters_results = {}
    puts 'Handling flow conditions...'
    selected_conditions = flow_conditions.select do |flow_identifier, flow_data|
      identifier = flow_identifier.to_s+'_back_conditions'
      filters_results[identifier] = {}
      Rails.logger.debug("  Flow: #{flow_identifier}")
      a_condition_fails = flow_data[:back_conditions].any? do |condition_identifier, condition_value|
        result = validate_flow_condition(input_objects, condition_identifier, condition_value)
        Rails.logger.debug("    #{condition_identifier} | expected: #{condition_value} | condition_respected: #{result}")
        filters_results[identifier][condition_identifier.to_s] = result.to_s
        result == false
      end
      !a_condition_fails
    end

    input_objects[:julie_action].try(:update, {ai_filters_results: filters_results})

    selected_conditions
  end

  def validate_flow_condition(input_objects, condition_identifier, condition_value)
    case condition_identifier
      when :feature_active
        feature_active? condition_value, session[:operator_id], session[:privilege]
      when :features_active
        !condition_value.map do |feature_name, should_be_active|
          validation_flow_condition_include_or_equals feature_active?(feature_name, session[:operator_id], session[:privilege]), should_be_active
        end.include? false
      when :action_nature
        validation_flow_condition_include_or_equals condition_value, required_input_object(input_objects, :julie_action).action_nature
      when :event_type
        validation_flow_condition_include_or_equals condition_value, required_input_object(input_objects, :julie_action).message_classification.appointment_nature
      when :should_book_resource
        validation_flow_condition_include_or_equals condition_value, required_input_object(input_objects, :julie_action).should_book_resource
      when :current_notes_present
        all_account_emails = required_input_object(input_objects, :julie_action).message_classification.other_account_emails + [required_input_object(input_objects, :messages_thread).account_email]
        all_account_emails.map{|email| Account.create_from_email(email).try(:has_current_notes?)}.include?(true) == condition_value
      when :free_notes_present
        validation_flow_condition_include_or_equals condition_value, required_input_object(input_objects, :julie_action).free_notes_present
      when :linked_attendees_present
        validation_flow_condition_include_or_equals condition_value, required_input_object(input_objects, :messages_thread).linked_attendees.present?
      when :all_clients_on_calendar_server
        all_account_emails = required_input_object(input_objects, :julie_action).message_classification.other_account_emails + [required_input_object(input_objects, :messages_thread).account_email]
        !all_account_emails.map{|email| Account.create_from_email(email).try(:using_calendar_server)}.include?(false) == condition_value
      when :main_client_auto_date_suggestions_on
        Account.create_from_email(required_input_object(input_objects, :messages_thread).account_email).try(:auto_date_suggestions).present?
      when :constraints_conflicts
        AdminApiInterface.constraints_conflicts(JSON.parse(required_input_object(input_objects, :julie_action).message_classification.constraints_data || "[]")) == condition_value
      when :client_on_trip
        validation_flow_condition_include_or_equals condition_value, required_input_object(input_objects, :julie_action).message_classification.client_on_trip != nil
      when :date_times_from_ai_count
        validation_flow_condition_superior_or_equals condition_value, ((required_input_object(input_objects, :julie_action).date_times_from_ai || {})['suggested_dates'] || []).length
      when :date_times_from_ai_on_all_day_event
        validation_flow_condition_include_or_equals condition_value, (required_input_object(input_objects, :julie_action).date_times_from_ai || {})['all_days_on_suggestions'] == 'true'
      else
        raise "Unsupported flow condition: #{condition_identifier}"
    end
  end

  def validation_flow_condition_superior_or_equals(condition_value, value_to_check)
    value_to_check >= condition_value
  end

  def validation_flow_condition_include_or_equals(condition_value, value_to_check)
    condition_value.is_a?(Array) ? condition_value.include?(value_to_check) : value_to_check == condition_value
  end

  def required_input_object input_objects, input_object_key
    input_object = input_objects[input_object_key]
    raise "Missing required input object #{input_object_key}" unless input_object
    input_object
  end
end