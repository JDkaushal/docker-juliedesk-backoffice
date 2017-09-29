module AutomaticsEmails
  module Rules
    TYPE_ACCESS_LOST_IN_THREAD = :access_lost_in_thread

    RULES = {}

    RULES[TYPE_ACCESS_LOST_IN_THREAD] = [
      {
        filter: AutomaticsEmails::Filters::Client.new(TYPE_ACCESS_LOST_IN_THREAD, 4.hours),
        conditions: [AutomaticsEmails::Conditions::CountLimit.new(5)]
      },
      {
        filter: AutomaticsEmails::Filters::Thread.new(TYPE_ACCESS_LOST_IN_THREAD, 4.hours),
        conditions: [AutomaticsEmails::Conditions::CountLimit.new(1)]
      }
    ]

  end
end