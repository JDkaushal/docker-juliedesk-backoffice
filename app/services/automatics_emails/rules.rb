module AutomaticsEmails
  module Rules
    TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION = :access_lost_in_thread_native_connexion
    TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION = :access_lost_in_thread_shared_connexion
    TYPE_TECHNICAL_ISSUE                        = :technical_issue

    RULES = {}

    RULES[TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION] = [
      {
        filter: AutomaticsEmails::Filters::Client.new(TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION, 4.hours),
        conditions: [AutomaticsEmails::Conditions::CountLimit.new(5)]
      },
      {
        filter: AutomaticsEmails::Filters::Thread.new(TYPE_ACCESS_LOST_IN_THREAD_NATIVE_CONNEXION, 4.hours),
        conditions: [AutomaticsEmails::Conditions::CountLimit.new(1)]
      }
    ]

    RULES[TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION] = [
        {
            filter: AutomaticsEmails::Filters::Client.new(TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION, 4.hours),
            conditions: [AutomaticsEmails::Conditions::CountLimit.new(5)]
        },
        {
            filter: AutomaticsEmails::Filters::Thread.new(TYPE_ACCESS_LOST_IN_THREAD_SHARED_CONNEXION, 4.hours),
            conditions: [AutomaticsEmails::Conditions::CountLimit.new(1)]
        }
    ]

    RULES[TYPE_TECHNICAL_ISSUE] = [
        {
            filter: AutomaticsEmails::Filters::Client.new(TYPE_TECHNICAL_ISSUE, 4.hours),
            conditions: [AutomaticsEmails::Conditions::CountLimit.new(5)]
        },
        {
            filter: AutomaticsEmails::Filters::Thread.new(TYPE_TECHNICAL_ISSUE, 4.hours),
            conditions: [AutomaticsEmails::Conditions::CountLimit.new(1)]
        }
    ]

  end
end