module FlowDispatcher
  class FlowFailed < StandardError ; end


  def init_flows!(flows, initial_data)
    # TODO: validate flows
    @flows = flows

    initial_data.each do |attr_name, attr_value|
      instance_variable_set("@initial_#{attr_name}", attr_value)
    end
  end


  def process_flow(flow_name)
    enter_flow(flow_name)
  end


  protected

  def enter_flow(flow_name)
    flow = @flows[flow_name]

    before_flow(flow[:before_flow] || [])
    trigger_flow(flow[:flow_items])
  end

  def before_flow(before_hooks)
    before_hooks.each do |validation|
      method    = validation[:method]

      params = (validation[:params] || []).map do |param|
        (param.is_a?(Symbol) && param.match(/^@/)) ? instance_variable_get(param) : param
      end
      store_as  = validation[:store_as]
      exception = validation[:raise]

      result = send(method, *params)
      unless exception.nil?
        raise exception.new unless result
      end

      if store_as.present? && store_as.is_a?(Symbol) && store_as.match(/^@/)
        instance_variable_set(store_as, result)
      end
    end

    true
  end

  def trigger_flow(flow)
    flow.each do |sub_flow|
      conditions = sub_flow.fetch(:conditions, [])
      actions    = sub_flow.fetch(:actions, [])
      exit_flow  = actions.any? { |action| action[:exit_flow].present? }

      if check_conditions(conditions)
        results = execute_actions(actions)
        return results.last if exit_flow
      end
    end
  end

  def check_conditions(conditions)
    begin
      conditions.all? do |c|
        method = c[:method]
        params = (c[:params] || []).map do |param|
          (param.is_a?(Symbol) && param.match(/^@/)) ? instance_variable_get(param) : param
        end


        condition_result = send(method, *params)
        raise c[:raise].new if c.has_key?(:raise) && !condition_result
        condition_result
      end
    rescue => e
      raise FlowFailed.new(e)
    end
  end

  def execute_actions(actions)
    actions.map do |action|
      method    = action.fetch(:method)
      params    = action.fetch(:params, [])
      store_as  = action.fetch(:store_as, nil)

      params = params.map do |param|
        (param.is_a?(Symbol) && param.match(/^@/)) ? instance_variable_get(param) : param
      end

      result = send(method, *params)

      if store_as.present? && store_as.is_a?(Symbol) && store_as.match(/^@/)
        instance_variable_set(store_as, result)
      end

      result
    end
  end

end