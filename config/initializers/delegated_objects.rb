#####

# This file will contains all the delegated objects we need to use in this app

#####

############################## Segment ########################
class DelegatedSegmentClient < SimpleDelegator
  def track(*params)
    unless ENV['STAGING_APP'] == 'TRUE'
      super(*params)
    end
  end
end

if ENV['SEGMENT_WRITE_KEY']
  SEGMENT_CLIENT = DelegatedSegmentClient.new(SimpleSegment::Client.new({write_key: ENV['SEGMENT_WRITE_KEY']}))
end
################################################################


############################## AdminApiInterface ###############
class DelegatedAdminApiInterface < SimpleDelegator
  def build_request(*params)
    unless ENV['STAGING_APP'] == 'TRUE'
      super(*params)
    end
  end
end

ADMIN_API_INTERFACE = DelegatedAdminApiInterface.new(AdminApiInterface.new)
################################################################

############################## AI proxy ###############
class DelegatedAiProxyInterface < SimpleDelegator
  def build_request(*params)
    if ENV['STAGING_APP'] == 'TRUE'
     unless [:send_dates_suggestions_learning_data, :dates_suggestions_auto_process_update].include?(params[0])
       super(*params)
     end
    else
      super(*params)
    end
  end
end

AI_PROXY_INTERFACE = DelegatedAiProxyInterface.new(AiProxy.new)
################################################################