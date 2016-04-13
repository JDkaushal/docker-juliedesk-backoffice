module FeatureHelper

  def feature_active? feature_name, operator_id=nil, operator_privilege=nil
    feature = Feature.find_by_name feature_name
    if feature
      if operator_id.nil? && operator_privilege.nil?
        true
      else
        feature.active_for_operator? operator_id, operator_privilege
      end
    else
      false
    end
  end
end