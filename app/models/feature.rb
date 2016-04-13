class Feature < ActiveRecord::Base

  ACTIVE_MODE_ALL = "all"
  ACTIVE_MODE_NONE = "none"
  ACTIVE_MODE_SPECIFIC_OPERATOR_IDS = "specific_operator_ids"
  ACTIVE_MODE_SPECIFIC_OPERATOR_PRIVILEGES = "specific_operator_privileges"

  def active_for_operator? operator_id, operator_privilege
    case active_mode
      when ACTIVE_MODE_ALL
        true
      when ACTIVE_MODE_SPECIFIC_OPERATOR_IDS
        JSON.parse(active_data || "[]").map(&:to_i).include? operator_id
      when ACTIVE_MODE_SPECIFIC_OPERATOR_PRIVILEGES
        JSON.parse(active_data || "[]").include? operator_privilege
      else
        false
    end

  end
end